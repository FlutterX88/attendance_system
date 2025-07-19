const pool = require('../config/db');

const createEmployeeRequest = async (req, res) => {
    try {
        const {
            employeeId,
            type,
            reason,
            date,
            status,
            fromDate,
            toDate,
            leaveType,
            howManyDays,
        } = req.body;

        console.log("Creating employee request:", req.body);

        const query = `
      INSERT INTO employee_requests
      (employee_id, request_type, reason, date, status, from_date, to_date, requested_date, leave_type, how_many_days)
      VALUES
      ($1, $2, $3, $4, $5, $6, $7, CURRENT_DATE, $8, $9)
      RETURNING id
    `;

        const result = await pool.query(query, [
            employeeId,
            type,
            reason,
            date,
            status || 'Pending',
            fromDate || null,
            toDate || null,
            leaveType || null,
            howManyDays || null,
        ]);

        res.status(201).json({
            message: "Request submitted",
            id: result.rows[0].id,
        });
    } catch (error) {
        console.error(error);
        res
            .status(500)
            .json({ message: "Failed to submit request", error: error.message });
    }
};

const getPendingRequests = async (req, res) => {
    try {
        const status = req.query.status || 'Pending';

        const result = await pool.query(
            `
      SELECT
          r.id,
          r.employee_id,
          e.full_name,
          r.request_type,
          r.reason,
          NULL as amount,
          NULL as payment_mode,
          r.date,
          r.status,
          r.from_date,
          r.to_date,
          r.requested_date,
          r.leave_type,
          r.how_many_days
      FROM employee_requests r
      JOIN employees e ON e.id = r.employee_id
      WHERE r.status = $1

      UNION ALL

      SELECT
          sa.id,
          sa.employee_id,
          e.full_name,
          'Advance' as request_type,
          sa.remarks as reason,
          sa.amount,
          sa.payment_mode,
          sa.date,
          sa.status,
          NULL as from_date,
          NULL as to_date,
          NULL as requested_date,
          NULL as leave_type,
          NULL as how_many_days
      FROM salary_advances sa
      JOIN employees e ON e.id = sa.employee_id
      WHERE sa.status = $1

      ORDER BY date DESC
      `,
            [status]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch requests' });
    }
};

const getAllRequests = async (req, res) => {
    try {
        const statusFilter = req.query.status; // e.g. "Pending", "Approved"

        const params = [];
        let whereAdvance = "";
        let whereRequest = "";

        if (statusFilter) {
            whereAdvance = `WHERE status = $1`;
            whereRequest = `WHERE r.status = $1`;
            params.push(statusFilter);
        }

        // Query for salary advances
        const advanceQuery = `
      SELECT
        id,
        employee_id,
        employee_name,
        'Advance' as request_type,
        COALESCE(remarks, '') as reason,
        amount,
        payment_mode,
        date,
        status,
        NULL as from_date,
        NULL as to_date,
        NULL as requested_date,
        NULL as leave_type,
        NULL as how_many_days
      FROM salary_advances
      ${whereAdvance}
      ORDER BY date DESC
    `;

        // Query for employee requests
        const empRequestQuery = `
      SELECT
        r.id,
        r.employee_id,
        e.full_name AS employee_name,
        r.request_type,
        COALESCE(r.reason, '') as reason,
        NULL as amount,
        NULL as payment_mode,
        r.date,
        r.status,
        r.from_date,
        r.to_date,
        r.requested_date,
        r.leave_type,
        r.how_many_days
      FROM employee_requests r
      JOIN employees e ON e.id = r.employee_id
      ${whereRequest}
      ORDER BY r.date DESC
    `;

        const [advances, requests] = await Promise.all([
            pool.query(advanceQuery, params),
            pool.query(empRequestQuery, params),
        ]);

        const combined = [...advances.rows, ...requests.rows].sort((a, b) => {
            const dateA = a.date ? new Date(a.date) : new Date(0);
            const dateB = b.date ? new Date(b.date) : new Date(0);
            return dateB - dateA;
        });

        res.json(combined);
    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Failed to fetch requests",
            error: error.message,
        });
    }
};

