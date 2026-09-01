# `ORDER BY` WITH Columns having `NULL` values

In SQL, the `ORDER BY` clause treats `NULL` (missing or unknown data) differently depending on the database system, because standard SQL leaves the default sorting behavior to the vendor.

## Default Behavior by Database

- **PostgreSQL, Oracle, and Snowflake:** Treat `NULL` as the _largest possible value_.
  - **ASC (Ascending):** `NULL` values appear **last**.
  - **DESC (Descending):** `NULL` values appear **first**.
- **MySQL and SQL Server:** Treat NULL as the _smallest possible value_.
  - **ASC (Ascending):** `NULL` values appear **first**.
  - **DESC (Descending):** `NULL` values appear **last**.

---

## Controlling Null Sorting (`NULLS FIRST` / `NULLS LAST`)

Many modern databases (like [PostgreSQL](https://www.postgresql.org/docs/current/queries-order.html), [Snowflake](https://docs.snowflake.com/en/sql-reference/constructs/order-by), and [Spark](https://spark.apache.org/docs/latest/sql-ref-syntax-qry-select-orderby.html)) support standard explicit modifiers to force where nulls appear:

```sql
-- Force NULLs to the top regardless of ASC or DESC
SELECT * FROM table_name ORDER BY column_name ASC NULLS FIRST;

-- Force NULLs to the bottom regardless of ASC or DESC
SELECT * FROM table_name ORDER BY column_name DESC NULLS LAST;
```

Read more about general database implementation nuances in this guide on [How ORDER BY and NULL Work Together in SQL](https://learnsql.com/blog/how-to-order-rows-with-nulls/).

---

## Workarounds for Databases without `NULLS FIRST/LAST` (e.g., MySQL)

If your database doesn't support the `NULLS FIRST` or `NULLS LAST` keywords natively, you can use a conditional expression or helper sort flag:

```sql
-- Puts NULL values last in MySQL (ASC sort)
SELECT * FROM table_name ORDER BY column_name IS NULL ASC, column_name ASC;
```

- **`ORDER BY column_name IS NULL ASC`** creates a hidden boolean column (`0` for data, `1` for `NULL`). Since `0` is smaller than `1`, your real data sorts to the top first, and NULL values are pushed to the bottom.
