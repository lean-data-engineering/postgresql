# postgre replication setup

1. creating basic cluster with primary and one replica

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

  postgres-replica:
    image: postgres:17
    container_name: postgres-replica
    environment:
      POSTGRES_PASSWORD: password # default user 'postgres' & deafault db 'postgres' is created if you don't mention it.
    volumes:
      - replica-data:/var/lib/postgresql/data
  api:
    build: .
    container_name: api
    ports:
      - "3000:3000"
    depends_on:
      - postgres-primary
      - postgres-replica

volumes:
  primary-data:
    driver: local
    name: postgres-primary-data

  replica-data:
    driver: local
    name: postgres-replica-data
```

## Step 2: Start Primary db

```bash
docker compose up -d postgres-primary
```

Verify:

```bash
docker ps
```

---

## Step 3: Connect to Primary

```bash
docker compose exec postgres-primary psql -U admin -d appdb
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

## Step 4: Understand Why Replication Doesn't Work Yet

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

## Step 5: Enable WAL Streaming

### Enter container

```bash
docker compose exec postgres-primary bash
```

### Locate config

```bash
psql -U admin -c "SHOW config_file;"
```

[Click to understand command](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#locate-config)

Usually:

```text
/var/lib/postgresql/data/postgresql.conf
```

---

### Append

```bash
echo "wal_level = replica" >> $PGDATA/postgresql.conf
echo "max_wal_senders = 10" >> $PGDATA/postgresql.conf
echo "hot_standby = on" >> $PGDATA/postgresql.conf
```

[Click to understand meaning of these additions to config file](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#append)

---

## Step 6: Create Replication User

### Connect

```bash
docker exec -it postgres-primary psql -U admin -d postgres
```

### Create

```sql
CREATE ROLE repl_user
WITH REPLICATION
LOGIN
PASSWORD 'repl_password';
```

This SQL command creates a dedicated user account in PostgreSQL specifically designed to handle database replication streaming.

Why? Because replicas connect like normal clients. PostgreSQL needs authentication.

Run it only on primary db

```text
Replica ---> Primary
```

[Click for cmd explantion and why ?](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#keyword-breakdown)

---

## Step 7: Allow Replica Connections

### Edit

```bash
docker exec -it postgres-primary bash
```

### Append line

```bash
echo "host replication repl_user all scram-sha-256" >> $PGDATA/pg_hba.conf
```

#### Meaning

```text
Allow user repl_user to perform replication.
```

##### Without this

```text
Replica connection rejected.
```

[What is pg_hba.conf file and how its related to replication process](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#what-is-pg_hbaconf-file-and-how-its-related-to-replication-process)

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

## Step 8: Start replica db

```bash
docker compose up -d postgres-replica
```

### Important

Replica cannot start with an empty database.

It needs a copy of the primary.

### Remove its data directory

1. you can't delete the data in running container. bc the data dir is used by postgres demon once its operational . when containers spin up they run initilization script to set up everything before running the postgres. and if we get chance to remove to dir when initilization is not complete then we can delete the data dir bc postgres is not runnig yet so it can't block you from deleting the data dir.
2. stop the container.
3. restart the container
4. delete the data dir
5. if getting error try again from step 2.

```bash
docker compose stop postgres-replica
docker compose restart postgres-replica
docker compose exec postgres-replica bash
rm -rf /var/lib/postgresql/data/*
```

---

## Step 9: Take Base Backup

This is the most important replication concept.

A replica cannot start from empty files.

It must start from a snapshot of primary.

Use [pg_basebackup](../../1-express-postgres-cluster/knowledge/3-pg_basebackup-and-pg_dump.md)

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

## [command explanation](../../1-express-postgres-cluster/knowledge/3-pg_basebackup-and-pg_dump.md)

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
docker compose restart postgres-replica
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

[What cmd mean](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#pg_stat_replication)

Expected:

```text
pid, client_addr, state, sync_state
```

You should see:

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

[What it means](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#pg_is_in_recovery)

```text
checks whether a PostgreSQL server is currently running as a replica (standby) or as the primary (master).
replica -> t
primary -> f
```

---

## Step 14: Test Replication

\l -> should display 'appdb' on replica.
create a new table and add some entreis and check if
the table and data is available in replica.

---

## The Mental Model

Most beginners think:

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

## Note

[replication user is only for replication and the main user will be used to connect to primary and replicas as well bc users are also copied . correct me if i am wrong?](../../1-express-postgres-cluster/knowledge/2-pg_replica.md#question-so-replication-user-is-only-for-replication-and-the-main-user-will-be-used-to-connect-to-primary-and-replicas-as-well-bc-users-are-also-copied--correct-me-if-i-am-wrong)

One note: the above procedure teaches the concepts correctly, but a production-ready Docker Compose would use persistent volumes, an init script for the replication user, and explicit networking. Once you're comfortable with the concepts, we can build a clean `docker-compose.yml` with a primary and replica using only the official PostgreSQL image and no manual shell work after `docker compose up`.

---
