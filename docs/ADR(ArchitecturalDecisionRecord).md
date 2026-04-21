# Architecture Decision Record — Org Hierarchy History Tracker

## ADR-001: Use SCD Type 2 instead of Type 1 or Type 3

**Status:** Accepted

**Context:**  
Employee records change over time — roles are updated, managers change, and departments are restructured. The system must support both current-state queries ("who does Carol report to today?") and historical queries ("who did Carol report to on 1 March 2025?"). Overwriting data would destroy the historical record.

**Options considered:**

| Option | How it works | Why rejected |
|--------|-------------|--------------|
| SCD Type 1 | Overwrite the existing row with new values | Destroys history — no way to answer point-in-time questions |
| SCD Type 3 | Add a `previous_value` column alongside `current_value` | Only tracks one prior change; multiple promotions still lose history |
| **SCD Type 2** | Close the old row (`end_date`, `is_current = FALSE`), insert a new row | Preserves the full version history indefinitely |

**Decision:**  
SCD Type 2 was chosen because the primary analytical requirement is point-in-time reporting. Every version of the truth must be preserved — auditing, compliance, and historical analytics all depend on it.

**Trade-offs accepted:**
- Queries require a `WHERE is_current = TRUE` filter or a date-range condition to avoid returning duplicate rows for the same employee
- Row count grows with every change; at scale, the table will be larger than a Type 1 equivalent
- Joins become slightly more complex because `employee_id` is no longer unique in the table

---

## ADR-002: Use a self-referencing foreign key for hierarchy modelling

**Status:** Accepted

**Context:**  
Organisational hierarchies are recursive — an employee has a manager, who is also an employee, who may also have a manager. This relationship needs to be modelled in the database.

**Options considered:**

| Option | How it works | Why rejected / accepted |
|--------|-------------|------------------------|
| **Self-referencing FK** (`manager_id → employee_id`) | Single table; `manager_id` points back to the same table | Simple, readable, and sufficient for this use case |
| Separate mapping table (`employee_manager` bridge) | Dedicated table for relationships | Adds complexity without benefit at this scale; better suited to many-to-many relationships |
| Adjacency list with closure table | Stores all ancestor paths explicitly | Powerful for deep hierarchies, but overkill for a 3-level org |

**Decision:**  
A self-referencing foreign key on `employee_dim` was chosen. It expresses the hierarchy naturally and keeps the schema simple.

**Trade-offs accepted:**
- Querying multi-level hierarchies (e.g. "all reports under Alice, recursively") requires recursive CTEs, which can become complex
- At very large scale (thousands of levels), a closure table or nested set model would outperform this approach

---

## ADR-003: Use SQLite instead of a full RDBMS

**Status:** Accepted

**Context:**  
This is a portfolio project demonstrating dimensional modelling concepts, not a production system. A database engine needed to be chosen that supports SQL, foreign keys, and date-based queries.

**Options considered:**

| Option | Consideration |
|--------|--------------|
| **SQLite** | Zero setup, file-based, runs anywhere, sufficient for all SQL features used |
| PostgreSQL | Production-grade, better type system, required server setup |
| SQL Server / SSMS | Familiar from prior projects, but Windows-only and heavier to run |

**Decision:**  
SQLite was chosen to keep the project portable and accessible — anyone can clone the repo and run the queries without installing a database server. All SQL patterns used (CTEs, date-range queries, self-joins) are directly transferable to PostgreSQL or SQL Server.

**What a production version would change:**
- Use surrogate keys managed by a sequence or `GENERATED ALWAYS AS IDENTITY` column rather than manual `employee_id` values
- Add indexes on `is_current` and `start_date` / `end_date` for query performance at scale
- Add a transaction wrapper around the close + insert operations to prevent partial updates

---

## ADR-004: Use natural keys across SCD versions rather than surrogate keys

**Status:** Accepted with known limitation

**Context:**  
In a full data warehouse implementation, each row in a Type 2 dimension table would have a unique surrogate key (e.g. `employee_sk`) separate from the natural business key (`employee_id`). This project reuses `employee_id` across versions.

**Decision:**  
For clarity and simplicity, `employee_id` is reused across versions. The current record is always identified by `is_current = TRUE`.

**Known limitation:**  
In a production data warehouse, fact tables would join to the dimension using the surrogate key — this allows the fact table to point to the exact version of the dimension that was current at the time the fact was recorded. Without surrogate keys, this precision is lost. This is a deliberate simplification for this project scope.
