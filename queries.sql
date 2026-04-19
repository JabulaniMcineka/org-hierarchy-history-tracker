-- =============================================================
-- queries.sql
-- Analytical queries against the SCD Type 2 employee_dim table
-- =============================================================


-- -------------------------------------------------------------
-- QUERY 1: Current org structure
--
-- Business question: "Who works here today, what is their role,
-- and who do they report to?"
--
-- This is the standard current-state snapshot a manager or HR
-- system would request. The double join on is_current = TRUE
-- ensures we show the manager's current name and role, not a
-- historical version of them.
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
--
-- Business question: "Show me every role and reporting line
-- Carol has ever had, in chronological order."
--
-- Useful for HR audits, performance reviews, and compliance.
-- COALESCE converts NULL end_date to the string 'present' so
-- the output is readable without knowing the SCD convention.
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
--
-- Business question: "Who did Carol report to on 1 March 2025,
-- even if her manager has since changed?"
--
-- This is the core value of SCD Type 2. A Type 1 system (which
-- overwrites rows) could not answer this question. The date is
-- applied to both the employee and manager join to ensure both
-- sides reflect the state at that exact point in time.
-- COALESCE treats NULL end_date as '9999-12-31' so open-ended
-- (still-current) records are correctly included in the range.
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
-- QUERY 4: All changes on or after a given date
--
-- Business question: "What organisational changes have happened
-- since June 2025? I need an audit trail."
--
-- start_date marks when a new version became active, so
-- filtering on start_date >= a threshold returns every change
-- event from that date forward. Useful for change management
-- reporting and compliance audits.
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
-- QUERY 5: Version count per employee
--
-- Business question: "Which employees have had the most role or
-- reporting line changes? Who is most active in the org?"
--
-- Each row in employee_dim represents one version of an employee
-- record. Counting rows per employee_id reveals how many times
-- that person's data has changed. High version counts may
-- indicate frequent promotions, restructures, or data corrections.
-- -------------------------------------------------------------

SELECT
    employee_id,
    MAX(full_name)   AS full_name,
    COUNT(*)         AS total_versions
FROM   employee_dim
GROUP BY employee_id
ORDER BY total_versions DESC;