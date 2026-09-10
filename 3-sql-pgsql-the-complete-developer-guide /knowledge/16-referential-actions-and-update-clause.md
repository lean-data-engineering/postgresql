# SQL Referential Actions and Update Clauses

## 1: Referential Actions

In SQL, the explicit concept name for `ON UPDATE` and `ON DELETE` actions is **`referential actions`**.

These actions are defined as clauses within a **foreign key constraint** to enforce referential integrity between a parent table (referenced) and a child table (referencing).

---

### 1.1: Standard Referential Actions

When a primary key in a parent table is modified or removed, SQL uses these five standard behaviors to dictate how the child table should react:

- **CASCADE:** Automatically propagates the change. If the parent row is deleted or updated, the matching child rows are deleted or updated as well.
- **RESTRICT:** Prevents and immediately rejects the modification or deletion of the parent row if any matching child rows exist.
- **NO ACTION:** Standard SQL behavior that is often identical to `RESTRICT`. It ensures the database checks for referential integrity violations before or during the transaction.
- **SET NULL:** Automatically sets the foreign key columns in the child table to `NULL` when the parent row is altered. (Requires the child column to allow null values).
- **SET DEFAULT:** Automatically resets the foreign key columns in the child table to their pre-defined default values.

---

### 1.2: `RESTRICT` VS `NO ACTION`

The primary difference between **`NO ACTION`** and **`RESTRICT`** is **`the timing of when the referential integrity check is enforced during a transaction`**.

Both options ultimately prevent an `UPDATE` or `DELETE` on a parent table if matching child rows exist. However, they handle transactions and constraint deferrals differently depending on the database management system (DBMS) you use.

#### 1.2.1: Core Behavioral Differences

- **`RESTRICT`:** Enforces the restriction **immediately**. It checks for violations at the outset of the statement execution and throws an error right away. It does not allow the constraint check to be deferred.
- **`NO ACTION`:** Enforces the restriction at the **end of the statement or transaction**. In database systems that support deferred constraints (like PostgreSQL Constraints), `NO ACTION` lets you temporarily violate the foreign key rule mid-transaction as long as a subsequent statement (like deleting or updating the child rows) fixes the reference before the transaction commits.

#### 1.2.2: Summary Comparison

| **Feature**                    | **`RESTRICT`**                                 | **`NO ACTION`**                                              |
| ------------------------------ | ---------------------------------------------- | ------------------------------------------------------------ |
| **When it checks**             | Immediately when the statement runs            | At the end of the statement or deferred to commit time       |
| **Allows temporary changes**   | No, rejects the operation instantly            | Yes, if the constraint is deferrable and fixed before commit |
| **Database behavior in MySQL** | Identical to `NO ACTION` (checked immediately) | Identical to `RESTRICT` (checked immediately)                |

---

### 1.3: Deffered Constraints

Here is a clear example of how **deferred constraints** work using **PostgreSQL**, showcasing the exact functional difference between `NO ACTION` and `RESTRICT` during a transaction.

Here is exactly how it works for **`ON UPDATE`** and **`ON DELETE`**

1. **For `ON UPDATE` (Deferred)**
   1. **The Action:** You change a parent row's ID.
   2. **The Temporary State:** The child rows are now pointing to an ID that no longer exists (orphaned data).
   3. **The Deferral:** The database allows this broken link to exist mid-transaction. You must update the child rows to point to the new ID before you type `COMMIT`.
2. **For `ON DELETE` (Deferred)**
   1. **The Action:** You delete a parent row entirely.
   2. **The Temporary State:** The child rows are left pointing to a deleted parent ID.
   3. **The Deferral:** The database does not throw an immediate error. It gives you until the end of the transaction to either delete those matching child rows, or insert a brand-new parent row with that same original ID to satisfy the relationship.

In systems like PostgreSQL, referential actions like `RESTRICT`, `CASCADE`, or `SET NULL` are executed _immediately_ at the statement level. Only the `NO ACTION` rule explicitly allows itself to be pushed to the end of a transaction.

Therefore, applying `DEFERRABLE` to a foreign key constraint only actually delays the parts of the constraint that are defined as `NO ACTION`.

