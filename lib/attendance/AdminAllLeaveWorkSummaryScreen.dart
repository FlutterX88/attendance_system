import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAllLeaveWorkSummaryScreen extends StatefulWidget {
  const AdminAllLeaveWorkSummaryScreen({super.key});

  @override
  State<AdminAllLeaveWorkSummaryScreen> createState() =>
      _AdminAllLeaveWorkSummaryScreenState();
}

class _AdminAllLeaveWorkSummaryScreenState
    extends State<AdminAllLeaveWorkSummaryScreen> {
  bool isLoading = true;
  List<dynamic> employees = [];

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    final url =
        Uri.parse('http://localhost:3000/api/employee/all-leave-work-summary');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          employees = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        debugPrint("Failed: ${response.body}");
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
        title: const Text("All Employees - Leave & Work Summary"),
        backgroundColor: const Color(0xFF2E3B55),
      ),
      backgroundColor: const Color(0xFFF4F4F4),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(
                  child: Text("No data found."),
                )
              : ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final emp = employees[index];
                    return _buildEmployeeCard(emp);
                  },
                ),
    );
  }

  Widget _buildEmployeeCard(dynamic emp) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Text(
          emp['full_name'],
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
        ),
        subtitle: Text(
          "Dept: ${emp['department']}",
          style: const TextStyle(color: Colors.grey),
        ),
        children: [
          if (emp['leave_summary'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Leave Summary",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  ...emp['leave_summary'].map<Widget>((leave) {
                    return Card(
                      color: const Color(0xFFE8F0FE),
                      child: ListTile(
                        title:
                            Text("${leave['leave_type']} (${leave['year']})"),
                        subtitle: Text(
                          "Total Entitlement: ${leave['total_entitlement']}\n"
                          "Taken: ${leave['leave_taken']}\n"
                          "Carry Forward: ${leave['carry_forward']}\n"
                          "Available: ${leave['available_leave']}",
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          if (emp['work_summary'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Work Hours Summary",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  ...emp['work_summary'].map<Widget>((work) {
                    return Card(
                      color: const Color(0xFFE0F7F4),
                      child: ListTile(
                        title: Text("${work['year']} - ${work['month']}"),
                        subtitle: Text(
                          "Required Hours: ${work['required_hours']}\n"
                          "Worked Hours: ${work['worked_hours']}",
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
