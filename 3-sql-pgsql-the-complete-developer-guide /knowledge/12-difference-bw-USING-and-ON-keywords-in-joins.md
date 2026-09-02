# Difference between `ON` and `USING` keywords in JOINS

The main difference is that **`USING`** combines columns with the exact same name into a single column in the output, while **`ON`** keeps both columns separate.

## 1: How `USING` Works

- Use **`USING`** when the two tables share a column with the **same name and data type**.
- It _automatically removes duplicate columns_ from the final result.
- You do not need to prefix the column name with a table name (like `table.column`).

**Example:**

```sql
SELECT *
FROM employees
JOIN departments USING (department_id);
```

## 2: How `ON` Works

- Use **`ON`** when the columns have **different names** or when you need a complex condition (like greater than or less than).
- It _keeps both columns_ in the final result.
- You must specify which table each column belongs to (like `employees.dept_id = departments.id`).

**Example:**

```sql
SELECT *
FROM employees
JOIN departments
    ON employees.department_id = departments.dept_id;
```

## Key Comparisons

- **Column Names:** `USING` _requires_ identical names. `ON` allows different names.
- **Output:** `USING` shows the matched column only once. `ON` shows both columns separately.
- **Flexibility:** `USING` only checks for equality (`=`). `ON` can use other operators like `>`, `<`, or `<>`.
