# SQL Numeric Functions, Data Types and Casting

## 1. Rounding Functions Comparison

| Function                     | Rules & Purpose                                                                      | Output Example (`123.456`, `2`) | Output Example (`123.99`) |
| :--------------------------- | :----------------------------------------------------------------------------------- | :------------------------------ | :------------------------ |
| **`ROUND()`**                | Standard math rounding ($0.5+$ rounds up). Requires `NUMERIC` for decimal precision. | `123.46`                        | `124.0` (if scale is 0)   |
| **`CEIL()` / `CEILING()`**   | Always rounds **up** to the nearest whole integer.                                   | N/A                             | `124`                     |
| **`FLOOR()`**                | Always rounds **down** to the nearest whole integer.                                 | N/A                             | `123`                     |
| **`TRUNC()` / `TRUNCATE()`** | Chops off remaining decimal numbers without rounding.                                | `123.45`                        | `123` (if scale is 0)     |

---

## 2. Approximate vs. Exact Data Types

PostgreSQL divides fractional numbers into two major structural groups:

### ⚠️ Approximate Types: `FLOAT` & `DOUBLE PRECISION`

- **Behind the scenes:** Stored using binary approximations (IEEE 754 standard).
- **Speed:** Extremely fast calculations, perfect for scientific/physics data.
- **The Catch:** Suffers from hidden decimal rounding errors (e.g., ghost digits like `.000000001`).
- **`ROUND()` Constraint:** PostgreSQL **will not allow** you to specify decimal places on floats directly (e.g., `ROUND(val::FLOAT, 2)` throws an error).

### 🎯 Exact Type: `NUMERIC` (or `DECIMAL`)

- **Behind the scenes:** Stored exactly as typed, avoiding any binary approximation drift.
- **Speed:** Mathematically slower and consumes slightly more storage.
- **Best Used For:** Currency, accounting, financial balances, and precise analytics.

---

## 3. The PostgreSQL Type Casting System

If you see the error `ERROR: function round(double precision, integer) does not exist`, you must convert your float type to a numeric type.

```sql
-- ❌ Throws Syntax Error (DOUBLE is incomplete keyword)
SELECT 123.2::DOUBLE;

-- ✅ Correct Shorthand Aliases
SELECT 123.2::DOUBLE PRECISION;
SELECT 123.2::FLOAT;
SELECT 123.2::FLOAT8;

-- ✅ The Safe Way to Round (Cast float calculation results safely)
SELECT ROUND(AVG(price)::NUMERIC, 2) FROM products;
```

---

## 4. Architectural Safety: `ROUND()` vs. `NUMERIC(p, s)`

When formatting query outputs, balancing safety against architectural strictness is essential:

- **`NUMERIC(precision, scale)`** (e.g., `NUMERIC(5,2)`) sets a hard structural ceiling (max `999.99`). If a value scales to `1000.00`, your script **crashes with a `numeric field overflow` error**. Use this primarily for table definitions (`CREATE TABLE`).
- **`ROUND(val::NUMERIC, 2)`** utilizes an unconstrained numeric block. It formats decimal spaces safely **without placing a ceiling on the integer growth**. Use this for data analysis, application layers, and reports to eliminate crash risks.

---

## 5. Finding Ranges

- **Integers/Floats:** Have fixed boundaries hardcoded into system storage structures (e.g., `INT` caps at $\pm 2.14$ Billion).
- **`NUMERIC(p, s)`:** Range is calculated `+/-(10^(precision) - 1) /10^(scale)` (e.g., `NUMERIC(5,2)` runs from `-999.99` to `+999.99`).
- **Table Audits:** Use `MIN(column)` and `MAX(column)` to view the highest and lowest values present in active datasets.
