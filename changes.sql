-- =============================================================
-- changes.sql
-- SCD Type 2 change simulations
-- Pattern: (1) close old record → (2) insert new record
-- =============================================================


-- -------------------------------------------------------------
-- CHANGE 1: Bob gets promoted to Senior Manager (1 Jun 2025)
-- -------------------------------------------------------------

-- Step A: Close Bob's current record
UPDATE employee_dim
SET    end_date   = '2025-06-01',
       is_current = FALSE
WHERE  employee_id = 2
AND    is_current  = TRUE;

-- Step B: Insert Bob's new record with updated role
INSERT INTO employee_dim (employee_id, full_name, role, manager_id, start_date, end_date, is_current)
VALUES (2, 'Bob', 'Senior Manager', 1, '2025-06-01', NULL, TRUE);

--
-- Org chart after Change 1:
--
--     Alice (CEO)
--           |
--     Bob (Senior Manager)   ← promoted
--           |
--     Carol (Analyst)
--


-- -------------------------------------------------------------
-- CHANGE 2: Carol now reports directly to Alice (1 Sep 2025)
-- -------------------------------------------------------------

-- Step A: Close Carol's current record
UPDATE employee_dim
SET    end_date   = '2025-09-01',
       is_current = FALSE
WHERE  employee_id = 3
AND    is_current  = TRUE;

-- Step B: Insert Carol's new record with updated manager
INSERT INTO employee_dim (employee_id, full_name, role, manager_id, start_date, end_date, is_current)
VALUES (3, 'Carol', 'Analyst', 1, '2025-09-01', NULL, TRUE);

--
-- Org chart after Change 2:
--
--     Alice (CEO)
--        /      \
--     Bob        Carol      ← now reports to Alice directly
--  (Sr. Mgr)   (Analyst)
--
