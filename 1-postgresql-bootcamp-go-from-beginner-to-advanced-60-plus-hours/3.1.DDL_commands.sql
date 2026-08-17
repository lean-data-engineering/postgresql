-- PostgreSQL DDL Commands

-- CREATE TABLE

CRATE DATABASE testdb;

-- PostgreSQL does not support IF NOT EXISTS clause in CREATE DATABASE the same way MySQL does.


CREATE TABLE employees (
    employee_id   SERIAL          PRIMARY KEY,       -- auto-increment
    first_name    VARCHAR(50)     NOT NULL,
    last_name     VARCHAR(50)     NOT NULL,
    email         TEXT            UNIQUE,
    hire_date     DATE            DEFAULT CURRENT_DATE,
    salary        NUMERIC(10,2)   DEFAULT 0.00,
    is_active     BOOLEAN         DEFAULT TRUE,
    created_at    TIMESTAMP       DEFAULT NOW()
);

-- PostgreSQL-specific types:
-- | Type                     | Use                                        |
-- |--------------------------|--------------------------------------------|
-- | `SERIAL` / `BIGSERIAL`   | Auto-increment integer                     |
-- | `TEXT`                   | Unlimited length string                    |
-- | `BOOLEAN`                | `TRUE` / `FALSE`                           |
-- | `JSONB`                  | Binary JSON storage                        |
-- | `UUID`                   | Unique identifier                          |
-- | `ARRAY`                  | Array of any type                          |
-- | `NUMERIC(p,s)`           | Exact decimal (use over `FLOAT` for money) |
-- | `TIMESTAMPTZ`            | Timestamp with timezone                    |



-- ALTER TABLE

    -- Add a column
    ALTER TABLE employees
    ADD COLUMN department_id INT;

    -- Add with constraint
    ALTER TABLE employees
    ADD COLUMN phone VARCHAR(20) UNIQUE;

    -- Change data type
    ALTER TABLE employees
    ALTER COLUMN salary TYPE NUMERIC(12,2);

    -- Set / drop a default
    ALTER TABLE employees
    ALTER COLUMN is_active SET DEFAULT TRUE;

    ALTER TABLE employees
    ALTER COLUMN is_active DROP DEFAULT;

    -- Set NOT NULL
    ALTER TABLE employees
    ALTER COLUMN first_name SET NOT NULL;

    -- Drop NOT NULL
    ALTER TABLE employees
    ALTER COLUMN phone DROP NOT NULL;

    -- Rename a column
    ALTER TABLE employees
    RENAME COLUMN last_name TO surname;

    -- Rename the table
    ALTER TABLE employees
    RENAME TO staff;

    -- Drop a column
    ALTER TABLE employees
    DROP COLUMN phone;

------------------------------------------------------------------
-- 3. Constraints

    -- Add a primary key after creation
    ALTER TABLE employees
    ADD CONSTRAINT pk_employees PRIMARY KEY (employee_id);

    -- Add foreign key
    ALTER TABLE employees
    ADD CONSTRAINT fk_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE;

    -- Add unique constraint
    ALTER TABLE employees
    ADD CONSTRAINT uq_email UNIQUE (email);

    -- Add check constraint
    ALTER TABLE employees
    ADD CONSTRAINT chk_salary CHECK (salary >= 0);

    -- Drop a constraint
    ALTER TABLE employees
    DROP CONSTRAINT chk_salary;


----------------------------------------------------------------------------
-- 4. DROP

    -- Drop table
    DROP TABLE employees;

    -- Safe drop
    DROP TABLE IF EXISTS employees;

    -- Drop and remove all dependent objects (views, FK refs)
    DROP TABLE employees CASCADE;

    -- Drop but fail if dependencies exist
    DROP TABLE employees RESTRICT;  -- default behavior


------------------------------------------------------------------------
-- 5. TRUNCATE


    -- Basic truncate
    TRUNCATE TABLE employees;

    -- Reset the SERIAL sequence back to 1
    TRUNCATE TABLE employees RESTART IDENTITY;

    -- Truncate and also truncate child tables with FK references
    TRUNCATE TABLE employees CASCADE;


------------------------------------------------------------------------------
-- 6. Indexes

    -- Basic index
    CREATE INDEX idx_last_name ON employees(last_name);

    -- Unique index
    CREATE UNIQUE INDEX idx_email ON employees(email);

    -- Composite index
    CREATE INDEX idx_name ON employees(last_name, first_name);

    -- Partial index (only index active employees)
    CREATE INDEX idx_active_emp ON employees(employee_id)
    WHERE is_active = TRUE;

    -- Drop index
    DROP INDEX idx_last_name;


------------------------------------------------------------------------------------------------
-- 7. Schemas (Namespaces)

    -- Postgres uses **schemas** to organize objects within a database.

    -- Create a schema
    CREATE SCHEMA hr;

    -- Create table inside a schema
    CREATE TABLE hr.employees (
        employee_id SERIAL PRIMARY KEY,
        first_name  VARCHAR(50)
    );

    -- Drop schema
    DROP SCHEMA hr;

    -- Drop schema and everything inside it
    DROP SCHEMA hr CASCADE;


-------------------------------------------------------------------
-- 8. Sequences (used by SERIAL internally)


-- Create manually
CREATE SEQUENCE emp_id_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    NO MAXVALUE;

-- Use in a table
CREATE TABLE employees (
    employee_id INT DEFAULT NEXTVAL('emp_id_seq')
);

-- Drop
DROP SEQUENCE emp_id_seq;


> In modern Postgres (v10+), prefer `GENERATED ALWAYS AS IDENTITY` over `SERIAL`:


CREATE TABLE employees (
    employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(50)
);


------------------------------------------------------------------------------
-- Quick Reference
-- | Command                   | Postgres Notes                            |
-- |---------------------------|-------------------------------------------|
-- | `CREATE TABLE`            | Use `SERIAL` or `IDENTITY` for PK         |
-- | `ALTER TABLE`             | Uses `ALTER COLUMN`, not `MODIFY`         |
-- | `DROP TABLE`              | Use `CASCADE` to handle dependencies      |
-- | `TRUNCATE`                | Supports `RESTART IDENTITY` and `CASCADE` |
-- | `CREATE INDEX`            | Supports partial indexes                  |
-- | `CREATE SCHEMA`           | Organizes tables into namespaces          |

