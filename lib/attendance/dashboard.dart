import 'dart:convert';

import 'package:attendance_system/attendance/AdminAllLeaveWorkSummaryScreen.dart';
import 'package:attendance_system/attendance/AttendanceSummaryScreen.dart';
import 'package:attendance_system/attendance/SalaryComponentsViewScreen.dart';
import 'package:attendance_system/attendance/admin_leave_work_screen.dart';
import 'package:attendance_system/attendance/attendanceEntryForm.dart';
import 'package:attendance_system/attendance/employeeShiftScreen.dart';
import 'package:attendance_system/attendance/employeescreen.dart';
import 'package:attendance_system/attendance/loginScreen.dart';
import 'package:attendance_system/attendance/pending_request.dart';
import 'package:attendance_system/attendance/registration_screen.dart';
import 'package:attendance_system/attendance/report.dart';
import 'package:attendance_system/attendance/salary_advance_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic> dashboardData = {};
  String? userName;
  String? userRole;
  String? loginTime;

  @override
  void initState() {
    super.initState();
    loadSession();
    fetchDashboardData();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('full_name') ?? "";
      userRole = prefs.getString('role') ?? "";
      loginTime = prefs.getString('login_time');
    });
  }

  Future<void> fetchDashboardData() async {
    final url = Uri.parse('http://localhost:3000/api/employee/owndashboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          dashboardData = jsonData;
          isLoading = false;
        });
      } else {
        debugPrint("Failed to load dashboard data");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  String formatLoginTime(String? time) {
    if (time == null || time.isEmpty) return "Unknown";
    final dt = DateTime.parse(time);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        centerTitle: true,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userName != null && userName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Logged in as: $userName ($userRole) at ${formatLoginTime(loginTime)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          _buildSectionTitle("Today's Summary"),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildTile(
                                title: "Total Employees",
                                value:
                                    dashboardData['totalEmployees'].toString(),
                                icon: Icons.people_alt,
                                color: Colors.indigo,
                              ),
                              _buildTile(
                                title: "Present Today",
                                value: dashboardData['presentToday'].toString(),
                                icon: Icons.person,
                                color: Colors.green,
                              ),
                              _buildTile(
                                title: "Absent Today",
                                value: dashboardData['absentToday'].toString(),
                                icon: Icons.person,
                                color: Colors.red,
                              ),
                              _buildTile(
                                title: "On Leave Today",
                                value: dashboardData['leaveToday'].toString(),
                                icon: Icons.beach_access,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Monthly Stats"),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildTile(
                                title: "Total Salary Paid",
                                value:
                                    "₹${dashboardData['totalSalaryThisMonth']}",
                                icon: Icons.attach_money,
                                color: Colors.teal,
                              ),
                              _buildTile(
                                title: "Total Advances",
                                value:
                                    "₹${dashboardData['totalAdvanceThisMonth']}",
                                icon: Icons.account_balance_wallet,
                                color: Colors.purple,
                              ),
                              _buildTile(
                                title: "Total Work Hours",
                                value:
                                    "${dashboardData['totalOvertimeThisMonth']} hrs",
                                icon: Icons.timelapse,
                                color: Colors.blue,
                              ),
                              _buildTile(
                                title: "Late Marks Today",
                                value:
                                    dashboardData['totalLateToday'].toString(),
                                icon: Icons.warning_amber,
                                color: Colors.deepOrange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (dashboardData['recentEmployees']?.isNotEmpty ??
                              false)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    "Recently Registered Employees"),
                                const SizedBox(height: 12),
                                ...dashboardData['recentEmployees']
                                    .map<Widget>((emp) {
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    elevation: 1,
                                    child: ListTile(
                                      leading: const Icon(Icons.person,
                                          color: Colors.indigo),
                                      title: Text(
                                        emp['full_name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(emp['department']),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text("Joined"),
                                          Text(
                                            emp['join_date'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          const SizedBox(height: 32),
                          if (dashboardData['recentAdvances']?.isNotEmpty ??
                              false)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Recent Salary Advances"),
                                const SizedBox(height: 12),
                                ...dashboardData['recentAdvances']
                                    .map<Widget>((adv) {
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    elevation: 1,
                                    child: ListTile(
                                      leading: const Icon(Icons.attach_money,
                                          color: Colors.green),
                                      title: Text(
                                        adv['employee_name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                          "₹${adv['amount']} • ${adv['payment_mode']}"),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text("Date"),
                                          Text(
                                            adv['date'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 220,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              "Owner Panel",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _drawerItem(Icons.dashboard, "Dashboard", () {
            Navigator.pop(context);
          }),
          _drawerItem(Icons.summarize, "Attendance Summary", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendanceSummaryScreen()));
          }),
          _drawerItem(Icons.schedule, "Shift Assign", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EmployeeShiftScreen()));
          }),
          _drawerItem(Icons.beach_access, "All Leave Work Summary", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminAllLeaveWorkSummaryScreen()));
          }),
          _drawerItem(Icons.admin_panel_settings, "Assign Leave", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminAssignLeaveWorkScreen()));
          }),
          _drawerItem(Icons.percent, "Salary Components View", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SalaryComponentsViewScreen()));
          }),
          _drawerItem(Icons.list_alt, "Employee List", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EmployeeListScreen()));
          }),
          _drawerItem(Icons.app_registration, "Registration", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegistrationScreen()));
          }),
          _drawerItem(Icons.lock_clock, "Attendance Entry", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AttendanceEntryForm()));
          }),
          _drawerItem(Icons.leaderboard, "Salary Advance Entry", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalaryAdvanceForm()));
          }),
          _drawerItem(Icons.report, "Pending Request", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PendingRequestsScreen()));
          }),
          _drawerItem(Icons.report, "Salary Report", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendanceAdvanceReportScreen()));
          }),
          _drawerItem(Icons.logout, "Logout", () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      onTap: onTap,
    );
  }
}
