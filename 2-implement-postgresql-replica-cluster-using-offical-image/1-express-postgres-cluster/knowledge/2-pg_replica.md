# postgre replication concept

1. creation and configuarion of postgres primary and replica using official postgres image from docker hub.

Let's do it the **real PostgreSQL way**, not the Bitnami way.

We'll build:

```text
                    Docker Network

      +----------------------+
      |      Primary         |
      |       :5432          |
      +----------------------+
                 |
                 | WAL Streaming
                 |
                 v
      +----------------------+
      |      Replica         |
      |       :5433          |
      +----------------------+
```

The goal is to understand **what PostgreSQL itself requires for replication**.

---

## Step 1: Create docker-compose.yml

Start with only the primary.

```yaml
services:
  postgres-primary:
    image: postgres:17
    container_name: postgres-primary
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password
      POSTGRES_DB: appdb
    ports:
      - "5432:5432"
    volumes:
      - primary-data:/var/lib/postgresql/data

volumes:
  primary-data:
```

> > if you are using postges:18 or its successors. use `var/lib/postgresql` to mount to your volume.

Start it:

```bash
docker compose up -d
```

Verify:

```bash
docker ps
```

---

## Step 2: Connect to Primary

```bash
docker exec -it postgres-primary psql -U admin -d appdb
```

Create test table:

```sql
CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    name TEXT
);

INSERT INTO users(name)
VALUES ('John');
```

Verify:

```sql
SELECT * FROM users;
```

Output:

```text
1 | John
```

---

## Step 3: Understand Why Replication Doesn't Work Yet

Current architecture:

```text
Primary
   |
 Database Files
```

No replica can connect because:

```text
wal_level = replica        ❌
replication user           ❌
replication permissions    ❌
```

Nothing is configured.

---

## Step 4: Enable WAL Streaming

### Enter container

```bash
docker compose exec postgres-primary bash
```

### Locate config

```bash
psql -U admin -c "SHOW config_file;"
```

- **`-c "..."`:** The `-c` flag tells psql to run a **single** SQL Command string and immediately exit, rather than opening an interactive terminal shell.
- **`SHOW config_file`:** This is the specific SQL **command** being executed. `SHOW` is a PostgreSQL parameter tool that reads **internal** configuration settings. Querying `config_file` tells the system to output the exact hard-drive **location** of your active configuration file.

Usually:

```text
/var/lib/postgresql/data/postgresql.conf
```

### Append

```bash
echo "wal_level = replica" >> $PGDATA/postgresql.conf
echo "max_wal_senders = 10" >> $PGDATA/postgresql.conf
echo "hot_standby = on" >> $PGDATA/postgresql.conf
```

`$PGDATA` environment variable is automatically set up by the official PostgreSQL Docker image.

#### `wal_level = replica`

It sets the logging level of the Write-Ahead Log (WAL) to "replica".

The `WAL` is a rolling record of every single data change made to your database. Setting it to replica tells PostgreSQL to log extra metadata (like transaction IDs and file allocations). This extra information is absolutely mandatory; without it, a standby replica cannot read the WAL stream to reconstruct your database tables

**Without this:**

Replica cannot replay changes.

#### `max_wal_senders = 10`

Allow WAL streaming connections. It specifies the maximum number of simultaneous, concurrent network connections allowed specifically for data streaming.

When your replica connects to your primary database, it starts a dedicated background worker process on the primary called a "WAL sender". Setting this value to 10 means up to 10 replicas (or backup tools like pg_basebackup) can connect and stream records simultaneously from this database node.

Think:

```text
Primary
  |
  +-- Replica1
  +-- Replica2
  +-- Replica3
```

Each replica consumes one sender.

#### `hot_standby = on`

It enables read-only query capabilities while a database is actively running in recovery mode.

If this line runs on your Primary node, it is safely ignored during normal operations.

If this line runs on your Replica node, it allows your Express application `(replicaPool.query('SELECT * FROM users'))` to connect and run read-only queries while the replica is actively pulling data from the primary node. Without this turned on, the replica would lock down completely and reject all client connections.

```sql
SELECT * FROM users;
```

while replication is happening.

---

## Step 5: Create Replication User

### Connect

```bash
docker compose exec postgres-primary psql -U admin -d postgres
```

### Create

```sql
CREATE ROLE repl_user
WITH REPLICATION
LOGIN
PASSWORD 'repl_password';
```

This SQL command creates a dedicated user account in PostgreSQL specifically designed to handle database replication streaming.

#### Keyword Breakdown

