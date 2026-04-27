-- ============================================================
-- CAMPUS CIRCLE - Seed Data  (02_seed.sql)
--
-- Row counts:
--   admin        :  4
--   users        : 12
--   categories   :  8
--   items        : 25
--   transactions : 15
--   meetup_slots : 10
--   reviews      : 12
--
-- Constraints respected:
--   * FK insertion order: admin -> categories -> users -> items
--     -> transactions -> meetup_slots -> reviews
--   * Every user.verified_by points at an existing admin row
--   * Every items.(seller_id/category_id/moderated_by) resolves
--   * Every transaction.(item_id/buyer_id/seller_id) resolves
--   * buyer_id <> seller_id (CHECK satisfied)
--   * total_amount >= 0
--   * end_date >= start_date
--   * rating BETWEEN 1 AND 5
--   * reviewer_id <> review_for_user_id
--   * (transaction_id, reviewer_id) is unique (no duplicate reviews)


USE campus_circle;

-- Clear data (optional; keeps schema, wipes rows).
-- Order matters due to FKs. Uncomment to reset before re-seeding.
-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE TABLE reviews;
-- TRUNCATE TABLE meetup_slots;
-- TRUNCATE TABLE transactions;
-- TRUNCATE TABLE items;
-- TRUNCATE TABLE categories;
-- TRUNCATE TABLE users;
-- TRUNCATE TABLE admin;
-- SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- 1. ADMIN   (4 rows)
-- ============================================================
INSERT INTO admin (admin_id, name, email, password, role) VALUES
 (1, 'Saksham Lodha', 'saksham.lodha.24cse@bmu.edu.in', 'hashed_pw_1', 'super_admin'),
 (2, 'Ravi Kumar',          'ravi.kumar@bmu.edu.in',      'hashed_pw_2', 'senior_moderator'),
 (3, 'Priya Sharma',        'priya.sharma@bmu.edu.in',    'hashed_pw_3', 'moderator'),
 (4, 'Arjun Mehta',         'arjun.mehta@bmu.edu.in',     'hashed_pw_4', 'support_lead');


-- ============================================================
-- 2. CATEGORIES   (8 rows)
-- ============================================================
INSERT INTO categories (category_id, category_name) VALUES
 (1, 'Books & Study Material'),
 (2, 'Electronics'),
 (3, 'Hostel Essentials'),
 (4, 'Bicycles'),
 (5, 'Sports Equipment'),
 (6, 'Fashion & Apparel'),
 (7, 'Furniture'),
 (8, 'Services');


-- ============================================================
-- 3. USERS   (12 rows, mix of verified / unverified)
-- ============================================================
INSERT INTO users
 (user_id, name, email, password, phone_number, hostel_block, is_verified, verified_by) VALUES
 ( 1, 'Rishit Rebant',       'rishit.rebant.240608@bmu.edu.in',    'hashed_u1',  '9812345001', 'Hostel-A', 1, 2),
 ( 2, 'Gauri Pandey',         'gauri.pandey.240959@bmu.edu.in',     'hashed_u2',  '9812345002', 'Hostel-B', 1, 2),
 ( 3, 'Saksham Lodha',        'saksham.lodha.240626@bmu.edu.in',    'hashed_u3',  '9812345003', 'Hostel-A', 1, 3),
 ( 4, 'Prerit Shrivastava',   'prerit.shrivastava.240593@bmu.edu.in','hashed_u4', '9812345004', 'Hostel-C', 1, 3),
 ( 5, 'Ananya Gupta',         'ananya.gupta@bmu.edu.in',            'hashed_u5',  '9812345005', 'Hostel-B', 1, 2),
 ( 6, 'Karan Singh',          'karan.singh@bmu.edu.in',             'hashed_u6',  '9812345006', 'Hostel-D', 1, 3),
 ( 7, 'Megha Jain',           'megha.jain@bmu.edu.in',              'hashed_u7',  '9812345007', 'Hostel-A', 1, 3),
 ( 8, 'Rohit Verma',          'rohit.verma@bmu.edu.in',             'hashed_u8',  '9812345008', 'Hostel-C', 1, 2),
 ( 9, 'Divya Nair',           'divya.nair@bmu.edu.in',              'hashed_u9',  '9812345009', 'Hostel-B', 1, 3),
 (10, 'Aditya Rao',           'aditya.rao@bmu.edu.in',              'hashed_u10', '9812345010', 'Hostel-D', 0, NULL),
 (11, 'Sneha Iyer',           'sneha.iyer@bmu.edu.in',              'hashed_u11', '9812345011', 'Hostel-A', 0, NULL),
 (12, 'Vikram Reddy',         'vikram.reddy@bmu.edu.in',            'hashed_u12', '9812345012', 'Hostel-C', 0, NULL);


