-- =====================================================================
-- Campus Circle — 07_transactions_demo.sql
-- Project        : CSE2021 DBMS Mini-Project
-- Author         : Saksham Lodha (240626)
-- Team           : Rishit Rebant (240608), Gauri Pandey (240959),
--                  Saksham Lodha (240626), Prerit Shrivastava (240593)
-- Supervisor     : Dr. Nishtha Phutela
-- Purpose        : TCL (Transaction Control Language) showcase.
--                  Demonstrates START TRANSACTION / COMMIT / ROLLBACK /
--                  SAVEPOINT / ROLLBACK TO SAVEPOINT / RELEASE SAVEPOINT
--                  plus the ACID properties of InnoDB.
-- Prerequisite   : 01_schema.sql + 02_seed.sql already executed.
-- How to run     : Execute All (Cmd+Shift+Enter).  Each demo section is
--                  fully self-contained: it begins with a count, does
--                  some work, commits or rolls back, and re-counts so
--                  you can SEE the atomicity.
-- Rubric hits    : START TRANSACTION, COMMIT, ROLLBACK, SAVEPOINT,
--                  ROLLBACK TO SAVEPOINT, RELEASE SAVEPOINT, autocommit,
--                  transaction isolation levels, ACID demonstration.
-- =====================================================================

USE campus_circle;

-- ---------------------------------------------------------------------
-- Helpful initial context: show autocommit and isolation level.
-- ---------------------------------------------------------------------
SELECT @@autocommit             AS autocommit_setting,
       @@transaction_isolation  AS current_isolation_level;


-- =====================================================================
-- DEMO 1 — COMMIT:  changes become permanent
-- Insert a test admin, commit, confirm it is visible afterwards.
-- =====================================================================
SELECT '=== DEMO 1: COMMIT ===' AS banner;

SELECT COUNT(*) AS admin_count_before FROM admin;

START TRANSACTION;

    INSERT INTO admin (name, email, password, role)
    VALUES ('TCL Demo 1 Admin',
            'tcl_demo1@bmu.edu.in',
            'hash_demo1',
            'demo');

    SELECT COUNT(*) AS admin_count_inside_txn FROM admin;

COMMIT;

SELECT COUNT(*) AS admin_count_after_commit FROM admin;
SELECT admin_id, name, email FROM admin WHERE email = 'tcl_demo1@bmu.edu.in';


-- =====================================================================
-- DEMO 2 — ROLLBACK:  changes are wiped
-- Insert a test admin, roll back, confirm the row never landed.
-- =====================================================================
SELECT '=== DEMO 2: ROLLBACK ===' AS banner;

SELECT COUNT(*) AS admin_count_before FROM admin;

START TRANSACTION;

    INSERT INTO admin (name, email, password, role)
    VALUES ('TCL Demo 2 Admin',
            'tcl_demo2@bmu.edu.in',
            'hash_demo2',
            'demo');

    SELECT COUNT(*) AS admin_count_inside_txn FROM admin;

ROLLBACK;

SELECT COUNT(*) AS admin_count_after_rollback FROM admin;
-- the next query must return 0 rows
SELECT admin_id, name, email FROM admin WHERE email = 'tcl_demo2@bmu.edu.in';


-- =====================================================================
-- DEMO 3 — SAVEPOINT + ROLLBACK TO SAVEPOINT:  partial rollback
-- Insert 2 rows, set SAVEPOINT, insert 2 more, then roll back to the
-- savepoint.  Only the first 2 should survive the final commit.
-- =====================================================================
SELECT '=== DEMO 3: SAVEPOINT + PARTIAL ROLLBACK ===' AS banner;

SELECT COUNT(*) AS admin_count_before FROM admin;

START TRANSACTION;

    -- Batch A (should survive)
    INSERT INTO admin (name, email, password, role) VALUES
        ('TCL Demo 3A - Kept1', 'tcl_demo3_kept1@bmu.edu.in', 'h', 'demo'),
        ('TCL Demo 3A - Kept2', 'tcl_demo3_kept2@bmu.edu.in', 'h', 'demo');

    SAVEPOINT sp_after_batch_a;

    -- Batch B (should be discarded by rollback-to-savepoint)
    INSERT INTO admin (name, email, password, role) VALUES
        ('TCL Demo 3B - Discarded1', 'tcl_demo3_drop1@bmu.edu.in', 'h', 'demo'),
        ('TCL Demo 3B - Discarded2', 'tcl_demo3_drop2@bmu.edu.in', 'h', 'demo');

    SELECT COUNT(*) AS admin_count_after_both_batches FROM admin;

    -- Roll back only Batch B — Batch A stays
    ROLLBACK TO SAVEPOINT sp_after_batch_a;

    -- Free the savepoint (good hygiene)
    RELEASE SAVEPOINT sp_after_batch_a;

    SELECT COUNT(*) AS admin_count_after_savepoint_rollback FROM admin;

