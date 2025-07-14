const pool = require('../config/db');

const getDashboardStats = async (req, res) => {
  const period = req.query.period || 'daily'; // 'daily' or 'monthly'
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

  const dateCondition = period === 'monthly'
    ? "date_trunc('month', date) = date_trunc('month', CURRENT_DATE)"
    : "date = CURRENT_DATE";

  try {
    const [totalEmployees, attendance, salaryAdvance] = await Promise.all([
      pool.query("SELECT COUNT(*) FROM employees"),
      pool.query(`
         SELECT
    COUNT(*) FILTER (WHERE status = 'Present') AS present,
    COUNT(*) FILTER (WHERE status = 'Absent') AS absent,
    COUNT(*) FILTER (WHERE status = 'Leave') AS leave,
    COUNT(*) FILTER (WHERE status = 'Late') AS late,
    SUM(EXTRACT(EPOCH FROM (
      CAST(out_time AS TIME) - CAST(in_time AS TIME)
    )) / 3600) FILTER (
      WHERE out_time IS NOT NULL AND in_time IS NOT NULL
    ) AS overtime
  FROM attendance
  WHERE ${dateCondition}
      `),
      pool.query(`
        SELECT COALESCE(SUM(amount), 0) AS total_advance
        FROM salary_advances
        WHERE ${dateCondition}
      `),
    ]);

    const result = {
      totalEmployees: parseInt(totalEmployees.rows[0].count),
      present: attendance.rows[0].present || 0,
      absent: attendance.rows[0].absent || 0,
      leave: attendance.rows[0].leave || 0,
      late: attendance.rows[0].late || 0,
      overtime: parseFloat(attendance.rows[0].overtime || 0).toFixed(1) + ' hours',
      advance: `₹${(parseFloat(salaryAdvance.rows[0].total_advance) / 1000).toFixed(1)}K`,
    };

    res.status(200).json(result);
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ message: 'Failed to fetch dashboard data', error: error.message });
  }
};

module.exports = { getDashboardStats };