-- ============================================================
-- 4. ITEMS   (25 rows)
--   - BUY items have price, rent_price_per_day = NULL
--   - RENT items have rent_price_per_day, price = NULL
--   - mix of availability statuses
-- ============================================================
INSERT INTO items
 (item_id, seller_id, category_id, moderated_by, title, price, rent_price_per_day, item_type, availability_status) VALUES
 -- Books (cat 1)
 ( 1,  1, 1, 2, 'DBMS by Navathe (6th Ed)',               850.00, NULL,   'BUY',  'available'),
 ( 2,  2, 1, 3, 'Operating System Concepts - Silberschatz', 700.00, NULL, 'BUY',  'sold'),
 ( 3,  3, 1, 2, 'Signals & Systems by Oppenheim',          600.00, NULL,  'BUY',  'available'),
 ( 4,  5, 1, NULL, 'GATE CSE Previous Year Questions',     450.00, NULL,  'BUY',  'reserved'),

 -- Electronics (cat 2)
 ( 5,  4, 2, 2, 'Dell Inspiron 15 (Used, 8GB/512GB)',      32000.00, NULL, 'BUY', 'available'),
 ( 6,  6, 2, 3, 'Logitech MX Master 3 Mouse',              4200.00, NULL,  'BUY', 'sold'),
 ( 7,  7, 2, 2, 'iPad Air 4 (Rent)',                       NULL,    180.00,'RENT','rented'),
 ( 8,  8, 2, 3, 'JBL Flip 5 Bluetooth Speaker',            2800.00, NULL,  'BUY', 'available'),
 ( 9,  9, 2, NULL, 'Raspberry Pi 4 (4GB) + SD card',       3500.00, NULL,  'BUY', 'available'),

 -- Hostel Essentials (cat 3)
 (10,  1, 3, 3, 'Study Table (Foldable)',                  950.00, NULL,  'BUY',  'available'),
 (11,  2, 3, 2, 'Electric Kettle 1.5L',                    650.00, NULL,  'BUY',  'sold'),
 (12,  5, 3, 3, 'Iron Press (Philips)',                    NULL,   20.00, 'RENT', 'available'),

 -- Bicycles (cat 4)
 (13,  6, 4, 2, 'Hercules MTB (Rent by day)',              NULL,   90.00, 'RENT', 'available'),
 (14,  4, 4, 3, 'Firefox 26T Bicycle (Used)',              5500.00, NULL, 'BUY',  'available'),

 -- Sports (cat 5)
 (15,  7, 5, 3, 'Cosco Football #5',                       550.00, NULL,  'BUY',  'available'),
 (16,  8, 5, 2, 'Badminton Racket (Yonex) - Rent',         NULL,   25.00, 'RENT', 'rented'),
 (17,  3, 5, 3, 'Cricket Bat (English Willow)',            2200.00, NULL, 'BUY',  'available'),

 -- Fashion (cat 6)
 (18,  9, 6, 2, 'Formal Blazer (Size M) - Rent',           NULL,   150.00,'RENT', 'available'),
 (19, 11, 6, NULL, 'Ethnic Kurta Set (Size L)',            1200.00, NULL, 'BUY',  'available'),

 -- Furniture (cat 7)
 (20,  2, 7, 3, 'Floor Cushion Set (2 pcs)',               800.00, NULL,  'BUY',  'available'),
 (21,  5, 7, 2, 'Wooden Stool',                            450.00, NULL,  'BUY',  'removed'),

 -- Services (cat 8)
 (22,  3, 8, 3, 'Math Tutoring (per hour)',                NULL,   300.00,'RENT', 'available'),
 (23,  1, 8, 2, 'Assignment Typing Help',                  NULL,   100.00,'RENT', 'available'),
 (24,  6, 8, 3, 'Haircut (on-campus)',                     NULL,   80.00, 'RENT', 'available'),

 -- One item listed by an unverified user gets removed by mod
 (25, 10, 2, 4, 'Second-hand charger (unverified seller)', 250.00, NULL, 'BUY', 'removed');


