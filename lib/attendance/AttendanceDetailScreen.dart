import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final int year;
  final int month;

  const AttendanceDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.month,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  List<dynamic> details = [];
  bool loading = true;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> fetchDetails() async {
    setState(() => loading = true);
    final startDate =
        "${widget.year}-${widget.month.toString().padLeft(2, '0')}-01";
    final endDate = DateTime(widget.year, widget.month + 1, 0);
    final endStr = endDate.toIso8601String().split("T")[0];

    final url = Uri.parse(
        'http://localhost:3000/api/employee/attendance/details'
        '?employeeId=${widget.employeeId}&startDate=$startDate&endDate=$endStr');

    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      setState(() {
        details = jsonDecode(resp.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: Text('Details: ${widget.employeeName}'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : details.isEmpty
              ? const Center(child: Text('No attendance records.'))
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
                          children: [
                            _buildHeaderRow(),
                            const Divider(height: 1, thickness: 1),
                            ...details.asMap().entries.map((entry) {
                              return _buildDataRow(entry.value, entry.key);
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
    final headers = [
      "Date",
      "Status",
      "Shift",
      "In Time",
      "Out Time",
      //   "Worked Hours",
      "Overtime",
      "Less Hours",
    ];

    return Row(
      children: headers.map((title) => _headerCell(title, width: 120)).toList(),
    );
  }

  Widget _headerCell(String text, {double width = 120}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade600,
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(dynamic row, int index) {
    final rowColor = index % 2 == 0 ? Colors.grey.shade50 : Colors.white;

    String lessHours = row['lessHours']?.toString() ?? "";
    String overtimeHours = row['overtimeHours']?.toString() ?? "";

    return Container(
      color: rowColor,
      child: Row(
        children: [
          _dataCell(row['date'] ?? "", width: 120),
          _dataCell(
            row['status'] ?? "",
            width: 120,
            backgroundColor: _statusColor(row['status']),
            textColor: _statusTextColor(row['status']),
          ),
          _dataCell(row['shift'] ?? "", width: 120),
          _dataCell(row['inTime'] ?? "", width: 120),
          _dataCell(row['outTime'] ?? "", width: 120),
          //  _dataCell(row['workedHours']?.toString() ?? "", width: 120),
          _dataCell(
            overtimeHours,
            width: 120,
            textColor: _getOvertimeTextColor(overtimeHours),
          ),
          _dataCell(
            lessHours,
            width: 120,
            textColor: _getLessHoursTextColor(lessHours),
          ),
        ],
      ),
    );
  }

  Color _getOvertimeTextColor(String hours) {
    final value = double.tryParse(hours) ?? 0;
    return value > 0 ? Colors.green.shade700 : Colors.black87;
  }

  Color _getLessHoursTextColor(String hours) {
    final value = double.tryParse(hours) ?? 0;
    return value > 0 ? Colors.red.shade700 : Colors.black87;
  }

  Widget _dataCell(String text,
      {double width = 120, Color? backgroundColor, Color? textColor}) {
    return Container(
      width: width,
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return Colors.transparent;

    switch (status.toLowerCase()) {
      case 'present':
        return Colors.blue.shade100;
      case 'absent':
        return Colors.red.shade100;
      case 'leave':
        return Colors.yellow.shade100;
      default:
        return Colors.transparent;
    }
  }

  Color _statusTextColor(String? status) {
    if (status == null) return Colors.black87;

    switch (status.toLowerCase()) {
      case 'present':
        return Colors.blue.shade900;
      case 'absent':
        return Colors.red.shade900;
      case 'leave':
        return Colors.orange.shade900;
      default:
        return Colors.black87;
    }
  }
}
