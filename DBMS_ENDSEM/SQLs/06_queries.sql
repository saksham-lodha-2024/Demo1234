-- =====================================================================
-- Campus Circle — 06_queries.sql
-- Project        : CSE2021 DBMS Mini-Project
-- Author         : Saksham Lodha (240626)
-- Team           : Rishit Rebant (240608), Gauri Pandey (240959),
--                  Saksham Lodha (240626), Prerit Shrivastava (240593)
-- Supervisor     : Dr. Nishtha Phutela
-- Purpose        : DQL (SELECT) showcase — one self-contained script
--                  that demonstrates every query-shape the DBMS rubric
--                  expects.  Each section is labelled so you can run
--                  a single section in the viva when asked.
-- Prerequisite   : 01_schema.sql + 02_seed.sql already executed.
--                  Views / procedures / triggers not required here.
-- How to run     : Execute All, OR highlight any one block and run
--                  just that selection.
-- Rubric hits    : JOINs (INNER, LEFT, RIGHT, self-join), subqueries
--                  (scalar, correlated, EXISTS, IN), aggregates, GROUP
--                  BY, HAVING, ORDER BY, set ops (UNION), string/date
--                  functions, window functions (ROW_NUMBER, RANK,
--                  DENSE_RANK, SUM OVER, LAG), CTE (WITH ... AS).
-- =====================================================================

USE campus_circle;

-- =====================================================================
-- SECTION 1 — Basic projection + filtering (SELECT / WHERE / ORDER BY)
-- =====================================================================

-- 1.1  All BUY items currently available, cheapest first.
SELECT item_id, title, price, availability_status
FROM   items
WHERE  item_type = 'BUY'
  AND  availability_status = 'available'
ORDER  BY price ASC;

-- 1.2  Users in hostels A or B, verified only.
SELECT user_id, name, hostel_block, is_verified
FROM   users
WHERE  hostel_block IN ('Hostel-A', 'Hostel-B')
  AND  is_verified = 1
ORDER  BY hostel_block, name;

-- 1.3  Transactions of the current week (date-range filter + BETWEEN).
SELECT transaction_id, item_id, total_amount, status, created_at
FROM   transactions
WHERE  created_at BETWEEN '2026-04-01' AND '2026-04-30'
ORDER  BY created_at DESC;


-- =====================================================================
-- SECTION 2 — JOINS  (inner, left, right, self-join)
-- =====================================================================

-- 2.1  INNER JOIN — every item with its category and seller name.
SELECT i.item_id, i.title, c.category_name,
       u.name AS seller_name, u.hostel_block,
       i.item_type, i.price, i.rent_price_per_day
FROM   items       i
JOIN   categories  c ON c.category_id = i.category_id
JOIN   users       u ON u.user_id     = i.seller_id
ORDER  BY i.item_id;

-- 2.2  LEFT JOIN — every user and how many listings they have (0 ok).
SELECT u.user_id, u.name,
       COUNT(i.item_id) AS listing_count
FROM   users u
LEFT JOIN items i ON i.seller_id = u.user_id
GROUP  BY u.user_id, u.name
ORDER  BY listing_count DESC, u.name;

-- 2.3  RIGHT JOIN — every category, with item counts (empty cats too).
SELECT c.category_name,
       COUNT(i.item_id) AS item_count
FROM   items      i
RIGHT  JOIN categories c ON c.category_id = i.category_id
GROUP  BY c.category_name
ORDER  BY item_count DESC, c.category_name;

-- 2.4  Multi-table JOIN — full transaction detail view.
SELECT t.transaction_id, t.status, t.total_amount,
       i.title                AS item_title,
       cat.category_name,
       bu.name                AS buyer_name,
       se.name                AS seller_name,
       t.created_at
FROM   transactions t
JOIN   items        i   ON i.item_id       = t.item_id
JOIN   categories   cat ON cat.category_id = i.category_id
JOIN   users        bu  ON bu.user_id      = t.buyer_id
JOIN   users        se  ON se.user_id      = t.seller_id
ORDER  BY t.transaction_id;

-- 2.5  SELF JOIN — pairs of users who live in the same hostel block
--      (demonstrates joining a table to itself with an alias).
SELECT  u1.name AS user_a, u2.name AS user_b, u1.hostel_block
FROM    users u1
JOIN    users u2
  ON    u1.hostel_block = u2.hostel_block
 AND    u1.user_id      < u2.user_id         -- avoid dup pairs (A,B)/(B,A)