const getAttendanceAdvanceReport = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        const year = new Date(startDate).getFullYear();
        const month = new Date(startDate).getMonth() + 1;

        // Fetch all employees
        const empResult = await pool.query(`
      SELECT id, full_name, department, basic_salary
      FROM employees
      ORDER BY full_name
    `);
        const employees = empResult.rows;

        // Fetch all attendance records in range
        const attendanceResult = await pool.query(`
      SELECT
          employee_id,
          date,
          status,
          in_time,
          out_time
      FROM attendance
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]);

        // Fetch salary components
        const compResult = await pool.query(`
      SELECT *
      FROM salary_components
      WHERE active = true
    `);
        const componentsList = compResult.rows;

        // Fetch salary advances
        const advanceResult = await pool.query(`
      SELECT
          employee_id,
          date,
          amount
      FROM salary_advances
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]);

        // Fetch leave summary for the report year
        const leaveSummaryResult = await pool.query(`
      SELECT
          employee_id,
          leave_type,
          year,
          total_entitlement,
          leave_taken,
          carry_forward
      FROM employee_leave_summary
      WHERE year = $1
    `, [year]);

        // Fetch overtime entries
        const overtimeResult = await pool.query(`
      SELECT employee_id, date, extra_hours
      FROM employee_overtime
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]);

        // Fetch less hours entries
        const lessHoursResult = await pool.query(`
      SELECT employee_id, date, less_hours
      FROM employee_less_hours
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]);

        // Fetch all shifts for employees
        const shiftResult = await pool.query(`
      SELECT employee_id, start_time, end_time
      FROM employee_shifts
    `);

        // Fetch salary report statuses
        const salaryReportResult = await pool.query(`
      SELECT
        employee_id,
        paid,
        paid_date
      FROM employee_salary_reports
      WHERE year = $1 AND month = $2
    `, [year, month]);

        const salaryStatusMap = {};
        for (const row of salaryReportResult.rows) {
            salaryStatusMap[row.employee_id] = {
                paid: row.paid,
                paid_date: row.paid_date
            };
        }

        // Prepare maps for fast lookup
        const attendanceMap = {};
        for (const row of attendanceResult.rows) {
            const dateStr = new Date(row.date).toISOString().split("T")[0];
            const key = `${row.employee_id}_${dateStr}`;
            attendanceMap[key] = row;
        }

        const advanceMap = {};
        for (const adv of advanceResult.rows) {
            if (!advanceMap[adv.employee_id]) {
                advanceMap[adv.employee_id] = [];
            }
            advanceMap[adv.employee_id].push(adv);
        }

        const leaveSummaryMap = {};
        for (const row of leaveSummaryResult.rows) {
            if (!leaveSummaryMap[row.employee_id]) {
                leaveSummaryMap[row.employee_id] = [];
            }
            leaveSummaryMap[row.employee_id].push(row);
        }

        const overtimeMap = {};
        for (const row of overtimeResult.rows) {
            if (!overtimeMap[row.employee_id]) {
                overtimeMap[row.employee_id] = [];
            }
            overtimeMap[row.employee_id].push(row);
        }

        const lessHoursMap = {};
        for (const row of lessHoursResult.rows) {
            if (!lessHoursMap[row.employee_id]) {
                lessHoursMap[row.employee_id] = [];
            }
            lessHoursMap[row.employee_id].push(row);
        }

        const shiftMap = {};
        for (const row of shiftResult.rows) {
            shiftMap[row.employee_id] = row;
        }

        // Build the date range array
        const days = [];
        let curr = new Date(startDate);
        const end = new Date(endDate);
        while (curr <= end) {
            days.push(curr.toISOString().split("T")[0]);
            curr.setDate(curr.getDate() + 1);
        }

        const report = employees.map((emp) => {
            let present = 0;
            let absent = 0;
            let leave = 0;
            let overtimeHours = 0;
            let lessHours = 0;

            let requiredHoursPerDay = 8; // default
            const shift = shiftMap[emp.id];
            if (shift) {
                const startDateTime = new Date(`2020-01-01T${shift.start_time}:00Z`);
                const endDateTime = new Date(`2020-01-01T${shift.end_time}:00Z`);
                let hoursDiff =
                    (endDateTime - startDateTime) / (1000 * 60 * 60);

                if (hoursDiff < 0) {
                    hoursDiff += 24;
                }
                requiredHoursPerDay = hoursDiff || 8;
            }

            days.forEach((d) => {
                const key = `${emp.id}_${d}`;
                const att = attendanceMap[key];

                if (!att) return;

                if (att.status === "Present") {
                    present++;
                } else if (att.status === "Absent") {
                    absent++;
                } else if (att.status === "Leave") {
                    leave++;
                }
            });

            const empOvertime = overtimeMap[emp.id] || [];
            overtimeHours = empOvertime.reduce(
                (sum, row) => sum + Number(row.extra_hours || 0),
                0
            );

            const empLessHours = lessHoursMap[emp.id] || [];
            lessHours = empLessHours.reduce(
                (sum, row) => sum + Number(row.less_hours || 0),
                0
            );

            const advances = advanceMap[emp.id] || [];
            const totalAdvance = advances.reduce(
                (sum, a) => sum + parseFloat(a.amount),
                0
            );

            const monthDays = new Date(
                new Date(startDate).getFullYear(),
                new Date(startDate).getMonth() + 1,
                0
            ).getDate();

            const perDaySalary = Number(emp.basic_salary) / monthDays;
            const perHourSalary = perDaySalary / requiredHoursPerDay;

            // LEAVE ADJUSTMENT
            let unpaidLeave = 0;
            let leaveAdjustmentDetails = [];

            const empLeaveSummary = leaveSummaryMap[emp.id] || [];
            const totalLeaveTaken = leave;

            if (totalLeaveTaken > 0) {
                const totalEntitlement = empLeaveSummary.reduce(
                    (sum, row) => sum + Number(row.total_entitlement || 0),
                    0
                );

                const carryForward = empLeaveSummary.reduce(
                    (sum, row) => sum + Number(row.carry_forward || 0),
                    0
                );

                const totalAvailable = totalEntitlement + carryForward;

                if (totalLeaveTaken > totalAvailable) {
                    unpaidLeave = totalLeaveTaken - totalAvailable;
                }

                leaveAdjustmentDetails.push({
                    total_entitlement: totalEntitlement,
                    carry_forward: carryForward,
                    leave_taken: totalLeaveTaken,
                    unpaid_leave: unpaidLeave,
                    leave_pending: Math.max(totalAvailable - totalLeaveTaken, 0),
                });
            }

            const absentDeduction = absent * perDaySalary;
            const leaveDeduction = unpaidLeave * perDaySalary;
            const lateDeduction = lessHours * perHourSalary;
            const overtimeAddition = overtimeHours * perHourSalary;

            const totalDeduction =
                absentDeduction + leaveDeduction + lateDeduction;

            let grossSalary = Number(emp.basic_salary);
            const componentsBreakup = [];

            for (const comp of componentsList) {
                const perc = Number(comp.employee_percentage) || 0;
                const amount = (grossSalary * perc) / 100;

                componentsBreakup.push({
                    name: comp.name,
                    type: comp.component_type,
                    percentage: perc,
                    amount: comp.component_type === "Allowance" ? amount : -amount,
                });

                if (comp.component_type === "Allowance") {
                    grossSalary += amount;
                } else if (comp.component_type === "Deduction") {
                    grossSalary -= amount;
                }
            }

            const netSalary =
                grossSalary - totalDeduction - totalAdvance + overtimeAddition;

            // Check paid status
            const salaryStatus = salaryStatusMap[emp.id] || {
                paid: false,
                paid_date: null
            };

            return {
                employee_id: emp.id,
                full_name: emp.full_name,
                department: emp.department,
                basic_salary: Number(emp.basic_salary).toFixed(2),
                shift_hours_per_day: requiredHoursPerDay.toFixed(2),
                total_present: present,
                total_absent: absent,
                total_leave: leave,
                total_overtime_hours: overtimeHours.toFixed(2),
                overtime_addition: overtimeAddition.toFixed(2),
                total_late_hours: lessHours.toFixed(2),
                late_deduction: lateDeduction.toFixed(2),
                total_advance: totalAdvance.toFixed(2),
                absent_deduction: absentDeduction.toFixed(2),
                leave_deduction: leaveDeduction.toFixed(2),
                total_deduction: totalDeduction.toFixed(2),
                gross_salary: grossSalary.toFixed(2),
                net_salary: netSalary.toFixed(2),
                paid: salaryStatus.paid,
                paid_date: salaryStatus.paid_date,
                components_breakup: componentsBreakup.map((c) => ({
                    name: c.name,
                    type: c.type,
                    percentage: c.percentage.toFixed(2),
                    amount: isFinite(c.amount) ? c.amount.toFixed(2) : "0.00",
                })),
                leave_adjustment_details: leaveAdjustmentDetails,
            };
        });

        res.json(report);
    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Failed to fetch report.",
            error: error.message,
        });
    }
};




