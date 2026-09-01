# Window Function

## 1: What is a Window Function?

A **window function** performs a calculation across a set of table rows that are related to the current row.

It is called a "window" function because the database isolates a specific subset of rows—a virtual window—to look at while processing the math for the current row. As the database moves from one row to the next, this window slides along with it.

---

## 2: What Were We Doing Earlier? (The Problem & The Solution)

### 2.1: The Old Way: Group By Aggregation

Before window functions were introduced to standard SQL, if you wanted to mix individual row information with summary metrics, you had to use a `GROUP BY` clause or complex subqueries.

The fundamental problem with a standard `GROUP BY` is that it **collapses your data**. It _condenses multiple rows into a single summary row_. Once you group by a column, you lose the ability to see individual row details.

### 2.2: The Problem Example

Imagine you have a table of employees, and your boss asks for a report showing each employee's name, their salary, and the average salary of their specific department.

If you tried this with `GROUP BY`:

```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id;
```

**The result:** You get a clean list of departments and averages, but **all employee names and individual salaries are completely gone.**

To fix this back in the day, you had to write a messy, slow self-join via a subquery:

```sql
-- The old, complex way to solve the problem
SELECT e.employee_name, e.salary, d.avg_salary
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) d ON e.department_id = d.department_id;
```

This requires the database to scan the table twice, create a temporary dataset, and stitch it back together. It is hard to read and performs poorly on large datasets.

### 2.3: How Window Functions Solved It

Window functions allow you to calculate aggregate data **without collapsing the rows.** Every single individual row remains on the screen, and the calculated summary is simply appended as a column directly next to it.

```sql
-- The modern window function way
SELECT
    employee_name,
    salary,
    AVG(salary) OVER(PARTITION BY department_id) AS avg_salary
FROM employees;
```

The database calculates the department average behind the scenes, leaves your individual employee rows intact, and pastes the calculation seamlessly on every line.

## 3: Window Function Syntax & Components

The general syntax format for any window function inside your code looks like this:

```sql
FUNCTION_NAME(expression) OVER (
    [PARTITION BY column_list]
    [ORDER BY column_list]
    [ROWS|RANGE frame_specification]
)
```

### 3.1: The Function Name (`FUNCTION_NAME`)

This is the math or operation you want to perform. It falls into three types:

- **Aggregates:** `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()`
- **Rankings:** `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`
- **Value Analytics:** `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()`

### 3.2: The Partition Clause (`PARTITION BY`)

This divides the dataset into distinct, independent groups (or buckets). The window function _runs independently inside each bucket_ and **resets to zero/clear** when a new bucket starts. If you completely omit `PARTITION BY`, the database treats the entire table as one giant bucket.

### 3.3: The Order Clause (`ORDER BY`)

This establishes the sequence of rows _inside_ each partition. It is strictly required for ranking functions (to know who is 1st or 2nd) and for running totals (to know what to add next chronologically).

### 3.4: The Frame Clause (`ROWS | RANGE`)

This defines the precise boundaries of the window relative to the current row. It tells the function exactly how many rows backward or forward to look.

- _Example:_ `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` forces the function to only look at the current line and the two lines immediately above it (perfect for a 3-day moving average).

---

## 4: The Need for a Separate Window Clause (The Named Way)

When writing complex queries, you often want to calculate multiple different metrics using the exact same window setup. Typing out the same layout over and over creates messy, redundant code.

### 4.1: The Problem: Code Duplication

```sql
SELECT
    employee_id,
    department_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank_num,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank_dense,
    LAG(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) AS prev_sal
FROM employees;
```

Notice how `PARTITION BY department_id ORDER BY salary DESC` is copy-pasted three distinct times. If your boss asks you to change the sort order to `hire_date` instead of `salary`, you have to change it in three separate places.

### 4.2: The Solution: The Named `WINDOW` Clause

To solve this, SQL provides a designated `WINDOW` clause that sits right after `HAVING` and before `ORDER BY`. It acts like a variable shortcut. You define the window configuration once, give it a name, and reuse it inside `SELECT`.

```sql
SELECT
    employee_id,
    department_id,
    salary,
    ROW_NUMBER() OVER dept_window AS rank_num,
    RANK() OVER dept_window AS rank_dense,
    LAG(salary) OVER dept_window AS prev_sal
FROM employees
WINDOW dept_window AS (PARTITION BY department_id ORDER BY salary DESC); -- Defined Once!
```