ORDER   BY u1.hostel_block, u1.name;


-- =====================================================================
-- SECTION 3 — AGGREGATES  (COUNT, SUM, AVG, MIN, MAX) + GROUP BY + HAVING
-- =====================================================================

-- 3.1  Global platform stats (single-row aggregate).
SELECT
    (SELECT COUNT(*) FROM users)        AS total_users,
    (SELECT COUNT(*) FROM items)        AS total_items,
    (SELECT COUNT(*) FROM transactions) AS total_transactions,
    (SELECT COUNT(*) FROM reviews)      AS total_reviews,
    (SELECT ROUND(AVG(rating),2) FROM reviews)       AS avg_review_rating,
    (SELECT SUM(total_amount)  FROM transactions
     WHERE status = 'completed')                     AS gmv_completed;

-- 3.2  Items per category (GROUP BY).
SELECT c.category_name,
       COUNT(i.item_id) AS item_count
FROM   categories c
LEFT   JOIN items i ON i.category_id = c.category_id
GROUP  BY c.category_name
ORDER  BY item_count DESC;

-- 3.3  Avg price per category, only categories with 2+ items (HAVING).
SELECT c.category_name,
       COUNT(i.item_id)        AS listings,
       ROUND(AVG(i.price), 2)  AS avg_price
FROM   categories c
JOIN   items      i ON i.category_id = c.category_id
WHERE  i.item_type = 'BUY'
GROUP  BY c.category_name
HAVING COUNT(i.item_id) >= 2
ORDER  BY avg_price DESC;

-- 3.4  Transaction volume + value by status.
SELECT status,
       COUNT(*)              AS cnt,
       SUM(total_amount)     AS total_value,
       ROUND(AVG(total_amount), 2) AS avg_value
FROM   transactions
GROUP  BY status
ORDER  BY cnt DESC;

-- 3.5  Listings-per-hostel breakdown (GROUP BY with JOIN).
SELECT u.hostel_block,
       COUNT(i.item_id) AS listings
FROM   users u
JOIN   items i ON i.seller_id = u.user_id
GROUP  BY u.hostel_block
ORDER  BY listings DESC;


-- =====================================================================
-- SECTION 4 — SUBQUERIES  (scalar, correlated, EXISTS, IN)
-- =====================================================================

-- 4.1  Scalar subquery in WHERE — items priced above the global avg.
SELECT item_id, title, price
FROM   items
WHERE  item_type = 'BUY'
  AND  price > (SELECT AVG(price) FROM items WHERE item_type='BUY')
ORDER  BY price DESC;

-- 4.2  Correlated subquery — for each seller, how many of their listings
--      are currently available.
SELECT u.user_id, u.name,
       (SELECT COUNT(*) FROM items i
         WHERE i.seller_id = u.user_id
           AND i.availability_status = 'available') AS available_listings
FROM   users u
ORDER  BY available_listings DESC, u.name;

-- 4.3  EXISTS — users who have at least one completed transaction
--      (either as buyer or seller).
SELECT u.user_id, u.name
FROM   users u
WHERE  EXISTS (
         SELECT 1 FROM transactions t
         WHERE  (t.buyer_id = u.user_id OR t.seller_id = u.user_id)
           AND  t.status    = 'completed'
       );

-- 4.4  NOT EXISTS — users who have never submitted a review.
SELECT u.user_id, u.name
FROM   users u
WHERE  NOT EXISTS (
         SELECT 1 FROM reviews r
         WHERE  r.reviewer_id = u.user_id
       );

