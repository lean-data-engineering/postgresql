# Writing and Execution Order of SQL Queries

1. SQL Query Writing Order
2. Logical Execution Order
3. What happens in each stage
4. Where scalar / aggregate / window functions work
5. Example step-by-step execution

---

## 1: SQL Query You Write

Typical SQL query:

```sql
SELECT [DISTINCT | ALL]
    column_name,
    AGGREGATE_FUNCTION(column_name),
    WINDOW_FUNCTION(column_name) OVER (
        [PARTITION BY column_list]
        [ORDER BY column_list]
        [ROWS | RANGE BETWEEN frame_specpecification]
    ) AS window_alias
FROM table_name_1
[INNER | LEFT | RIGHT | FULL] JOIN table_name_2
    ON join_condition
WHERE row_condition
GROUP BY column_list
[WITH ROLLUP | WITH CUBE]
HAVING group_condition
WINDOW window_name AS (PARTITION BY column_list ORDER BY column_list)
ORDER BY column_list [ASC | DESC] [NULLS FIRST | NULLS LAST]
LIMIT row_count OFFSET offset_count;
```

But PostgreSQL **does not execute it in this order**.

---

## 2: Actual Logical Execution Order

The **logical order** is:

```text
1. FROM
2. JOIN
3. ON
4. WHERE
5. GROUP BY
6. HAVING
7. SELECT
8. WINDOW FUNCTIONS
9. DISTINCT
10. ORDER BY
11. LIMIT / OFFSET
```

Think of SQL as a **data pipeline**.

Each stage transforms the result of the previous stage.

---

## 3: Step-by-Step Explanation

---

### Step 1 — FROM

The query starts by identifying the **source tables**.

Example:

```sql
SELECT *
FROM employees;
```

PostgreSQL loads rows from `employees`.

Result after this stage:

```text
all rows from employees
```

---

### Step 2 — JOIN

If joins exist, PostgreSQL combines tables.

Example:

```sql
SELECT *
FROM employees e
JOIN departments d
```

Now we get a **cartesian candidate set** before filtering.

---

### Step 3 — ON (Join condition)

Join conditions filter rows from the join.

Example:

```sql
SELECT *
FROM employees e
JOIN departments d
ON e.department_id = d.id;
```

Result:

```text
joined rows where department_id matches
```

---

### Step 4 — WHERE

Now **row filtering happens**.

Example:

```sql
SELECT *
FROM employees
WHERE salary > 50000;
```

Rows that fail the condition are removed.

Important:

```text
WHERE works BEFORE grouping
```

So aggregate functions are **not allowed here**.

❌ Invalid

```sql
WHERE COUNT(*) > 10
```

_Note: You can't use computed columns in `WHERE` clause as they are evaluted after it ie in `SELECT`_

---

### Step 5 — GROUP BY

Rows are grouped.

Example:

```sql
SELECT department_id
FROM employees
GROUP BY department_id;
```

Rows become groups:

```text
dept 1 → group
dept 2 → group
dept 3 → group
```

---

### Step 6 — HAVING

HAVING filters **groups**, not rows.

Example:

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5;
```

Groups with `≤5` employees are removed.

Difference:

| Clause | Works On |
| ------ | -------- |
| WHERE  | rows     |
| HAVING | groups   |

---

### Step 7 — SELECT

Now the **final columns are computed**.

Example:

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
```

At this stage:

- scalar functions run
- aggregate functions compute results

Example:

```sql
SELECT
UPPER(name),
salary * 1.1
FROM employees;
```

Each row processed.

---

### Step 8 — Window Functions

Window functions run **after SELECT and GROUP BY**.

Example:

```sql
SELECT
name,
salary,
RANK() OVER (ORDER BY salary DESC)
FROM employees;
```

Important rule:

```text
Window functions cannot be used in WHERE or GROUP BY
```

---

### Step 9 — DISTINCT

Duplicates are removed.

Example:

```sql
SELECT DISTINCT country
FROM users;
```

---

### Step 10 — ORDER BY

Rows are sorted.

Example:

```sql
SELECT name, salary
FROM employees
ORDER BY salary DESC;
```

At this stage you can use:

- column aliases
- window functions
- expressions

---

### Step 11 — LIMIT / OFFSET

Finally PostgreSQL trims the result.

Example:

```sql
SELECT *
FROM employees
ORDER BY salary DESC
LIMIT 10;
```

Returns top 10 rows.

---

## 4: Full Example Walkthrough

Query:

```sql
SELECT
department_id,
COUNT(*) AS emp_count
FROM employees
WHERE salary > 50000
GROUP BY department_id
HAVING COUNT(*) > 3
ORDER BY emp_count DESC
LIMIT 5;
```

Execution:

---

### Step 1 — `FROM`

```text
load employees table
```

---

### Step 2 — `WHERE`

```text
filter salary > 50000
```

---

### Step 3 — `GROUP BY`

```text
group rows by department_id
```

---

### Step 4 — `HAVING`

```text
remove groups where count <= 3
```

---

### Step 5 — `SELECT`

```text
compute department_id and COUNT(*)
```

---

### Step 6 — `ORDER BY`

```text
sort by emp_count descending
```

---

### Step 7 — `LIMIT`

```text
return top 5 rows
```

---

## 5: Where Functions Work

| Function Type | WHERE | SELECT | HAVING | ORDER BY |
| ------------- | ----- | ------ | ------ | -------- |
| Scalar        | ✅    | ✅     | ❌     | ✅       |
| Aggregate     | ❌    | ✅     | ✅     | ✅       |
| Window        | ❌    | ✅     | ❌     | ✅       |

---

## 6: Mental Model

Think of SQL execution as a **data pipeline**:

```text
TABLES
   ↓
FROM
   ↓
JOIN
   ↓
WHERE (filter rows)
   ↓
GROUP BY (create groups)
   ↓
HAVING (filter groups)
   ↓
SELECT (compute columns)
   ↓
WINDOW FUNCTIONS
   ↓
DISTINCT
   ↓
ORDER BY
   ↓
LIMIT
```

---

## 7: One Classic Trick (Interview Favorite)

Why this works:

```sql
SELECT salary * 2 AS double_salary
FROM employees
ORDER BY double_salary;
```

Because:

```text
SELECT happens before ORDER BY
```

So alias is available.

But this fails:

```sql
SELECT salary * 2 AS double_salary
FROM employees
WHERE double_salary > 10000;
```

Because:

```text
WHERE runs before SELECT
```

Alias doesn't exist yet.

---
