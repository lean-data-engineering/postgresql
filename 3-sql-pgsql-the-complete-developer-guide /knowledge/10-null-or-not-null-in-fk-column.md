# FK column - `NULL` or `NOT NULL`

Deciding whether a foreign key column should be `NOT NULL` or allow `NULL` values is a **pure business logic decision**, not a technical limitation of SQL.

Here is a quick mental guide to help you decide how to set up your foreign key columns based on real-world business scenarios:

---

## Scenario A: The Parent is Mandatory (`NOT NULL`)

Use `NOT NULL` when the child row **cannot logically exist** without being attached to an active parent row. If the parent disappears, the child makes absolutely no sense.

- **Business Examples:**
  - An `order_items` row **must** belong to an `orders` ID. An item cannot float in space without an actual order.
  - A `transactions` record **must** link to a specific `bank_accounts` ID. Money cannot move without a source/destination account.
- **The SQL Setup:**

  ```sql
  CREATE TABLE order_items (
      item_id INT PRIMARY KEY,
      order_id INT NOT NULL, -- Mandatory parent
      FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
  );
  ```

  _(Note: We use `ON DELETE CASCADE` here so that if an entire order is deleted, all its items are wiped out instantly.)_

---

## Scenario B: The Parent is Optional (`NULL` Allowed)

Allow `NULL` when the relationship is temporary, optional, or represents a state where the child row can exist as an "orphan" or an unassigned entity.

- **Business Examples:**
  - An `employees` record might have a `manager_id` column. The CEO doesn’t report to anyone, so their `manager_id` would be NULL.
  - A support `tickets` row might have an `assigned_agent_id`. When a customer first submits a ticket, no agent has claimed it yet, so the column is NULL until someone picks it up.
- The SQL Setup:
  ```sql
  CREATE TABLE tickets (
      ticket_id INT PRIMARY KEY,
      issue_description TEXT,
      assigned_agent_id INT NULL, -- Optional parent
      FOREIGN KEY (assigned_agent_id) REFERENCES agents(agent_id) ON DELETE SET NULL
  );
  ```
  \_(Note: We use `ON DELETE SET NULL` here so that if an agent leaves the company and their profile is deleted, the ticket isn't lost—it simply goes back to being unassigned/`NULL`).

---

## Summary Checklist for Database Design

| **Business Rule**                                         | **Foreign Key Constraint** | **Best `ON DELETE` Action**               |
| --------------------------------------------------------- | -------------------------- | ----------------------------------------- |
| "The child **cannot exist** without the parent."          | `NOT NULL`                 | `CASCADE` (Delete child with parent)      |
| "The **child can exist independently** or be unassigned." | `NULL`                     | `SET NULL` (Orphan the child safely)      |
| "Never allow a parent to be deleted if children exist."   | `NOT NULL` or `NULL`       | `RESTRICT` / `NO ACTION` (Block deletion) |