1. `CREATE ROLE repl_user`: This creates a new database user identity named `repl_user`.
2. `WITH REPLICATION`: This grants the account the highly privileged `REPLICATION` attribute. This attribute bypasses normal security tables and allows the user to stream raw write-ahead logs (WAL) out of the primary server.
3. `LOGIN`: This explicitly permits the role to log in and establish a network connection. (In PostgreSQL, a "Role" can just be a group; adding LOGIN transforms it into a fully active user account).
4. `PASSWORD 'repl_password`': This assigns a secure authentication password to the account so it can verify its identity when connecting across the network.

**Why?**

Because replicas connect like normal clients. PostgreSQL needs authentication.

```text
Replica ---> Primary
```

**Where should you run this?**

You must execute this query only on your Primary database container (never on the replica). Because the replica is a read-only mirror, it will automatically inherit this user once replication streaming kicks off successfully.

**How it fits into your setup?**

Now that this user exists, your replica container can log in using these credentials to pull live data updates. This is the exact user that matches the `pg_hba.conf` firewall rule.

---

## Step 6: Allow Replica Connections

### Edit

```bash
docker exec -it postgres-primary bash
```

### Append line

```bash
echo "host replication repl_user all scram-sha-256" >> $PGDATA/pg_hba.conf
```

#### Meaning

Allow user repl_user to perform replication.

##### Without this

Replica connection rejected.

#### What is `pg_hba.conf` file and how its related to replication process

`pg_hba.conf` is the main configuration file that controls client authentication in PostgreSQL.The letters `HBA` stand for **Host-Based Authentication**. Think of it as a firewall for your database: if a connection request does not match one of the rules defined inside this file, PostgreSQL will instantly reject it, even if the user provides the correct password.

**File Content:**

```text
## TYPE    DATABASE        USER            ADDRESS                 METHOD
host      all             all             127.0.0.1/32            scram-sha-256
```

Every active line in `pg_hba.conf` follows a strict, sequential structure containing 5 or 6 fields separated by spaces or tabs:

1. **TYPE:** How the client is connecting.
   1. **local:** Connections using Unix domain sockets (running commands directly inside the container shell).
   2. **host:** Connections over network TCP/IP (unencrypted or encrypted).
   3. **hostssl:** Connections requiring secure SSL/TLS encryption
2. **DATABASE:** Which database they can access. Can be a specific name, all, or replication (critical for streaming replication clusters).
3. **USER:** Which database user can connect. Can be a specific name or all.
4. **ADDRESS:** The IP address range allowed to connect.
   1. `127.0.0.1/32` means local loopback only.
   2. `0.0.0.0/0` means any IP address in the world.
   3. `all` (both ipv4 & ipv6) or samehost.
5. **METHOD:** How the user must prove their identity.
   1. **scram-sha-256:** Secure, encrypted password verification (default and recommended).
   2. **trust:** No password required! Anyone matching this line gets unconditional root access (dangerous).
   3. **reject:** Unconditionally reject the connection.

**Why it is critical for your Replication Cluster ?**

By default, the official PostgreSQL Docker image configures `pg_hba.conf` to allow standard database connections, but it does **not** allow streaming replication.To make your replica container connect to your primary container, you must append a custom rule to the primary's pg_hba.conf file:

```text
## Allow the "repl_user" user from any container inside the Docker network to stream logs
host    replication     repl_user      all                     scram-sha-256
```

**Order Matters:**

!PostgreSQL reads this file from top to bottom. It checks the lines in sequence and uses the first matching rule it encounters. If a broad reject rule sits at the top of the file, lower rules allowing your replica access will be ignored completely.

---

## Step 7: Restart Primary

Restart:

```bash
docker restart postgres-primary
```

Verify:

```bash
docker logs postgres-primary
```

No errors.

---

## Step 8: Create Replica Container

### Important

Replica cannot start with an empty database.

It needs a copy of the primary.

### Create replica container

```bash
docker run -d \
  --name postgres-replica \
  --network $(docker inspect postgres-primary \
      --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}') \
  -e POSTGRES_PASSWORD=postgres \
  -p 5433:5432 \
  postgres:17
```

#### explain `$(docker inspect postgres-primary --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}')` command?

This flag automatically forces your new postgres-replica container to join the exact same Docker network as your existing postgres-primary container.

Instead of making you manually find and type out the network name, it uses a nested command to look up and insert the correct network name dynamically.

Here is the exact step-by-step breakdown of how it works:

