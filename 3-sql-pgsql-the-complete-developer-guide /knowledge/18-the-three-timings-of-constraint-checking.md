# The Timing Of Constraint Checking

**Question:** whats the difference between constraint enforcement **during the statement execution**, **end of statement** and **end of transaction** ?

The distinction between **during statement execution**, **end of the statement**, and **end of the transaction** comes down to granular timing.

Yes, **the database state can absolutely become _temporarily_ invalid during the execution of a single statement**, and the engine is perfectly fine with that.

---

## The Three Timings of Constraint Checking

To clear up the confusion, think of a database like a teacher grading an exam. There are three ways they could check for mistakes:

### 1. During Statement Execution (Row-by-Row)

- **What it means:** The database checks the constraint the exact millisecond a single row is modified, _before_ moving to the next row in the same query.
- **Does the state become invalid? No.** The database will not allow even a temporary invalid state. If row #2 breaks a rule, it halts and crashes the entire query immediately, even if row #3 would have fixed it.
- **Example:** Standard `NOT DEFERRABLE` unique or check constraints.

### 2. End of the Statement

- **What it means:** The database allows the _entire_ single SQL query (like an `UPDATE` that changes 10,000 rows) to completely finish running. Once the statement is 100% done, the database steps in and looks at the final result of that specific statement.
- **Does the state become invalid? Yes, but _only_ during the statement's execution.** The database allows rows to be temporarily invalid while the query is actively crunching data, as long as everything resolves to a valid state by the time the semicolon hits.
- **Example:** `DEFERRABLE INITIALLY IMMEDIATE` constraints.
-

### 3. End of the Transaction (COMMIT)

- **What it means:** The database lets you run statement after statement (`INSERT`, then `UPDATE`, then `DELETE`). It doesn't check the rules at the end of statement 1, nor statement 2. It waits until you type `COMMIT`.
- **Does the state become invalid? Yes.** The data can remain invalid for minutes across multiple different queries, as long as it is cleaned up before you save the transaction.
- **Example:** `DEFERRABLE INITIALLY DEFERRED` constraints.

---

## A Concrete Example: Swapping Ranks (Why "End of Statement" matters)

Imagine you have a table of employees with a `rank` column that must be `UNIQUE`:

| Employee | Rank |
| -------- | ---- |
| Alice    | 1    |
| Bob      | 2    |

You want to shift everyone's rank down by 1 using a single statement:

```sql
UPDATE employees SET rank = rank + 1;
```

### If checked "During Statement Execution" (`NOT DEFERRABLE`)

1. The database processes Alice first. It tries to change her rank from `1` to `2`.
2. It looks at the table, sees Bob is already at rank `2`, **panics immediately**, and throws a `Unique Constraint Violation` error. The query fails instantly.

### If checked at the "End of the Statement" (`INITIALLY IMMEDIATE`)

1. The database processes Alice: changes her to `2`. (The state is now **temporarily invalid** because both Alice and Bob are rank `2`).
2. The database processes Bob _in the same statement_: changes him from `2` to `3`.
3. The statement finishes executing.
4. The database checks the constraint. It sees Alice is `2` and Bob is `3`. Everything is unique! **The query succeeds.**

---

## Summary Checklist

| Mode                      | Allowed to be invalid _during_ a query? | Allowed to be invalid _between_ two queries? |
| ------------------------- | --------------------------------------- | -------------------------------------------- |
| **`NOT DEFERRABLE`**      | ❌ No                                   | ❌ No                                        |
| **`INITIALLY IMMEDIATE`** | Yes                                     | ❌ No                                        |
| **`INITIALLY DEFERRED`**  | Yes                                     | Yes                                          |
