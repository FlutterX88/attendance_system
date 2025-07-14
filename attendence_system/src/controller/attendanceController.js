const pool = require('../config/db');


function to24Hour(timeStr) {
    if (!timeStr) return null;
    try {
        const [time, modifier] = timeStr.split(" ");
        let [hours, minutes] = time.split(":").map(Number);

        if (modifier && modifier.toUpperCase() === "PM" && hours < 12) {
            hours += 12;
        }
        if (modifier && modifier.toUpperCase() === "AM" && hours === 12) {
            hours = 0;
        }
        return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}`;
    } catch (e) {
        console.error("Invalid time format:", timeStr);
        return null;
    }
}


const markAttendance = async (req, res) => {
    try {
        const {
            employeeName,
            employee_id,
            date,
            inTime,
            outTime,
            status,
        } = req.body;

        console.log("markAttendance called");

        // Check if attendance already exists
        const check = await pool.query(
            `SELECT id, in_time, out_time
             FROM attendance
             WHERE employee_id = $1 AND date = $2`,
            [employee_id, date]
        );

        if (check.rows.length === 0) {
            console.log("Inserting new attendance…");
            await pool.query(
                `INSERT INTO attendance
                 (employee_name, employee_id, date, in_time, out_time, status)
                 VALUES ($1, $2, $3, $4, $5, $6)`,
                [employeeName, employee_id, date, inTime || null, outTime || null, status]
            );
            return res.status(201).json({ message: "Attendance recorded" });
        } else {
            const existing = check.rows[0];

            if (existing.out_time) {
                console.log("Attendance already completed for this day.");
                return res.status(400).json({
                    message: "Attendance already completed for this day.",
                });
            }

            if (!outTime) {
                return res.status(400).json({
                    message: "Please provide Out Time.",
                });
            }

            // Update out_time
            await pool.query(
                `UPDATE attendance
                 SET out_time = $1
                 WHERE id = $2`,
                [outTime, existing.id]
            );

            // Compute worked hours
            const { in_time } = existing;
            const inTime24 = to24Hour(in_time);
            const outTime24 = to24Hour(outTime);

            if (!inTime24 || !outTime24) {
                return res.status(400).json({
                    message: "Time conversion failed.",
                });
            }

            const workedHours = (
                (new Date(`1970-01-01T${outTime24}:00Z`) -
                    new Date(`1970-01-01T${inTime24}:00Z`)) /
                (1000 * 60 * 60)
            ).toFixed(2);

            console.log("Worked Hours:", workedHours);

            if (workedHours < 0) {
                return res.status(400).json({
                    message: "Worked hours calculation failed.",
                });
            }

            // Get employee required daily work hours
            const empRow = await pool.query(
                `SELECT required_work_hours_daily
                 FROM employees
                 WHERE id = $1`,
                [employee_id]
            );

            const requiredHours = parseFloat(empRow.rows[0]?.required_work_hours_daily) || 0;

            let lessHours = 0;
            let extraHours = 0;

            if (workedHours < requiredHours) {
                lessHours = parseFloat((requiredHours - workedHours).toFixed(2));
                console.log("Less hours:", lessHours);

                await pool.query(
                    `INSERT INTO employee_less_hours
                     (employee_id, date, required_hours, worked_hours, less_hours)
                     VALUES ($1, $2, $3, $4, $5)`,
                    [employee_id, date, requiredHours, workedHours, lessHours]
                );
            } else if (workedHours > requiredHours) {
                extraHours = parseFloat((workedHours - requiredHours).toFixed(2));
                console.log("Overtime hours:", extraHours);

                await pool.query(
                    `INSERT INTO employee_overtime
                     (employee_id, date, extra_hours)
                     VALUES ($1, $2, $3)`,
                    [employee_id, date, extraHours]
                );
            }

            // Update monthly summary
            const dateObj = new Date(date);
            const year = dateObj.getFullYear();
            const month = dateObj.getMonth() + 1;

            const checkSummary = await pool.query(
                `SELECT id FROM employee_work_summary
                 WHERE employee_id = $1 AND year = $2 AND month = $3`,
                [employee_id, year, month]
            );

            if (checkSummary.rows.length > 0) {
                await pool.query(
                    `UPDATE employee_work_summary
                     SET worked_hours = worked_hours + $1
                     WHERE employee_id = $2 AND year = $3 AND month = $4`,
                    [workedHours, employee_id, year, month]
                );
            } else {
                await pool.query(
                    `INSERT INTO employee_work_summary
                     (employee_id, year, month, worked_hours)
                     VALUES ($1, $2, $3, $4)`,
                    [employee_id, year, month, workedHours]
                );
            }

            return res.json({
                message: "Out time updated and worked hours processed.",
                workedHours,
                lessHours,
                extraHours,
            });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Failed to mark attendance.",
            error: error.message,
        });
    }
};



const checkAttendance = async (req, res) => {
    try {
        const { employeeId, date } = req.query;

        const result = await pool.query(
            `
      SELECT id, status, in_time, out_time
      FROM attendance
      WHERE employee_id = $1 AND date = $2
      `,
            [employeeId, date]
        );

        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.json(null);
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Failed to check attendance." });
    }
};

module.exports = { markAttendance, checkAttendance };


//ALTER TABLE attendance
//ALTER COLUMN out_time DROP NOT NULL;
// ALTER TABLE attendance
// ALTER COLUMN in_time DROP NOT NULL;



// CREATE TABLE employee_shifts (
//     id SERIAL PRIMARY KEY,
//     employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
//     shift_name VARCHAR(50),
//     start_time TIME NOT NULL,
//     end_time TIME NOT NULL,
//     shift_type VARCHAR(20) DEFAULT 'Day'   -- e.g. 'Day', 'Night'
// );

// CREATE TABLE employee_less_hours (
//     id SERIAL PRIMARY KEY,
//     employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
//     date DATE NOT NULL,
//     required_hours NUMERIC(5,2) NOT NULL,
//     worked_hours NUMERIC(5,2) NOT NULL,
//     less_hours NUMERIC(5,2) NOT NULL
// );


// CREATE TABLE employee_overtime (
//     id SERIAL PRIMARY KEY,
//     employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
//     date DATE NOT NULL,
//     extra_hours NUMERIC(5,2) NOT NULL
// );
