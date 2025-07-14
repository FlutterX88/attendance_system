const pool = require('../config/db');

const registerEmployee = async (req, res) => {
    try {
        const {
            fullName, email, phone, password, dob, gender, bloodGroup,
            joinDate, department, designation, experience, basicSalary,
            workType, address, city, state, zip,
            emergencyContactName, emergencyContactNumber,
            annualLeaveEntitlement,
            requiredWorkHoursDaily,
            requiredWorkHoursMonthly
        } = req.body;

        const query = `
          INSERT INTO employees (
            full_name, email, phone, password, dob, gender, blood_group,
            join_date, department, designation, experience, basic_salary,
            work_type, address, city, state, zip,
            emergency_contact_name, emergency_contact_number,
            annual_leave_entitlement, required_work_hours_daily, required_work_hours_monthly
          )
          VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22)
          RETURNING id
        `;

        const values = [
            fullName, email, phone, password, dob, gender, bloodGroup,
            joinDate, department, designation, experience, basicSalary,
            workType, address, city, state, zip,
            emergencyContactName, emergencyContactNumber,
            annualLeaveEntitlement || 0,
            requiredWorkHoursDaily || 0,
            requiredWorkHoursMonthly || 0
        ];

        const result = await pool.query(query, values);
        res.status(201).json({ message: 'Employee registered', userId: result.rows[0].id });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Registration failed', error: error.message });
    }
};

