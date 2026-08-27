# subqueries

**A _subquery_ is a nested SQL query placed inside a larger main query (called the outer query)**. It acts as a temporary data provider, passing its results back to the outer query to filter, calculate, or project data.

The primary difference in execution is that a **subquery isolates and evaluates its datasets independently (or sequentially) before or during the main query**, whereas a **join merges relational tables directly into a single execution stream**, matching rows on the fly using shared keys.

---

## How Subqueries Are Executed

The way a database engine executes a subquery depends entirely on its structural dependency on the outer query.

### 1. Non-Correlated Subqueries (Independent)

In a non-correlated subquery, the inner query does not reference any columns from the outer query.

- **The Process:** The database engine executes the inner subquery **exactly once** first.
- **The Result:** The result set is materialized as an intermediate dataset (often stored in memory or a cache).
- **The Final Step:** The outer query treats this result as a hardcoded static value, list, or temporary table to finalize its execution.
- _Analogy: It is like doing a quick background calculation on a calculator, writing down the number, and then plugging that number into your main equation._

### 2. Correlated Subqueries (Dependent)

In a correlated subquery, the inner query references one or more columns from the outer query.

- **The Process:** The database engine processes the outer query **row by row**.
- **The Re-execution:** For every single row evaluated by the outer query, the inner subquery must re-execute using variables from that specific row.
- _Analogy: It is like a nested loop in programming, where the inner loop runs completely for every single tick of the outer loop._

---

## Execution Difference: Subqueries vs. Joins

While modern database optimizers try to rewrite simple subqueries into joins internally, the core mechanical execution paths remain distinct: [3, 6]

| **Execution Phase**       | **Subquery Execution**                                                                                                                      | **Join Execution**                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Data Scope & Pipeline** | Isolates data. It creates an intermediary, temporary dataset in a separate memory buffer.                                                   | unifies data. It streams and compares rows across multiple tables simultaneously in a single pipeline.       |
| **Looping Behavior**      | Often forces sequential steps (Step A finishes, then Step B reads it) or row-by-row iteration (for correlated queries).                     | Uses relational algorithms (Nested Loop, Hash Match, or Merge Join) to compare index keys uniformly.         |
| **Index Utilization**     | Inner indexes are used during the subquery phase, but the outer query may not be able to leverage indexes on the temporary subquery output. | Highly efficient use of primary or foreign key indexes across both tables to jump straight to matching rows. |
| **Resource Profile**      | Can trigger massive memory/CPU overhead if the inner query generates a heavy temporary dataset or re-runs millions of times.                | Requires memory to build hash tables, but avoids redundant sequential scanning of the same dataset.          |

---

## Why Joins Generally Execute Faster

In most localized relational database management systems (RDBMS), **joins outperform subqueries**.

When you use a subquery, the database engine must often construct separate query execution trees.
If the optimizer fails to flatten the query, the engine is forced to waste time managing overhead: allocating memory for temporary caches, tracking isolated contexts, or repeating executions.

A join bypasses this fragmented workflow. Because it operates on a singular relational matrix, the database optimizer can map out an optimal execution plan from start to finish, choosing the fastest method to lace the datasets together via index paths.

> > _(Note: In distributed databases, subqueries are sometimes preferred because filtering data locally within a subquery prevents heavy, slow table transfers across network nodes.)_

---
