# Multiple CTE'S In A Single Query

**Question:** can we define multiple ctes in a single query?

**`Yes, you can absolutely define multiple CTEs in a single query.`**

To do this, you only write the `WITH` keyword **once**, and then separate each CTE name and query using a **comma**.

Here is the structural template of how it looks:

```sql

WITH first_cte AS (
    SELECT ...
),
second_cte AS (
    SELECT ...
),
third_cte AS (
    SELECT ...
)
SELECT *
FROM first_cte
JOIN second_cte ON ... ;

```

## 💡 Pro Tip: CTEs Can Reference Each Other

When you define multiple CTEs, a later CTE can actually read data from an earlier one. They compile sequentially from top to bottom. For example:

```sql

WITH raw_counts AS (
    -- First CTE gets the raw numbers
    SELECT user_id, COUNT(*) as actions FROM logs GROUP BY user*id
),
filtered_counts AS (
    -- Second CTE reads directly from 'raw_counts'
    SELECT user_id, actions FROM raw_counts WHERE actions > 10
)
SELECT * FROM filtered_counts;

```