const saveSalaryReport = async (req, res) => {
    try {
        const {
            employeeId,
            year,
            month,
            basicSalary,
            grossSalary,
            netSalary,
            totalAllowances,
            totalDeductions,
            absentDeduction,
            leaveDeduction,
            lateDeduction,
            overtimeAddition,
            totalAdvance,
            paid
        } = req.body;

        // Check if salary report already exists
        const check = await pool.query(
            `SELECT id FROM employee_salary_reports
       WHERE employee_id = $1 AND year = $2 AND month = $3`,
            [employeeId, year, month]
        );

        if (check.rows.length > 0) {
            // UPDATE existing record
            await pool.query(
                `UPDATE employee_salary_reports
         SET 
            basic_salary = $1,
            gross_salary = $2,
            net_salary = $3,
            total_allowances = $4,
            total_deductions = $5,
            absent_deduction = $6,
            leave_deduction = $7,
            late_deduction = $8,
            overtime_addition = $9,
            total_advance = $10,
            paid = $11,
            paid_date = CASE WHEN $11 THEN NOW() ELSE NULL END
         WHERE employee_id = $12 AND year = $13 AND month = $14`,
                [
                    basicSalary,
                    grossSalary,
                    netSalary,
                    totalAllowances,
                    totalDeductions,
                    absentDeduction,
                    leaveDeduction,
                    lateDeduction,
                    overtimeAddition,
                    totalAdvance,
                    paid,
                    employeeId,
                    year,
                    month
                ]
            );
        } else {
            // INSERT new record
            await pool.query(
                `INSERT INTO employee_salary_reports
         (
           employee_id,
           year,
           month,
           basic_salary,
           gross_salary,
           net_salary,
           total_allowances,
           total_deductions,
           absent_deduction,
           leave_deduction,
           late_deduction,
           overtime_addition,
           total_advance,
           paid,
           paid_date
         )
         VALUES
         (
           $1, $2, $3,
           $4, $5, $6,
           $7, $8, $9, $10, $11, $12,
           $13, $14,
           CASE WHEN $14 THEN NOW() ELSE NULL END
         )`,
                [
                    employeeId,
                    year,
                    month,
                    basicSalary,
                    grossSalary,
                    netSalary,
                    totalAllowances,
                    totalDeductions,
                    absentDeduction,
                    leaveDeduction,
                    lateDeduction,
                    overtimeAddition,
                    totalAdvance,
                    paid
                ]
            );
        }

        res.json({ message: "Salary report saved successfully." });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: "Failed to save salary report." });
    }
};