---

## 5: Comprehensive Practical Examples

### 1: Calculating a Running Total (Using Aggregate `SUM`)

Track how business revenue accumulates sequentially over a given week.

```sql
SELECT
    sale_date,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY sale_date) AS running_total
FROM sales;
```

**Output View:**

| **sale_date** | **daily_revenue** | **running_total** |
| ------------- | ----------------- | ----------------- |
| 2026-09-01    | $100              | **$100**          |
| 2026-09-02    | $150              | **$250**          |
| 2026-09-03    | $200              | **$450**          |

---

### 2: Finding Month-Over-Month Growth (Using Value `LAG`)

Compare the current month's performance directly against the previous month's performance.

```sql
SELECT
    sales_month,
    monthly_sales,
    LAG(monthly_sales, 1) OVER (ORDER BY sales_month) AS previous_month_sales
FROM monthly_performance;
```

**Output View:**

| **sales_month** | **monthly_sales** | **previous_month_sales** |
| --------------- | ----------------- | ------------------------ |
| January         | $10,000           | _NULL_ (No previous row) |
| February        | $12,000           | **$10,000**              |
| March           | $11,500           | **$12,000**              |

---

### 3. The Duplicate Data Tie Trap (`RANK` vs. `DENSE_RANK` vs. `ROW_NUMBER`)

**The Trick:** When ordering data that contains duplicate values, choosing the wrong function will distort your downstream metrics or cause non-deterministic behavior.

```sql
SELECT
    student_name,
    test_score,
    ROW_NUMBER() OVER (ORDER BY test_score DESC) AS row_num,
    RANK() OVER (ORDER BY test_score DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY test_score DESC) AS dense_rnk
FROM exam_results;
```

#### 🔎 Edge-Case Behavior Breakdown

- **`ROW_NUMBER()` is non-deterministic here:** Because Bob and Charlie both scored 95, the database will randomly assign one of them `2` and the other `3`. If you run this query tomorrow, their positions might swap.
- **`RANK()` leaves gaps:** It assigns both `2`, but skips `3`. David becomes `4`. If you look for `WHERE rnk = 3`, you will get zero results back.
- **`DENSE_RANK()` keeps it tight:** It assigns both `2`, and makes David `3`. No numbers are skipped.

| **student_name** | **test_score** | **row_num** | **rnk** | **dense_rnk** |
| ---------------- | -------------- | ----------- | ------- | ------------- |
| Alice            | 100            | 1           | 1       | 1             |
| **Bob**          | **95**         | **2**       | **2**   | **2**         |
| **Charlie**      | 95             | **3**       | **2**   | **2**         |
| David            | 90             | 4           | **4**   | **3**         |

---

### 4. The Invisible Default Frame Trap (Running Total vs. Grand Total)

**The Trick:** If you write an aggregate window function like `SUM()` and include an `ORDER BY` clause, SQL silently adds a default frame restriction: `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. This completely changes how the math behaves compared to omitting `ORDER BY`.

```sql
SELECT
    emp_name,
    salary,
    SUM(salary) OVER () AS static_grand_total,
    SUM(salary) OVER (ORDER BY salary) AS sliding_running_total
FROM corporate_payroll;
```

#### 🔎 Edge-Case Behavior Breakdown

- **`static_grand_total`:** Because there is no `ORDER BY`, the window is wide open. It returns the total payroll sum ($23,000) across every single line.
- **`sliding_running_total`:** Because `ORDER BY` is present, it computes a running sum. However, watch what happens on **Frank** and **Grace's** rows. Because their salaries are tied at $5,000, `RANGE` processes their rows _together_. Instead of adding $5,000 sequentially, it jumps straight to adding $10,000 for both rows simultaneously.

| **emp_name** | **salary** | **static_grand_total** | **sliding_running_total** | **What actually happened**               |
| ------------ | ---------- | ---------------------- | ------------------------- | ---------------------------------------- |
| Emily        | $3,000     | $23,000                | $3,000                    | $3,000                                   |
| **Frank**    | **$5,000** | $23,000                | **$13,000**               | Tied values evaluated as a single group! |
| **Grace**    | **$5,000** | $23,000                | **$13,000**               | ($3,000 + $5,000 + $5,000)               |
| Henry        | $10,000    | $23,000                | $23,000                   | Final accumulator step.                  |

> 💡 The Fix: If you want a strict row-by-row running total that doesn't lump ties together, use ROWS instead of RANGE:`SUM(salary) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`

---

### 5. The `NULL` Value Sorting Pitfall (`LAG` & Sorting)

**The Trick:** By default, databases handle `NULL` values differently when sorting. In databases like PostgreSQL, `NULL` is treated as the largest possible value (appears last in `ASC`, first in `DESC`). In SQL Server, it is treated as the smallest. This completely breaks chronological trend lines using `LAG` or `LEAD`.

```sql
SELECT
    device_id,
    reading_time,
    temperature,
    -- Danger: NULL temperatures can float to the top and break logic
    LAG(temperature) OVER (
        PARTITION BY device_id
        ORDER BY temperature DESC
    ) AS wrong_trend,

    -- Solution: Force NULLs to the back regardless of sort order
    LAG(temperature) OVER (
        PARTITION BY device_id
        ORDER BY temperature DESC NULLS LAST
    ) AS clean_trend
