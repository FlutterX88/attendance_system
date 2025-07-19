
const bcrypt = require('bcrypt');
const pool = require('../config/db');

const registerUser = async (req, res) => {
    try {
        const { fullName, email, password, role } = req.body;

        if (!fullName || !email || !password || !role) {
            return res.status(400).json({ message: "All fields required." });
        }

        const hash = await bcrypt.hash(password, 10);

        await pool.query(
            `INSERT INTO users (full_name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)`,
            [fullName, email, hash, role]
        );

        res.json({ message: "Registration successful." });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: "Registration failed." });
    }
};



const loginUser = async (req, res) => {


    try {
        const { email, password } = req.body;

        const result = await pool.query(
            `SELECT id, full_name, email, password_hash, role
       FROM users
       WHERE email = $1 AND is_active = true`,
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ message: "Invalid email or password." });
        }

        const user = result.rows[0];
        const match = await bcrypt.compare(password, user.password_hash);

        if (!match) {
            return res.status(401).json({ message: "Invalid email or password." });
        }

        res.json({
            userId: user.id,
            fullName: user.full_name,
            email: user.email,
            role: user.role
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: "Login failed." });
    }


};


const forgotPassword = async (req, res) => {
    try {
        const { email, newPassword } = req.body;

        const result = await pool.query(
            `SELECT id FROM users WHERE email = $1`,
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "User not found." });
        }

        const hash = await bcrypt.hash(newPassword, 10);

        await pool.query(
            `UPDATE users
       SET password_hash = $1,
           updated_at = NOW()
       WHERE email = $2`,
            [hash, email]
        );

        res.json({ message: "Password reset successfully." });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: "Failed to reset password." });
    }

}

const requestPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ success: false, message: "Email is required." });
        }

        const result = await pool.query(
            `SELECT id FROM users WHERE email = $1`,
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "No user found with this email."
            });
        }

        // Here, you could generate a token and email it to the user.
        // For now, just return success.
        res.json({
            success: true,
            message: "Email exists. Proceed to reset."
        });

    } catch (e) {
        console.error(e);
        res.status(500).json({
            success: false,
            message: "Failed to check email."
        });
    }

}



module.exports = { registerUser, forgotPassword, loginUser, requestPassword };


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