1. **The Dynamic Sub-Command:** `$(docker inspect ...)`: The `$()` syntax is a shell feature called command substitution. The shell runs the command inside the parentheses first, captures its text output, and injects that text directly into your main docker run command.
2. **The Target:** `postgres-primary`: This tells Docker to look up the metadata, configuration, and state settings of your already running container named postgres-primary.
3. **The Extractor:** `--format '{{range ...}}'`: By default, docker inspect outputs a massive JSON file containing hundreds of lines of technical details. The `--format` flag filters that data using a Go template to extract only the specific string you need:.
   1. **`NetworkSettings.Networks`:** Digs deep into the JSON metadata to find the network configuration object.
   2. **`range $k, $v := ...`:** Loops through the list of networks attached to that container.
   3. **`{{$k}}`:** Grabs only the Key name of the network (for example: my_project_default or bridge).

**What it looks like after execution?**

If your primary container is running on a network named `pg_cluster_network`, the inner loop outputs the string `pg_cluster_network`.The shell evaluates the complete statement, changing your run script into this explicit command right before launching the container:

```bash
docker run -d --name postgres-replica --network pg_cluster_network ...
```

**Why this is essential for your Replication Setup?**

For your replica container to mirror the primary database, it must communicate directly over TCP/IP network packets. Docker containers cannot talk to each other by default unless they reside on the exact same internal Docker network. Using this dynamic lookup guarantees they can see and ping each other instantly.

### Remove its data directory

1. you can't delete the data in running container. bc the data dir is used by postgres demon once its operational . when containers spin up they run initilization script to set up everything before running the postgres. and if we get chance to remove to dir when initilization is not complete then we can delete the data dir bc postgres is not runnig yet so it can't block you from deleting the data dir.
2. stop the container.
3. restart the container
4. delete the data dir
5. if getting error try again from step 2.

```bash
docker stop postgres-replica
docker restart postgres-replica
docker exec -it postgres-replica bash
rm -rf /var/lib/postgresql/data/*
```

