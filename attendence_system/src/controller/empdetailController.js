const pool = require('../config/db');

const getEmployeeDetail = async (req, res) => {
    try {
        const id = req.params.id;

        // Get employee basic info
        const empResult = await pool.query(`
      SELECT id, full_name, basic_salary
      FROM employees
      WHERE id = $1
    `, [id]);

        if (empResult.rows.length === 0) {
            return res.status(404).json({ message: 'Employee not found' });
        }

        const emp = empResult.rows[0];

        // Get last salary paid date (dummy logic, adjust if you track payments)
        const lastSalaryDate = '2025-04-30';
        const lastSalaryPaid = emp.basic_salary;

        // Attendance summary
        const attResult = await pool.query(`
      SELECT
        COUNT(*) FILTER (WHERE status = 'Present') AS present_days,
        COUNT(*) FILTER (WHERE status = 'Absent') AS absent_days,
        COUNT(*) FILTER (WHERE status = 'Leave') AS leave_days,
        COUNT(*) AS total_days
      FROM attendance
      WHERE employee_name = (
        SELECT full_name FROM employees WHERE id = $1
      )
    `, [id]);

        // Advances
        const advResult = await pool.query(`
      SELECT amount, to_char(date, 'YYYY-MM-DD') as date
      FROM salary_advances
      WHERE employee_name = (
        SELECT full_name FROM employees WHERE id = $1
      )
    `, [id]);

        // Overtime / Half day records
        const extraResult = await pool.query(`
      SELECT
        to_char(date, 'YYYY-MM-DD') as date,
        status as type,
        EXTRACT(EPOCH FROM (CAST(out_time AS TIME) - CAST(in_time AS TIME)))/3600 as hours
      FROM attendance
      WHERE employee_name = (
        SELECT full_name FROM employees WHERE id = $1
      )
      AND out_time IS NOT NULL
      AND in_time IS NOT NULL
      AND status IN ('Overtime', 'Half Day')
    `, [id]);

        res.json({
            id: emp.id,
            full_name: emp.full_name,
            basic_salary: parseFloat(emp.basic_salary),
            last_salary_paid: parseFloat(lastSalaryPaid),
            last_salary_date: lastSalaryDate,
            attendance_summary: {
                total_days: parseInt(attResult.rows[0].total_days) || 0,
                present_days: parseInt(attResult.rows[0].present_days) || 0,
                absent_days: parseInt(attResult.rows[0].absent_days) || 0,
                leave_days: parseInt(attResult.rows[0].leave_days) || 0
            },
            advances: advResult.rows.map(row => ({
                amount: parseFloat(row.amount),
                date: row.date
            })),
            extra_hours: extraResult.rows.map(row => ({
                date: row.date,
                type: row.type,
                hours: parseFloat(row.hours || 0).toFixed(1)
            }))
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to load employee detail' });
    }
};

module.exports = { getEmployeeDetail };
