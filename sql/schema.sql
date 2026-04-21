-- =============================================================
-- schema.sql
-- Org Hierarchy History Tracker
-- SCD Type 2 dimensional model
-- =============================================================

CREATE TABLE employee_dim (
    employee_id  INT,           -- natural key (reused across versions)
    full_name    TEXT,
    role         TEXT,
    manager_id   INT,           -- self-referencing: points to employee_id of manager
    start_date   DATE,          -- when this version became active
    end_date     DATE,          -- when this version was superseded (NULL = still current)
    is_current   INT            -- convenience flag for filtering current records(-- use 1 for TRUE, 0 for FALSE)
);

-- Notes:
-- manager_id IS NULL means the employee has no manager (e.g., CEO)
-- end_date IS NULL means the record is open-ended (currently active)
-- For true data warehouse compliance, add a surrogate key (e.g., employee_sk SERIAL PRIMARY KEY)
-- is_current is technically redundant with end_date IS NULL, but improves query readability
