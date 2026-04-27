-- CAMPUS CIRCLE - MySQL Schema 

DROP DATABASE IF EXISTS campus_circle;
CREATE DATABASE campus_circle
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE campus_circle;


-- 1. ADMIN TABLE

CREATE TABLE admin (
    admin_id     INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100)  NOT NULL,
    email        VARCHAR(100)  NOT NULL UNIQUE,
    password     VARCHAR(255)  NOT NULL,
    role         VARCHAR(50)   NOT NULL DEFAULT 'moderator',
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- 2. USERS TABLE
-- (verified_by references admin.admin_id -> ADMIN VERIFIES USERS)

CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(100)  NOT NULL,
    email          VARCHAR(100)  NOT NULL UNIQUE,
    password       VARCHAR(255)  NOT NULL,
    phone_number   VARCHAR(15),
    hostel_block   VARCHAR(50),
    is_verified    TINYINT(1)    NOT NULL DEFAULT 0,
    verified_by    INT NULL,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_verified_by
        FOREIGN KEY (verified_by) REFERENCES admin(admin_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 3. CATEGORIES TABLE

CREATE TABLE categories (
    category_id    INT AUTO_INCREMENT PRIMARY KEY,
    category_name  VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;


-- 4. ITEMS TABLE
-- (seller_id -> USERS LISTS ITEMS)
-- (category_id -> CATEGORIES CATEGORIZES ITEMS)
-- (moderated_by -> ADMIN MODERATES ITEMS)

CREATE TABLE items (
    item_id              INT AUTO_INCREMENT PRIMARY KEY,
    seller_id            INT NOT NULL,
    category_id          INT NOT NULL,
    moderated_by         INT NULL,
    title                VARCHAR(150)   NOT NULL,
    price                DECIMAL(8,2)   NULL,
    rent_price_per_day   DECIMAL(8,2)   NULL,
    item_type            ENUM('BUY', 'RENT') NOT NULL,
    availability_status  ENUM('available', 'reserved', 'sold', 'rented', 'removed')
                         NOT NULL DEFAULT 'available',
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_items_seller
        FOREIGN KEY (seller_id)   REFERENCES users(user_id)         ON DELETE CASCADE,
    CONSTRAINT fk_items_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_items_moderator
        FOREIGN KEY (moderated_by) REFERENCES admin(admin_id)        ON DELETE SET NULL,

    CONSTRAINT chk_items_price_positive
        CHECK (price IS NULL OR price >= 0),
    CONSTRAINT chk_items_rent_positive
        CHECK (rent_price_per_day IS NULL OR rent_price_per_day >= 0)
) ENGINE=InnoDB;


-- 5. TRANSACTIONS TABLE
-- Splits user role into buyer_id and seller_id
-- (USERS BUYS_in TRANSACTIONS  and  USERS SELLS_in TRANSACTIONS)
-- (ITEMS INVOLVED_IN TRANSACTIONS)

CREATE TABLE transactions (
    transaction_id     INT AUTO_INCREMENT PRIMARY KEY,
    item_id            INT NOT NULL,
    buyer_id           INT NOT NULL,
    seller_id          INT NOT NULL,
    transaction_type   ENUM('BUY', 'RENT') NOT NULL,
    start_date         DATE NULL,
    end_date           DATE NULL,
    total_amount       DECIMAL(8,2) NOT NULL,
    payment_status     ENUM('pending', 'held', 'released', 'refunded') NOT NULL DEFAULT 'pending',
    status             ENUM('requested', 'approved', 'active', 'completed', 'cancelled', 'rejected')
                       NOT NULL DEFAULT 'requested',
    meetup_location    VARCHAR(150),
    created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_trx_item
        FOREIGN KEY (item_id)   REFERENCES items(item_id)   ON DELETE CASCADE,
    CONSTRAINT fk_trx_buyer
        FOREIGN KEY (buyer_id)  REFERENCES users(user_id)   ON DELETE CASCADE,
    CONSTRAINT fk_trx_seller
        FOREIGN KEY (seller_id) REFERENCES users(user_id)   ON DELETE CASCADE,

    CONSTRAINT chk_trx_buyer_not_seller
        CHECK (buyer_id <> seller_id),
    CONSTRAINT chk_trx_amount_positive
        CHECK (total_amount >= 0),
    CONSTRAINT chk_trx_dates
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;


-- 6. MEETUP_SLOTS TABLE  (Weak entity of TRANSACTIONS)

CREATE TABLE meetup_slots (
    slot_id              INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id       INT NOT NULL,
    proposed_time_slot   TEXT NOT NULL,
    selected             TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT fk_slots_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- 7. REVIEWS TABLE  (Weak entity of TRANSACTIONS)
-- reviewer_id     -> USERS WRITES REVIEWS
-- review_for_user_id -> USERS RECEIVES REVIEWS

CREATE TABLE reviews (
    review_id            INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id       INT NOT NULL,
    reviewer_id          INT NOT NULL,
    review_for_user_id   INT NOT NULL,
    rating               INT NOT NULL,
    comment              TEXT,
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_rev_transaction
        FOREIGN KEY (transaction_id)     REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    CONSTRAINT fk_rev_reviewer
        FOREIGN KEY (reviewer_id)        REFERENCES users(user_id)               ON DELETE CASCADE,
    CONSTRAINT fk_rev_reviewee
        FOREIGN KEY (review_for_user_id) REFERENCES users(user_id)               ON DELETE CASCADE,

    CONSTRAINT chk_rev_rating
        CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_rev_not_self
        CHECK (reviewer_id <> review_for_user_id),
    CONSTRAINT uq_rev_one_per_trx_per_reviewer
        UNIQUE (transaction_id, reviewer_id)
) ENGINE=InnoDB;


-- BASIC INDEXES (for DBMS rubric item 3: Indexing basics)

CREATE INDEX idx_items_seller        ON items(seller_id);
CREATE INDEX idx_items_category      ON items(category_id);
CREATE INDEX idx_items_type_status   ON items(item_type, availability_status);
CREATE INDEX idx_trx_buyer           ON transactions(buyer_id);
CREATE INDEX idx_trx_seller          ON transactions(seller_id);
CREATE INDEX idx_trx_status          ON transactions(status);
CREATE INDEX idx_slots_trx           ON meetup_slots(transaction_id);
CREATE INDEX idx_rev_reviewee        ON reviews(review_for_user_id);
CREATE INDEX idx_users_hostel        ON users(hostel_block);


-- END --

USE campus_circle;
SHOW TABLES;

SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'campus_circle'
ORDER BY TABLE_NAME;