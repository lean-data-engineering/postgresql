# SQL `GROUP BY` Column Rules

## 1. The Golden Rule of `GROUP BY`

When grouping data in SQL, every column in your `SELECT` clause must fall into one of two categories:

- **Aggregated:** Wrapped inside an aggregate function like `SUM()`, `COUNT()`, `AVG()`, `MIN()`, or `MAX()`.
- **Grouped:** Explicitly listed in the `GROUP BY` clause.

_Note: You never put aggregated columns into the `GROUP BY` clause._

---

## 2. When Do You Have to List Non-Aggregated Columns?

### Standard Rule (Strict SQL)

If you select a regular, non-aggregated column, you **must** list it in the `GROUP BY` clause. Otherwise, the database engine will throw an error because it doesn't know which row's value to display for that group.

### The Big Exception: Functional Dependency

If you group by a table's **Primary Key** (e.g., `order_id`), many modern databases are smart enough to know that other columns in that same table (like `order_date` or `customer_id`) have exactly one unique value per ID.

---

## 3. Database Engine Comparison

| Database Engine | Can you group _only_ by Primary Key? | behavior                                                                               |
| :-------------- | :----------------------------------- | :------------------------------------------------------------------------------------- |
| **PostgreSQL**  | Yes                                  | Supports Functional Dependency.                                                        |
| **MySQL**       | Yes                                  | Supports Functional Dependency (in modern versions with `ONLY_FULL_GROUP_BY` enabled). |
| **SQL Server**  | No                                   | Strict. Requires you to list **all** non-aggregated columns.                           |
| **Oracle**      | No                                   | Strict. Requires you to list **all** non-aggregated columns.                           |

---

## 4. Practical Example: Order Revenue Calculation

### Scenario

- `orders` table: `order_id` (Primary Key), `order_date`, `order_status`, `customer_id`
- `order_items` table: `item_id`, `order_id`, `sub_total`, `qty`

### Approach A: The Modern Way (PostgreSQL / MySQL)

If `order_id` is the primary key, you can omit the other descriptive columns from the `GROUP BY` clause.

```sql
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    o.customer_id,
    SUM(oi.sub_total) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;
```

### Approach B: The Strict Way (SQL Server / Oracle)

You must explicitly repeat all non-aggregated columns to avoid a syntax error.

```sql
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    o.customer_id,
    SUM(oi.sub_total) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, o.order_status, o.customer_id;
```
