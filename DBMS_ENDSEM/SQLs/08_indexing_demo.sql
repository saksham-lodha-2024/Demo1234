-- =====================================================================
-- Campus Circle — 08_indexing_demo.sql
-- Project        : CSE2021 DBMS Mini-Project
-- Author         : Saksham Lodha (240626)
-- Team           : Rishit Rebant (240608), Gauri Pandey (240959),
--                  Saksham Lodha (240626), Prerit Shrivastava (240593)
-- Supervisor     : Dr. Nishtha Phutela
-- Purpose        : Indexing demonstration — shows how an index changes
--                  the query plan.  Covers the DBMS rubric bullet on
--                  "indexing basics" and explains what the MySQL
--                  optimizer does with and without an index.
-- Prerequisite   : 01_schema.sql + 02_seed.sql already executed.
-- How to run     : Execute All (Cmd+Shift+Enter).  Compare the "type",
--                  "key" and "rows" columns of the EXPLAIN output
--                  BEFORE vs AFTER each CREATE INDEX.
-- Rubric hits    : EXPLAIN, SHOW INDEX, CREATE INDEX, DROP INDEX,
--                  composite / multi-column indexes, leftmost-prefix
--                  rule, B-Tree vs FULLTEXT (informational).
-- Note           : MySQL does NOT support "DROP INDEX IF EXISTS".
--                  We build a tiny helper procedure to simulate it.
-- =====================================================================

USE campus_circle;

-- Make the optimiser use up-to-date statistics.
ANALYZE TABLE admin, users, categories, items, transactions, meetup_slots, reviews;


-- =====================================================================
-- Helper procedure: drop an index only if it exists (MySQL lacks
-- native DROP INDEX IF EXISTS).  Defined once, used everywhere below.
-- =====================================================================
DROP PROCEDURE IF EXISTS _drop_index_if_exists;

DELIMITER $$

CREATE PROCEDURE _drop_index_if_exists(
    IN p_tbl VARCHAR(64),
    IN p_idx VARCHAR(64)
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM   information_schema.STATISTICS
        WHERE  TABLE_SCHEMA = DATABASE()
          AND  TABLE_NAME   = p_tbl
          AND  INDEX_NAME   = p_idx
    ) THEN
        SET @sql := CONCAT('DROP INDEX ', p_idx, ' ON ', p_tbl);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- SECTION 1 — Inventory of every existing index on every table.
-- Pulled from information_schema so we see all 9 seed-level indexes
-- that 01_schema.sql created.
-- =====================================================================
SELECT 'SECTION 1: existing indexes' AS banner;

SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME
FROM   information_schema.STATISTICS
WHERE  TABLE_SCHEMA = 'campus_circle'
ORDER  BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- Same info table-by-table in the conventional MySQL format.
SHOW INDEX FROM items;
SHOW INDEX FROM transactions;
SHOW INDEX FROM reviews;


-- =====================================================================
-- SECTION 2 — BASELINE: query plans BEFORE we add new indexes.
-- Watch the EXPLAIN output — columns to focus on:
--   type   : "ALL" = full table scan (slow).  "ref"/"range"/"eq_ref" = index used.
--   key    : NULL = no index being used.  Otherwise name of index chosen.
--   rows   : estimated rows the optimiser expects to scan.
-- =====================================================================
SELECT 'SECTION 2: BEFORE INDEXING (expect type=ALL)' AS banner;

-- 2.1  Filter items by price range — items.price is NOT indexed.
EXPLAIN
SELECT item_id, title, price
FROM   items
WHERE  price BETWEEN 500 AND 5000;

-- 2.2  Filter transactions by total_amount — not indexed either.
EXPLAIN
SELECT transaction_id, total_amount, status
FROM   transactions
WHERE  total_amount > 1000;

-- 2.3  Filter reviews by reviewer_id — not indexed (we only indexed
-- the reviewee side: review_for_user_id).
EXPLAIN
SELECT review_id, transaction_id, reviewer_id, rating
FROM   reviews
WHERE  reviewer_id = 3;


-- =====================================================================
-- SECTION 3 — CREATE new indexes to optimize the baseline queries.
-- =====================================================================
SELECT 'SECTION 3: creating new indexes' AS banner;

-- Idempotent drops via helper procedure (simulated IF EXISTS).
CALL _drop_index_if_exists('items',        'idx_items_price');
CALL _drop_index_if_exists('transactions', 'idx_trx_total_amount');
CALL _drop_index_if_exists('reviews',      'idx_reviews_reviewer');

-- Create a B-Tree index on items.price for range queries
CREATE INDEX idx_items_price
    ON items(price);

-- Create a B-Tree index on transactions.total_amount
CREATE INDEX idx_trx_total_amount
    ON transactions(total_amount);

-- Create a B-Tree index on reviews.reviewer_id for the WRITES relationship
CREATE INDEX idx_reviews_reviewer
    ON reviews(reviewer_id);

-- Refresh optimiser stats after index creation
ANALYZE TABLE items, transactions, reviews;


-- =====================================================================
-- SECTION 4 — AFTER indexing: SAME queries, NEW plans.
-- Compare to section 2.  Expect "type" to improve from ALL -> range/ref,
-- "key" to name the new index, and "rows" to drop sharply.
-- =====================================================================
SELECT 'SECTION 4: AFTER INDEXING (expect type=range/ref)' AS banner;

-- 4.1  Same as 2.1 — now should use idx_items_price
EXPLAIN
SELECT item_id, title, price
FROM   items
WHERE  price BETWEEN 500 AND 5000;

