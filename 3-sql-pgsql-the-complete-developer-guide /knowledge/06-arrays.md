# Array in PostgreSQL

In PostgreSQL, an **_array data type_ allows you to store a collection of multi-valued elements within a single table column**. PostgreSQL permits arrays of any built-in, user-defined, enum, or composite data type, provided that all elements within a specific array share the exact same type.

Here is a comprehensive guide to defining, querying, and manipulating arrays in PostgreSQL according to the [PostgreSQL Array Documentation](https://www.postgresql.org/docs/current/arrays.html). [1]

---

## 1. Table Creation & Syntax

You can declare an array column by appending square brackets `[]` to the data type. While you can specify sizes or dimensions (e.g., `integer[4]`), PostgreSQL does not enforce size limits or multi-dimensional constraints at compile time.

```sql
CREATE TABLE contacts (
    id serial PRIMARY KEY,
    name text,
    phones text[], -- 1D text array
    pay_by_quarter integer[4], -- 1D integer array (size not enforced)
    schedule text[][] -- 2D text array
);
```

## 2. Inserting Data

You can insert arrays using either **literal strings** with curly braces `{}` or the explicit `ARRAY` constructor.

> _Note: single quotes around the entire literal string are mandatory when using the curly brace format `{}` in PostgreSQL._

```sql
-- Method A: Literal format using curly braces
INSERT INTO contacts (name, phones) VALUES ('Alice', '{"555-0100", "555-0199"}');

-- Method B: ARRAY constructor (Recommended for clarity, no quotes around keywords)
INSERT INTO contacts (name, phones, pay_by_quarter) VALUES ('Bob', ARRAY['555-0200', '555-0222'], ARRAY[10000, 11000, 12000, 13000]);
```

## 3. Querying & Accessing Elements

- **1-Based Indexing:** PostgreSQL arrays use **1-based indexing** by default, not 0.
- **Array Slicing:** You can fetch segments using the [start:end] boundary syntax. _`start` and `end` both are inclusive._

```sql
-- Get the first phone number
SELECT name, phones[1] FROM contacts;

-- Slice the first two quarters of pay (start and end are inclusive)
SELECT name, pay_by_quarter[1:2] FROM contacts;
```

## 4. Searching & Filtering Arrays

To find rows based on array values, you can use specialized operators and expressions:

- **`ANY` Expression:** `True` if a value matches _any_ element in the array.
- **Overlap Operator (`&&`):** True if the arrays share _any_ common elements.
- **Contains Operator (`@>`):** True if the left array completely contains the right array.

```sql
-- Find contacts with a specific phone number
SELECT * FROM contacts WHERE '555-0100' = ANY(phones);

-- Find contacts containing BOTH specified numbers
SELECT * FROM contacts WHERE phones @> ARRAY['555-0200', '555-0222'];

-- Find contacts with any overlapping phone numbers
SELECT * FROM contacts WHERE phones && ARRAY['555-0100', '999-9999'];
```

## 5. Modifying Arrays

You can update an entire array, replace a specific index, or use built-in functions like `array_append()` or `array_cat()`.

> ⚠️ Performance Note: Modifying a single element requires PostgreSQL to copy and rewrite the entire row. Avoid frequent array append operations on massive datasets.

```sql
-- Update a specific index directly
UPDATE contacts SET phones[2] = '555-9999' WHERE name = 'Alice';

-- Append an item to the end of the array
UPDATE contacts SET phones = array_append(phones, '555-8888') WHERE name = 'Bob';
```

## 6. Unnesting (Exploding) Arrays

The `unnest()` function expands an array into a standard set of rows, making it easy to treat array elements like a normal relational dataset.

```sql
SELECT name, unnest(phones) AS individual_phone FROM contacts;
```

## 7. Indexing & Optimization

Standard B-tree indexes are ineffective for searching inside array columns. To optimize performance for array search operations (like `@>` and `&&`), you must use a **GIN (Generalized Inverted Index)**:

```sql
CREATE INDEX idx_contacts_phones ON contacts USING gin (phones);
```

---

## Best Practices vs. Relational Anti-Patterns

- **When to use arrays:** Best for data that shares an identical lifecycle with the parent row (e.g., tags on a blog post, daily temperature logs).
- **When to avoid arrays:** Do not use arrays to enforce relational foreign-key constraints (e.g., storing a list of `user_ids` inside a `group row`). Use a traditional junction/join table instead to preserve First Normal Form (1NF) and data integrity.