(For a production setup we'd use a dedicated volume, but for learning this is okay.)

---

## Step 9: Take Base Backup

This is the most important replication concept.

A replica cannot start from empty files.

It must start from a snapshot of primary.

Use [pg_basebackup](./3-pg_basebackup-and-pg_dump.md)

Run inside replica:

Install client tools if needed (already present in postgres image).

Run:

```bash
pg_basebackup \
  -h postgres-primary \
  -U repl_user \
  -D $PGDATA \
  -Fp \
  -Xs \
  -R
```

Password:

```text
repl_password
```

---

What happened?

```text
Primary
    |
    | pg_basebackup
    |
    v
Replica
```

PostgreSQL copied:

```text
tables
indexes
catalogs
WAL position
```

Everything.

---

## Step 10: What Does -R Do?

This is magic.

It automatically creates:

```text
standby.signal
```

and:

```text
primary_conninfo
```

Example:

```text
host=postgres-primary
user=repl_user
password=repl_password
```

This tells PostgreSQL:

```text
I am a replica.
Connect to primary.
Fetch WAL.
```

---

## Step 11: Start Replica

Restart:

```bash
docker restart postgres-replica
```

Now:

```text
Primary
    |
    | WAL
    |
    v
Replica
```

is active.

---

## Step 12: Verify Streaming Replication

Connect to primary:

```bash
docker exec -it postgres-primary psql -U postgres
```

Run:

```sql
SELECT * FROM pg_stat_replication;
```

### `pg_stat_replication`

PostgreSQL system view that provides vital statistics about the active WAL (Write-Ahead Log) sender processes streaming data to standby or replica servers. It must be executed on the primary (publisher) server and is restricted to superusers.

**Key Columns & Their Meanings:**

When you run the query, it outputs one row per connected standby server. The most critical fields to track include:

- **application_name:** The name identifying the replica (often configured in recovery.conf or postgresql.conf).
- **client_addr:** The IP address of the standby server.
- **state:** The current replication status (e.g., startup, catchup, streaming, backup). A healthy active replica will display streaming.
- **sent_lsn, write_lsn, flush_lsn, replay_lsn:** The Log Sequence Numbers (LSN) marking how much data has been sent to, written by, flushed to disk, and replayed on the replica.

**Expected:**

```text
pid
client_addr
state
sync_state
```

**You should see:**

```text
state = streaming
```

This is the proof replication is working.

---

## Step 13: Verify Replica

Connect:

```bash
docker exec -it postgres-replica psql -U postgres
```

Run:

```sql
SELECT pg_is_in_recovery();
```

### `pg_is_in_recovery()`

The `SELECT pg_is_in_recovery();` command checks whether a PostgreSQL server is currently running as a **replica (standby)** or as the **primary (master)**.

Direct Meaning

- **`true (t)`:** The server is a replica. It is in read-only mode and is actively applying logs from a primary server.
- **`false (f)`:** The server is the primary. It is open for both reads and writes.

**Summary Table:**

| **Result**  | **server Role**   | **Write Access** | **Read Access** |
| ----------- | ----------------- | ---------------- | --------------- |
| `t (true)`  | Standby / Replica | ❌ Blocked       | Allowed         |
| `f (false)` | Primary / Master  | Allowed          | Allowed         |

---

## Step 14: Test Replication

Insert on primary:

```sql
INSERT INTO users(name)
VALUES ('Alice');
```

Primary:

```sql
SELECT * FROM users;
```

```text
1 John
2 Alice
```

Now query replica:

```sql
SELECT * FROM users;
```

Output:

```text
1 John
2 Alice
```

No insert happened on replica.

The change arrived through `WAL streaming`.

---

## The Mental Model

**Most beginners think:**

```text
Primary sends table rows
to Replica
```

Not true.

PostgreSQL actually does:

```text
INSERT
   |
Generate WAL
   |
Write WAL
   |
Stream WAL
   |
Replica replays WAL
```

```text
Primary
   |
 WAL records
   |
   v
Replica
```

The replica rebuilds the exact same database state by replaying WAL records.

This WAL-based architecture is one of the reasons PostgreSQL replication is reliable and efficient.

> > note: the above procedure teaches the concepts correctly, but a production-ready Docker Compose would use persistent volumes, an init script for the replication user, and explicit networking. Once you're comfortable with the concepts, we can build a clean `docker-compose.yml` with a primary and replica using only the official PostgreSQL image and no manual shell work after `docker compose up`.

---

## Question? so replication user is only for replication and the main user will be used to connect to primary and replicas as well bc users are also copied . correct me if i am wrong?

Exactly right.

Let's separate the two types of connections.

### 1. Replication Connection

This is an internal PostgreSQL connection.

```text
Replica
   |
   |  WAL Streaming
   |
   v
Primary
```

The replica logs into the primary using:

```text
repl_user
```

Example:

```text
host=primary
user=repl_user
password=repl_password
```

This user exists solely for:

- reading WAL
- replication protocol
- base backups (`pg_basebackup`)

It is not an application user.

Think of it like:

```text
Replication Service Account
```

---

### 2. Application Connections

Your application connects using normal database users.

Example:

```text
admin
app_user
reporting_user
```

```text
Application
    |
    +----> Primary
    |
    +----> Replica
```

These users run:

```sql
SELECT
INSERT
UPDATE
DELETE
```

and other SQL operations.

---

### How Does This Work? we haven't created any users on replica and still all the users in primary are also duplicated in replica

Suppose on primary you create:

```sql
CREATE ROLE app_user LOGIN PASSWORD 'secret';
```

Then:

```sql
CREATE TABLE users (
    id INT,
    name TEXT
);
```

Then:

```sql
GRANT SELECT ON users TO app_user;
```

All of these changes are written to WAL.

The replica replays them.

So replica automatically gets:

```text
Role app_user
Table users
Permissions
Data
```

---

### What Exists On The Replica?

If primary has:

```text
Role: admin
Role: app_user
Role: reporting_user

Database: appdb

Table: users
Table: orders
```

Replica eventually has:

```text
Role: admin
Role: app_user
Role: reporting_user

Database: appdb

Table: users
Table: orders
```

because it is replaying WAL.

---

### Typical Production Setup

```text
                    App
                     |
          +----------+----------+
          |                     |
      Writes                Reads
          |                     |
          v                     v

      Primary             Replica(s)

      app_user            app_user
```

Application uses:

```text
app_user
```

for both primary and replicas.

---

Meanwhile:

```text
Replica
   |
   | replication protocol
   |
   v
Primary
```

uses:

```text
repl_user
```

internally.

> User/role creation and changes are replicated because they are stored in PostgreSQL system catalogs, which are copied and updated through WAL replay.

---

### Mental Model

Think of the primary as having two doors:

```text
                 Primary

             +-----------+
             |           |
             |           |
             +-----------+

              ^         ^
              |         |

          repl_user   app_user
```

#### Door 1

```text
repl_user
```

Used only by replicas.

Purpose:

```text
Give me WAL records
```

---

#### Door 2

```text
app_user
admin
reporting_user
```

Used by applications and humans.

Purpose:

```text
Run SQL queries
```

### Summary

✅ `repl_user` is only for replication.

✅ Normal database users (`admin`, `app_user`, etc.) can connect to both primary and replicas.

✅ Roles, permissions, schemas, tables, and data are replicated, so those users exist on replicas as well.

---
