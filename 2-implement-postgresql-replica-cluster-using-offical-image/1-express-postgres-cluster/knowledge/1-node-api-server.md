# node express api

1. its a bare metal api
2. /register api registers user using primary db (writes)
3. /users api fetches all the registerd users using replica db (read)
4. uses postgres primary db and replica db for storage and retrival of data. [Read more](pg_replica.md)

Let's build it in a way that demonstrates **write → primary** and **read → replica**.

Architecture:

```text
Express API

          POST /register
                |
                v
            Primary

          GET /users
                |
                v
            Replica
```

This lets you see replication working in real time.

---

## 1. Create Users Table

Connect to the primary:

```bash
psql -h localhost -p 5432 -U admin -d appdb
```

Create table:

```sql id="m9v8nb"
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 2. Create Project

```bash
npm init -y
npm install express pg
```

```text
change the package.json 'type' property to 'module' instad of 'commonjs'
```

## 3. db.js

```javascript
import { Pool } from "pg";

const primaryPool = new Pool({
  host: "localhost",
  port: 5432,
  user: "admin",
  password: "admin",
  database: "appdb",
});

const replicaPool = new Pool({
  host: "localhost",
  port: 5433,
  user: "admin",
  password: "admin",
  database: "appdb",
});

module.exports = {
  primaryPool,
  replicaPool,
};
```

---

## 4. server.js

```javascript
const express = require("express");
const { primaryPool, replicaPool } = require("./db");

const app = express();

app.use(express.json());
```

---

## 5. Registration Endpoint

Writes always go to Primary.

```javascript
app.post("/register", async (req, res) => {
  try {
    const { firstName, lastName, password } = req.body;

    const result = await primaryPool.query(
      `
      INSERT INTO users (
        first_name,
        last_name,
        password
      )
      VALUES ($1, $2, $3)
      RETURNING *
      `,
      [firstName, lastName, password],
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: error.message,
    });
  }
});
```

---

## 6. Read Endpoint

Reads go to Replica.

```javascript
app.get("/users", async (req, res) => {
  try {
    const result = await replicaPool.query(`
      SELECT
        id,
        first_name,
        last_name,
        created_at
      FROM users
      ORDER BY id
    `);

    res.json(result.rows);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: error.message,
    });
  }
});
```

---

## 7. Health Endpoint

Useful for testing.

```javascript
app.get("/health", async (req, res) => {
  const primary = await primaryPool.query("SELECT pg_is_in_recovery()");

  const replica = await replicaPool.query("SELECT pg_is_in_recovery()");

  res.json({
    primary: primary.rows[0].pg_is_in_recovery,
    replica: replica.rows[0].pg_is_in_recovery,
  });
});
```

Expected:

```json id="i5t3o9"
{
  "primary": false,
  "replica": true
}
```

---

## 8. Start Server

```javascript
app.listen(3000, () => {
  console.log("Server running on port 3000");
});
```

Run:

```bash
node server.js
```

---

## 9. Register User

```bash
curl -X POST http://localhost:3000/register \
-H "Content-Type: application/json" \
-d '{
  "firstName":"John",
  "lastName":"Doe",
  "password":"secret"
}'
```

Flow:

```text
Client
   |
POST /register
   |
Express
   |
Primary
   |
WAL
   |
Replica
```

---

## 10. Read Users

```bash
curl http://localhost:3000/users
```

Flow:

```text
Client
   |
GET /users
   |
Express
   |
Replica
```

Response:

```json
[
  {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe"
  }
]
```

---

## What You Are Learning Here

Your setup uses:

```text
                 Express

         +----------+----------+
         |                     |
         v                     v

    Primary Pool         Replica Pool
         |                     |
         v                     v

      Primary             Replica
```

The application decides:

```text id="f2j6uw"
POST -> Primary

PUT -> Primary

DELETE -> Primary

GET -> Replica
```

This is how many production systems implement read scaling with PostgreSQL replication. The database cluster itself isn't routing queries; your application is choosing the appropriate connection pool.