-- 4.5  IN subquery — items in the top-3 categories (by listing count).
--      MySQL refuses LIMIT directly inside an IN subquery
--      (Error 1235: "This version of MySQL doesn't yet support
--       'LIMIT & IN/ALL/ANY/SOME subquery'"), so we wrap the inner
--      LIMITed query in a derived table alias — MySQL materializes it
--      first, then treats the outer as a plain IN-list.
SELECT i.item_id, i.title, c.category_name
FROM   items i
JOIN   categories c ON c.category_id = i.category_id
WHERE  i.category_id IN (
         SELECT category_id FROM (
             SELECT   category_id
             FROM     items
             GROUP BY category_id
             ORDER BY COUNT(*) DESC
             LIMIT    3
         ) top3
       )
ORDER  BY c.category_name, i.title;

-- 4.6  ANY / ALL — items cheaper than ALL items in 'Electronics'.
SELECT item_id, title, price, category_id
FROM   items
WHERE  item_type = 'BUY'
  AND  price < ALL (
         SELECT i2.price
         FROM   items i2
         JOIN   categories c2 ON c2.category_id = i2.category_id
         WHERE  c2.category_name = 'Electronics'
           AND  i2.price IS NOT NULL
       )
ORDER  BY price;


-- =====================================================================
-- SECTION 5 — WINDOW FUNCTIONS  (MySQL 8+)
-- =====================================================================

-- 5.1  ROW_NUMBER — rank items by price within each category.
SELECT
    c.category_name,
    i.title,
    i.price,
    ROW_NUMBER() OVER (PARTITION BY c.category_id
                       ORDER BY i.price DESC) AS price_rank_in_category
FROM   items i
JOIN   categories c ON c.category_id = i.category_id
WHERE  i.item_type = 'BUY'
ORDER  BY c.category_name, price_rank_in_category;

-- 5.2  RANK + DENSE_RANK on users by avg rating.
SELECT
    u.user_id, u.name,
    ROUND(AVG(r.rating),2) AS avg_rating,
    RANK()       OVER (ORDER BY AVG(r.rating) DESC) AS rank_by_rating,
    DENSE_RANK() OVER (ORDER BY AVG(r.rating) DESC) AS dense_rank_by_rating
FROM   users u
JOIN   reviews r ON r.review_for_user_id = u.user_id
GROUP  BY u.user_id, u.name;

-- 5.3  SUM OVER — running total of completed transactions by date.
SELECT
    transaction_id,
    created_at,
    total_amount,
    SUM(total_amount) OVER (ORDER BY created_at, transaction_id
                            ROWS BETWEEN UNBOUNDED PRECEDING
                                     AND CURRENT ROW) AS running_gmv
FROM   transactions
WHERE  status = 'completed'
ORDER  BY created_at, transaction_id;

-- 5.4  LAG — show each transaction's amount against the previous txn
--      for the same seller.
SELECT
    t.seller_id,
    t.transaction_id,
    t.total_amount,
    LAG(t.total_amount)    OVER (PARTITION BY t.seller_id
                                 ORDER BY t.created_at) AS prev_txn_amount,
    t.total_amount
      - LAG(t.total_amount) OVER (PARTITION BY t.seller_id
                                  ORDER BY t.created_at) AS delta_vs_prev
FROM   transactions t
ORDER  BY t.seller_id, t.created_at;


-- =====================================================================
-- SECTION 6 — CTEs  (WITH ... AS)  — MySQL 8+
-- =====================================================================

-- 6.1  Multi-CTE chain: (a) completed transactions, (b) seller totals,
--      (c) top-3 seller earnings ranking.
WITH completed_txn AS (
        SELECT * FROM transactions WHERE status = 'completed'
     ),
     seller_totals AS (
        SELECT seller_id, SUM(total_amount) AS total_earnings
        FROM   completed_txn
        GROUP  BY seller_id
     )
SELECT u.user_id, u.name,
       st.total_earnings,
       DENSE_RANK() OVER (ORDER BY st.total_earnings DESC) AS earnings_rank
FROM   seller_totals st
JOIN   users u ON u.user_id = st.seller_id
ORDER  BY st.total_earnings DESC
LIMIT  3;


-- =====================================================================
-- SECTION 7 — SET OPERATIONS
-- =====================================================================

-- 7.1  UNION — every distinct user who has appeared in any transaction
--      (as buyer OR seller).
SELECT user_id, 'buyer'  AS role FROM transactions t JOIN users u ON u.user_id=t.buyer_id
UNION
SELECT user_id, 'seller' AS role FROM transactions t JOIN users u ON u.user_id=t.seller_id;

-- 7.2  UNION ALL — per-user tally of how often they appear as buyer and
--      as seller (kept separate, then rolled up).
SELECT role, COUNT(*) AS appearances
FROM (
    SELECT buyer_id  AS user_id, 'buyer'  AS role FROM transactions
    UNION ALL
    SELECT seller_id AS user_id, 'seller' AS role FROM transactions
) x
GROUP BY role;


-- =====================================================================
-- SECTION 8 — STRING + DATE FUNCTIONS
-- =====================================================================

-- 8.1  CONCAT + FORMAT + DATE_FORMAT for display-friendly output.
SELECT
    t.transaction_id,
    CONCAT(bu.name, ' → ', se.name)                           AS parties,
    CONCAT('Rs. ', FORMAT(t.total_amount, 2))                 AS amount_display,
    DATE_FORMAT(t.created_at, '%d-%b-%Y %h:%i %p')            AS when_created,
    UPPER(t.status)                                           AS status_badge
FROM   transactions t
JOIN   users bu ON bu.user_id = t.buyer_id
JOIN   users se ON se.user_id = t.seller_id
ORDER  BY t.created_at DESC
LIMIT  10;

-- 8.2  DATEDIFF — for RENT transactions, how many days the rental ran.
SELECT transaction_id, start_date, end_date,
       DATEDIFF(end_date, start_date) + 1 AS rental_days,
       total_amount
FROM   transactions
WHERE  transaction_type = 'RENT'
  AND  start_date IS NOT NULL
  AND  end_date   IS NOT NULL
ORDER  BY rental_days DESC;


-- =====================================================================
-- SECTION 9 — DML showcase (UPDATE + DELETE with WHERE)
--             Marked SAFE with WHERE + LIMIT — harmless to re-run.
-- =====================================================================

-- 9.1  Safe UPDATE demo — raise phone visibility for verified users
--      that have no phone on file.  (Does nothing if none match.)
UPDATE users
   SET updated_at = CURRENT_TIMESTAMP
 WHERE is_verified = 1
   AND phone_number IS NULL;

-- 9.2  Safe DELETE demo — remove any audit_log rows older than 1 year.
--      (Currently 0 rows qualify, but the statement is syntactically valid.)
DELETE FROM audit_log
WHERE  created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);