-- 4.2  Same as 2.2 — should use idx_trx_total_amount
EXPLAIN
SELECT transaction_id, total_amount, status
FROM   transactions
WHERE  total_amount > 1000;

-- 4.3  Same as 2.3 — should use idx_reviews_reviewer
EXPLAIN
SELECT review_id, transaction_id, reviewer_id, rating
FROM   reviews
WHERE  reviewer_id = 3;


-- =====================================================================
-- SECTION 5 — COMPOSITE INDEX + LEFTMOST-PREFIX RULE
-- The schema already has a composite index idx_items_type_status on
-- (item_type, availability_status).  Demonstrate:
--   (a) The index fires when the FIRST column is in the WHERE clause.
--   (b) The index does NOT fire if you query only the SECOND column
--       (the "leftmost-prefix" rule).
-- =====================================================================
SELECT 'SECTION 5: composite index behavior' AS banner;

-- 5.1  Filter on item_type alone -> composite idx hits (uses its prefix)
EXPLAIN
SELECT item_id, title
FROM   items
WHERE  item_type = 'BUY';

-- 5.2  Filter on BOTH columns -> composite idx hits with tighter rows estimate
EXPLAIN
SELECT item_id, title
FROM   items
WHERE  item_type = 'BUY'
  AND  availability_status = 'available';

-- 5.3  Filter on availability_status alone -> composite idx CANNOT help,
--      because leftmost column (item_type) is not in the WHERE.
--      Optimizer either does a full scan or falls back to a single-column
--      idx if one exists.
EXPLAIN
SELECT item_id, title
FROM   items
WHERE  availability_status = 'available';


-- =====================================================================
-- SECTION 6 — INDEX TYPES + FOREIGN KEY INDEXES (informational)
-- FK columns are auto-indexed by InnoDB.  Show them.
-- =====================================================================
SELECT 'SECTION 6: index types summary' AS banner;

SELECT TABLE_NAME, INDEX_NAME, INDEX_TYPE,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns
FROM   information_schema.STATISTICS
WHERE  TABLE_SCHEMA = 'campus_circle'
GROUP  BY TABLE_NAME, INDEX_NAME, INDEX_TYPE
ORDER  BY TABLE_NAME, INDEX_NAME;


-- =====================================================================
-- SECTION 7 — Cardinality (how many distinct values the optimiser
-- thinks each index column has).  Higher = more selective = more useful.
-- =====================================================================
SELECT 'SECTION 7: index cardinality' AS banner;

SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, CARDINALITY
FROM   information_schema.STATISTICS
WHERE  TABLE_SCHEMA = 'campus_circle'
  AND  INDEX_NAME  <> 'PRIMARY'
ORDER  BY TABLE_NAME, INDEX_NAME;


-- =====================================================================
-- SECTION 8 — DROP INDEX demo (cleanup of one new index — syntax demo).
-- We keep idx_items_price and idx_reviews_reviewer (useful in production),
-- and drop idx_trx_total_amount just to show the syntax works.
-- =====================================================================
SELECT 'SECTION 8: DROP INDEX syntax demo' AS banner;

-- Use our helper procedure so this is idempotent across re-runs.
CALL _drop_index_if_exists('transactions', 'idx_trx_total_amount');

-- Prove it's gone
SELECT INDEX_NAME
FROM   information_schema.STATISTICS
WHERE  TABLE_SCHEMA = 'campus_circle'
  AND  TABLE_NAME   = 'transactions'
ORDER  BY INDEX_NAME;


-- =====================================================================
-- SECTION 9 — Final index inventory.  Should show the original 9
-- schema indexes plus the 2 new ones we kept
-- (idx_items_price, idx_reviews_reviewer) plus the 7 PRIMARY KEYs
-- plus the UNIQUE indexes.
-- =====================================================================
SELECT 'SECTION 9: final index inventory' AS banner;

SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns
FROM   information_schema.STATISTICS
WHERE  TABLE_SCHEMA = 'campus_circle'
GROUP  BY TABLE_NAME, INDEX_NAME, NON_UNIQUE
ORDER  BY TABLE_NAME, INDEX_NAME;


-- =====================================================================
-- Cleanup: drop the helper procedure (keeps the DB routine-list clean).
-- =====================================================================
DROP PROCEDURE IF EXISTS _drop_index_if_exists;


-- =====================================================================
-- KEY TAKEAWAYS FOR VIVA
-- ---------------------------------------------------------------------
-- 1. EXPLAIN is the MySQL optimizer's plan — it's FREE, doesn't run
--    the query, and is the fastest way to diagnose slow queries.
-- 2. "type=ALL" = full table scan.  For small tables this is fine;
--    for large ones (~100k+ rows) it's devastating.
-- 3. "rows" is the optimizer's estimate of how many rows it will
--    inspect.  Lower is better.
-- 4. Composite indexes follow the LEFTMOST-PREFIX rule: an index on
--    (a, b, c) can serve queries filtering on (a), (a,b), (a,b,c),
--    but NOT (b), (c), (b,c).
-- 5. Every INDEX speeds up reads but slows down writes (INSERT/UPDATE/
--    DELETE have to maintain the B-Tree).  Trade-off matters.
-- 6. Foreign-key columns in InnoDB are auto-indexed (see the fk_*
--    entries in Section 1) — you don't have to re-index them.
-- 7. MySQL lacks DROP INDEX IF EXISTS natively; you either accept a
--    1091 error on first run, or (like we did here) use a helper proc.
-- =====================================================================