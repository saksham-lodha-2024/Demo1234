-- =====================================================================
-- Campus Circle — 05_triggers.sql
-- Project        : CSE2021 DBMS Mini-Project
-- Author         : Saksham Lodha (240626)
-- Team           : Rishit Rebant (240608), Gauri Pandey (240959),
--                  Saksham Lodha (240626), Prerit Shrivastava (240593)
-- Supervisor     : Dr. Nishtha Phutela
-- Purpose        : Database triggers for automated side-effects and
--                  enforced invariants.  Covers the "triggers" rubric
--                  requirement of CSE2021.
-- Prerequisite   : 01_schema.sql, 02_seed.sql, 03_views.sql,
--                  04_procedures.sql executed.
-- How to run     : Open in MySQL Workbench → Execute All (Cmd+Shift+Enter).
-- Rubric hits    : BEFORE vs AFTER, INSERT/UPDATE/DELETE triggers,
--                  OLD and NEW row references, SIGNAL SQLSTATE, FOR EACH ROW.
-- =====================================================================

USE campus_circle;

-- ---------------------------------------------------------------------
-- 0.  audit_log table — used by AFTER triggers for logging events.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    audit_id    INT AUTO_INCREMENT PRIMARY KEY,
    event_type  VARCHAR(40)  NOT NULL,
    entity      VARCHAR(40)  NOT NULL,
    entity_id   INT          NOT NULL,
    details     VARCHAR(255),
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Drop existing triggers first (idempotent re-runs)
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_insert_items;
DROP TRIGGER IF EXISTS trg_after_insert_items;
DROP TRIGGER IF EXISTS trg_before_delete_items;
DROP TRIGGER IF EXISTS trg_after_insert_transaction;
DROP TRIGGER IF EXISTS trg_after_update_transaction;
DROP TRIGGER IF EXISTS trg_after_insert_reviews;


-- =====================================================================
-- TRIGGER 1 : trg_before_insert_items
-- Purpose : Belt-and-braces invariant.  CHECK constraints handle the
--           "price >= 0" rule, but we also need "BUY items must have a
--           price" and "RENT items must have a rent_price_per_day".
--           This is a semantic rule that CHECK cannot fully express
--           cross-column without it getting messy, so we do it here.
-- Type    : BEFORE INSERT, row-level, SIGNAL on violation.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_before_insert_items
BEFORE INSERT ON items
FOR EACH ROW
BEGIN
    IF NEW.item_type = 'BUY' AND NEW.price IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'trg_before_insert_items: BUY item must have a price';
    END IF;

    IF NEW.item_type = 'RENT' AND NEW.rent_price_per_day IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'trg_before_insert_items: RENT item must have a rent_price_per_day';
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- TRIGGER 2 : trg_after_insert_items
-- Purpose : Log every new listing into the audit_log.
-- Type    : AFTER INSERT, row-level.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_after_insert_items
AFTER INSERT ON items
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (event_type, entity, entity_id, details)
    VALUES ('ITEM_LISTED', 'items', NEW.item_id,
            CONCAT('seller_id=', NEW.seller_id,
                   ', type=',    NEW.item_type,
                   ', title=',   NEW.title));
END$$

DELIMITER ;


-- =====================================================================
-- TRIGGER 3 : trg_before_delete_items
-- Purpose : Prevent deleting items that still have non-final
--           transactions (requested / approved / active).  This protects
--           against accidental data loss during the MAD app demo.
-- Type    : BEFORE DELETE, row-level, SIGNAL on violation.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_before_delete_items
BEFORE DELETE ON items
FOR EACH ROW
BEGIN
    DECLARE v_open_count INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_open_count
      FROM transactions
     WHERE item_id = OLD.item_id
       AND status IN ('requested', 'approved', 'active');

    IF v_open_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'trg_before_delete_items: item has open transactions, cannot delete';
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- TRIGGER 4 : trg_after_insert_transaction
-- Purpose : Log every new transaction into the audit_log.
-- Type    : AFTER INSERT, row-level.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_after_insert_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (event_type, entity, entity_id, details)
    VALUES ('TRX_CREATED', 'transactions', NEW.transaction_id,
            CONCAT('item_id=', NEW.item_id,
                   ', buyer=', NEW.buyer_id,
                   ', seller=', NEW.seller_id,
                   ', amount=', NEW.total_amount));
END$$

DELIMITER ;


