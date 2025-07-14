const pool = require('../config/db');

const getSalaryComponents = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM salary_components
            ORDER BY name
        `);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch components' });
    }
};

const createSalaryComponents = async (req, res) => {
    try {
        const { components } = req.body;

        if (!Array.isArray(components)) {
            return res.status(400).json({
                message: "components must be an array."
            });
        }

        const errors = [];
        for (const comp of components) {
            const {
                name,
                component_type,
                employee_percentage,
                employer_percentage,
                remarks,
                active
            } = comp;

            if (!name?.trim() || !component_type?.trim()) {
                errors.push({
                    message: "name and component_type are required.",
                    comp
                });
                continue; // skip this invalid component, but continue processing others
            }

            // check if the component already exists (by name)
            const result = await pool.query(
                `
        SELECT id FROM salary_components
        WHERE LOWER(name) = LOWER($1)
      `,
                [name]
            );

            if (result.rows.length > 0) {
                // UPDATE
                const id = result.rows[0].id;
                await pool.query(
                    `
          UPDATE salary_components
          SET
            component_type = $1,
            employee_percentage = $2,
            employer_percentage = $3,
            remarks = $4,
            active = $5,
            updated_at = now()
          WHERE id = $6
        `,
                    [
                        component_type,
                        employee_percentage || 0,
                        employer_percentage || 0,
                        remarks || null,
                        active ?? true,
                        id
                    ]
                );
            } else {
                // INSERT
                await pool.query(
                    `
          INSERT INTO salary_components
            (name, component_type, employee_percentage, employer_percentage, remarks, active)
          VALUES ($1, $2, $3, $4, $5, $6)
        `,
                    [
                        name,
                        component_type,
                        employee_percentage || 0,
                        employer_percentage || 0,
                        remarks || null,
                        active ?? true
                    ]
                );
            }
        }

        if (errors.length > 0) {
            return res.status(400).json({
                message: "Some components could not be saved.",
                errors
            });
        }

        res.status(201).json({
            message: "Components saved successfully."
        });
    } catch (error) {
        console.error(error);
        res
            .status(500)
            .json({ message: "Failed to save components.", error: error.message });
    }
};


const updateSalaryComponent = async (req, res) => {
    try {
        const id = req.params.id;
        const {
            name,
            component_type,
            employee_percentage,
            employer_percentage,
            remarks,
            active
        } = req.body;

        await pool.query(`
            UPDATE salary_components
            SET
                name = $1,
                component_type = $2,
                employee_percentage = $3,
                employer_percentage = $4,
                remarks = $5,
                active = $6,
                updated_at = now()
            WHERE id = $7
        `, [
            name,
            component_type,
            employee_percentage || 0,
            employer_percentage || 0,
            remarks || null,
            active,
            id
        ]);

        res.json({ message: 'Component updated' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to update component' });
    }
};

const deleteSalaryComponent = async (req, res) => {
    try {
        const id = req.params.id;

        await pool.query(`
            DELETE FROM salary_components
            WHERE id = $1
        `, [id]);

        res.json({ message: 'Component deleted' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to delete component' });
    }
};

module.exports = {
    getSalaryComponents,
    createSalaryComponents,
    updateSalaryComponent,
    deleteSalaryComponent
};
