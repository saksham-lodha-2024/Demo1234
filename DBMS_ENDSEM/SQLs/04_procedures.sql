-- =====================================================================
-- Campus Circle — 04_procedures.sql
-- Project        : CSE2021 DBMS Mini-Project
-- Author         : Saksham Lodha (240626)
-- Team           : Rishit Rebant (240608), Gauri Pandey (240959),
--                  Saksham Lodha (240626), Prerit Shrivastava (240593)
-- Supervisor     : Dr. Nishtha Phutela
-- Purpose        : Stored Procedures + User-Defined Functions.
--                  These encapsulate the core business logic of the
--                  Campus Circle marketplace so the Android app can
--                  invoke them via JDBC as atomic operations.
-- Prerequisite   : 01_schema.sql, 02_seed.sql, 03_views.sql executed.
-- How to run     : Open in MySQL Workbench → Execute All (Cmd+Shift+Enter).
-- Rubric hits    : IN / OUT parameters, control flow (IF, CASE),
--                  SIGNAL SQLSTATE error handling, SELECT INTO,
--                  DECLARE HANDLER, EXISTS subqueries, aggregates.
-- =====================================================================

USE campus_circle;

-- ---------------------------------------------------------------------
-- Drop existing routines first (idempotent re-runs)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_list_new_item;
DROP PROCEDURE IF EXISTS sp_create_transaction;
DROP PROCEDURE IF EXISTS sp_complete_transaction;
DROP PROCEDURE IF EXISTS sp_submit_review;
DROP PROCEDURE IF EXISTS sp_verify_user;

DROP FUNCTION  IF EXISTS fn_user_avg_rating;
DROP FUNCTION  IF EXISTS fn_user_review_count;
DROP FUNCTION  IF EXISTS fn_user_total_earnings;


-- =====================================================================
-- FUNCTION 1 : fn_user_avg_rating(user_id)
-- Returns average rating (1..5) received by a user, or 0 if no reviews.
-- =====================================================================
DELIMITER $$

