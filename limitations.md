# Known Limitations & Future Work

This document honestly describes what the current implementation does not handle, and what a production-ready version would require. Understanding the edges of your own system is as important as building it.

---

## Current limitations

### 1. No surrogate key column
Each row is identified by `employee_id` + `is_current` rather than a unique surrogate key per version. In a true data warehouse, a fact table (e.g. `fact_performance_reviews`) would need to join to the exact dimension version that was current when the review was recorded — not just the current version. Without a surrogate key, this precision is not possible.

**What a production system would do:** Add an `employee_sk` column using `GENERATED ALWAYS AS IDENTITY` (PostgreSQL) or an auto-increment sequence, and use this as the primary key on all fact table joins.

---

### 2. No transaction safety on SCD updates
The SCD Type 2 update process requires two operations: closing the old record and inserting a new one. In this project these are separate SQL statements. If the process fails between the two steps, the data is left in an inconsistent state — the old record is closed but no new record exists.

**What a production system would do:** Wrap both operations in a single database transaction so they succeed or fail atomically.

---

### 3. Recursive hierarchy queries are not implemented
The current queries retrieve direct manager-employee relationships. Querying the full reporting chain (e.g. "all employees who report to Alice, at any level") would require a recursive CTE. This is not currently included in `queries.sql`.

**What a production system would do:** Use a recursive CTE or a closure table to support arbitrary-depth hierarchy traversal.

---

### 4. No handling of concurrent or same-day changes
If two changes occur for the same employee on the same date (e.g. both a role change and a manager change), the current schema and logic do not account for this cleanly. `start_date` alone is not granular enough to sequence same-day events.

**What a production system would do:** Add a `row_effective_datetime` timestamp column and a `change_sequence` integer to order multiple changes within a single day.

---

### 5. No indexes
The current schema has no indexes beyond the primary key. On a table with thousands of employees and years of history, queries filtering on `is_current` or date ranges would perform a full table scan.

**What a production system would do:** Add indexes on `is_current`, `start_date`, and `end_date` at minimum.

---

## Intentional simplifications

The following are known simplifications made to keep the project focused on demonstrating dimensional modelling concepts:

- **SQLite instead of PostgreSQL or SQL Server** — all SQL patterns used are transferable, but SQLite lacks certain production features (e.g. enforced `NOT NULL` constraints on some types, full `GENERATED` column support)
- **Manual seed data** — a production pipeline would ingest from an HR source system via an ETL process, not manual SQL inserts
- **No SCD Type 0 columns** — some attributes (e.g. date of birth, original hire date) should never change and would be modelled differently in a full implementation

---

These limitations are not failures — they are the natural boundary of a focused portfolio project. Knowing where a system breaks down is part of engineering maturity.
