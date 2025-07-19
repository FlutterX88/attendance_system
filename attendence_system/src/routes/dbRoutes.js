const express = require('express');
const router = express.Router();
const { registerEmployee } = require('../controller/employeeController');
const { markAttendance, gridSummary, attendanceDetails

} = require('../controller/attendanceController');
const { giveSalaryAdvance } = require('../controller/salaryAdvanceController');
const { getDashboardStats } = require('../controller/dashboardController');
const { getownDashboardStats } = require('../controller/ownerdashController');
const { getAllEmployees } = require('../controller/emplistController');
const { getEmployeeDetail } = require('../controller/empdetailController');
const { createEmployeeRequest } = require('../controller/employeeRequestController');
const { getPendingRequests } = require('../controller/employeeRequestController');
const { updateRequestStatus } = require('../controller/employeeRequestController');
const { getAllRequests } = require('../controller/employeeRequestController');
const { getAttendanceAdvanceReport, saveSalaryReport } = require('../controller/employeeRequestController');
const { getSalaryComponents } = require('../controller/salarycomponentsController');
const { createSalaryComponents } = require('../controller/salarycomponentsController');
const { updateSalaryComponent } = require('../controller/salarycomponentsController');
const { deleteSalaryComponent } = require('../controller/salarycomponentsController');
const { getWorkHoursSummary } = require('../controller/employeeController');
const { upsertWorkHours } = require('../controller/employeeController');
const { getLeaveSummary } = require('../controller/employeeController');
const { takeLeave } = require('../controller/employeeController');
const { upsertEmployeeLeave } = require('../controller/employeeController');
const { incrementWorkedHours } = require('../controller/employeeController');
const { saveLeaveSummary } = require('../controller/employeeController');
const { saveWorkSummary } = require('../controller/employeeController');
const { getAllLeaveAndWorkSummary } = require('../controller/employeeController');
const { checkAttendance } = require('../controller/attendanceController');
const { getAttendanceAdvancedetailReport } = require('../controller/attendancereportController');
const {
    addShift,
    updateShift,
    deleteShift,
    getAllShifts,
    checkShift
} = require('../controller/shiftController');
const { registerUser, loginUser, forgotPassword, requestPassword } = require('../controller/loginController');




router.post('/register', registerEmployee);
router.post('/attendance', markAttendance);
router.post('/advance', giveSalaryAdvance);
router.get('/dashboard', getDashboardStats);
router.get('/owndashboard', getownDashboardStats);
router.get('/emplist', getAllEmployees);
router.get('/employeeinfo/:id/detail', getEmployeeDetail);
router.post('/request', createEmployeeRequest);
router.get('/requests', getPendingRequests);
router.put('/requests/:id', updateRequestStatus);
router.get('/all-requests', getAllRequests);
router.get('/all-attendance-advance-report', getAttendanceAdvanceReport);
router.get('/salary-components', getSalaryComponents);
router.post('/salary-components', createSalaryComponents);
router.put('/salary-components/:id', updateSalaryComponent);
router.delete('/salary-components/:id', deleteSalaryComponent);
router.post('/leave', upsertEmployeeLeave);
router.post('/leave/take', takeLeave);
router.get('/leave/summary/:employeeId', getLeaveSummary);
router.post('/workhours', upsertWorkHours);
router.post('/workhours/increment', incrementWorkedHours);
router.get('/workhours/summary/:employeeId', getWorkHoursSummary);
router.post('/leave/summary', saveLeaveSummary);
router.post('/workhours/summary', saveWorkSummary);
router.get('/all-leave-work-summary', getAllLeaveAndWorkSummary);
router.get('/attendance/check', checkAttendance);
router.post('/shift', addShift);
router.put('/shift/:id', updateShift);
router.delete('/shift/:id', deleteShift);
router.get('/shift', getAllShifts);
router.get('/employee/shift/check', checkShift);
router.post('/salary/pay', saveSalaryReport);
router.get('/attendance/advance-report', getAttendanceAdvancedetailReport);
router.get('/attendance/grid-summary', gridSummary);
router.get('/attendance/details', attendanceDetails);
router.post('/auth/register', registerUser);
router.post('/auth/login', loginUser);
router.post('/auth/forgot-password', forgotPassword);
router.post('/auth/forgot-password-request', requestPassword);

module.exports = router


// CREATE TABLE employee_requests (
//   id SERIAL PRIMARY KEY,
//   employee_id INTEGER REFERENCES employees(id),
//   request_type TEXT,
//   reason TEXT,
//   date DATE
// );

//npm install exceljs --save