CREATE FUNCTION fn_user_avg_rating(p_user_id INT)
RETURNS DECIMAL(3,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avg DECIMAL(3,2);

    SELECT IFNULL(ROUND(AVG(rating), 2), 0.00)
      INTO v_avg
      FROM reviews
     WHERE review_for_user_id = p_user_id;

    RETURN v_avg;
END$$

DELIMITER ;


-- =====================================================================
-- FUNCTION 2 : fn_user_review_count(user_id)
-- Returns total number of reviews a user has received.
-- =====================================================================
DELIMITER $$

CREATE FUNCTION fn_user_review_count(p_user_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*)
      INTO v_count
      FROM reviews
     WHERE review_for_user_id = p_user_id;

    RETURN v_count;
END$$

DELIMITER ;


-- =====================================================================
-- FUNCTION 3 : fn_user_total_earnings(user_id)
-- Returns sum of completed-transaction amounts where user was seller.
-- =====================================================================
DELIMITER $$

CREATE FUNCTION fn_user_total_earnings(p_user_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_earnings DECIMAL(10,2);

    SELECT IFNULL(SUM(total_amount), 0.00)
      INTO v_earnings
      FROM transactions
     WHERE seller_id = p_user_id
       AND status    = 'completed';

    RETURN v_earnings;
END$$

DELIMITER ;


-- =====================================================================
-- PROCEDURE 1 : sp_list_new_item
-- Seller lists a new item. Validates the seller exists and is verified,
-- validates price/rent fields match the item_type, then inserts.
-- Uses IN + OUT parameters, SIGNAL for custom errors.
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE sp_list_new_item(
    IN  p_seller_id          INT,
    IN  p_category_id        INT,
    IN  p_title              VARCHAR(150),
    IN  p_item_type          ENUM('BUY', 'RENT'),
    IN  p_price              DECIMAL(8,2),
    IN  p_rent_price_per_day DECIMAL(8,2),
    OUT p_new_item_id        INT
)
BEGIN
    DECLARE v_seller_exists INT DEFAULT 0;
    DECLARE v_is_verified   TINYINT DEFAULT 0;

    -- 1. seller must exist
    SELECT COUNT(*), IFNULL(MAX(is_verified), 0)
      INTO v_seller_exists, v_is_verified
      FROM users
     WHERE user_id = p_seller_id;

    IF v_seller_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_list_new_item: seller does not exist';
    END IF;

    -- 2. seller must be verified before they can list
    IF v_is_verified = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_list_new_item: seller is not verified';
    END IF;

    -- 3. price/rent must match the item_type
    IF p_item_type = 'BUY' AND (p_price IS NULL OR p_price < 0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_list_new_item: BUY item needs non-negative price';
    END IF;

    IF p_item_type = 'RENT' AND (p_rent_price_per_day IS NULL OR p_rent_price_per_day < 0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_list_new_item: RENT item needs non-negative rent_price_per_day';
    END IF;

    -- 4. do the insert
    INSERT INTO items (seller_id, category_id, title, item_type, price, rent_price_per_day)
    VALUES (p_seller_id, p_category_id, p_title, p_item_type,
            CASE WHEN p_item_type = 'BUY'  THEN p_price              ELSE NULL END,
            CASE WHEN p_item_type = 'RENT' THEN p_rent_price_per_day ELSE NULL END);

    SET p_new_item_id = LAST_INSERT_ID();
END$$

DELIMITER ;


-- =====================================================================
-- PROCEDURE 2 : sp_create_transaction
-- Buyer creates a transaction on an available item. Reserves the item
-- atomically (wrapped in a START TRANSACTION block with a rollback
-- handler so any mid-flight failure leaves the database consistent).
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE sp_create_transaction(
    IN  p_item_id        INT,
    IN  p_buyer_id       INT,
    IN  p_start_date     DATE,
    IN  p_end_date       DATE,
    OUT p_new_trx_id     INT
)
BEGIN
    DECLARE v_seller_id       INT;
    DECLARE v_item_type       ENUM('BUY','RENT');
    DECLARE v_avail           ENUM('available','reserved','sold','rented','removed');
    DECLARE v_price           DECIMAL(8,2);
    DECLARE v_rent            DECIMAL(8,2);
    DECLARE v_days            INT;
    DECLARE v_total           DECIMAL(8,2);

    -- auto-rollback + re-raise on any SQL exception inside this procedure
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. fetch item state
    SELECT seller_id, item_type, availability_status, price, rent_price_per_day
      INTO v_seller_id, v_item_type, v_avail, v_price, v_rent
      FROM items
     WHERE item_id = p_item_id
     FOR UPDATE;                    -- lock the row until we commit

    -- 2. validations
    IF v_seller_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_create_transaction: item does not exist';
    END IF;

    IF v_avail <> 'available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_create_transaction: item is not available';
    END IF;

    IF v_seller_id = p_buyer_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_create_transaction: buyer cannot be the seller';
    END IF;

    -- 3. compute total_amount based on type
    IF v_item_type = 'BUY' THEN
        SET v_total = v_price;
    ELSE
        IF p_start_date IS NULL OR p_end_date IS NULL OR p_end_date < p_start_date THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'sp_create_transaction: invalid rent date range';
        END IF;
        SET v_days  = DATEDIFF(p_end_date, p_start_date) + 1;
        SET v_total = v_rent * v_days;
    END IF;

    -- 4. insert transaction row
    INSERT INTO transactions
        (item_id, buyer_id, seller_id, transaction_type, start_date, end_date,
         total_amount, payment_status, status)
    VALUES
        (p_item_id, p_buyer_id, v_seller_id, v_item_type,
         p_start_date, p_end_date, v_total, 'pending', 'requested');

    SET p_new_trx_id = LAST_INSERT_ID();

    -- 5. reserve the item so nobody else can transact on it
    UPDATE items
       SET availability_status = 'reserved'
     WHERE item_id = p_item_id;

    COMMIT;
END$$

DELIMITER ;


-- =====================================================================
-- PROCEDURE 3 : sp_complete_transaction
-- Marks a transaction as completed, flips the item to sold/rented,
-- releases payment. Wrapped in transaction for atomicity.
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE sp_complete_transaction(
    IN p_transaction_id INT
)
BEGIN
    DECLARE v_item_id     INT;
    DECLARE v_trx_type    ENUM('BUY','RENT');
    DECLARE v_cur_status  ENUM('requested','approved','active','completed','cancelled','rejected');
    DECLARE v_new_avail   ENUM('available','reserved','sold','rented','removed');

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT item_id, transaction_type, status
      INTO v_item_id, v_trx_type, v_cur_status
      FROM transactions
     WHERE transaction_id = p_transaction_id
     FOR UPDATE;

    IF v_item_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_complete_transaction: transaction not found';
    END IF;

    IF v_cur_status IN ('completed','cancelled','rejected') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_complete_transaction: transaction already finalized';
    END IF;

    -- BUY → item becomes sold; RENT → item becomes rented
    SET v_new_avail = CASE v_trx_type WHEN 'BUY' THEN 'sold' ELSE 'rented' END;

    UPDATE transactions
       SET status         = 'completed',
           payment_status = 'released'
     WHERE transaction_id = p_transaction_id;

    UPDATE items
       SET availability_status = v_new_avail
     WHERE item_id = v_item_id;

    COMMIT;
END$$

DELIMITER ;


-- =====================================================================
-- PROCEDURE 4 : sp_submit_review
-- Writes a review. Enforces: transaction must be completed; reviewer
-- must be either the buyer or the seller; reviewer cannot review self;
-- at most one review per (transaction, reviewer).
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE sp_submit_review(
    IN  p_transaction_id INT,
    IN  p_reviewer_id    INT,
    IN  p_rating         INT,
    IN  p_comment        TEXT,
    OUT p_new_review_id  INT
)
BEGIN
    DECLARE v_buyer_id     INT;
    DECLARE v_seller_id    INT;
    DECLARE v_status       ENUM('requested','approved','active','completed','cancelled','rejected');
    DECLARE v_review_for   INT;
    DECLARE v_dupe         INT DEFAULT 0;

    SELECT buyer_id, seller_id, status
      INTO v_buyer_id, v_seller_id, v_status
      FROM transactions
     WHERE transaction_id = p_transaction_id;

    IF v_buyer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_submit_review: transaction not found';
    END IF;

    IF v_status <> 'completed' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_submit_review: cannot review a non-completed transaction';
    END IF;

    IF p_rating < 1 OR p_rating > 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_submit_review: rating must be between 1 and 5';
    END IF;

    -- reviewer must be one of the parties
    IF p_reviewer_id = v_buyer_id THEN
        SET v_review_for = v_seller_id;
    ELSEIF p_reviewer_id = v_seller_id THEN
        SET v_review_for = v_buyer_id;
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_submit_review: reviewer is not a party to this transaction';
    END IF;

    -- check for dupe (also enforced by UNIQUE index, but we want a clean error)
    SELECT COUNT(*)
      INTO v_dupe
      FROM reviews
     WHERE transaction_id = p_transaction_id
       AND reviewer_id    = p_reviewer_id;

    IF v_dupe > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_submit_review: reviewer has already reviewed this transaction';
    END IF;

    INSERT INTO reviews (transaction_id, reviewer_id, review_for_user_id, rating, comment)
    VALUES (p_transaction_id, p_reviewer_id, v_review_for, p_rating, p_comment);

    SET p_new_review_id = LAST_INSERT_ID();
END$$

DELIMITER ;


-- =====================================================================
-- PROCEDURE 5 : sp_verify_user
-- Admin verifies a user. Checks admin exists and user exists,
-- then flips is_verified=1 and stamps verified_by.
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE sp_verify_user(
    IN p_admin_id INT,
    IN p_user_id  INT
)
BEGIN
    DECLARE v_admin_ok INT DEFAULT 0;
    DECLARE v_user_ok  INT DEFAULT 0;

    SELECT COUNT(*) INTO v_admin_ok FROM admin WHERE admin_id = p_admin_id;
    SELECT COUNT(*) INTO v_user_ok  FROM users WHERE user_id  = p_user_id;

    IF v_admin_ok = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_verify_user: admin does not exist';
    END IF;

    IF v_user_ok = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_verify_user: user does not exist';
    END IF;

    UPDATE users
       SET is_verified = 1,
           verified_by = p_admin_id
     WHERE user_id     = p_user_id;
END$$

DELIMITER ;


-- =====================================================================
-- SANITY CHECKS (run after creation)
-- =====================================================================

-- 1. Confirm all 5 procs + 3 functions exist.
SELECT ROUTINE_TYPE, ROUTINE_NAME
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = 'campus_circle'
ORDER  BY ROUTINE_TYPE, ROUTINE_NAME;

-- 2. Functions demo (using seed data)
SELECT
    u.user_id,
    u.name,
    fn_user_avg_rating(u.user_id)     AS avg_rating,
    fn_user_review_count(u.user_id)   AS review_count,
    fn_user_total_earnings(u.user_id) AS total_earnings
FROM users u
ORDER BY total_earnings DESC
LIMIT 5;

-- 3. Procedure demo: verify a user. (user_id=12 in seed is unverified — flip it)
--    Safe because sp_verify_user is idempotent.
CALL sp_verify_user(1, 12);
SELECT user_id, name, is_verified, verified_by FROM users WHERE user_id = 12;

-- 4. Procedure demo: list a new item for Saksham (user_id=3, verified).
SET @new_item := NULL;
CALL sp_list_new_item(3, 2, 'Test: USB-C Hub 6-in-1', 'BUY', 1200.00, NULL, @new_item);
SELECT @new_item AS new_item_id;
SELECT * FROM items WHERE item_id = @new_item;

-- 5. Procedure demo: a different buyer (user_id=1, Rishit) buys that item.
SET @new_trx := NULL;
CALL sp_create_transaction(@new_item, 1, NULL, NULL, @new_trx);
SELECT @new_trx AS new_trx_id;
SELECT * FROM transactions WHERE transaction_id = @new_trx;

-- 6. Procedure demo: complete that transaction.
CALL sp_complete_transaction(@new_trx);
SELECT transaction_id, status, payment_status FROM transactions WHERE transaction_id = @new_trx;
SELECT item_id, title, availability_status      FROM items        WHERE item_id        = @new_item;

-- 7. Procedure demo: Rishit (buyer) reviews Saksham (seller) for that transaction.
SET @new_rev := NULL;
CALL sp_submit_review(@new_trx, 1, 5, 'Smooth pickup, item as described.', @new_rev);
SELECT * FROM reviews WHERE review_id = @new_rev;