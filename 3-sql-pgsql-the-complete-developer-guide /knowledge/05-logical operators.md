# logical operators

**SQL logical operators** are keywords used in a `WHERE` or `HAVING` clause to combine, negate, or filter records based on multiple criteria. They evaluate conditions and return a boolean result: `TRUE`, `FALSE`, or `UNKNOWN` [`NULL`]. These operators act as the decision-making engine of a database query, allowing you to extract highly specific datasets.

## Core Logical Operators

The three foundational logical operators are used to connect basic conditional expressions.

- **`AND`:** Returns `TRUE` only if **all conditions** separated by the operator are true.
  - _Analogy:_ Going to a movie only if you have money **`AND`** the theater is open.
  - _Example:_ `SELECT * FROM employees WHERE department = 'sales' AND salary > 50000;`
- **`OR`:** Returns `TRUE` if at least one of the conditions is true.
  - _Analogy:_ Eating out if you crave pizza `OR` you crave burgers.
  - _Example:_ `SELECT * FROM customers WHERE country = 'USA' OR country = 'Canada';`
- **`NOT`:** Reverses the outcome of a boolean expression, turning `TRUE` into `FALSE` and vice-versa.
  - _Analogy:_ Entering a room only if it is `NOT` locked.
  - _Example:_ `SELECT * FROM Products WHERE NOT discontinued = 1;`

---

## Comparison & Range Filtering Operators

These operators check individual values against ranges, patterns, sets, or structural traits.

- **`BETWEEN`:** Filters values that fall within an **inclusive range**.
  - _Example:_ `WHERE age BETWEEN 20 AND 30;` (Includes 20 and 30).
- **`IN`:** Matches a column value against **any literal value** in a specified comma-separated list.
  - _Example:_ `WHERE role IN ('Manager', 'Director', 'VP');`
- **`LIKE`:** Performs **pattern matching** using wildcard characters like `%` (zero or more characters) or `_` (exactly one character).
  - _Example:_ `WHERE name LIKE 'J%';` (Finds names starting with 'J').
- **`IS NULL`/ `IS NOT NULL`:** Specifically identifies records where a field contains no data (`NULL`) or `not NULL`.
  - _Example:_ `WHERE email IS NULL;`

---

## Subquery Operators

These operators compare a specific column value against a list or dataset generated dynamically by an internal subquery.

- **`EXISTS`:** Returns `TRUE` if the subquery returns **one or more rows**, regardless of the data inside them.
  - _Example:_ `WHERE EXISTS (SELECT 1 FROM orders WHERE orders.customerID = customers.id);`
- **`ANY` / `SOME`:** Returns `TRUE` if the condition matches **at least one value** produced by the subquery.
  - _Example:_ `WHERE price > ANY (SELECT price FROM competitor_products);`
- **`ALL`:** Returns `TRUE` only if the condition evaluates to true for **every single value** in the subquery result.
- _Example:_ `WHERE score > ALL (SELECT Score FROM class_b);`

---

## Operator Precedence (Order of Operations)

When you write complex filters combining multiple conditions, SQL evaluates them using a strict structural hierarchy:

1. **NOT** (Evaluated first)
2. **AND** (Evaluated second)
3. **OR** (Evaluated last)

**Pro Tip:** Always use parentheses `()` to override default precedence rules and make your queries easier to read. For example, `WHERE (A OR B) AND C` runs completely differently than `WHERE A OR B AND C`

---

## A closer look at `ANY` , `SOME`, `ALL`, `IN`, `EXISTS` and `LIKE`

### 1. IN

The `IN` operator checks if a value matches **any value in a literal list** or the results of a subquery. It is a cleaner, shorter way to write multiple `OR` conditions.

- **Syntax:** `column IN (value1, value2, ...)` or `column IN (SELECT column FROM ...)`
- **Behavior:** Returns `TRUE` if the value exists in the list.
- **Example:** Find customers living in specific cities.

  ```sql
  SELECT * FROM customers
  WHERE City IN ('London', 'Paris', 'Tokyo');
  ```

  _(This replaces city = 'London' OR city = 'Paris' OR city = 'Tokyo')_

---

### 2. EXISTS

The `EXISTS` operator tests for the **presence of rows** in a subquery. It does not look at the actual data values; it simply checks if the subquery returns _at least one row_.

- **Syntax:** `WHERE EXISTS (SELECT 1 FROM table WHERE condition)`
- **Behavior:** It stops searching as soon as it finds the first matching row (**highly efficient for large datasets**).
- **Example:** Find customers who have placed at least one order.

  ```sql
  SELECT customer_name FROM customers c
  WHERE EXISTS (
      SELECT 1 FROM Orders o
      WHERE o.customer_id = c.customer_id
  );
  ```

---

### 3. LIKE

The `LIKE` operator is used for **pattern matching** in text columns. It uses two unique wildcard characters:

- `%` represents zero, one, or multiple characters.
- `_` represents exactly one single character.
- **Syntax:** `column LIKE 'pattern'`
- **Examples:**
  - `WHERE name LIKE 'A%'` → Starts with "A" (e.g., Alice, Albert).
  - `WHERE name LIKE '%son'` → Ends with "son" (e.g., Johnson, Simpson).
  - `WHERE name LIKE '_a%'` → Has "a" as the second letter (e.g., Mary, Gary).

---

### 4. ANY / SOME

`ANY` and `SOME` are exact synonyms; they do identical work. They compare a single scalar value to **a single-column set of values** returned by a subquery.

- **Syntax:** `column comparison_operator ANY (SELECT column FROM ...)`
- **Behavior:** Returns TRUE if the comparison is true for at least one value in the subquery.
- **Example:** Find products that are more expensive than at least one product in Category 2.

  ```sql
  SELECT product_name, price FROM products
  WHERE price > ANY (
      SELECT price FROM products WHERE category_id = 2
  );
  ```

  _(If category 2 has prices, > ANY means greater than the minimum value, so > 10)_

---

### 5. ALL

The `ALL` operator compares a single scalar value against **every single value** returned by a subquery.

- **Syntax:** `column comparison_operator ALL (SELECT column FROM ...)`
- **Behavior:** Returns TRUE only if the comparison is true for all values in the subquery.
- **Example:** Find products that are more expensive than every product in Category 2.

  ```sql
  SELECT product_name, price FROM products
  WHERE price > ALL (
      SELECT price FROM products WHERE category_id = 2
  );
  ```

  _(If category 2 has prices, > ALL means greater than the maximum value, so > 50)_

---

### Quick Comparison Summary

| **Operator**       | **Type of Input**                    | **What makes it TRUE?**                    |
| ------------------ | ------------------------------------ | ------------------------------------------ |
| **`IN`**           | List of values or Subquery           | Value matches any item in the list         |
| **`EXISTS`**       | Subquery only                        | The subquery returns 1 or more rows        |
| **`LIKE`**         | Text string pattern                  | Text matches wildcards (% or \_)           |
| **`ANY` / `SOME`** | Subquery combined with =, >, <, etc. | Comparison holds true for at least one row |
| **`ALL`**          | Subquery combined with =, >, <, etc. | Comparison holds true for every single row |
