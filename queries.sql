-- =============================================================
-- queries.sql
-- Analytical queries against the SCD Type 2 employee_dim table
-- =============================================================


-- -------------------------------------------------------------
-- QUERY 1: Current org structure
-- Returns one row per employee — their latest active record
-- -------------------------------------------------------------

SELECT
    e.employee_id,
    e.full_name,
    e.role,
    m.full_name AS reports_to,
    e.start_date AS in_role_since
FROM   employee_dim e
LEFT JOIN employee_dim m
       ON e.manager_id = m.employee_id
      AND m.is_current = TRUE
WHERE  e.is_current = TRUE
ORDER BY e.manager_id NULLS FIRST, e.employee_id;


-- -------------------------------------------------------------
-- QUERY 2: Full history for a single employee
-- Shows every version of Carol's record across all time
-- -------------------------------------------------------------

SELECT
    employee_id,
    full_name,
    role,
    manager_id,
    start_date,
    COALESCE(end_date::TEXT, 'present') AS end_date,
    is_current
FROM   employee_dim
WHERE  employee_id = 3
ORDER BY start_date;


-- -------------------------------------------------------------
-- QUERY 3: Point-in-time lookup
-- "Who did Carol report to on 1 March 2025?"
-- Handles open-ended records with COALESCE
-- -------------------------------------------------------------

SELECT
    e.full_name          AS employee,
    e.role,
    m.full_name          AS reported_to,
    m.role               AS manager_role,
    e.start_date,
    e.end_date
FROM   employee_dim e
LEFT JOIN employee_dim m
       ON e.manager_id = m.employee_id
      AND '2025-03-01' BETWEEN m.start_date
                           AND COALESCE(m.end_date, '9999-12-31')
WHERE  e.employee_id = 3
AND    '2025-03-01' BETWEEN e.start_date
                        AND COALESCE(e.end_date, '9999-12-31');


-- -------------------------------------------------------------
-- QUERY 4: All changes that happened on or after a given date
-- Useful for audit trails and change tracking
-- -------------------------------------------------------------

SELECT
    employee_id,
    full_name,
    role,
    manager_id,
    start_date  AS effective_from,
    end_date    AS effective_to,
    is_current
FROM   employee_dim
WHERE  start_date >= '2025-06-01'
ORDER BY start_date, employee_id;


-- -------------------------------------------------------------
-- QUERY 5: How many versions does each employee have?
-- Reveals who has changed the most
-- -------------------------------------------------------------

SELECT
    employee_id,
    MAX(full_name)   AS full_name,
    COUNT(*)         AS total_versions
FROM   employee_dim
GROUP BY employee_id
ORDER BY total_versions DESC;
