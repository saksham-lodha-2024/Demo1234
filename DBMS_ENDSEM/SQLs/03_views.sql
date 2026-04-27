-- =====================================================================
-- Campus Circle — 03_views.sql   (v2, column names matched to 01_schema.sql)
-- Project        : CSE2021 DBMS Mini-Project
-- Author         : Saksham Lodha (240626)
-- Team           : Rishit Rebant (240608), Gauri Pandey (240959),
--                  Saksham Lodha (240626), Prerit Shrivastava (240593)
-- Supervisor     : Dr. Nishtha Phutela
-- Purpose        : Define SQL Views covering the DQL rubric requirement.
-- Prerequisite   : 01_schema.sql and 02_seed.sql must be executed first.
-- How to run     : Open in MySQL Workbench → Execute All (Cmd+Shift+Enter).
-- =====================================================================

USE campus_circle;

-- Drop in reverse dependency order so re-runs stay idempotent.
DROP VIEW IF EXISTS v_active_listings;
DROP VIEW IF EXISTS v_top_rated_users;
DROP VIEW IF EXISTS v_seller_dashboard;

-- =====================================================================
-- VIEW 1 : v_seller_dashboard
-- Purpose : One-row-per-seller aggregate used by the "My Dashboard"
--           screen in the Android app. Shows listing counts, completed
--           transactions, total earnings, and average rating received.
-- SQL concepts demoed : LEFT JOIN (x3), COUNT, SUM, AVG, GROUP BY,
--                       IFNULL / COALESCE, CASE expression, ROUND.
-- =====================================================================
CREATE VIEW v_seller_dashboard AS
SELECT
    u.user_id                                                         AS seller_id,
    u.name                                                            AS seller_name,
    u.hostel_block,
    u.is_verified,
    COUNT(DISTINCT i.item_id)                                         AS total_listings,
    COUNT(DISTINCT CASE WHEN i.availability_status = 'available'
                        THEN i.item_id END)                           AS active_listings,
    COUNT(DISTINCT CASE WHEN i.availability_status = 'sold'
                        THEN i.item_id END)                           AS items_sold,
    COUNT(DISTINCT CASE WHEN i.availability_status = 'rented'
                        THEN i.item_id END)                           AS items_rented,
    COUNT(DISTINCT CASE WHEN t.status = 'completed'
                        THEN t.transaction_id END)                    AS completed_transactions,
    COALESCE(SUM(CASE WHEN t.status = 'completed'
                      THEN t.total_amount END), 0)                    AS total_earnings,
    COUNT(r.review_id)                                                AS reviews_received,
    ROUND(IFNULL(AVG(r.rating), 0), 2)                                AS avg_rating
FROM users u
LEFT JOIN items        i ON i.seller_id          = u.user_id
LEFT JOIN transactions t ON t.seller_id          = u.user_id
LEFT JOIN reviews      r ON r.review_for_user_id = u.user_id
GROUP BY u.user_id, u.name, u.hostel_block, u.is_verified;


-- =====================================================================
-- VIEW 2 : v_top_rated_users
-- Purpose : Leaderboard of users by average rating received.
--           Used by the "Top Rated Sellers" carousel in the app.
--           HAVING clause filters out users with too few reviews to
--           avoid small-sample noise (min 2 reviews).
-- SQL concepts demoed : INNER JOIN, AVG, COUNT, GROUP BY, HAVING,
--                       ORDER BY with multi-key tiebreaker.
-- =====================================================================
CREATE VIEW v_top_rated_users AS
SELECT
    u.user_id,
    u.name                           AS full_name,
    u.hostel_block,
    u.is_verified,
    COUNT(r.review_id)               AS review_count,
    ROUND(AVG(r.rating), 2)          AS avg_rating,
    MAX(r.created_at)                AS last_review_at
FROM users u
INNER JOIN reviews r
        ON r.review_for_user_id = u.user_id
GROUP BY u.user_id, u.name, u.hostel_block, u.is_verified
HAVING COUNT(r.review_id) >= 2
ORDER BY avg_rating DESC, review_count DESC, u.name ASC;


-- =====================================================================
-- VIEW 3 : v_active_listings
-- Purpose : The home-feed query for the MAD app — every item currently
--           available with joined seller + category context. Replaces
--           what would otherwise be a 3-table JOIN on every app launch.
-- SQL concepts demoed : INNER JOIN (x2), WHERE filter, column aliases,
--                       CASE for derived "price_display" column.
-- =====================================================================
CREATE VIEW v_active_listings AS
SELECT
    i.item_id,
    i.title,
    i.item_type,
    i.availability_status,
    i.price,
    i.rent_price_per_day,
    CASE
        WHEN i.item_type = 'BUY'  THEN CONCAT('Rs.', FORMAT(i.price, 2))
        WHEN i.item_type = 'RENT' THEN CONCAT('Rs.', FORMAT(i.rent_price_per_day, 2), ' / day')
    END                                   AS price_display,
    i.created_at                          AS listed_on,
    c.category_id,
    c.category_name,
    u.user_id                             AS seller_id,
    u.name                                AS seller_name,
    u.hostel_block                        AS seller_hostel,
    u.is_verified                         AS seller_verified,
    u.phone_number                        AS seller_phone
FROM items i
INNER JOIN categories c ON c.category_id = i.category_id
INNER JOIN users      u ON u.user_id     = i.seller_id
WHERE i.availability_status = 'available'
ORDER BY i.created_at DESC;


-- =====================================================================
-- SANITY CHECKS — run these to confirm the views were created and
-- return sensible data. Each should return > 0 rows given the seed.
-- =====================================================================

-- Confirm all 3 views exist in the schema.
-- (information_schema.VIEWS has no TABLE_TYPE column, so we query
--  information_schema.TABLES filtered by TABLE_TYPE='VIEW' instead.)
SELECT TABLE_NAME AS view_name, TABLE_TYPE
FROM   information_schema.TABLES
WHERE  TABLE_SCHEMA = 'campus_circle'
  AND  TABLE_TYPE   = 'VIEW'
ORDER  BY TABLE_NAME;

-- Preview each view.
SELECT 'v_seller_dashboard'  AS source, COUNT(*) AS row_count FROM v_seller_dashboard
UNION ALL
SELECT 'v_top_rated_users'   AS source, COUNT(*) AS row_count FROM v_top_rated_users
UNION ALL
SELECT 'v_active_listings'   AS source, COUNT(*) AS row_count FROM v_active_listings;

-- Sample data previews.
SELECT * FROM v_seller_dashboard ORDER BY total_earnings DESC LIMIT 5;
SELECT * FROM v_top_rated_users  LIMIT 5;
SELECT * FROM v_active_listings  LIMIT 5;