# `CREATE DATABASE` quirks in postgresql

**you cannot run `CREATE DATABASE` inside a transaction.**

PostgreSQL strictly prohibits this. If you try, the database engine will immediately throw the error: `ERROR: CREATE DATABASE cannot run inside a transaction block`.

> _postgresql doesn't support `CREATE DATABASE IF NOT EXISTS` command_

## Why PostgreSQL Restricts This

- **Cluster-Wide Impact:** A database is a massive container. Creating it modifies global system catalogs (`pg_database`) and physical file directories on the server.
- **No Rollback Capability:** If PostgreSQL allowed this in a transaction and you later called `ROLLBACK`, safely deleting the physical files and reverting system catalogs mid-stream is too complex and risky for data integrity.

## The Strict Requirement

To run `CREATE DATABASE`, your database connection **must be in autocommit mode**. This means every single command runs in its own implicit, immediate transaction and commits instantly.

## How to Bypass this restriction by Language/Environment

If you are using tools or languages that wrap commands in transactions by default, you have to explicitly turn that off for this command:

### 1. Python (`psycopg2` / `psycopg`)

Python DB-API wrappers automatically start transactions behind the scenes. You must enable `autocommit`.

```python
conn = psycopg2.connect(dsn)
# This line disables the automatic transaction block:
conn.set_isolation_level(0)

cur = conn.cursor()
cur.execute("CREATE DATABASE my_database")
```

### 2. Node.js (`pg` / `pg-pool`)

The pg library does not start transactions automatically unless you explicitly send a `BEGIN` command. You can run it safely on a standard client.

```javascript
// This works because no transaction block is openedawait
client.query("CREATE DATABASE my_database");
```

---