-- =====================================================================
-- SECTION 10 — CHALLENGE QUERIES
--              Composite queries that mix 3+ techniques from above —
--              great viva-demo material.
-- =====================================================================

-- 10.1  Best-selling category: the category with the highest total GMV
--       from completed transactions (JOIN + GROUP BY + ORDER BY + LIMIT).
SELECT c.category_name,
       COUNT(t.transaction_id)     AS completed_txns,
       SUM(t.total_amount)         AS total_gmv
FROM   transactions t
JOIN   items      i ON i.item_id     = t.item_id
JOIN   categories c ON c.category_id = i.category_id
WHERE  t.status = 'completed'
GROUP  BY c.category_name
ORDER  BY total_gmv DESC
LIMIT  1;

-- 10.2  Power sellers: users who have sold ≥2 items AND have avg
--       review ≥ 4  (multi-condition HAVING on a JOIN aggregate).
SELECT u.user_id, u.name,
       COUNT(DISTINCT CASE WHEN t.status='completed'
                           THEN t.transaction_id END) AS items_sold,
       ROUND(AVG(r.rating), 2)                        AS avg_rating
FROM   users u
LEFT   JOIN transactions t ON t.seller_id          = u.user_id
LEFT   JOIN reviews      r ON r.review_for_user_id = u.user_id
GROUP  BY u.user_id, u.name
HAVING items_sold >= 2
   AND avg_rating >= 4
ORDER  BY items_sold DESC, avg_rating DESC;

-- 10.3  Lonely sellers — verified users who have listed items but
--       never completed a transaction (anti-join via NOT EXISTS).
SELECT u.user_id, u.name,
       COUNT(i.item_id) AS listings
FROM   users u
JOIN   items i ON i.seller_id = u.user_id
WHERE  u.is_verified = 1
  AND  NOT EXISTS (
         SELECT 1 FROM transactions t
         WHERE  t.seller_id = u.user_id
           AND  t.status    = 'completed'
       )
GROUP  BY u.user_id, u.name
ORDER  BY listings DESC;

-- 10.4  Category leaderboard with window function — for each category,
--       show the single most-expensive available BUY item.
SELECT category_name, title, price
FROM (
    SELECT c.category_name, i.title, i.price,
           ROW_NUMBER() OVER (PARTITION BY c.category_id
                              ORDER BY i.price DESC) AS rn
    FROM   items      i
    JOIN   categories c ON c.category_id = i.category_id
    WHERE  i.item_type          = 'BUY'
      AND  i.availability_status = 'available'
) ranked
WHERE rn = 1
ORDER BY price DESC;