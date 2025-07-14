const pool = require('../config/db');


const addShift = async (req, res) => {
    try {
        const { employeeId, shiftName, startTime, endTime, shiftType } = req.body;

        if (!employeeId || !shiftName || !startTime || !endTime) {
            return res.status(400).json({
                message: "employeeId, shiftName, startTime and endTime are required."
            });
        }

        await pool.query(
            `INSERT INTO employee_shifts 
             (employee_id, shift_name, start_time, end_time, shift_type) 
             VALUES ($1, $2, $3, $4, $5)`,
            [employeeId, shiftName, startTime, endTime, shiftType || 'Day']
        );

        res.status(201).json({ message: 'Shift added successfully.' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to add shift.' });
    }
};


/**
 * Update shift by ID
 */
const updateShift = async (req, res) => {
    try {
        const { id } = req.params;
        const { shiftName, startTime, endTime, shiftType } = req.body;

        if (!shiftName || !startTime || !endTime) {
            return res.status(400).json({
                message: "shiftName, startTime and endTime are required."
            });
        }

        await pool.query(
            `UPDATE employee_shifts
             SET shift_name = $1,
                 start_time = $2,
                 end_time = $3,
                 shift_type = $4
             WHERE id = $5`,
            [shiftName, startTime, endTime, shiftType || 'Day', id]
        );

        res.json({ message: 'Shift updated successfully.' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to update shift.' });
    }
};


/**
 * Delete shift by ID
 */
const deleteShift = async (req, res) => {
    try {
        const { id } = req.params;

        await pool.query(
            `DELETE FROM employee_shifts WHERE id = $1`,
            [id]
        );

        res.json({ message: 'Shift deleted successfully.' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to delete shift.' });
    }
};


/**
 * Get list of all shifts (with employee names)
 */
const getAllShifts = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT 
                s.id, 
                s.employee_id, 
                e.full_name, 
                s.shift_name, 
                s.start_time, 
                s.end_time, 
                s.shift_type
             FROM employee_shifts s
             JOIN employees e ON s.employee_id = e.id
             ORDER BY s.id DESC`
        );

        res.json(result.rows);

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch shifts.' });
    }
};


/**
 * Check shift by employee (like your checkShift format)
 */
const checkShift = async (req, res) => {
    try {
        const { employeeId, date } = req.query;

        if (!employeeId || !date) {
            return res.status(400).json({ message: "employeeId and date are required." });
        }

        const result = await pool.query(
            `SELECT id, shift_name, start_time, end_time, shift_type
             FROM employee_shifts
             WHERE employee_id = $1`,
            [employeeId]
        );

        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.json(null);
        }

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Failed to check shift." });
    }
};


module.exports = {
    addShift,
    updateShift,
    deleteShift,
    getAllShifts,
    checkShift
};



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
