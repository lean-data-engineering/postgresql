import {Pool} from "pg";

export const primaryPool = new Pool({
    host: "localhost",
    port: 5432,
    user: "admin",
    password: "password",
    database: "appdb",
});

export const replicaPool = new Pool({
    host: "localhost",
    port: 5433,
    user: "admin",
    password: "password",
    database: "appdb",
});

