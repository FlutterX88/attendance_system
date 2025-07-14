const pool = require('../config/db');

const getownDashboardStats = async (req, res) => {
    try {
        const [
            totalEmployees,
            todayAttendance,
            salaryMonth,
            advancesMonth,
            overtimeMonth,
            lateToday,
            recentEmployees,
            recentAdvances
        ] = await Promise.all([
            pool.query(`SELECT COUNT(*) FROM employees`),
            pool.query(`
        SELECT
          COUNT(*) FILTER (WHERE status = 'Present') AS present,
          COUNT(*) FILTER (WHERE status = 'Absent') AS absent,
          COUNT(*) FILTER (WHERE status = 'Leave') AS leave
        FROM attendance
        WHERE date = CURRENT_DATE
    `),
            pool.query(`
        SELECT COALESCE(SUM(basic_salary::numeric), 0) AS total_salary
        FROM employees
    `),
            pool.query(`
        SELECT COALESCE(SUM(amount::numeric), 0) AS total_advance
        FROM salary_advances
        WHERE date_trunc('month', date) = date_trunc('month', CURRENT_DATE)
    `),
            pool.query(`
        SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (
          CAST(out_time AS TIME) - CAST(in_time AS TIME)
        )) / 3600), 0) AS total_overtime
        FROM attendance
        WHERE out_time IS NOT NULL AND in_time IS NOT NULL
          AND date_trunc('month', date) = date_trunc('month', CURRENT_DATE)
    `),
            pool.query(`
        SELECT COUNT(*) AS total_late
        FROM attendance
        WHERE status = 'Late'
          AND date = CURRENT_DATE
    `),
            pool.query(`
        SELECT id, full_name, department, to_char(join_date, 'YYYY-MM-DD') AS join_date
        FROM employees
        ORDER BY join_date DESC
        LIMIT 5
    `),
            pool.query(`
        SELECT employee_name, amount, payment_mode,
               to_char(date, 'YYYY-MM-DD') AS date
        FROM salary_advances
        ORDER BY date DESC
        LIMIT 5
    `)
        ]);


        res.json({
            totalEmployees: parseInt(totalEmployees.rows[0].count),
            presentToday: parseInt(todayAttendance.rows[0].present || 0),
            absentToday: parseInt(todayAttendance.rows[0].absent || 0),
            leaveToday: parseInt(todayAttendance.rows[0].leave || 0),
            totalSalaryThisMonth: parseFloat(salaryMonth.rows[0].total_salary),
            totalAdvanceThisMonth: parseFloat(advancesMonth.rows[0].total_advance),
            totalOvertimeThisMonth: parseFloat(overtimeMonth.rows[0].total_overtime).toFixed(1),
            totalLateToday: parseInt(lateToday.rows[0].total_late || 0),
            recentEmployees: recentEmployees.rows,
            recentAdvances: recentAdvances.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to load owner dashboard' });
    }
};

module.exports = { getownDashboardStats };
