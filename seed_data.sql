-- =============================================================
-- seed_data.sql
-- Initial org structure — Version 1 (Jan 2025)
-- =============================================================
--
-- Org chart:
--
--     Alice (CEO)
--           |
--     Bob (Manager)
--           |
--     Carol (Analyst)
--
-- seed_data.sql: change TRUE → 1, FALSE → 0
INSERT INTO employee_dim (employee_id, full_name, role, manager_id, start_date, end_date, is_current)
VALUES
    (1, 'Alice', 'CEO',      NULL, '2025-01-01', NULL, 1),
    (2, 'Bob',   'Manager',  1,    '2025-01-01', NULL, 1),
    (3, 'Carol', 'Analyst',  2,    '2025-01-01', NULL, 1);