COMMIT;

SELECT COUNT(*) AS admin_count_after_commit FROM admin;
-- Kept1 / Kept2 should be present, Discarded1 / Discarded2 should NOT
SELECT admin_id, name, email
FROM   admin
WHERE  email LIKE 'tcl_demo3_%'
ORDER  BY admin_id;


-- =====================================================================
-- DEMO 4 — Atomicity on multi-statement failure
-- Two good inserts, one intentionally broken insert (UNIQUE violation
-- on existing email 'tcl_demo1@bmu.edu.in').  We wrap them in a txn
-- and show that when the 3rd fails, we can ROLLBACK the whole batch
-- so the first two don't leak into the table.
-- =====================================================================
SELECT '=== DEMO 4: ATOMICITY (rollback on error) ===' AS banner;

SELECT COUNT(*) AS admin_count_before FROM admin;

START TRANSACTION;

    -- Two successful inserts
    INSERT INTO admin (name, email, password, role) VALUES
        ('TCL Demo 4 Admin A', 'tcl_demo4a@bmu.edu.in', 'h', 'demo');

    INSERT INTO admin (name, email, password, role) VALUES
        ('TCL Demo 4 Admin B', 'tcl_demo4b@bmu.edu.in', 'h', 'demo');

    SELECT COUNT(*) AS admin_count_before_failure FROM admin;

    -- This third insert WILL FAIL because tcl_demo1@bmu.edu.in already
    -- exists (Demo 1 committed it), and admin.email is UNIQUE.
    -- In a real app, the app code catches the error and issues ROLLBACK.
    -- Workbench stops the script here — we issue ROLLBACK below anyway.
    -- (If you want to see the SQL error raised, uncomment the next line.)
    /*
    INSERT INTO admin (name, email, password, role) VALUES
        ('Oops - duplicate email', 'tcl_demo1@bmu.edu.in', 'h', 'demo');
    */

-- Whether or not the duplicate above ran, we now simulate the
-- application's error handler by rolling back the whole batch.
ROLLBACK;

SELECT COUNT(*) AS admin_count_after_rollback FROM admin;
-- both Admin A and Admin B should now be gone
SELECT admin_id, name, email
FROM   admin
WHERE  email LIKE 'tcl_demo4%';


-- =====================================================================
-- DEMO 5 — autocommit toggled off, then back on
-- Prove that when autocommit=0, an INSERT is NOT persisted until we
-- explicitly COMMIT.  We verify with @@in_transaction.
-- =====================================================================
SELECT '=== DEMO 5: autocommit toggle ===' AS banner;

SET autocommit = 0;
SELECT @@autocommit AS autocommit_now;

INSERT INTO admin (name, email, password, role)
VALUES ('TCL Demo 5 Admin', 'tcl_demo5@bmu.edu.in', 'h', 'demo');

-- Inside implicit transaction, row is visible to THIS session:
SELECT COUNT(*) AS admin_count_same_session FROM admin;

-- Now choose to discard this pending work
ROLLBACK;

-- Row gone
SELECT admin_id, name FROM admin WHERE email = 'tcl_demo5@bmu.edu.in';

-- Restore normal mode
SET autocommit = 1;
SELECT @@autocommit AS autocommit_restored;


-- =====================================================================
-- DEMO 6 — Isolation levels (informational)
-- MySQL's default is REPEATABLE READ.  Show it, then show how to
-- change it for the current session and for the next transaction only.
-- =====================================================================
SELECT '=== DEMO 6: isolation levels ===' AS banner;

SELECT @@transaction_isolation AS default_isolation;

-- change for the next single transaction only (does not persist)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;
    SELECT @@transaction_isolation AS inside_txn_isolation;
    -- any work would go here
COMMIT;

-- back to session default
SELECT @@transaction_isolation AS back_to_default;


-- =====================================================================
-- CLEANUP — remove the surviving demo admins so the DB is pristine
-- for the next demo run.  (Demos 1 and 3 left rows behind on purpose.)
-- =====================================================================
SELECT '=== CLEANUP ===' AS banner;

START TRANSACTION;

    DELETE FROM admin
    WHERE  email IN (
        'tcl_demo1@bmu.edu.in',
        'tcl_demo3_kept1@bmu.edu.in',
        'tcl_demo3_kept2@bmu.edu.in'
    );

COMMIT;

SELECT COUNT(*) AS remaining_demo_admins
FROM   admin
WHERE  email LIKE 'tcl_demo%';

-- Final admin list (should be back to the original 4 from the seed)
SELECT admin_id, name, email, role FROM admin ORDER BY admin_id;