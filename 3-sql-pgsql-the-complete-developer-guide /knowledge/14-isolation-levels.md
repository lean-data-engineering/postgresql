# Read Phenomena (data consistency problems) And Isolation Levels

## 1: Data Consistency Problems (Read Phenomena)

A **dirty read, a non-repeatable read, and a phantom read** are **`three common data consistency problems (called read phenomena) that happen when multiple database transactions run at the same time`**.

---

### 1. Dirty Read

A dirty read happens when one transaction reads data that another transaction has changed, but **has not committed yet**.

- **What happens:** Transaction A updates a row's value (e.g., changing a price from $10 to $15) but does not save/commit it yet. Transaction B reads that new value ($15). If Transaction A suddenly cancels (_rolls back_) the change, the $15 value Transaction B saw never actually existed in the database.
- **Core issue:** Reading temporary, uncommitted data.
- **Prevented by:** _Read Committed_ isolation level.

---

### 2. Non-Repeatable Read

A non-repeatable read happens when a transaction reads the same row twice, but gets **different values** each time because another transaction changed and committed that row in between the reads.

- **What happens:** Transaction A reads a row and sees a balance of $100. Then, Transaction B updates that same row to $200 and commits the change. If Transaction A reads the exact same row again later in the same transaction, it now sees $200.
- **Core issue:** The data inside an existing row changed during the transaction.
- **Prevented by:** _Repeatable Read_ isolation level.

---

### 3. Phantom Read

A phantom read happens when a transaction runs the exact same query twice, but the **set of rows** returned is different because another transaction inserted or deleted rows that fit the query's filter in the meantime.

- **What happens:** Transaction A counts all users older than 30 and gets 5 rows. Meanwhile, Transaction B inserts a new user who is 35 and commits the change. If Transaction A runs the same count query again, it suddenly gets 6 rows—the new row acts like a "phantom" appearing out of nowhere.
- **Core issue:** The _number of rows_ matching a condition changes (due to inserts or deletes), unlike a non-repeatable read which modifies a single existing row.
- **Prevented by:** _Serializable isolation_ level.

---

### Summary Table

| **Read Phenomenon**     | **What Changes?**          | **Caused by Uncommitted Data?**      | **Prevented At This Isolation Level** |
| ----------------------- | -------------------------- | ------------------------------------ | ------------------------------------- |
| **Dirty Read**          | Single row value           | Yes (Reads uncommitted data)         | Read Committed                        |
| **Non-Repeatable Read** | Single row value           | No (Reads committed changes)         | Repeatable Read                       |
| **Phantom Read**        | Entire set of rows (count) | No (Reads committed inserts/deletes) | Serializable                          |

---

---

## 2: Transaction Isolation Levels

**Transaction isolation levels** are **`database settings that define how well one transaction is protected from the changes made by other concurrent transactions`**. They act as a control knob: a higher isolation level offers **greater data accuracy** but causes **slower performance** because the database has to _lock data_ or _queue up operations_.

---

### The 4 Standard Isolation Levels

