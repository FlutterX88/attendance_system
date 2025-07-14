const pool = require('../config/db');

const getAllEmployees = async (req, res) => {
    try {
        const result = await pool.query(`
      SELECT e.id, e.full_name, 
        COALESCE(a.status, 'Not Marked') AS status
      FROM employees e
      LEFT JOIN LATERAL (
        SELECT status
        FROM attendance
        WHERE employee_name = e.full_name
          AND date = CURRENT_DATE
        LIMIT 1
      ) a ON TRUE
      ORDER BY e.full_name
    `);

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to load employees' });
    }
};

module.exports = { getAllEmployees };
