const pool = require('../config/db');

const giveSalaryAdvance = async (req, res) => {
  try {
    const { employeeName, date, amount, paymentMode, remarks, status, employee_id } = req.body;

    const query = `
      INSERT INTO salary_advances (
        employee_name, date, amount, payment_mode, remarks,status, employee_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id
    `;

    const values = [employeeName, date, amount, paymentMode, remarks, status, employee_id];

    const result = await pool.query(query, values);
    res.status(201).json({ message: 'Salary advance recorded', id: result.rows[0].id });

  } catch (error) {
    console.error('Salary advance error:', error);
    res.status(500).json({ message: 'Failed to record salary advance', error: error.message });
  }
};

module.exports = { giveSalaryAdvance };


// ALTER TABLE salary_advances
// ADD COLUMN status VARCHAR(20) DEFAULT 'Pending';