Database engines follow the **SQL standard** which defines four isolation levels. Each level builds on the previous one, fixing more of the [read phenomena (dirty, non-repeatable, and phantom reads) that we discussed earlier](#1-data-consistency-problems-read-phenomena).

| **Isolation Level**     | **Prevents Dirty Reads?** | **Prevents Non-Repeatable Reads?** | **Prevents Phantom Reads?** | **Performance Speed** |
| ----------------------- | ------------------------- | ---------------------------------- | --------------------------- | --------------------- |
| **1. Read Uncommitted** | ❌ No                     | ❌ No                              | ❌ No                       | ⚡ Fastest            |
| **2. Read Committed**   | Yes                       | ❌ No                              | ❌ No                       | 🏎️ Fast               |
| **3. Repeatable Read**  | Yes                       | Yes                                | ❌ No                       | 🐢 Slower             |
| **4. Serializable**     | Yes                       | Yes                                | Yes                         | 🐌 Slowest            |

---

### Detailed Breakdown

---

#### 1. Read Uncommitted

This is the lowest isolation level. Transactions can see data that is currently being modified by other transactions, even if those changes haven't been saved yet.

- **Pros:** Highest performance and zero waiting time for locks.
- **Cons:** Allows **dirty reads**, **non-repeatable reads**, and **phantom reads**.
- **Best Used For:** Reports or telemetry analytics where 100% accuracy isn't critical (e.g., counting total page views on a blog).

---

#### 2. Read Committed

A transaction can only read data that has already been saved (committed) to the database. This is the default isolation level for many major databases like **PostgreSQL** and **SQL Server**.

- **Pros:** Completely eliminates **dirty reads**.
- **Cons:** Still allows **non-repeatable reads** and **phantom reads** because data can be modified by another transaction right after you read it.
- **Best Used For:** Most standard web applications where you need decent speed and want to make sure you never read fake, rolled-back data.

---

#### 3. Repeatable Read

This level guarantees that if you read a row once, you can read it again later in the same transaction and the data inside that row will look exactly the same. This is the default isolation level for **MySQL (InnoDB)**.

- **Pros:** Eliminates both **dirty reads** and **non-repeatable reads**.
- **Cons:** Still technically allows **phantom reads** (though some databases like MySQL use special tricks to prevent them even at this level).
- **Best Used For:** Financial calculations where you are running multiple operations on the same set of existing rows and cannot afford to have their values shift mid-process.

---

#### 4. Serializable

This is the highest and most restrictive isolation level. It forces transactions to run as if they are in a single-file line, one after another, completely isolated from each other.

- **Pros:** Completely eliminates all read anomalies, including **phantom reads**. Your data is 100% consistent.
- **Cons:** Terrible for performance under high traffic. Transactions frequently lock each other out, causing delays or failures (deadlocks).
- **Best Used For:** Critical systems where absolute accuracy is non-negotiable, such as **transferring money between bank accounts** or **booking airline seats**.

---

---

## 3: Implementaion of Isolation Levels

To implement isolation levels, database management systems (DBMS) rely on two core underlying mechanisms: **Locking (Pessimistic Concurrency Control) and Multi-Version Concurrency Control (MVCC) (Optimistic Concurrency Control)**.

Modern databases like **PostgreSQL**, **MySQL (InnoDB)**, and **Oracle** primarily use a combination of both, favoring MVCC for better performance.

---

### Mechanism 1: Locking (Pessimistic)

Locking prevents conflicts by forcing transactions to wait their turn. Databases use different types of locks to enforce isolation levels:

- **Shared Locks (S-Locks / Read Locks):** Multiple transactions can hold a shared lock on the same data to read it at the same time. Nobody can modify the data while a shared lock is active.
- **Exclusive Locks (X-Locks / Write Locks):** Only one transaction can hold an exclusive lock to modify data. No other transaction can read or write to that data until the lock is released.

---

**How Locking Implements the Levels:**

#### 1: Read Uncommitted

---

No read locks are requested. A transaction just reads the data as it is. Exclusive locks are still used for writes so data doesn't get corrupted, but readers don't care.

---

#### 2:Read Committed

The transaction acquires a Shared Lock before reading a row, but releases it immediately after reading that row. This ensures it doesn't read uncommitted data, but allows another transaction to change the row later.

##### Question-1: the tansaction T1 acquires the shared lock for the row its currenlty reading reads the data and releases the shared lock. then transaction T2 acquires the write-lock to write/update the data and releases the lock and when again T1 reads the data, will it not read uncommited data if write-lock by T2 is released before end of transaction?

Your logic is absolutely spot on regarding how locks _would_ fail if they behaved that way. However, you have one key detail slightly reversed: **a transaction never releases its write locks (exclusive locks) before the end of the transaction**.

This rule is a fundamental pillar of database design called **Strict Two-Phase Locking (Strict 2PL)**.

Here is how the scenario you described actually plays out step-by-step under the **Read Committed** isolation level to prevent the exact problem you pointed out:

###### The Safe Reality (Strict 2PL)

Let's look at how **Transaction 1 (T1)** and **Transaction 2 (T2)** interact using strict database locking rules:

1. **T1 Reads:** T1 acquires a **Shared Lock (S-Lock)** on a row, reads the data, and **immediately releases** it. (This is standard for Read Committed).
2. **T2 Modifies:** T2 now wants to update that same row. It acquires a **Write Lock (X-Lock)** and modifies the data.
3. **The Guardrail:** **T2 cannot release its Write Lock yet**. Under the rules of almost all relational databases, a transaction must hold all of its write locks until it completely finishes (**Commit** or **Rollback**).
4. **T1 Tries to Read Again:** While T2 is still running, T1 tries to read that row a second time. T1 requests a Shared Lock.
5. **The Block:** Because T2 is still holding the Write Lock, T1's request for a Shared Lock is **blocked**. T1 is forced to pause and wait.
6. **The Outcome:**
   1. **If T2 Commits:** T2 saves the data and releases its Write Lock. T1 wakes up, gets its Shared Lock, and reads the _new, committed_ data. (This is a non-repeatable read, which is allowed in Read Committed).
   2. **If T2 Rolls Back:** T2 discards the changes and releases its Write Lock. T1 wakes up and reads the _old, original_ data. **Uncommitted data is never read**.

###### What if a database actually worked the way you described?

If a database allowed Transaction 2 to release its write lock _before_ committing (which is called **Basic 2PL** instead of _Strict 2PL_), you would be 100% correct.

If T2 released the lock early, T1 could swoop in, read the dirty data, and if T2 rolled back a second later, the system would suffer a catastrophic data anomaly known as a **Dirty Read** or a **Cascading Rollback**. To prevent this nightmare, database engineers designed **Strict 2PL** to ensure write locks are always held until the very end.

---

##### Two-Phase Locking (2PL)

**`Two-Phase Locking (2PL) is a concurrency control protocol used by database management systems to ensure that concurrent transactions do not interfere with each other and corrupt data`**. It is called "two-phase" because a transaction's life cycle is split into two strict operational periods: **a growing phase** (where the transaction only acquires locks and cannot release any) and a **shrinking phase** (where the transaction only releases locks and cannot acquire any new ones).

**The Two Phases of 2PL:**

1. **Growing Phase:** The transaction requests and receives locks (shared locks for reading, exclusive locks for writing) as it needs data. It cannot let go of any lock it already holds during this time.
2. **Shrinking Phase:** Once the transaction releases its very first lock, it enters the shrinking phase. From this point forward, it can only release locks and is strictly forbidden from acquiring any new locks.

**Basic 2PL vs. Strict 2PL:**

The difference between Basic 2PL and Strict 2PL lies entirely in **when** a transaction is allowed to start releasing its exclusive (write) locks during that shrinking phase.

| **Locking Type** | **When Write Locks are Released**                                                                | **Risk of Dirty Reads / Cascading Aborts**                                                            |
| ---------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Basic 2PL**    | As soon as the operation on that specific row is done, even if the transaction is still running. | **High** (If the transaction rolls back later, other transactions already acted on uncommitted data). |
| **Strict 2PL**   | Held until the entire transaction officially **Commits** or **Rolls Back**.                      | **None** (Other transactions cannot touch modified rows until the changes are permanent).             |

1. **Basic 2PL (Standard):** In Basic 2PL, a transaction follows the two-phase rule, but it can release a write lock the moment it finishes updating a row.
   - **The Problem:** If Transaction A updates a row, releases the write lock, and then crashes or rolls back five steps later, any other transaction that read or wrote to that unlocked row in the meantime now holds invalid data. This forces the database into a messy "cascading rollback" where multiple transactions have to be undone.

2. **Strict 2PL:** To fix the danger of Basic 2PL, databases use **Strict 2PL**. Under this rule, any **exclusive lock (write lock)** acquired by a transaction must be held all the way until the transaction ends (Commit or Rollback). Shared locks (read locks) might still be dropped earlier depending on the isolation level, but write locks are locked down until the final decision is made.
   - **The Benefit:** No other transaction can read or write to a row modified by an uncommitted transaction. This completely shields the database from dirty reads and cascading rollbacks.

**Basic 2PL:**

**Basic 2PL is taught as the theoretical baseline in computer science textbooks, but it is rarely used in production databases because it causes dangerous cascading aborts**.

Database theory builds concepts step-by-step. Textbooks introduce **Basic 2PL** first to prove a mathematical concept: _if you follow the growing and shrinking phases, your transactions will be serializable and correct._ However, database architects realized that "correct on paper" still leads to a practical disaster in real systems: **cascading rollbacks**.

###### Why Basic 2PL is a Trap in Practice

If a real database used Basic 2PL, it would lead to this chain reaction:

1. **Transaction A** updates a row, finishes its work on that row, and **releases its write lock early** (allowed in Basic 2PL).
2. **Transaction B** immediately jumps in, reads that newly updated row, and uses it.
3. **Transaction A** suddenly crashes or rolls back five steps later.
4. **The Disaster:** Transaction B already made decisions based on data from Transaction A that no longer exists. Because Transaction A rolled back, **Transaction B must also be forced to roll back and abort**, even though Transaction B did nothing wrong. If Transaction C read what Transaction B wrote, Transaction C must also abort (a cascading failure).

###### How Textbooks vs. Reality Differ

- **In Theory (Classrooms):** Basic 2PL is the "standard definition" because it proves the fundamental logic of locking phases without extra restrictions.
- **In Reality (Engineering):** Database builders added one extra rule—_never release write locks early_—which transformed Basic 2PL into **Strict 2PL**.

Strict 2PL solved the cascading rollback problem completely, making it the actual standard for pessimistic locking in enterprise databases.

###### Why Read Uncommitted is not Basic 2PL

If Read Uncommitted used Basic 2PL, it would actually be _more restrictive_ than it is. Let's look at why:

1. **In Basic 2PL:** A transaction updating data _must_ hold a write lock. A transaction wanting to read that data _must_ request a read lock. Because a write lock and a read lock conflict, the reader would be forced to wait until the writer decides to release its lock during its shrinking phase.
2. **In Read Uncommitted:** A transaction updating data holds a write lock. However, a reading transaction completely ignores this lock. It doesn't ask for permission; it just reads the uncommitted data straight out of the buffer.

---

#### 3: Repeatable Read

The transaction acquires a **Shared Lock** when it reads a row, but **holds onto it until the entire transaction ends**. Because the lock is held, no other transaction can modify that row until the first transaction finishes.

---

#### 4: Serializable (2-Phase Locking & Range Locks)

The database uses **Predicate Locks** or **Index-Range Locks**. It doesn't just lock the specific rows you read; it locks the entire _range_ of potential rows matching your query criteria (e.g., locking the index for all users where `age > 30`). This completely prevents other transactions from inserting "phantom" rows into that range.

---

### Mechanism 2: Multi-Version Concurrency Control (MVCC)

MVCC is the modern standard because locking forces readers and writers to wait for each other, slowing down the database. MVCC operates on a golden rule: **"Readers never block writers, and writers never block readers."**

Instead of locking a row, MVCC treats data as immutable versions. When you update a row, the database doesn't overwrite it; it creates a new version of that row alongside a timestamp or transaction ID (TxID).

#### How MVCC Implements the Levels

Every transaction is assigned a unique, increasing transaction ID (e.g., `TxID 100`). The database creates a hidden **Read View (Snapshot)** for the transaction to determine which row versions are visible.

1. **Read Committed:**
   1. The transaction creates a **new snapshot at the start of every single SQL statement**.
   2. If `Statement 1` runs, it sees all data committed up to that millisecond. If `Statement 2` runs five seconds later, it generates a fresh snapshot and will see any new data committed during those five seconds.
2. **Repeatable Read / Snapshot Isolation:**
   1. The transaction creates **one single snapshot at very start of the transaction**.
   2. No matter how many times you query the database, or how long the transaction takes, the database evaluates row versions against that initial snapshot. Anything committed after your transaction started is invisible to you.

3. **Serializable (Serializable Snapshot Isolation - SSI):**
   1. It uses the same snapshot system as Repeatable Read, but the database actively tracks **read-write dependencies** in memory.
   2. If the database detects a "cycle" (e.g., Transaction A read data that Transaction B modified, and Transaction B read data that Transaction A modified), it flags a conflict and forces one of them to abort and roll back.

---

### Directly Comparing Implementation Styles

| **Feature / Scenario**   | **Pessimistic Locking Implementation**                 | **MVCC Implementation**                                                                                                      |
| ------------------------ | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| **When a write happens** | Blocks other readers and writers.                      | Creates a new version of the row; readers keep looking at the old version.                                                   |
| **Storage overhead**     | Low (just tracking locks in memory).                   | High (requires cleaning up old row versions via background processes like PostgreSQL's **VACUUM** or MySQL's **Undo Logs**). |
| **Handling conflicts**   | Transactions pause and wait in line (risks Deadlocks). | Transactions run instantly, but one might fail with a serialization error at commit time.                                    |
