# RegEx Functions

## 1. Key Functions Quick Reference

| **Function**                | **Primary Purpose**                                      | **Returns**           |
| --------------------------- | -------------------------------------------------------- | --------------------- |
| **`REGEXP_REPLACE`**        | Find and replace text matching a pattern.                | `TEXT`                |
| **`REGEXP_MATCH`**          | Extracts the **first** match or its capture groups.      | `TEXT[]` (Array)      |
| **REGEXP_MATCHES**          | Extracts **all** matches (using `'g'` flag) as rows.     | `SETOF TEXT[]` (Rows) |
| **`REGEXP_SUBSTR`**         | Extracts a substring or specific group as plain text.    | `TEXT`                |
| **`REGEXP_SPLIT_TO_ARRAY`** | Splits a string by a regex delimiter into an array.      | `TEXT[]` (Array)      |
| **`REGEXP_SPLIT_TO_TABLE`** | Splits a string by a regex delimiter into separate rows. | `SETOF TEXT` (Rows)   |

## 2. Operators (For `WHERE` Clauses)

- `~` : Case-sensitive match (True/False)
- `~*` : Case-insensitive match (True/False)
- `!~ / !~*` : Does not match (Case-sensitive / Case-insensitive)

```sql
-- ~  (Case-sensitive match)
-- ~* (Case-insensitive match)
-- !~ (Does not match, case-sensitive)
SELECT email FROM users
WHERE email ~* '^[a-z0-9._%+-]+@gmail\.com$';
```

## 3. Syntax Rules & Gotchas ⚠️

- **No Slashes (`/`):** Pass regex as standard string literals in single quotes (`'pattern'`), not `/pattern/` like JavaScript.
- **Dollar Quoting (`$$`):** Use `$$pattern$$` instead of single quotes to safely use backslashes (`\s`, `\d`, `\w`) without Postgres complaining about escape characters.
- **Combining Flags:** Pass multiple flags as a single combined string (e.g., `'gi'` for global + case-insensitive).
  - `g` = Global (find all occurrences)
  - `i` = Case-insensitive
- **No Named Groups:** Named capture groups like (`?<name>...`) are ignored by built-in functions. You must use numeric indexing.

Here is your comprehensive, copy-pasteable PostgreSQL regex reference sheet, complete with production-ready code snippets and real-world edge cases.

## 4. Key Functions & Code Snippets

### 🔹 `REGEXP_REPLACE` (Modify or Delete Text)

- **Purpose:** Replaces matched text with a new string.
- **Snippet:** Reformatting a phone number using numbered capture groups (`\1`, `\2`, `\3`).

  ```sql
  SELECT REGEXP_REPLACE('123-456-7890', '^(\d{3})-(\d{3})-(\d{4})$', '(\1) \2-\3');
  -- Output: (123) 456-7890

  -- Cleaning strings to convert them to numbers will fail if your regex accidentally leaves trailing letters behind.
  -- ERROR: '1250.50USD' cannot be cast to numeric
  SELECT REGEXP_REPLACE('$1,250.50USD', '[$,]', '', 'g')::NUMERIC;

  -- FIX: Match everything except digits and decimals, then replace with nothing
  SELECT REGEXP_REPLACE('$1,250.50USD', '[^0-9.]', '', 'g')::NUMERIC; -- Output: 1250.50
  ```

- **Edge Case (The "First Match Only" Trap):** By default, it only replaces the first match. You must pass `'g'` as the 4th parameter to clean the whole string.

  ```sql
  -- BUG: Only removes the first space
  SELECT REGEXP_REPLACE('1 2 3 4', '\s', '');     -- Output: '12 3 4'

  -- FIX: Use 'g' flag
  SELECT REGEXP_REPLACE('1 2 3 4', '\s', '', 'g'); -- Output: '1234'
  ```

### 🔹 `REGEXP_MATCH` (Extract First Occurrence)

- **Purpose:** Extracts the first match or its capture groups into a single text array.
- **Snippet:** Extracting an area code.

  ```sql
  SELECT REGEXP_MATCH('(415) 555-1234', '^\((\d{3})\)');
  -- Output: {415} (Access plain text using index:)
  ```

- **Edge Case (No Matches Return `NULL`):** If the pattern fails to match, it returns a literal `NULL` value, which can break math operators or string concatenations downstream.

  ```sql
  SELECT REGEXP_MATCH('No numbers here', '\d+');
  -- Output: NULL (Handle using COALESCE if needed)
  ```

### 🔹 `REGEXP_MATCHES` (Extract Multiple Rows)

- **Purpose:** Finds _all_ matches in a string and returns them as a set of rows. it behaves exactly like `REGEXP_MATCH` if `g` flag is not used.
- **Snippet:** Extracting all hashtags from a block of text.

  ```sql
  SELECT REGEXP_MATCHES('Learning #sql and #postgres in #2026', '#\w+', 'g');
  -- Output:
  --  {#sql}
  --  {#postgres}
  --  {#2026}
  ```

- **Edge Case (The Vanishing Row Trap):** If `REGEXP_MATCHES` does not find a match, it returns **0 rows**. If you use it inside a standard `SELECT` clause next to other columns, it will completely hide the entire row from your query results.

  ```sql
  -- DANGER: If 'bio' has no hashtags, this user disappears from your query entirely!
  SELECT username, REGEXP_MATCHES(bio, '#\w+', 'g') FROM users;

  -- FIX: Left join a LATERAL subquery to keep the user row even with zero matches
  SELECT u.username, m[1] FROM users uLEFT JOIN LATERAL REGEXP_MATCHES(u.bio, '#\w+', 'g') AS m ON true;
  ```

### 🔹 `REGEXP_SUBSTR` (Extract Directly as Plain Text)

- **Purpose:** Pulls text or a specific capture group directly as standard text, skipping the array wrapping.
- **Snippet:** Pulling out a domain name using the 6th position parameter (`group_index`).

  ```sql
  -- Signature: (source, pattern, start_pos, occurrence, flags, capture_group)
  SELECT REGEXP_SUBSTR('admin@internal.dev', '@([a-z.]+)', 1, 1, '', 1);
  -- Output: internal.dev
  ```

- **Edge Case (Position Limits):** If your `start_pos` (3rd parameter) is larger than the string length, Postgres returns `NULL` rather than throwing an error.

## 🔹 `REGEXP_SPLIT_TO_ARRAY` & `REGEXP_SPLIT_TO_TABLE` (Parsing Delimiters)

- **Purpose:** Splits text by a regex pattern delimiter into an array or a set of rows.
- **Snippet:** Splitting a string with messy whitespace and comma separators.

  ```sql
  SELECT REGEXP_SPLIT_TO_ARRAY('apple ,  banana,   cherry', '\s*,\s*');
  -- Output: {apple,banana,cherry}

  SELECT REGEXP_SPLIT_TO_TABLE('A; B | C', '\s*[;|]\s*');
  -- Output: 三 separate rows: 'A', 'B', 'C'
  ```

- **Edge Case (Trailing Separators):** If your text ends with the delimiter, these functions will generate an empty string element at the end.

  ```sql
  SELECT REGEXP_SPLIT_TO_TABLE('A,B,C,', ',');
  -- Output: Four rows ('A', 'B', 'C', and one blank '')
  ```