const updateRequestStatus = async (req, res) => {
    try {
        const requestId = req.params.id;
        const { status, request_type } = req.body;

        if (request_type === 'Advance') {
            await pool.query(
                `UPDATE salary_advances
         SET status = $1
         WHERE id = $2`,
                [status, requestId]
            );
        } else {
            await pool.query(
                `UPDATE employee_requests
         SET status = $1
         WHERE id = $2`,
                [status, requestId]
            );
        }

        res.json({ message: 'Request updated' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to update request' });
    }
};


module.exports = {
    createEmployeeRequest,
    getPendingRequests,
    updateRequestStatus,
    getAllRequests,
    getAttendanceAdvanceReport, saveSalaryReport
};


// CREATE TABLE employee_requests (
//   id SERIAL PRIMARY KEY,
//   employee_id INTEGER REFERENCES employees(id),
//   request_type TEXT,
//   reason TEXT,
//   date DATE
// );

//ALTER TABLE attendance ADD   employee_id INTEGER REFERENCES employees(id)
//ALTER TABLE salary_advances ADD   employee_id INTEGER REFERENCES employees(id)
//ALTER TABLE employee_requests ADD COLUMN status VARCHAR(20) DEFAULT 'Pending';

// CREATE TABLE salary_components (
//     id SERIAL PRIMARY KEY,
//     component_name VARCHAR(50) NOT NULL,
//     component_type VARCHAR(20) CHECK (component_type IN ('Deduction', 'Allowance')),
//     employee_percentage NUMERIC(5,2),
//     employer_percentage NUMERIC(5,2),
//     remarks TEXT
// );
