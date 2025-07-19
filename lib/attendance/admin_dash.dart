// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pms_plus/attendance/attendanceEntryForm.dart';
import 'package:pms_plus/attendance/salary_advance_form.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'employeescreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedPeriod = 'Daily';
  Map<String, Map<String, String>> data = {'Daily': {}, 'Monthly': {}};
  int totalEmployees = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData(selectedPeriod);
  }

  Future<void> fetchDashboardData(String period) async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        'http://localhost:3000/api/employee/dashboard?period=${period.toLowerCase()}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          totalEmployees = json['totalEmployees'];
          data[period] = {
            'present': '${json['present']} Present',
            'absent': '${json['absent']} Absent',
            'leave': '${json['leave']} On Leave',
            'overtime': '${json['overtime']} Overtime',
            'late': '${json['late']} Late Marks',
            'advance': '${json['advance']} Salary Advance',
          };
        });
      } else {
        debugPrint('Failed to load dashboard data');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentData = data[selectedPeriod] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("Admin Dashboard",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E3B55),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AttendanceEntryForm()));
              },
              icon: const Icon(Icons.cake_sharp)),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalaryAdvanceForm()));
              },
              icon: const Icon(Icons.extension))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("Total Employees",
                          totalEmployees.toString(), Colors.indigo),
                      _buildStatCard("Leaves", currentData['leave'] ?? '-',
                          Colors.deepPurple),
                      _buildStatCard("Salary Advances",
                          currentData['advance'] ?? '-', Colors.teal),
                      _buildStatCard("Late Marks", currentData['late'] ?? '-',
                          Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: selectedPeriod,
                    items: ['Daily', 'Monthly']
                        .map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedPeriod = newValue!;
                      });
                      fetchDashboardData(selectedPeriod);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Attendance Overview",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Expanded(
                            child: SfCircularChart(
                              legend: const Legend(
                                  isVisible: true,
                                  overflowMode: LegendItemOverflowMode.wrap),
                              series: <CircularSeries<ChartData, String>>[
                                PieSeries<ChartData, String>(
                                  dataSource: [
                                    ChartData(
                                        'Present',
                                        double.tryParse(currentData['present']
                                                    ?.split(' ')
                                                    .first ??
                                                '0') ??
                                            0),
                                    ChartData(
                                        'Absent',
                                        double.tryParse(currentData['absent']
                                                    ?.split(' ')
                                                    .first ??
                                                '0') ??
                                            0),
                                    ChartData(
                                        'On Leave',
                                        double.tryParse(currentData['leave']
                                                    ?.split(' ')
                                                    .first ??
                                                '0') ??
                                            0),
                                  ],
                                  xValueMapper: (ChartData data, _) =>
                                      data.status,
                                  yValueMapper: (ChartData data, _) =>
                                      data.count,
                                  dataLabelSettings:
                                      const DataLabelSettings(isVisible: true),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 10),
                          const Text("Attendance Status",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildStatusRow(
                              today: currentData['present'] ?? '-',
                              absent: currentData['absent'] ?? '-',
                              leave: currentData['leave'] ?? '-'),
                          const SizedBox(height: 16),
                          _buildStatusRow(
                              today: currentData['overtime'] ?? '-',
                              absent: '0 hours',
                              leave: '0 hours'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Employees"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
        onTap: (inx) {
          if (inx == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EmployeeListScreen()));
          }
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 14, color: Colors.blue.shade700)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      {required String today, required String absent, required String leave}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusCard(today, Colors.green),
        _buildStatusCard(absent, Colors.red),
        _buildStatusCard(leave, Colors.orange),
      ],
    );
  }

  Widget _buildStatusCard(String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        ),
      ),
    );
  }
}

class ChartData {
  final String status;
  final double count;
  ChartData(this.status, this.count);
}