-- =====================================================================
-- TRIGGER 5 : trg_after_update_transaction
-- Purpose : Lifecycle automation.  When a transaction is moved into a
--           terminal "unsuccessful" state (cancelled / rejected) and
--           the underlying item is still 'reserved', release the
--           reservation so the item becomes available for others.
--           Also logs the status change.
-- Type    : AFTER UPDATE, row-level.  Uses OLD vs NEW to detect
--           status transitions.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_after_update_transaction
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
    -- 1) only act if status actually changed
    IF OLD.status <> NEW.status THEN

        INSERT INTO audit_log (event_type, entity, entity_id, details)
        VALUES ('TRX_STATUS_CHANGE', 'transactions', NEW.transaction_id,
                CONCAT('from=', OLD.status, ' to=', NEW.status));

        -- 2) if the txn was just killed AND the item is still reserved, release it
        IF NEW.status IN ('cancelled', 'rejected') THEN
            UPDATE items
               SET availability_status = 'available'
             WHERE item_id = NEW.item_id
               AND availability_status = 'reserved';
        END IF;

    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- TRIGGER 6 : trg_after_insert_reviews
-- Purpose : Log every new review into audit_log with a rating summary.
-- Type    : AFTER INSERT, row-level.
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_after_insert_reviews
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (event_type, entity, entity_id, details)
    VALUES ('REVIEW_SUBMITTED', 'reviews', NEW.review_id,
            CONCAT('trx=', NEW.transaction_id,
                   ', reviewer=', NEW.reviewer_id,
                   ', for_user=', NEW.review_for_user_id,
                   ', rating=',   NEW.rating));
END$$

DELIMITER ;


-- =====================================================================
-- SANITY CHECKS (run after creation)
-- =====================================================================

-- 1. Confirm all 6 triggers exist.
SELECT TRIGGER_NAME, EVENT_MANIPULATION, ACTION_TIMING, EVENT_OBJECT_TABLE
FROM   information_schema.TRIGGERS
WHERE  TRIGGER_SCHEMA = 'campus_circle'
ORDER  BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;

-- 2. Demo: a simple INSERT of a RENT item via sp_list_new_item
--    should auto-write an ITEM_LISTED row to audit_log.
SET @trig_item := NULL;
CALL sp_list_new_item(3, 3, 'Test Trigger: 3-hole puncher', 'RENT', NULL, 20.00, @trig_item);
SELECT @trig_item AS new_item_id;

SELECT * FROM audit_log
 WHERE entity = 'items' AND entity_id = @trig_item;


-- 3. Demo: invalid BUY insert (no price) should raise our custom error.
--    Wrap in a try-style select: if it succeeds, something is wrong.
--    Uncomment the next block to prove the trigger fires:
/*
INSERT INTO items (seller_id, category_id, title, item_type, price, rent_price_per_day)
VALUES (3, 2, 'Broken test: BUY item with no price', 'BUY', NULL, NULL);
-- Expected: ERROR 1644 (45000): trg_before_insert_items: BUY item must have a price
*/


-- 4. Demo: create a new transaction then CANCEL it; trigger 5 should
--    release the item from 'reserved' back to 'available' AND log the
--    status change.
SET @trig_trx := NULL;
CALL sp_create_transaction(@trig_item, 1, '2026-05-01', '2026-05-03', @trig_trx);
SELECT item_id, availability_status FROM items WHERE item_id = @trig_item;   -- should show 'reserved'

UPDATE transactions SET status = 'cancelled' WHERE transaction_id = @trig_trx;
SELECT item_id, availability_status FROM items WHERE item_id = @trig_item;   -- should show 'available'

-- Audit log snapshot for this transaction lifecycle:
SELECT * FROM audit_log
 WHERE entity = 'transactions' AND entity_id = @trig_trx
 ORDER BY audit_id;


-- 5. Demo: attempt to DELETE an item that has an open transaction —
--    trigger 3 should block it with our custom error.
--    Uncomment the next block to demo the block:
/*
-- First create an item with an OPEN transaction (non-terminal status):
SET @del_item := NULL;
CALL sp_list_new_item(3, 4, 'Test Delete Block: Cricket Bat', 'RENT', NULL, 50.00, @del_item);
SET @del_trx := NULL;
CALL sp_create_transaction(@del_item, 1, '2026-06-01', '2026-06-03', @del_trx);
DELETE FROM items WHERE item_id = @del_item;
-- Expected: ERROR 1644 (45000): trg_before_delete_items: item has open transactions, cannot delete
*/


-- 6. Final view of the audit_log.
SELECT * FROM audit_log ORDER BY audit_id DESC LIMIT 15;