import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pms_plus/attendance/AttendanceDetailScreen.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<dynamic> data = [];
  bool loading = true;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> fetchSummary() async {
    setState(() => loading = true);

    final url = Uri.parse(
        'http://localhost:3000/api/employee/attendance/grid-summary?year=$selectedYear&month=$selectedMonth');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        data = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  List<String> getDays() {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    return List.generate(daysInMonth, (i) {
      final d = i + 1;
      return d.toString().padLeft(2, '0');
    });
  }

  String mapStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'present':
        return 'P';
      case 'absent':
        return 'A';
      case 'leave':
        return 'L';
      default:
        return raw; // keep W/P etc.
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'P':
        return Colors.blue.shade200;
      case 'A':
        return Colors.red.shade200;
      case 'L':
        return Colors.yellow.shade300;
      case 'W/P':
        return Colors.teal.shade200;
      case 'SL/P':
        return Colors.purple.shade200;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'P':
      case 'W/P':
      case 'SL/P':
        return Colors.blue.shade900;
      case 'A':
        return Colors.red.shade900;
      case 'L':
        return Colors.orange.shade900;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text("Employee Attendance Summary"),
        actions: [
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) {
              final m = i + 1;
              return DropdownMenuItem(
                  value: m, child: Text(m.toString().padLeft(2, '0')));
            }),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  selectedMonth = v;
                  fetchSummary();
                });
              }
            },
            underline: Container(),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedYear,
            items: List.generate(5, (i) {
              final y = DateTime.now().year - i;
              return DropdownMenuItem(value: y, child: Text(y.toString()));
            }),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  selectedYear = v;
                  fetchSummary();
                });
              }
            },
            underline: Container(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderRow(),
                        const Divider(height: 1, thickness: 1),
                        ...data.asMap().entries.map((entry) {
                          return _buildEmployeeRow(entry.value, entry.key);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        _headerCell("Employee (ID)", width: 200),
        ...getDays().map((day) => _headerCell(day, width: 50)),
      ],
    );
  }

  Widget _headerCell(String text, {double width = 60}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade600,
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildEmployeeRow(dynamic emp, int index) {
    final empId = emp['employeeId']?.toString() ?? "";
    final empName = emp['employeeName'] ?? "";
    final rowBgColor = index % 2 == 0 ? Colors.grey.shade50 : Colors.white;

    final mostCommonStatus = _getMostCommonStatus(emp);
    final empCellColor =
        mostCommonStatus == "" ? rowBgColor : _statusColor(mostCommonStatus);

    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendanceDetailScreen(
                  employeeId: int.parse(empId.toString()),
                  employeeName: empName,
                  year: selectedYear,
                  month: selectedMonth,
                ),
              ),
            );
          },
          child: Container(
            width: 200,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: empCellColor,
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Text(
              "$empName (ID: $empId)",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _statusTextColor(mostCommonStatus),
              ),
            ),
          ),
        ),
        ...getDays().map((day) {
          final dayStr =
              '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-$day';
          final rawStatus = emp['days']?[dayStr] ?? "";
          final status = mapStatus(rawStatus);

          return Container(
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              color: status.isEmpty ? rowBgColor : _statusColor(status),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: status.isEmpty ? Colors.black : _statusTextColor(status),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Determine the most frequent status for the employee
  String _getMostCommonStatus(dynamic emp) {
    final statusCounts = <String, int>{};
    final daysMap = emp['days'] as Map<String, dynamic>?;

    if (daysMap != null) {
      for (var value in daysMap.values) {
        final status = mapStatus(value.toString());
        if (status.isEmpty) continue;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    if (statusCounts.isEmpty) return "";
    return statusCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}
