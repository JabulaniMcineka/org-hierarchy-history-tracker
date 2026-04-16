# Org Hierarchy History Tracker

> **"SQL-based data modelling project implementing Slowly Changing Dimension (Type 2) to track organisational hierarchy changes over time."**

---

## What This Project Demonstrates

| Concept | Implementation |
|---|---|
| Hierarchical data modelling | Self-referencing `manager_id` foreign key on `employee_dim` |
| Historical tracking | SCD Type 2 — `start_date`, `end_date`, `is_current` pattern |
| Dimensional design principles | Based on Kimball's *Data Warehouse Toolkit* methodology |

---

## Why It Matters

- Real-world HR systems **must preserve history** — you can't just overwrite a promotion
- Reporting structures **change over time** — Carol's manager today may not be her manager in 6 months
- We must **never lose historical data** — audits, compliance, and analytics all depend on it

---

## The SCD Type 2 Pattern

When something changes (role, manager, department), we do **two things**:

1. **Close** the old record — set `end_date` and `is_current = FALSE`
2. **Insert** a new record — with the new values and `is_current = TRUE`

This means every version of the truth is preserved forever.

---

## Repo Structure

```
org-hierarchy-tracker/
│
├── schema.sql       — table definition
├── seed_data.sql    — initial org structure
├── changes.sql      — SCD Type 2 change simulations
├── queries.sql      — analytical queries
└── README.md        — this file
```

---

## Org Structure (Visual)

### Version 1 — Initial State (Jan 2025)

```
        Alice (CEO)
              |
        Bob (Manager)
              |
        Carol (Analyst)
```

### Version 2 — After Bob's Promotion (Jun 2025)

```
        Alice (CEO)
              |
        Bob (Senior Manager)
              |
        Carol (Analyst)
```

### Version 3 — After Carol's Manager Change (Sep 2025)

```
        Alice (CEO)
           /     \
        Bob       Carol
  (Sr. Manager)  (Analyst)
```

---

## Key Queries

**Current org snapshot:**
```sql
SELECT * FROM employee_dim WHERE is_current = TRUE;
```

**Point-in-time lookup — who did Carol report to on 1 March 2025?**
```sql
SELECT *
FROM employee_dim
WHERE employee_id = 3
AND '2025-03-01' BETWEEN start_date AND COALESCE(end_date, '9999-12-31');
```

---

## Concepts Applied

- **Self-referencing foreign key** — `manager_id` points back to `employee_id` in the same table
- **SCD Type 2** — full row versioning with date ranges
- **Surrogate vs natural keys** — `employee_id` is reused across versions (natural); a surrogate key column could be added for true DW compliance
- **COALESCE for open-ended dates** — `NULL` end_date means "still current"; treated as far-future date in range queries

---

*Built as a portfolio project demonstrating dimensional modelling and historical data tracking.*
