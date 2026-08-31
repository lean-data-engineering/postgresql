# double quotes and single quotes in postgresql

In PostgreSQL, the rule for quotes is incredibly strict and absolute: **Single quotes are for data values, and double quotes are for database objects (like tables and columns).**

Swapping them will immediately cause a syntax error. Here is the exact breakdown of how they work:

---

## 1. Single Quotes (`'Text'`) = _Text Data Values_

Use single quotes exclusively when you are typing out **literal string values, dates, or timestamps** that you want to insert, update, or filter.

- **What they do:** They tell PostgreSQL: "This is raw text data."
- **Examples:**

  ```sql
  -- Correct: Data values are wrapped in single quotes
  SELECT * FROM employees
  WHERE first_name = 'John' AND hire_date = '2026-01-15';
  ```

- **What happens if you use double quotes instead?**

  ```sql
  -- ❌ ERROR: column "John" does not exist
  SELECT * FROM employees WHERE first_name = "John";
  ```

  _PostgreSQL thinks you are trying to compare the column `first_name` to a completely different column named `John`._

---

## 2. Double Quotes (`"Identifier"`) = _Database Objects (Tables & Columns)_

Use double quotes exclusively for **identifiers**—the names of your tables, columns, schemas, or views.

Most of the time, you do not need to use them at all. You only pull out double quotes in two specific scenarios:

### Scenario A: Your table or column name uses Capital Letters

PostgreSQL forces everything to lowercase by default. If you created a table or column using camelCase or capital letters and want to preserve that capitalization, you must wrap it in double quotes every time you reference it.

```sql
-- Correct: Forces PostgreSQL to look for the exact casing
SELECT "FirstName" FROM employees;

-- ❌ ERROR: column "firstname" does not exist
SELECT FirstName FROM employees;
```

### Scenario B: Your column name has Spaces or Special Characters

If a column name contains a space, a hyphen, or matches a reserved SQL keyword (like `group` or `order`), you must use double quotes so the database knows it is a single column name.

PostgreSQL does not allow hyphens (-) or spaces in standard unquoted identifiers for table, database, or column names because it treats the hyphen as a minus sign and space as command/keyword seperators.

#### How to Use Hyphens and spaces (If Needed)

- **Double Quotes:** You can use hyphens & spaces by wrapping the name in double quotes, like `"my-table"` or `"my table"`.
- **The Catch:** You must use double quotes every time you query that table or column (e.g., `SELECT * FROM "my-table";` or `SELECT * FROM "my table";`).
- **Best Practice:** Avoid hyphens and spaces completely. Use underscores (my_table) instead.


```sql
-- Correct: Handles spaces and reserved keywords safely
SELECT "first name", "order" FROM sales_data;

```

---

## The Ultimate Golden Rule

- **`'Single Quotes'`** are for **S**trings (Data content).
- **`"Double Quotes"`** are for **D**atabase objects (Tables and Columns).

```sql
-- The anatomy of a valid PostgreSQL query:
SELECT "ColumnName" FROM "TableName" WHERE "ColumnName" = 'StringValue';

```
