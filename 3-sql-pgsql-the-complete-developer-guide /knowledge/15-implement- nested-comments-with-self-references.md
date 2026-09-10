# Implementing Nested Comments with SelfReferencing

## 1: ER diagram for bog subsystem

An Entity-Relationship (ER) diagram for a blog subsystem **`models core components like users, posts, comments, categories, and tags`**.

You can reference a visual model using templates like the [Blog Database ER Diagram](https://www.edrawmax.com/templates/1002460/).

### Core Entities and Attributes

- **User**: Represents the author or reader of the blog.
  - `UserID` (PK)
  - `Username`
  - `Email`
  - `Password`
  - `Created_at`
- **Post:** Represents an individual blog article.
  - `PostID` (PK)
  - `UserID` (FK referencing User)
  - `Title`
  - `Content`
  - `Created_at`
- **Comment:** Represents user feedback on a specific post.
  - `CommentID` (PK)
  - `PostID` (FK referencing Post)
  - `UserID` (FK referencing User)
  - `Text`
  - `Created_at`
- **Category:** Classifies blog posts into broader topics.
  - `CategoryID` (PK)
  - `Name`
- **Tag:** Labels specific keywords for searchability.
  - `TagID` (PK)
  - `Name`

### Relationships and Cardinality

- **User to Post:** One-to-Many. One user can write multiple posts, but each post belongs to a single user.
- **Post to Comment:** One-to-Many. One post can have multiple comments, but each comment belongs to one post.
- **User to Comment:** One-to-Many. One user can write multiple comments, but each comment is written by one user.
- **Post to Category:** Many-to-One (or Many-to-Many if posts have multiple categories). A category can contain many posts, but a standard post belongs to one main category.
- **Post to Tag:** Many-to-Many. A post can have multiple tags, and a tag can apply to multiple posts (managed via a junction table PostTag).

## 2: [problem with blog subsystem](#1-er-diagram-for-bog-subsystem)

`User` instances can post only post comment on blog post but no one can comment/reply (conversation) on those comments.

## Solution - self-referencing relationship

Adding a `parent_id` inside the `Comment` entity is the **most common and efficient way** to implement nested, Twitter-like conversations. This pattern is known as a **self-referencing relationship** (or a recursive relationship).

Here is exactly how it works, how it affects your database design, and how to query it.

### The Self-Referencing Comment Entity

By adding a `parent_id` that points back to the `CommentID` in the same table, you create a tree structure.

- A **top-level comment** on a blog post will have `parent_id = NULL`.
- A **reply** to a comment will have `parent_id = [The CommentID of the comment being replied to]`.

### Updated Comment Schema

- `CommentID` (Primary Key)
- `PostID` (Foreign Key referencing Post)
- `UserID` (Foreign Key referencing User)
- **`ParentID`** (Foreign Key referencing **CommentID** in the same table, allows `NULL`)
- `Text`
- `Created_at`

---

### How the ER Relationship Looks

In your ER diagram, this is drawn as a **looping line** that starts at the `Comment` entity and points back to the `Comment` entity.

- **Cardinality:** One-to-Many (`1:N`). One parent comment can have many child replies, but each child reply can only have **one** direct parent comment.

---

### Alternative Advanced Approaches

While the `parent_id` (**Adjacency List model**) is perfect for most applications, it can sometimes be slow to fetch deeply nested structures in SQL because it requires multiple queries or recursive joins. If you expect massive, deep Twitter-like threads, developers use these alternatives:

| **Approach**                     | **How it works**                                                                  | **Pros**                                                              | **Cons**                                                                       |
| -------------------------------- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Adjacency List** (`parent_id`) | Each row stores only its immediate parent.                                        | Easiest to write, insert, and understand.                             | Fetching deep trees requires complex recursive SQL queries (`WITH RECURSIVE`). |
| **Materialized Path**            | Each row stores its full lineage as a string (e.g., `path = "1/5/12/"`).          | Very fast to find all replies in a single query using `LIKE '1/5/%'`. | Harder to maintain if a comment moves or is deleted.                           |
| **Closure Table**                | A separate table stores every relationship between all ancestors and descendants. | Fastest query performance for deep nesting.                           | Requires extra space and writes to a second table for every reply.             |

### Recommendation

For a standard blog subsystem, stick with the **`parent_id`** approach. Modern database systems handle recursive queries incredibly fast, and it keeps your logic simple.

---

## Implementaion using Adjacency List in PostgreSQL

### 1: The Database Table Schema (PostgreSQL)

To make this work, the `parent_id` column must allow `NULL` values (for top-level comments) and must have a `FOREIGN KEY` constraint that points directly back to the `comment_id` column of the same table.

```sql
CREATE TABLE comments (
    comment_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    parent_id INT DEFAULT NULL, -- Points to the comment being replied to
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Relationships
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comments(comment_id) ON DELETE CASCADE
);
```

---

### 2: The Challenge with Nested Comments

If Comment A has a reply (Comment B), and Comment B has a reply (Comment C), they sit at different levels of a "tree."

- Standard SQL cannot predict how deep a conversation will go.
- To fetch the whole conversation in the correct order, we use a **Common Table Expression (CTE)** with the `WITH RECURSIVE` command.

---

### 3. How to Query a Thread (Recursive SQL)

This query selects a specific blog post's comments, automatically figures out who replied to whom, tracks the nesting depth, and sorts them so the conversation reads chronologically like a Twitter thread.

```sql
WITH RECURSIVE comment_tree AS (
    -- STEP 1: Anchor Member (Get all top-level comments for the post)
    SELECT
        comment_id,
        post_id,
        user_id,
        parent_id,
        content,
        created_at,
        1 AS depth,                         -- Top-level comments start at depth 1
        CAST(comment_id AS CHAR(255)) AS path -- Keeps track of the thread order
    FROM comments
    WHERE post_id = 42 AND parent_id IS NULL -- Replace 42 with your actual PostID

    UNION ALL

    -- STEP 2: Recursive Member (Find replies by joining the table to itself)
    SELECT
        c.comment_id,
        c.post_id,
        c.user_id,
        c.parent_id,
        c.content,
        c.created_at,
        ct.depth + 1 AS depth,              -- Increment depth for each reply level
        CONCAT(ct.path, ',', c.comment_id)   -- Append the reply ID to the path
    FROM comments c
    INNER JOIN comment_tree ct ON c.parent_id = ct.comment_id
)-- STEP 3: Output the results ordered by their conversation path
SELECT * FROM comment_tree
ORDER BY path ASC, created_at ASC;
```

### How the Query Output Looks

If **User 1** comments on a post, **User 2** replies to User 1, and **User 3** replies to User 2, the recursive query outputs the data cleanly structured for your front-end team to indent:

| **comment_id** | **parent_id** | **content**                        | **depth** | **path**      |
| -------------- | ------------- | ---------------------------------- | --------- | ------------- |
| 101            | _NULL_        | "Great blog post!"                 | 1         | `101`         |
| 102            | 101           | "I agree, especially section 2."   | 2         | `101,102`     |
| 105            | 102           | "Section 2 was my favorite too!"   | 3         | `101,102,105` |
| 103            | _NULL_        | "I disagree with your conclusion." | 1         | `103`         |

### How it Works

in a normal CTE, you cannot reference the CTE inside its own definition.

However, the **`RECURSIVE`** keyword changes the rules of SQL completely. It explicitly tells the database engine to allow this self-reference because it is performing a loop.

Here is the secret of how the database processes a recursive CTE under the hood without breaking:

#### The Secret: The CTE has Two Different "States"

When you use `WITH RECURSIVE`, the database splits the CTE into two internal pools:

1. **The Accumulator (The Final Result):** Where rows are saved to be sent back to you at the end.
2. **The Working Set (The Current Loop Data):** A temporary buffer that holds _only_ the rows found in the **very last loop**.

When you reference `comment_tree` inside the recursive query part, **you are not reading the whole CTE**. You are only reading the **Working Set** (the rows from the immediate previous step).

---

#### Step-by-Step Visualization of the Mechanism

Let's look at the query again:

```sql
WITH RECURSIVE comment_tree AS (
    -- Part A: The Anchor Member
    SELECT comment_id FROM comments WHERE parent_id IS NULL

    UNION ALL

    -- Part B: The Recursive Member
    SELECT c.comment_id FROM comments c
    INNER JOIN comment_tree ct ON c.parent_id = ct.comment_id -- <-- Self-reference!
)
```

Here is how the database engine executes this without creating an infinite, impossible paradox:

##### Step 1: Initialization

The engine runs **Part A (Anchor)** once.

- It finds Comment `101`.
- **Working Set becomes:** `[101]`
- **Accumulator becomes:** `[101]`

##### Step 2: The First Loop

The engine looks at **Part B**. It sees `FROM comment_tree ct`. Instead of looking at the whole definition, it substitutes `ct` with the current **Working Set** (`[101]`).

- The query effectively becomes: `SELECT ... FROM comments c WHERE c.parent_id IN (101)`
- It finds Comment `102`.
- **Working Set is wiped and updated to:** `[102]` (The old 101 is gone from the working set).
- **Accumulator grows to:** `[101, 102]`

##### Step 3: The Second Loop

The engine runs **Part B** again. It substitutes `ct` with the _new_ **Working Set** (`[102]`).

- The query effectively becomes: `SELECT ... FROM comments c WHERE c.parent_id IN (102)`
- It finds Comment `105`.
- **Working Set becomes:** `[105]`
- **Accumulator grows to:** `[101, 102, 105]`

##### Step 4: The Exit

The engine runs **Part B** using Working Set `[105]`. It finds `0` rows.

- **Working Set becomes:** Empty `[]`
- Because the Working Set is empty, the recursion ends. The engine ignores the definition loop and finally outputs whatever is sitting inside the **Accumulator**.

A query cannot read its own incomplete self. But with `WITH RECURSIVE`, the database tricks the system by passing only the output of the previous step into the next step, behaving exactly like a standard while loop in programming.

### How to Render This in Your Code

When your backend sends this tabular structure to your frontend (React, Vue, mobile app, etc.), the application loops through the array.

- If `depth = 1`, it renders flat against the screen margin.
- If `depth = 2`, it adds a **left margin/padding** (e.g., `margin-left: 20px`) to visually indent the reply under its parent, instantly creating a Twitter-like UI.
