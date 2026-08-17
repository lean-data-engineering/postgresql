import {Pool} from "pg";

export const primaryPool = new Pool({
    host: "postgres-primary",
    port: 5432,
    user: "admin",
    password: "password",
    database: "appdb",
});

export const replicaPool = new Pool({
    host: "postgres-replica",
    port: 5432,
    user: "admin",
    password: "password",
    database: "appdb",
});

