const express = require('express');
const router = express.Router();
const dbRoutes = require('./dbRoutes');

router.use('/employee', dbRoutes);

module.exports = router;
