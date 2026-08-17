# express postgresql cluster

Architecture:

```text
                    Docker Network

       +----------------------+
       |      Node API        |
       |       :3000          |
       +----------+-----------+
                  |
        +---------+---------+
        |                   |
        v                   v

 +--------------+   +--------------+
 |   Primary    |   |   Replica    |
 |    :5432     |   |    :5432     |
 +--------------+   +--------------+
```

Notice something important:

❌ Inside Docker containers you should **not use localhost**.

This is wrong:

```javascript
host: "localhost";
```

because from the Node container:

```text
localhost = Node container itself
```

not PostgreSQL.

Instead use the Docker service names:

```javascript
host: "postgres-primary";
host: "postgres-replica";
```

---

## Project Structure

```text
.
├── docker-compose.yml
├── Dockerfile
├── package.json
├── db.js
└── server.js
```

---

## setup primary and replica postgresql server

[setup postgres cluster](./knowledge/pg-replica-setup.md)

---

## Dockerfile

```dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

---

## db.js

Update hosts:

```javascript
const { Pool } = require("pg");

const primaryPool = new Pool({
  host: "postgres-primary",
  port: 5432,
  user: "admin",
  password: "admin",
  database: "appdb",
});

const replicaPool = new Pool({
  host: "postgres-replica",
  port: 5432,
  user: "admin",
  password: "admin",
  database: "appdb",
});

module.exports = {
  primaryPool,
  replicaPool,
};
```

Notice:

```text
postgres-primary
postgres-replica
```

are Docker DNS names.

---

## docker-compose.yml

Assuming you already have your primary and replica containers.

```yaml
services:
  postgres-primary:
    image: postgres:17
    container_name: postgres-primary
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
      POSTGRES_DB: appdb
    ports:
      - "5432:5432"

  postgres-replica:
    image: postgres:17
    container_name: postgres-replica
    ports:
      - "5433:5432"

  api:
    build: .
    container_name: express-api
    ports:
      - "3000:3000"
    depends_on:
      - postgres-primary
      - postgres-replica
```

---

## Build Everything

```bash
docker compose up --build
```

Verify:

```bash
docker ps
```

Expected:

```text
postgres-primary
postgres-replica
express-api
```

---

## Test Registration

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
curl
  |
  v
Node Container
  |
  v
postgres-primary
```

---

## Test Reads

```bash
curl http://localhost:3000/users
```

Flow:

```text
curl
  |
  v
Node Container
  |
  v
postgres-replica
```

---

## Verify the API Is Actually Reading from Replica

Add this endpoint:

```javascript
app.get("/which-db", async (req, res) => {
  const result = await replicaPool.query(`
    SELECT
      inet_server_addr(),
      inet_server_port(),
      pg_is_in_recovery()
  `);

  res.json(result.rows[0]);
});
```

Request:

```bash
curl http://localhost:3000/which-db
```

Example:

```json
{
  "inet_server_addr": "172.20.0.3",
  "inet_server_port": 5432,
  "pg_is_in_recovery": true
}
```

The important part:

```json
{
  "pg_is_in_recovery": true
}
```

which proves the query was executed against the replica and not the primary.

---

>> `depends_on` only ensures containers start in order. It does **not** guarantee PostgreSQL is ready to accept connections. In production you'd typically add a health check and make the Node API wait until PostgreSQL becomes healthy before starting. That's another common Docker Compose pattern worth learning after this setup works.