-- ============================================================
-- 5. TRANSACTIONS   (15 rows, across all 6 status values)
-- ============================================================
INSERT INTO transactions
 (transaction_id, item_id, buyer_id, seller_id, transaction_type,
  start_date, end_date, total_amount, payment_status, status, meetup_location) VALUES
 -- Completed BUY
 ( 1,  2, 3, 2, 'BUY',  '2026-02-10', '2026-02-10',   700.00, 'released',  'completed', 'Library Entrance'),
 ( 2,  6, 2, 6, 'BUY',  '2026-02-12', '2026-02-12',  4200.00, 'released',  'completed', 'Hostel-B Common Room'),
 ( 3, 11, 4, 2, 'BUY',  '2026-02-15', '2026-02-15',   650.00, 'released',  'completed', 'Cafeteria'),

 -- Completed RENT
 ( 4,  7, 5, 7, 'RENT', '2026-03-01', '2026-03-07',  1260.00, 'released',  'completed', 'Block-2 Gate'),
 ( 5, 16, 9, 8, 'RENT', '2026-03-05', '2026-03-08',    75.00, 'released',  'completed', 'Sports Complex'),

 -- Active RENT (ongoing)
 ( 6, 13, 9, 6, 'RENT', '2026-04-15', '2026-04-22',   630.00, 'held',      'active',    'Main Gate'),

 -- Approved but not yet started
 ( 7,  1, 8, 1, 'BUY',  '2026-04-20',  NULL,          850.00, 'held',      'approved',  'Library Lobby'),

 -- Requested (buyer requested, seller not acted)
 ( 8,  5, 7, 4, 'BUY',  NULL,          NULL,        32000.00, 'pending',   'requested', 'Admin Block'),
 ( 9, 17, 2, 3, 'BUY',  NULL,          NULL,         2200.00, 'pending',   'requested', 'Cricket Ground'),

 -- Cancelled (buyer withdrew)
 (10,  8, 5, 8, 'BUY',  NULL,          NULL,         2800.00, 'refunded',  'cancelled', 'Hostel-C Gate'),
 (11, 14, 3, 4, 'BUY',  NULL,          NULL,         5500.00, 'refunded',  'cancelled', 'Parking'),

 -- Rejected (seller declined)
 (12, 20, 7, 2, 'BUY',  NULL,          NULL,          800.00, 'pending',   'rejected',  'Hostel-B'),

 -- Completed services (RENT type)
 (13, 22, 8, 3, 'RENT', '2026-03-10', '2026-03-10',   300.00, 'released',  'completed', 'Study Hall'),
 (14, 23, 9, 1, 'RENT', '2026-03-15', '2026-03-15',   100.00, 'released',  'completed', 'Canteen'),

 -- One more completed BUY for extra review variety
 (15, 15, 11, 7, 'BUY', '2026-03-20', '2026-03-20',   550.00, 'released',  'completed', 'Sports Complex');


-- ============================================================
-- 6. MEETUP_SLOTS   (10 rows; some selected, some not)
-- ============================================================
INSERT INTO meetup_slots
 (slot_id, transaction_id, proposed_time_slot, selected) VALUES
 ( 1,  1, '2026-02-10 14:00',  1),
 ( 2,  1, '2026-02-10 18:00',  0),
 ( 3,  2, '2026-02-12 11:00',  1),
 ( 4,  4, '2026-03-01 10:00',  1),
 ( 5,  6, '2026-04-15 09:30',  1),
 ( 6,  6, '2026-04-15 17:00',  0),
 ( 7,  7, '2026-04-21 12:00',  1),
 ( 8,  8, '2026-04-22 13:00',  0),
 ( 9,  8, '2026-04-23 15:00',  0),
 (10, 13, '2026-03-10 16:00',  1);


-- ============================================================
-- 7. REVIEWS   (12 rows, ratings 1-5, buyer <-> seller pairs)
--   Each (transaction_id, reviewer_id) is unique per constraint.
-- ============================================================
INSERT INTO reviews
 (review_id, transaction_id, reviewer_id, review_for_user_id, rating, comment) VALUES
 -- Transaction 1 : buyer=3 reviews seller=2, and seller=2 reviews buyer=3
 ( 1,  1, 3, 2, 5, 'Book in great condition, fast handover.'),
 ( 2,  1, 2, 3, 5, 'Polite buyer, paid on time.'),

 -- Transaction 2 : buyer=2 reviews seller=6, and seller=6 reviews buyer=2
 ( 3,  2, 2, 6, 4, 'Works perfectly. Minor scuffs as described.'),
 ( 4,  2, 6, 2, 5, 'Great communication. Recommended.'),

 -- Transaction 3 : buyer=4 reviews seller=2
 ( 5,  3, 4, 2, 4, 'Kettle works well. Packaging ok.'),

 -- Transaction 4 : buyer=5 reviews seller=7, and seller=7 reviews buyer=5
 ( 6,  4, 5, 7, 5, 'iPad was in excellent condition. Smooth rental.'),
 ( 7,  4, 7, 5, 4, 'Returned on time and clean.'),

 -- Transaction 5 : buyer=9 reviews seller=8
 ( 8,  5, 9, 8, 3, 'Racket string a bit loose but usable.'),

 -- Transaction 13 : buyer=8 reviews seller=3
 ( 9, 13, 8, 3, 5, 'Super helpful tutor. Explained clearly.'),

 -- Transaction 14 : buyer=9 reviews seller=1
 (10, 14, 9, 1, 4, 'Typing help was fast and accurate.'),

 -- Transaction 15 : buyer=11 reviews seller=7, and seller=7 reviews buyer=11
 (11, 15, 11, 7, 5, 'Football in perfect shape.'),
 (12, 15, 7, 11, 4, 'Smooth transaction.');


-- ============================================================
-- Sanity counts (uncomment to run after seeding)
-- ============================================================
SELECT 'admin'        AS tbl, COUNT(*) AS n FROM admin
UNION ALL SELECT 'users',        COUNT(*) FROM users
UNION ALL SELECT 'categories',   COUNT(*) FROM categories
UNION ALL SELECT 'items',        COUNT(*) FROM items
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'meetup_slots', COUNT(*) FROM meetup_slots
UNION ALL SELECT 'reviews',      COUNT(*) FROM reviews;
--
-- Expected:
--   admin=4  users=12  categories=8  items=25
--   transactions=15  meetup_slots=10  reviews=12
-- END 