const upsertEmployeeLeave = async (req, res) => {
    try {
        const {
            employeeId,
            leaveType,
            year,
            totalEntitlement,
            carryForward
        } = req.body;

        if (!employeeId || !leaveType || !year) {
            return res
                .status(400)
                .json({ message: 'employeeId, leaveType, and year are required.' });
        }

        const check = await pool.query(
            `SELECT id FROM employee_leave_summary
       WHERE employee_id = $1 AND leave_type = $2 AND year = $3`,
            [employeeId, leaveType, year]
        );

        if (check.rows.length > 0) {
            await pool.query(
                `UPDATE employee_leave_summary
         SET total_entitlement = $1,
             carry_forward = $2
         WHERE employee_id = $3 AND leave_type = $4 AND year = $5`,
                [totalEntitlement, carryForward || 0, employeeId, leaveType, year]
            );
            return res.json({ message: 'Leave updated' });
        } else {
            await pool.query(
                `INSERT INTO employee_leave_summary
          (employee_id, leave_type, year, total_entitlement, carry_forward)
         VALUES ($1, $2, $3, $4, $5)`,
                [employeeId, leaveType, year, totalEntitlement, carryForward || 0]
            );
            return res.status(201).json({ message: 'Leave created' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to save leave data.' });
    }
};

const takeLeave = async (req, res) => {
    try {
        const { employeeId, leaveType, year, days } = req.body;

        if (!employeeId || !leaveType || !year || !days) {
            return res
                .status(400)
                .json({ message: 'employeeId, leaveType, year, and days are required.' });
        }

        await pool.query(
            `UPDATE employee_leave_summary
       SET leave_taken = leave_taken + $1
       WHERE employee_id = $2  AND year = $3`,
            //  WHERE employee_id = $2 AND leave_type = $3 AND year = $4`,
            [days, employeeId, year]
        );

        res.json({ message: 'Leave taken updated' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to update leave taken.' });
    }
};

const getLeaveSummary = async (req, res) => {
    try {
        const employeeId = req.params.employeeId;

        const result = await pool.query(
            `SELECT id, leave_type, year,
              total_entitlement, leave_taken, carry_forward,
              (total_entitlement + carry_forward - leave_taken) as available_leave
       FROM employee_leave_summary
       WHERE employee_id = $1
       ORDER BY year DESC, leave_type`,
            [employeeId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch leave summary.' });
    }
};

const getAllLeaveAndWorkSummary = async (req, res) => {
    try {
        // Fetch all employees
        const empResult = await pool.query(`
      SELECT id, full_name, department FROM employees ORDER BY full_name
    `);
        const employees = empResult.rows;

        const summaries = [];

        for (const emp of employees) {
            // fetch leave summary
            const leaveRes = await pool.query(
                `SELECT leave_type, year, total_entitlement, leave_taken, carry_forward,
                (total_entitlement + carry_forward - leave_taken) as available_leave
         FROM employee_leave_summary
         WHERE employee_id = $1
         ORDER BY year DESC, leave_type`,
                [emp.id]
            );

            // fetch work summary
            const workRes = await pool.query(
                `SELECT year, month, required_hours, worked_hours
         FROM employee_work_summary
         WHERE employee_id = $1
         ORDER BY year DESC, month DESC`,
                [emp.id]
            );

            summaries.push({
                employee_id: emp.id,
                full_name: emp.full_name,
                department: emp.department,
                leave_summary: leaveRes.rows,
                work_summary: workRes.rows,
            });
        }

        res.json(summaries);
    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: 'Failed to fetch leave and work summaries for all employees.',
        });
    }
};


const upsertWorkHours = async (req, res) => {
    try {
        const { employeeId, year, month, requiredHours, workedHours } = req.body;

        if (!employeeId || !year || !month) {
            return res
                .status(400)
                .json({ message: 'employeeId, year, and month are required.' });
        }

        const check = await pool.query(
            `SELECT id FROM employee_work_summary
       WHERE employee_id = $1 AND year = $2 AND month = $3`,
            [employeeId, year, month]
        );

        if (check.rows.length > 0) {
            await pool.query(
                `UPDATE employee_work_summary
         SET required_hours = $1,
             worked_hours = $2
         WHERE employee_id = $3 AND year = $4 AND month = $5`,
                [requiredHours || 0, workedHours || 0, employeeId, year, month]
            );

            return res.json({ message: 'Work hours updated.' });
        } else {
            await pool.query(
                `INSERT INTO employee_work_summary
          (employee_id, year, month, required_hours, worked_hours)
         VALUES ($1, $2, $3, $4, $5)`,
                [employeeId, year, month, requiredHours || 0, workedHours || 0]
            );

            return res.status(201).json({ message: 'Work hours created.' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to save work hours.' });
    }
};


const incrementWorkedHours = async (req, res) => {
    try {
        const { employeeId, date } = req.body;

        if (!employeeId || !date) {
            return res.status(400).json({
                message: 'employeeId and date are required.',
            });
        }

        // Fetch attendance for that day
        const attResult = await pool.query(
            `SELECT in_time, out_time
       FROM attendance
       WHERE employee_id = $1
         AND date = $2`,
            [employeeId, date]
        );

        if (attResult.rows.length === 0) {
            return res.status(404).json({
                message: 'No attendance found for that date.',
            });
        }

        const { in_time, out_time } = attResult.rows[0];

        if (!in_time || !out_time) {
            return res.status(400).json({
                message: 'Incomplete in_time or out_time in attendance.',
            });
        }

        const workedHours =
            (new Date(`1970-01-01T${out_time}:00Z`) -
                new Date(`1970-01-01T${in_time}:00Z`)) /
            (1000 * 60 * 60);

        const year = new Date(date).getFullYear();
        const month = new Date(date).getMonth() + 1;

        // Check if summary exists
        const check = await pool.query(
            `SELECT id FROM employee_work_summary
       WHERE employee_id = $1 AND year = $2 AND month = $3`,
            [employeeId, year, month]
        );

        if (check.rows.length > 0) {
            await pool.query(
                `UPDATE employee_work_summary
         SET worked_hours = worked_hours + $1
         WHERE employee_id = $2 AND year = $3 AND month = $4`,
                [workedHours, employeeId, year, month]
            );
        } else {
            await pool.query(
                `INSERT INTO employee_work_summary
          (employee_id, year, month, worked_hours)
         VALUES ($1, $2, $3, $4)`,
                [employeeId, year, month, workedHours]
            );
        }

        res.json({
            message: 'Worked hours incremented.',
            added_hours: workedHours.toFixed(2),
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to increment worked hours.' });
    }
};



const getWorkHoursSummary = async (req, res) => {
    try {
        const employeeId = req.params.employeeId;

        const result = await pool.query(
            `SELECT year, month, required_hours, worked_hours
       FROM employee_work_summary
       WHERE employee_id = $1
       ORDER BY year DESC, month DESC`,
            [employeeId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch work hours summary.' });
    }
};

const saveLeaveSummary = async (req, res) => {
    try {
        const {
            employeeId,
            leave_type,
            year,
            total_entitlement,
            carry_forward
        } = req.body;

        // Check if exists
        const check = await pool.query(
            `SELECT id FROM employee_leave_summary
       WHERE employee_id = $1 AND leave_type = $2 AND year = $3`,
            [employeeId, leave_type, year]
        );

        if (check.rows.length > 0) {
            await pool.query(
                `UPDATE employee_leave_summary
         SET total_entitlement = $1,
             carry_forward = $2
         WHERE employee_id = $3 AND leave_type = $4 AND year = $5`,
                [
                    total_entitlement,
                    carry_forward,
                    employeeId,
                    leave_type,
                    year
                ]
            );
        } else {
            await pool.query(
                `INSERT INTO employee_leave_summary
         (employee_id, leave_type, total_entitlement, carry_forward, year)
         VALUES ($1, $2, $3, $4, $5)`,
                [employeeId, leave_type, total_entitlement, carry_forward, year]
            );
        }

        res.json({ message: "Leave summary saved." });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: "Failed to save leave summary." });
    }
};
const saveWorkSummary = async (req, res) => {
    try {
        const {
            employeeId,
            year,
            month,
            required_hours
        } = req.body;

        const check = await pool.query(
            `SELECT id FROM employee_work_summary
       WHERE employee_id = $1 AND year = $2 AND month = $3`,
            [employeeId, year, month]
        );

        if (check.rows.length > 0) {
            await pool.query(
                `UPDATE employee_work_summary
         SET required_hours = $1
         WHERE employee_id = $2 AND year = $3 AND month = $4`,
                [required_hours, employeeId, year, month]
            );
        } else {
            await pool.query(
                `INSERT INTO employee_work_summary
         (employee_id, year, month, required_hours, worked_hours)
         VALUES ($1, $2, $3, $4, 0)`,
                [employeeId, year, month, required_hours]
            );
        }

        res.json({ message: "Work summary saved." });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: "Failed to save work summary." });
    }
};




module.exports = {
    saveWorkSummary,
    saveLeaveSummary,
    getWorkHoursSummary,
    upsertWorkHours,
    getLeaveSummary,
    registerEmployee,
    upsertEmployeeLeave,
    takeLeave,
    incrementWorkedHours,
    getAllLeaveAndWorkSummary

};


// ALTER TABLE employees
// ADD COLUMN annual_leave_entitlement NUMERIC(5,2) DEFAULT 0,
// ADD COLUMN required_work_hours_daily NUMERIC(5,2) DEFAULT 0,
// ADD COLUMN required_work_hours_monthly NUMERIC(7,2) DEFAULT 0;


// CREATE TABLE employee_leave_summary (
//     id SERIAL PRIMARY KEY,
//     employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
//     leave_type VARCHAR(50) NOT NULL,
//     total_entitlement NUMERIC(5,2) DEFAULT 0,   -- e.g. 12 days CL
//     leave_taken NUMERIC(5,2) DEFAULT 0,        -- incremented when leave approved
//     carry_forward NUMERIC(5,2) DEFAULT 0,      -- unused leave carried to next year
//     year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)
// );

// CREATE TABLE employee_work_summary (
//     id SERIAL PRIMARY KEY,
//     employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
//     year INTEGER NOT NULL,
//     month INTEGER NOT NULL,
//     required_hours NUMERIC(7,2) DEFAULT 0,
//     worked_hours NUMERIC(7,2) DEFAULT 0
// );
//atble alter
// ALTER TABLE public.employee_requests
// ADD COLUMN from_date date,
// ADD COLUMN to_date date,
// ADD COLUMN requested_date date DEFAULT CURRENT_DATE,
// ADD COLUMN leave_type varchar(50),
// ADD COLUMN how_many_days numeric(5,2);

// CREATE TABLE employee_salary_reports (
//     id SERIAL PRIMARY KEY,
//     employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
//     year INTEGER NOT NULL,
//     month INTEGER NOT NULL,
    
//     -- Store financials for that month's report
//     basic_salary NUMERIC(12, 2) NOT NULL,
//     gross_salary NUMERIC(12, 2) NOT NULL,
//     net_salary NUMERIC(12, 2) NOT NULL,
    
//     total_allowances NUMERIC(12, 2) DEFAULT 0,
//     total_deductions NUMERIC(12, 2) DEFAULT 0,
//     absent_deduction NUMERIC(12, 2) DEFAULT 0,
//     leave_deduction NUMERIC(12, 2) DEFAULT 0,
//     late_deduction NUMERIC(12, 2) DEFAULT 0,
//     overtime_addition NUMERIC(12, 2) DEFAULT 0,
//     total_advance NUMERIC(12, 2) DEFAULT 0,

//     paid BOOLEAN DEFAULT FALSE,
//     paid_date TIMESTAMP
// );