FROM sensor_logs;
```

- **The Takeaway:** Always explicitly declare `NULLS FIRST` or `NULLS LAST` inside your window `ORDER BY` clause if your underlying data columns are nullable.

---

### 6. Overriding a Base Window Definition (Mixing Constraints)

**The Trick:** What if you want to use the Named `WINDOW` clause to share a common pattern, but one of your columns needs to look at a slightly wider frame constraint than the rest? You can selectively extend or override parts of a named window inline.

```sql
SELECT
    transaction_date,
    amount,
    -- 1. Uses the base window exactly as defined
    AVG(amount) OVER w_vitals AS standard_running_avg,

    -- 2. Inherits PARTITION and ORDER but adds a custom physical frame constraint
    SUM(amount) OVER (w_vitals ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS rolling_4day_sum
FROM revenue_ledger
WINDOW w_vitals AS (PARTITION BY store_id ORDER BY transaction_date ASC);
```

- **The Takeaway:** You can pass a window name into the `OVER()` parentheses and then append additional parameters directly after it to extend its capabilities on the fly.

---

### 7. Filtering the Output of a Window Function (The Wrapper Requirement)

**The Trick:** Because of the SQL logical processing order, window functions execute inside the `SELECT` phase, which happens after `WHERE`. You cannot use a window function inside a `WHERE` clause directly (e.g., `WHERE ROW_NUMBER() OVER(...) = 1` will throw a syntax error).

#### ❌ The Broken Way

```sql
-- THIS WILL ERROR
SELECT employee_name, salary
FROM employees
WHERE RANK() OVER (ORDER BY salary DESC) <= 3;
```

#### The Correct Way (Using a CTE / Subquery wrapper)

You must project the calculation out into an isolated temporary workspace first, then apply your filtering rules against the resulting static column name.

```sql
WITH RankedPayroll AS (
    SELECT
        employee_name,
        salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS financial_rank
    FROM employees
)
SELECT employee_name, salary, financial_rank
FROM RankedPayroll
WHERE financial_rank <= 3; -- Works flawlessly!
```

---

### 8. Empty Window Frames (`FIRST_VALUE` vs `LAST_VALUE`)

**The Trick:** Many developers expect `LAST_VALUE()` to return the final value of a group. However, because of the default sliding frame restriction (`RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`), the "window" stops expanding at the current row you are standing on. Thus, `LAST_VALUE()` ends up returning the current row's value, rendering it useless.

#### ❌ The Broken Instinct

```sql
SELECT
    category,
    product_name,
    price,
    LAST_VALUE(price) OVER (PARTITION BY category ORDER BY price ASC) AS breaking_last_price
FROM inventory;
```

_Result:_ `breaking_last_price` will just show the current row's price, because the window hasn't "seen" the rows below it yet.

#### The Fixes

You must either explicitly open up the window frame boundary to search the entire partition block, or reverse the sort layout and swap to `FIRST_VALUE()`.

```sql
SELECT
    category,
    product_name,
    price,
    -- Option A: Explicitly extend the window view clear to the bottom of the group
    LAST_VALUE(price) OVER (
        PARTITION BY category
        ORDER BY price ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS true_highest_price,

    -- Option B: Keep default frame but change sort behavior (Highly Recommended for speed)
    FIRST_VALUE(price) OVER (
        PARTITION BY category
        ORDER BY price DESC
    ) AS true_highest_price_optimized
FROM inventory;
```
