import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AttendanceAdvanceReportScreen extends StatefulWidget {
  const AttendanceAdvanceReportScreen({super.key});

  @override
  State<AttendanceAdvanceReportScreen> createState() =>
      _AttendanceAdvanceReportScreenState();
}

class _AttendanceAdvanceReportScreenState
    extends State<AttendanceAdvanceReportScreen> {
  bool isLoading = true;
  List reportData = [];

  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() => isLoading = true);

    // Compute start and end date for selected month
    final startDate = DateTime(selectedYear, selectedMonth, 1);
    final endDate = DateTime(selectedYear, selectedMonth + 1, 0);

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    try {
      final url = Uri.parse(
          'http://localhost:3000/api/employee/all-attendance-advance-report'
          '?startDate=$startStr'
          '&endDate=$endStr');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          reportData = json;
          isLoading = false;
        });
      } else {
        debugPrint(response.body);
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  List<DropdownMenuItem<int>> get _monthItems {
    return List.generate(12, (index) {
      final monthNum = index + 1;
      final monthName = DateFormat.MMMM().format(DateTime(2025, monthNum, 1));
      return DropdownMenuItem(
        value: monthNum,
        child: Text(monthName),
      );
    });
  }

  List<DropdownMenuItem<int>> get _yearItems {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) {
      final year = currentYear - index;
      return DropdownMenuItem(
        value: year,
        child: Text(year.toString()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      appBar: AppBar(

        automaticallyImplyLeading: true,
        title: _buildTitleBar(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportData.isEmpty
              ? const Center(
                  child: Text(
                    "No data available.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: reportData.map<Widget>((emp) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    emp['full_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Text(
                                  "₹${emp['net_salary']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.teal),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 20,
                                runSpacing: 8,
                                children: [
                                  _miniStat("Dept", emp['department'] ?? ""),
                                  _miniStat("Basic Salary",
                                      "₹${emp['basic_salary']}"),
                                  _miniStat("Shift Hours/Day",
                                      emp['shift_hours_per_day'].toString()),
                                  _miniStat("Present",
                                      emp['total_present'].toString()),
                                  _miniStat(
                                      "Absent", emp['total_absent'].toString(),
                                      color: Colors.red),
                                  _miniStat(
                                      "Leave", emp['total_leave'].toString(),
                                      color: Colors.orange),
                                ],
                              ),
                            ),
                            children: [
                              Divider(color: Colors.grey.shade300),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _detailRow("Overtime Hours",
                                        emp['total_overtime_hours']),
                                    _detailRow("Overtime Addition",
                                        "₹${emp['overtime_addition']}",
                                        color: Colors.green),
                                    _detailRow(
                                        "Late Hours", emp['total_late_hours'],
                                        color: Colors.red),
                                    _detailRow("Late Deduction",
                                        "₹${emp['late_deduction']}",
                                        color: Colors.red),
                                    _detailRow(
                                        "Advance", "₹${emp['total_advance']}"),
                                    _detailRow("Absent Deduction",
                                        "₹${emp['absent_deduction']}"),
                                    _detailRow("Leave Deduction",
                                        "₹${emp['leave_deduction']}"),
                                    _detailRow("Total Deductions",
                                        "₹${emp['total_deduction']}"),
                                    const SizedBox(height: 12),
                                    _buildLeaveAdjustment(
                                        emp['leave_adjustment_details'] ?? []),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const Text(
                                      "Salary Components:",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._buildComponentsBreakup(
                                        emp['components_breakup'] ?? []),
                                    const SizedBox(height: 12),
                                    _detailRow("Gross Salary",
                                        "₹${emp['gross_salary']}",
                                        bold: true),
                                    _detailRow(
                                        "Net Salary", "₹${emp['net_salary']}",
                                        bold: true, color: Colors.teal),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTitleBar() {
    return Row(
      children: [
        const Text(
          "Attendance & Advance Report",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        DropdownButton<int>(
          //  dropdownColor: Colors.white,
          value: selectedMonth,
          items: _monthItems,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedMonth = value;
                fetchReport();
              });
            }
          },
          //  style: const TextStyle(color: Colors.white),
          underline: Container(),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          //   dropdownColor: Colors.white,
          value: selectedYear,
          items: _yearItems,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedYear = value;
                fetchReport();
              });
            }
          },
          //  style: const TextStyle(color: Colors.white),
          underline: Container(),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color ?? Colors.black87),
        ),
      ],
    );
  }

  Widget _detailRow(String label, dynamic value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          Text(
            value?.toString() ?? "-",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLeaveAdjustment(List details) {
    if (details.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Leave Adjustment:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        ...details.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                    "Total Entitlement", item['total_entitlement'].toString()),
                _detailRow("Carry Forward", item['carry_forward'].toString()),
                _detailRow("Leave Taken", item['leave_taken'].toString()),
                _detailRow("Unpaid Leave", item['unpaid_leave'].toString(),
                    color: Colors.red),
                _detailRow("Pending Leave Adjustment",
                    item['leave_pending'].toString(),
                    color: Colors.green),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildComponentsBreakup(List comps) {
    if (comps.isEmpty) {
      return [
        const Text(
          "No additional salary components.",
          style: TextStyle(color: Colors.black54),
        )
      ];
    }

    return comps.map<Widget>((c) {
      final isAllowance = c['type'] == 'Allowance';
      final amount = double.tryParse(c['amount'] ?? '0') ?? 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${c['name']} (${c['percentage']}%)",
                style: TextStyle(
                  color: isAllowance ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              "${isAllowance ? "+" : "-"}₹${amount.abs().toStringAsFixed(2)}",
              style: TextStyle(
                color: isAllowance ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      );
    }).toList();
  }
}


//TABLE VIEW

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class AttendanceAdvanceReportScreen extends StatefulWidget {
//   const AttendanceAdvanceReportScreen({super.key});

//   @override
//   State<AttendanceAdvanceReportScreen> createState() =>
//       _AttendanceAdvanceReportScreenState();
// }

// class _AttendanceAdvanceReportScreenState
//     extends State<AttendanceAdvanceReportScreen> {
//   bool isLoading = true;
//   List reportData = [];

//   DateTimeRange dateRange = DateTimeRange(
//     start: DateTime(DateTime.now().year, DateTime.now().month, 1),
//     end: DateTime.now(),
//   );

//   @override
//   void initState() {
//     super.initState();
//     fetchReport();
//   }

//   Future<void> fetchReport() async {
//     setState(() => isLoading = true);
//     try {
//       final url = Uri.parse(
//           'http://localhost:3000/api/employee/all-attendance-advance-report'
//           '?startDate=${dateRange.start.toIso8601String().split("T")[0]}'
//           '&endDate=${dateRange.end.toIso8601String().split("T")[0]}');

//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         setState(() {
//           reportData = json;
//           isLoading = false;
//         });
//       } else {
//         debugPrint(response.body);
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("Error: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEFF2F7),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF2E3B55),
//         automaticallyImplyLeading: true,
//         title: _buildTitleBar(),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : reportData.isEmpty
//               ? const Center(
//                   child: Text(
//                     "No data available.",
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: SingleChildScrollView(
//                     child: DataTable(
//                       columnSpacing: 20,
//                       headingRowColor:
//                           MaterialStateProperty.all(const Color(0xFF2E3B55)),
//                       headingTextStyle:
//                           const TextStyle(color: Colors.white, fontSize: 14),
//                       dataRowHeight: 60,
//                       columns: [
//                         _col("Employee"),
//                         _col("Dept"),
//                         _col("Shift hrs/day"),
//                         _col("Present"),
//                         _col("Absent"),
//                         _col("Leave"),
//                         _col("OT Hrs"),
//                         _col("OT Add"),
//                         _col("Late Hrs"),
//                         _col("Late Deduction"),
//                         _col("Advances"),
//                         _col("Absent Deduction"),
//                         _col("Leave Deduction"),
//                         _col("Total Deduction"),
//                         _col("Gross Salary"),
//                         _col("Net Salary"),
//                       ],
//                       rows: reportData.map<DataRow>((emp) {
//                         return DataRow(cells: [
//                           DataCell(Text(emp['full_name'] ?? "-")),
//                           DataCell(Text(emp['department'] ?? "-")),
//                           DataCell(Text(emp['shift_hours_per_day'].toString())),
//                           DataCell(Text(emp['total_present'].toString())),
//                           DataCell(Text(emp['total_absent'].toString())),
//                           DataCell(Text(emp['total_leave'].toString())),
//                           DataCell(Text(emp['total_overtime_hours'].toString())),
//                           DataCell(Text("₹${emp['overtime_addition']}")),
//                           DataCell(Text(emp['total_late_hours'].toString())),
//                           DataCell(Text("₹${emp['late_deduction']}")),
//                           DataCell(Text("₹${emp['total_advance']}")),
//                           DataCell(Text("₹${emp['absent_deduction']}")),
//                           DataCell(Text("₹${emp['leave_deduction']}")),
//                           DataCell(Text("₹${emp['total_deduction']}")),
//                           DataCell(Text("₹${emp['gross_salary']}")),
//                           DataCell(
//                             Text(
//                               "₹${emp['net_salary']}",
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.teal),
//                             ),
//                           ),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//     );
//   }

//   DataColumn _col(String label) => DataColumn(
//         label: Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//       );

//   Widget _buildTitleBar() {
//     return Row(
//       children: [
//         const Text(
//           "Attendance & Advance Report",
//           style: TextStyle(
//               color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         const Spacer(),
//         ElevatedButton.icon(
//           onPressed: () async {
//             final picked = await showDateRangePicker(
//               context: context,
//               firstDate: DateTime(2023),
//               lastDate: DateTime(2100),
//               initialDateRange: dateRange,
//             );
//             if (picked != null) {
//               setState(() => dateRange = picked);
//               fetchReport();
//             }
//           },
//           icon: const Icon(Icons.date_range, size: 16),
//           label: Text(
//             "${dateRange.start.toString().split(" ")[0]} → ${dateRange.end.toString().split(" ")[0]}",
//             style: const TextStyle(fontSize: 14),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black,
//             textStyle: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }
// }

