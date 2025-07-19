// src/controller/attendancereportController.js

const pool = require('../config/db');
const ExcelJS = require('exceljs');
const path = require('path');

/** Validate and parse the incoming dates */
function validateDates(startDate, endDate) {
    if (!startDate || !endDate) {
        throw new Error(
            'Both startDate and endDate query parameters are required (as YYYY-MM-DD).'
        );
    }
    const s = new Date(startDate);
    const e = new Date(endDate);
    if (isNaN(s.getTime()) || isNaN(e.getTime())) {
        throw new Error(
            `Invalid date format. Expected “YYYY-MM-DD”, got startDate="${startDate}", endDate="${endDate}".`
        );
    }
    return { start: s, end: e };
}

/** Build the JSON report */
async function buildAttendanceAdvanceReport(startDate, endDate) {
    const { start, end } = validateDates(startDate, endDate);
    const year = start.getFullYear();
    const month = start.getMonth() + 1;

    // fetch master tables in parallel
    const [empRes, compRes, shiftRes, leaveSumRes] = await Promise.all([
        pool.query(`
      SELECT id, full_name, department, basic_salary
      FROM employees
      ORDER BY full_name
    `),
        pool.query(`
      SELECT *
      FROM salary_components
      WHERE active = true
    `),
        pool.query(`
      SELECT employee_id, start_time, end_time
      FROM employee_shifts
    `),
        pool.query(`
      SELECT employee_id, leave_type, year, total_entitlement, leave_taken, carry_forward
      FROM employee_leave_summary
      WHERE year = $1
    `, [year])
    ]);

    const employees = empRes.rows;
    const componentsList = compRes.rows;
    const shiftMap = Object.fromEntries(shiftRes.rows.map(r => [r.employee_id, r]));
    const leaveSummaryMap = leaveSumRes.rows.reduce((m, r) => {
        (m[r.employee_id] = m[r.employee_id] || []).push(r);
        return m;
    }, {});

    // fetch ranged data
    const [
        attRes, advRes, otRes, lhRes, salaryRptRes
    ] = await Promise.all([
        pool.query(`
      SELECT employee_id, date, status
      FROM attendance
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]),
        pool.query(`
      SELECT employee_id, amount
      FROM salary_advances
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]),
        pool.query(`
      SELECT employee_id, extra_hours
      FROM employee_overtime
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]),
        pool.query(`
      SELECT employee_id, less_hours
      FROM employee_less_hours
      WHERE date BETWEEN $1 AND $2
    `, [startDate, endDate]),
        pool.query(`
      SELECT employee_id, paid, paid_date
      FROM employee_salary_reports
      WHERE year = $1 AND month = $2
    `, [year, month])
    ]);

    // build quick lookup maps
    const attendanceMap = Object.fromEntries(
        attRes.rows.map(r => {
            const d = r.date.toISOString().split('T')[0];
            return [`${r.employee_id}_${d}`, r];
        })
    );
    const advanceMap = advRes.rows.reduce((m, r) => {
        (m[r.employee_id] = m[r.employee_id] || []).push(r);
        return m;
    }, {});
    const overtimeMap = otRes.rows.reduce((m, r) => {
        (m[r.employee_id] = m[r.employee_id] || []).push(r);
        return m;
    }, {});
    const lessHoursMap = lhRes.rows.reduce((m, r) => {
        (m[r.employee_id] = m[r.employee_id] || []).push(r);
        return m;
    }, {});
    const salaryStatusMap = Object.fromEntries(
        salaryRptRes.rows.map(r => [r.employee_id, { paid: r.paid, paid_date: r.paid_date }])
    );

    // build list of days in the range
    const days = [];
    for (let d = new Date(startDate); d <= new Date(endDate); d.setDate(d.getDate() + 1)) {
        days.push(d.toISOString().split('T')[0]);
    }

    // assemble per-employee
    const report = employees.map(emp => {
        // parse basic_salary into a number
        const basicSalaryNum = Number(emp.basic_salary) || 0;

        // count attendance statuses
        let present = 0, absent = 0, leaveCount = 0;
        days.forEach(d => {
            const row = attendanceMap[`${emp.id}_${d}`];
            if (!row) return;
            if (row.status === 'Present') present++;
            if (row.status === 'Absent') absent++;
            if (row.status === 'Leave') leaveCount++;
        });

        // determine required hours per day
        let reqHrs = 8;
        const shift = shiftMap[emp.id];
        if (shift) {
            let s = new Date(`2020-01-01T${shift.start_time}:00Z`);
            let e = new Date(`2020-01-01T${shift.end_time}:00Z`);
            let diff = (e - s) / (1000 * 60 * 60);
            if (diff < 0) diff += 24;
            reqHrs = diff || 8;
        }

        // overtime, late, advances
        const otHrs = (overtimeMap[emp.id] || []).reduce((s, r) => s + Number(r.extra_hours || 0), 0);
        const lhHrs = (lessHoursMap[emp.id] || []).reduce((s, r) => s + Number(r.less_hours || 0), 0);
        const advAmt = (advanceMap[emp.id] || []).reduce((s, r) => s + parseFloat(r.amount || 0), 0);

        // salary math
        const monthDays = new Date(year, month, 0).getDate();
        const perDay = basicSalaryNum / monthDays;
        const perHour = perDay / reqHrs;

        // leave adjustments
        const leaveSum = leaveSummaryMap[emp.id] || [];
        const totalEnt = leaveSum.reduce((s, r) => s + Number(r.total_entitlement || 0), 0);
        const carryFwd = leaveSum.reduce((s, r) => s + Number(r.carry_forward || 0), 0);
        const avail = totalEnt + carryFwd;
        const unpaid = Math.max(0, leaveCount - avail);
        const leaveAdj = [{
            total_entitlement: totalEnt,
            carry_forward: carryFwd,
            leave_taken: leaveCount,
            unpaid_leave: unpaid,
            leave_pending: Math.max(avail - leaveCount, 0)
        }];

        // components & gross/net salary
        let gross = basicSalaryNum;
        const comps = componentsList.map(c => {
            const pct = Number(c.employee_percentage) || 0;
            const amt = (gross * pct) / 100;
            gross += (c.component_type === 'Allowance') ? amt : -amt;
            return {
                name: c.name,
                type: c.component_type,
                percentage: pct.toFixed(2),
                amount: amt.toFixed(2)
            };
        });

        const deductions = absent * perDay + unpaid * perDay + lhHrs * perHour;
        const overtimeAdd = otHrs * perHour;
        const net = gross - deductions - advAmt + overtimeAdd;
        const status = salaryStatusMap[emp.id] || { paid: false, paid_date: null };

        return {
            employee_id: emp.id,
            full_name: emp.full_name,
            department: emp.department,
            basic_salary: basicSalaryNum.toFixed(2),
            shift_hours_per_day: reqHrs.toFixed(2),
            total_present: present,
            total_absent: absent,
            total_leave: leaveCount,
            total_overtime_hours: otHrs.toFixed(2),
            overtime_addition: overtimeAdd.toFixed(2),
            total_late_hours: lhHrs.toFixed(2),
            late_deduction: (lhHrs * perHour).toFixed(2),
            total_advance: advAmt.toFixed(2),
            absent_deduction: (absent * perDay).toFixed(2),
            leave_deduction: (unpaid * perDay).toFixed(2),
            total_deduction: deductions.toFixed(2),
            gross_salary: gross.toFixed(2),
            net_salary: net.toFixed(2),
            paid: status.paid,
            paid_date: status.paid_date,
            components_breakup: comps,
            leave_adjustment_details: leaveAdj
        };
    });

    return { report, componentsList, year, month };
}

/** Stream out an Excel file */
async function sendAttendanceReportExcel(res, report, componentsList, year, month) {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet(`${year}-${String(month).padStart(2, '0')}`);

    // base columns
    const baseCols = [
        { header: 'Employee ID', key: 'employee_id' },
        { header: 'Name', key: 'full_name' },
        { header: 'Department', key: 'department' },
        { header: 'Basic Salary', key: 'basic_salary' },
        { header: 'Shift Hrs/Day', key: 'shift_hours_per_day' },
        { header: 'Present', key: 'total_present' },
        { header: 'Absent', key: 'total_absent' },
        { header: 'Leave', key: 'total_leave' },
        { header: 'Overtime Hrs', key: 'total_overtime_hours' },
        { header: 'Overtime Addition', key: 'overtime_addition' },
        { header: 'Late Hrs', key: 'total_late_hours' },
        { header: 'Late Deduction', key: 'late_deduction' },
        { header: 'Total Advance', key: 'total_advance' },
        { header: 'Absent Deduction', key: 'absent_deduction' },
        { header: 'Leave Deduction', key: 'leave_deduction' },
        { header: 'Total Deduction', key: 'total_deduction' },
        { header: 'Gross Salary', key: 'gross_salary' },
        { header: 'Net Salary', key: 'net_salary' },
        { header: 'Paid', key: 'paid' },
        { header: 'Paid Date', key: 'paid_date' }
    ];
    const compCols = componentsList.flatMap(c => [
        { header: `${c.name} %`, key: `${c.name}_percentage` },
        { header: `${c.name} Amt`, key: `${c.name}_amount` }
    ]);
    const leaveCols = [
        { header: 'Entitlement', key: 'total_entitlement' },
        { header: 'Carry Forward', key: 'carry_forward' },
        { header: 'Leave Taken', key: 'leave_taken' },
        { header: 'Unpaid Leave', key: 'unpaid_leave' },
        { header: 'Leave Pending', key: 'leave_pending' }
    ];
    sheet.columns = [...baseCols, ...compCols, ...leaveCols];

    report.forEach(emp => {
        const row = { ...emp };
        emp.components_breakup.forEach(c => {
            row[`${c.name}_percentage`] = c.percentage;
            row[`${c.name}_amount`] = c.amount;
        });
        const la = emp.leave_adjustment_details[0] || {};
        leaveCols.forEach(col => row[col.key] = la[col.key] ?? 0);
        sheet.addRow(row);
    });

    res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
        'Content-Disposition',
        `attachment; filename="attendance_${year}_${month}.xlsx"`
    );
    await workbook.xlsx.write(res);
    res.end();
}

/** Express route handler */
async function getAttendanceAdvancedetailReport(req, res) {
    try {
        // coerce to strings
        const rawStart = req.query.startDate;
        const rawEnd = req.query.endDate;
        const startDate = Array.isArray(rawStart) ? rawStart[0] : String(rawStart);
        const endDate = Array.isArray(rawEnd) ? rawEnd[0] : String(rawEnd);
        const format = req.query.format;

        const { report, componentsList, year, month } =
            await buildAttendanceAdvanceReport(startDate, endDate);

        if (format === 'excel') {
            return await sendAttendanceReportExcel(res, report, componentsList, year, month);
        }
        res.json(report);
    } catch (err) {
        console.error('Error generating attendance report:', err.message);
        res.status(400).json({
            message: err.message,
            error: err.message
        });
    }
}

module.exports = {
    getAttendanceAdvancedetailReport,
    buildAttendanceAdvanceReport,
    sendAttendanceReportExcel
};


// CREATE TABLE users (
//     id SERIAL PRIMARY KEY,
//     full_name VARCHAR(100) NOT NULL,
//     email VARCHAR(150) UNIQUE NOT NULL,
//     password_hash TEXT NOT NULL,
//     role VARCHAR(20) NOT NULL CHECK (role IN ('employee', 'owner', 'hr', 'accounts')),
//     is_active BOOLEAN DEFAULT true,
//     created_at TIMESTAMP DEFAULT NOW(),
//     updated_at TIMESTAMP DEFAULT NOW()
// );

