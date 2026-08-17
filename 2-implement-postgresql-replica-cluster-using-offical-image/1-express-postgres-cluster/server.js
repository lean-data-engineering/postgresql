import express from 'express';
import { primaryPool, replicaPool } from './db.js';

const app = express();
const PORT = 3000;
app.use(express.json());

app.post('/register', async (req, res) => {
    try{
        const { firstName, lastName, password } = req.body;
        const result = await primaryPool.query('INSERT INTO users (first_name, last_name, password) VALUES ($1, $2, $3) RETURNING *', [firstName, lastName, password]);
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error registering user:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
})

app.get('/users', async (req, res) => {
    try {
        const result = await replicaPool.query('SELECT * FROM users');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('/health', async (req, res) => {
    try {
        const primary = await primaryPool.query("SELECT pg_is_in_recovery()");
        const replica = await replicaPool.query("SELECT pg_is_in_recovery()");
        res.status(200).json({
            primary: primary.rows[0].pg_is_in_recovery ? "Primary is in recovery mode" : "Primary is not in recovery mode",
            replica: replica.rows[0].pg_is_in_recovery ? "Replica is in recovery mode" : "Replica is not in recovery mode"
        });
    } catch (error) {
        console.error('Error checking health:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});