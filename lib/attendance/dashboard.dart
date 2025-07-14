import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:attendance_system/attendance/AdminAllLeaveWorkSummaryScreen.dart';
import 'package:attendance_system/attendance/SalaryComponentsViewScreen.dart';
import 'package:attendance_system/attendance/admin_leave_work_screen.dart';
import 'package:attendance_system/attendance/attendanceEntryForm.dart';
import 'package:attendance_system/attendance/employeeShiftScreen.dart';
import 'package:attendance_system/attendance/employeescreen.dart';
import 'package:attendance_system/attendance/history.dart';
import 'package:attendance_system/attendance/pending_request.dart';
import 'package:attendance_system/attendance/registration_screen.dart';
import 'package:attendance_system/attendance/report.dart';
import 'package:attendance_system/attendance/salary_advance_form.dart';
import 'package:attendance_system/attendance/salarycomponentsmaster.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic> dashboardData = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
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
        print(response.body);
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
              tooltip: "Shift Assign",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EmployeeShiftScreen()));
              },
              icon: const Icon(Icons.shopify)),
          IconButton(
              tooltip: "All leave work summery",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AdminAllLeaveWorkSummaryScreen()));
              },
              icon: const Icon(Icons.monitor)),
          IconButton(
              tooltip: "Assign Leave",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AdminAssignLeaveWorkScreen()));
              },
              icon: const Icon(Icons.admin_panel_settings)),
          IconButton(
              tooltip: "Salary Components View",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const SalaryComponentsViewScreen()));
              },
              icon: const Icon(Icons.percent)),
          IconButton(
              tooltip: "Salary Components Add",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalaryComponentsMaster()));
              },
              icon: const Icon(Icons.compost_outlined)),
          IconButton(
              tooltip: "Salary Report",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AttendanceAdvanceReportScreen()));
              },
              icon: const Icon(Icons.report)),
          IconButton(
              tooltip: "ALL Request",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllRequestsScreen()));
              },
              icon: const Icon(Icons.report_gmailerrorred)),
          IconButton(
              tooltip: "Pending Request",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PendingRequestsScreen()));
              },
              icon: const Icon(Icons.request_page)),
          IconButton(
              tooltip: "Registration Screen",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()));
              },
              icon: const Icon(Icons.app_registration)),
          IconButton(
              tooltip: "Attendance Entry",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AttendanceEntryForm()));
              },
              icon: const Icon(Icons.lock_clock)),
          IconButton(
              tooltip: "Employee List",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EmployeeListScreen()));
              },
              icon: const Icon(Icons.list_alt)),
          IconButton(
              tooltip: "Salary Advance Entry",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalaryAdvanceForm()));
              },
              icon: const Icon(Icons.leaderboard))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                          "Total Employees",
                          dashboardData['totalEmployees'].toString(),
                          Colors.indigo),
                      _buildStatCard(
                          "Present Today",
                          dashboardData['presentToday'].toString(),
                          Colors.green),
                      _buildStatCard("Absent Today",
                          dashboardData['absentToday'].toString(), Colors.red),
                      _buildStatCard(
                          "On Leave Today",
                          dashboardData['leaveToday'].toString(),
                          Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard("Total Salary Paid This Month",
                      "₹${dashboardData['totalSalaryThisMonth']}", Colors.teal),
                  _buildInfoCard(
                      "Total Advances Given This Month",
                      "₹${dashboardData['totalAdvanceThisMonth']}",
                      Colors.purple),
                  _buildInfoCard(
                      "Total Work Hours This Month",
                      "${dashboardData['totalOvertimeThisMonth']} hrs",
                      Colors.blue),
                  _buildInfoCard(
                      "Total Late Marks Today",
                      dashboardData['totalLateToday'].toString(),
                      Colors.deepOrange),
                  const SizedBox(height: 24),
                  Text("Recently Registered Employees",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  ...List.generate(
                      dashboardData['recentEmployees']?.length ?? 0, (index) {
                    final emp = dashboardData['recentEmployees'][index];
                    return ListTile(
                      title: Text(emp['full_name']),
                      subtitle: Text(emp['department']),
                      trailing: Text(emp['join_date']),
                    );
                  }),
                  const SizedBox(height: 24),
                  Text("Recent Salary Advances",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  ...List.generate(dashboardData['recentAdvances']?.length ?? 0,
                      (index) {
                    final adv = dashboardData['recentAdvances'][index];
                    return ListTile(
                      title: Text(adv['employee_name']),
                      subtitle:
                          Text("₹${adv['amount']} • ${adv['payment_mode']}"),
                      trailing: Text(adv['date']),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Text(value,
            style: TextStyle(
                fontSize: 16, color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