In standard SQL (and engines like **PostgreSQL**), the database engine will not throw a syntax error if you combine `DEFERRABLE` with actions like `CASCADE` or `RESTRICT`. However, **only the `NO ACTION` clause will actually defer**.

The other actions will always behave immediately, meaning **you must use `NO ACTION` for whichever specific action you want to postpone**.

---

#### 1.3.1: Setup: Creating the Tables

To make a foreign key constraint deferrable, it **must be explicitly defined as `DEFERRABLE`**, and it must use `NO ACTION` (not `RESTRICT`).

```sql
-- Parent Table
CREATE TABLE parents (
    id INT PRIMARY KEY
);

-- Child Table with DEFERRABLE NO ACTION
CREATE TABLE children_no_action (
    id INT PRIMARY KEY,
    parent_id INT REFERENCES parents(id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE INITIALLY DEFERRED
);

-- Child Table with RESTRICT (Cannot be deferred)
CREATE TABLE children_restrict (
    id INT PRIMARY KEY,
    parent_id INT REFERENCES parents(id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

-- Seed Initial Data
INSERT INTO parents (id) VALUES (1);
INSERT INTO children_no_action (id, parent_id) VALUES (10, 1);
INSERT INTO children_restrict (id, parent_id) VALUES (20, 1);
```

---

#### 1.3.2: The `RESTRICT` Behavior (Fails Instantly)

If you attempt to update the parent ID, `RESTRICT` evaluates the change **immediately at the statement level** and halts execution.

```sql
BEGIN;
-- This statement fails instantly and aborts the entire transaction
UPDATE parents SET id = 2 WHERE id = 1;

-- ERROR: update or delete on table "parents" violates foreign key constraint on table "children_restrict"
-- DETAIL: Key (id)=(1) is still referenced from table "children_restrict".
ROLLBACK;
```

---

#### 1.2.3: The `NO ACTION` Behavior (Succeeds via Deferral)

Because `children_no_action` is set to `DEFERRABLE INITIALLY DEFERRED`, PostgreSQL **postpones the check until the very end of the transaction (`COMMIT`)**. This lets you break the rule temporarily as long as you fix it before saving.

```sql
BEGIN;
-- 1. Update the parent ID (PostgreSQL allows this temporarily)
UPDATE parents SET id = 2 WHERE id = 1;

-- 2. Fix the child table so it points to the new ID
UPDATE children_no_action SET parent_id = 2 WHERE parent_id = 1;

-- 3. Commit the transaction
COMMIT;

-- SUCCESS! The integrity check passes at commit time because all data aligns.
```

If you omitted step 2 in the transaction above, the `COMMIT` would fail and roll back everything automatically.

---

## 2: when `ON UPDATE` triggers?

if you update any column in the parent table _other_ than the referenced column (like the `ID`), the database will let you update it with no issues.

However, the **`ON UPDATE`** clause specifically triggers when you alter the actual referenced value (the `ID` itself) in the parent table.

While it is rare and generally considered a bad practice to change a primary key `ID`,
there are scenarios where IDs can change, and that is exactly why the `ON UPDATE` clause exists.

---

### 2.1: Why would a parent ID change?

- **Natural Primary Keys:** If your primary key is a "natural key" like a **username**, **email address**, or **SKU code** instead of an auto-incrementing integer, users change these all the time. If a user updates their username, `ON UPDATE CASCADE` ensures all their related data moves with them.
- **Database Migrations & Merges:** If two companies merge and need to combine databases, ID conflicts occur. If a parent ID has to be shifted (e.g., from `101` to `9101`) to avoid a collision, the `ON UPDATE clause` ensures hundreds of child rows don't suddenly become orphaned.

---

### 2.2: What happens without it?

If you try to update a parent ID without an ON UPDATE clause (which defaults to `NO ACTION` / `RESTRICT`), the database will **block the update entirely** and throw an error because changing that ID would instantly break the link to the child rows.

The database npicks a single keyword as its implicit rule:

- **PostgreSQL / SQL Standard:** Defaults to **`NO ACTION`** (which allows for future statement/transaction-end checking).
- **MySQL:** Defaults to **`RESTRICT`** (where everything is checked instantly).However, because MySQL does not support deferring constraints at all, `NO ACTION` and `RESTRICT` are 100% identical in MySQL.
