// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool isLoading = true;
  List<dynamic> employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    final url = Uri.parse('http://localhost:3000/api/employee/emplist');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          employees = data;
          isLoading = false;
        });
      } else {
        debugPrint("Failed to load employees");
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
        title: const Text("Employees"),

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index];
                final status = emp['status'] ?? 'Not Marked';

                Color statusColor;
                switch (status) {
                  case 'Present':
                    statusColor = Colors.green;
                    break;
                  case 'Absent':
                    statusColor = Colors.red;
                    break;
                  case 'Leave':
                    statusColor = Colors.orange;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: statusColor),
                    ),
                    title: Text(
                      emp['full_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Status: $status",
                      style: TextStyle(color: statusColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeDetailScreen(id: emp['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class EmployeeDetailScreen extends StatefulWidget {
  final int id;
  const EmployeeDetailScreen({super.key, required this.id});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic> empData = {};

  @override
  void initState() {
    super.initState();
    fetchEmployeeDetail();
  }

  Future<void> fetchEmployeeDetail() async {
    final url = Uri.parse(
        'http://localhost:3000/api/employee/employeeinfo/${widget.id}/detail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          empData = data;
          isLoading = false;
        });
      } else {
        print(response.body);
        debugPrint("Failed to load employee detail");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  void _showRequestDialog() {
    final formKey = GlobalKey<FormState>();
    String? selectedType;
    String? leaveType;
    String reason = '';
    DateTime selectedDate = DateTime.now();
    DateTime? fromDate;
    DateTime? toDate;
    int? howManyDays;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              void calculateDays() {
                if (fromDate != null && toDate != null) {
                  final diff = toDate!.difference(fromDate!).inDays + 1;
                  setState(() {
                    howManyDays = diff > 0 ? diff : 0;
                  });
                } else {
                  setState(() {
                    howManyDays = null;
                  });
                }
              }

              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Send Employee Request",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Select Type",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Leave"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedType = val;
                          // Reset leave fields when changing type
                          leaveType = null;
                          fromDate = null;
                          toDate = null;
                          howManyDays = null;
                        });
                      },
                      validator: (val) => val == null ? "Select type" : null,
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == "Leave") ...[
                      DropdownButtonFormField<String>(
                        value: leaveType,
                        decoration: const InputDecoration(
                          labelText: "Leave Type",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          "Sick Leave",
                          "Casual Leave",
                          "Paid Leave",
                          "Maternity Leave",
                          "Emergency Leave"
                        ]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() => leaveType = val);
                        },
                        validator: (val) =>
                            val == null ? "Select leave type" : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "From Date",
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text: fromDate != null
                                    ? DateFormat('yyyy-MM-dd').format(fromDate!)
                                    : '',
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    fromDate = picked;
                                    calculateDays();
                                  });
                                }
                              },
                              validator: (val) {
                                if (selectedType == "Leave" &&
                                    fromDate == null) {
                                  return "Select From Date";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "To Date",
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text: toDate != null
                                    ? DateFormat('yyyy-MM-dd').format(toDate!)
                                    : '',
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: toDate ?? DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    toDate = picked;
                                    calculateDays();
                                  });
                                }
                              },
                              validator: (val) {
                                if (selectedType == "Leave" && toDate == null) {
                                  return "Select To Date";
                                }
                                return null;
                              },
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Total Days",
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                            text: howManyDays?.toString() ?? ''),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Reason / Remarks",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (val) => reason = val,
                    ),
                    const SizedBox(height: 16),
                    if (selectedType != "Leave") ...[
                      TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(selectedDate),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          if (selectedType == "Leave") {
                            _submitEmployeeRequest(
                              type: selectedType!,
                              reason: reason,
                              fromDate: fromDate!,
                              toDate: toDate!,
                              leaveType: leaveType!,
                              howManyDays: howManyDays ?? 0,
                            );
                          } else {
                            _submitEmployeeRequest(
                              type: selectedType!,
                              reason: reason,
                              date: selectedDate,
                            );
                          }
                        }
                      },
                      child: const Text("Submit Request"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submitEmployeeRequest({
    required String type,
    required String reason,
    DateTime? date,
    DateTime? fromDate,
    DateTime? toDate,
    String? leaveType,
    int? howManyDays,
  }) async {
    final payload = {
      "employeeId": widget.id,
      "type": type,
      "reason": reason,
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "status": "Pending",
      "fromDate":
          fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null,
      "toDate": toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null,
      "leaveType": leaveType,
      "howManyDays": howManyDays,
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/employee/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully")),
        );
        fetchEmployeeDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final att = empData['attendance_summary'];
    final salary = empData['basic_salary'] ?? 0.0;
    final advanceList = empData['advances'] as List<dynamic>;
    final extraHours = empData['extra_hours'] as List<dynamic>;

    final presentDays = att['present_days'];
    final absentDays = att['absent_days'];
    final leaveDays = att['leave_days'];
    final totalDays = att['total_days'];

    final List<PieChartData> pieData = [
      PieChartData('Present', presentDays.toDouble(), Colors.green),
      PieChartData('Absent', absentDays.toDouble(), Colors.red),
      PieChartData('Leave', leaveDays.toDouble(), Colors.orange),
    ];

    double totalAdvance = advanceList.fold(
        0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
    final remainingSalary = salary - totalAdvance;

    final List<PieChartData> salaryAdvanceData = [
      PieChartData('Advance Taken', totalAdvance, Colors.purple),
      PieChartData('Remaining Salary', remainingSalary, Colors.teal),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(empData['full_name'] ?? ''),
  
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRequestDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Attendance Summary",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _summaryBox("Present: $presentDays Days", Colors.green.shade50),
                const SizedBox(width: 12),
                _summaryBox("Absent: $absentDays Days", Colors.red.shade50),
                const SizedBox(width: 12),
                _summaryBox("Leaves: $leaveDays Days", Colors.orange.shade50),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle(
                "Salary vs Advance Taken & Attendance % ($totalDays Days)"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SfCircularChart(
                    legend: const Legend(isVisible: true),
                    series: [
                      PieSeries<PieChartData, String>(
                        dataSource: salaryAdvanceData,
                        xValueMapper: (data, _) => data.category,
                        yValueMapper: (data, _) => data.value,
                        pointColorMapper: (data, _) => data.color,
                        dataLabelMapper: (data, _) =>
                            '${((data.value / salary) * 100).toStringAsFixed(1)}%',
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: true),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SfCircularChart(
                    legend: const Legend(isVisible: true),
                    series: [
                      PieSeries<PieChartData, String>(
                        dataSource: pieData,
                        xValueMapper: (data, _) => data.category,
                        yValueMapper: (data, _) => data.value,
                        pointColorMapper: (data, _) => data.color,
                        dataLabelMapper: (data, _) =>
                            '${((data.value / totalDays) * 100).toStringAsFixed(1)}%',
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: true),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle("Salary Details"),
            const SizedBox(height: 16),
            _infoBox(
              "- Basic Salary: ₹$salary\n"
              "- Last Paid: ₹${empData['last_salary_paid']} on ${empData['last_salary_date']}",
              Colors.blue.shade50,
            ),
            const SizedBox(height: 24),
            _sectionTitle("Advance Taken"),
            const SizedBox(height: 16),
            ...advanceList.map((adv) => _infoBox(
                "- ₹${adv['amount']} on ${adv['date']}", Colors.blue.shade50)),
            const SizedBox(height: 24),
            _sectionTitle("Overtime / Half Days"),
            const SizedBox(height: 16),
            ...extraHours.map((item) => _infoBox(
                "- ${item['date']}: ${item['type']} (${item['hours']} hrs)",
                Colors.grey.shade100)),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String text, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _infoBox(String content, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Text(content),
    );
  }
}

class PieChartData {
  final String category;
  final double value;
  final Color color;

  PieChartData(this.category, this.value, this.color);
}
