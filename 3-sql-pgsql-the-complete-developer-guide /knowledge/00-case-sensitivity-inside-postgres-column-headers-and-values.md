# case sensitivity for column headers and column values in postgresql

the answer is split: **column names are generally case-insensitive (by default), but the values inserted inside the tables are strictly case-sensitive.**

Here is exactly how PostgreSQL handles both scenarios.

---

## 1. Column Names (Case-Insensitive by Default)

PostgreSQL automatically converts all unquoted column names, table names, and identifiers to **lowercase** behind the scenes.

Because of this automatic lowercase conversion, you can query a column using any casing you like, and PostgreSQL will still find it.

### The Default Behavior

If you create a table like this:

```sql
CREATE TABLE users (
    FirstName VARCHAR(50)
);
```

PostgreSQL actually creates the column as `firstname` (all lowercase). Because of this, all of the following queries will work perfectly:

```sql
SELECT firstname FROM users;  -- Works
SELECT FirstName FROM users;  -- Works (converted to lowercase)
SELECT FIRSTNAME FROM users;  -- Works (converted to lowercase)
```

### The Exception: Double Quotes `""`

If you force PostgreSQL to respect your casing by wrapping the column name in **double quotes** during creation, it becomes strictly **case-sensitive**.

```sql
CREATE TABLE users (
    "FirstName" VARCHAR(50) -- Forced casing
);

```

If you do this, you **must** use double quotes and the exact casing every single time you query it:

```sql
SELECT "FirstName" FROM users; --  Works
SELECT firstname FROM users;   -- ❌ ERROR: column "firstname" does not exist
```

_Best Practice: In PostgreSQL, always use `lowercase_with_underscores` (snake_case) for table and column names to avoid headaches._

---

## 2. Inserted Values (Strictly Case-Sensitive)

The actual text data (strings) you insert into a table is **100% case-sensitive**. To PostgreSQL, `'John'`, `'john'`, and `'JOHN'` are three completely different values.

### The Behavior:

Imagine your table has a row where the name is `'Alice'`.

```sql
-- 1. This will find the row
SELECT * FROM users WHERE firstname = 'Alice';
-- 2. This will return ZERO rows (No match)
SELECT * FROM users WHERE firstname = 'alice';
-- 3. This will return ZERO rows (No match)
SELECT * FROM users WHERE firstname = 'ALICE';
```

#### How to perform case-insensitive searches on values:

If you want to search for data without worrying about capitalization, PostgreSQL offers two great solutions:

1. **Use `ILIKE` instead of `LIKE`:** The `ILIKE` operator is a unique PostgreSQL feature that performs a case-insensitive pattern match.

   ```sql
   -- This will successfully find 'Alice', 'alice', or 'ALICE'
   SELECT * FROM users WHERE firstname ILIKE 'alice';
   ```

2. **Use the `LOWER()` function:** Convert the column data to lowercase before comparing it to a lowercase search term.

   ```sql
   -- This forces both sides to lowercase for a perfect match
   SELECT * FROM users WHERE LOWER(firstname) = 'alice';
   ```
