import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceEntryForm extends StatefulWidget {
  const AttendanceEntryForm({super.key});

  @override
  State<AttendanceEntryForm> createState() => _AttendanceEntryFormState();
}

class _AttendanceEntryFormState extends State<AttendanceEntryForm> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? selectedEmployee;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? inTime;
  TimeOfDay? outTime;
  String? selectedStatus;
  bool inTimeEnabled = false;
  bool outTimeEnabled = false;

  bool isLoading = true;
  bool isExistingRecord = false;
  bool timesEditable = true;

  List<dynamic> employees = [];

  final List<String> statusOptions = ['Present', 'Absent'];
  final TextEditingController _inTimeController = TextEditingController();
  final TextEditingController _outTimeController = TextEditingController();

  bool inTimereadonly = true;
  bool outTimereadonly = true;

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
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      if (selectedEmployee != null) {
        checkExistingAttendance();
      }
    }
  }

  String cleanTime(String s) {
    // 1) Remove all non-ASCII chars (this nukes U+202F, U+00A0, etc.)
    s = s.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
    // 2) Collapse any run of whitespace to a single space and trim
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  TimeOfDay parseTimeOfDay(String raw) {
    // 1) Collapse *all* whitespace (including U+202F, U+00A0, tabs, etc.) into ASCII space:
    var cleaned = raw
        .replaceAll(
          RegExp(r'[\s\u00A0\u2000-\u200A\u202F]+'),
          ' ',
        )
        .trim();

    // 2) Extract H, M and AM/PM with a regex:
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$').firstMatch(cleaned);
    if (match == null) {
      throw FormatException('Invalid time format: "$cleaned"');
    }

    var hour = int.parse(match.group(1)!);
    var minute = int.parse(match.group(2)!);
    var ampm = match.group(3)!.toUpperCase();

    // 3) Convert to 24-hour:
    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> checkExistingAttendance() async {
    setState(() {
      isLoading = true;
      isExistingRecord = false;
      timesEditable = true;
      selectedStatus = null;
      inTime = null;
      outTime = null;
    });

    final dateStr = "${selectedDate.toLocal()}".split(' ')[0];
    final empId = selectedEmployee!['id'];

    final url = Uri.parse(
        'http://localhost:3000/api/employee/attendance/check?employeeId=$empId&date=$dateStr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null) {
          // attendance already exists
          setState(() {
            inTimeEnabled = true;
            outTimeEnabled = true;
            isExistingRecord = true;
            selectedStatus = data['status'];

            if (selectedStatus == "Leave") {
              statusOptions.remove("Leave");
              statusOptions.add("Leave");
            }

            if (data['status'] == 'Present') {
              if (data['in_time'] != null) {
                final raw = data['in_time'] as String;
                final t = parseTimeOfDay(raw);
                inTime = t;
                inTimereadonly = true;
                outTimereadonly = false;
                _inTimeController.text = t.format(context);
              }

              if (data['out_time'] != null) {
                final raw = data['out_time'] as String;
                final t = parseTimeOfDay(raw);
                outTime = t;
                outTimereadonly = true;
                _outTimeController.text = t.format(context);
              }
              timesEditable = data['out_time'] == null;
            } else {
              timesEditable = false;
            }
          });
        } else {
          setState(() {
            inTimereadonly = false;
            outTimereadonly = true;
            inTimeEnabled = true;
            outTimeEnabled = false;
            timesEditable = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Check attendance error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _pickTime(bool isInTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (!isInTime) {
        // We're picking out-time → validate against in-time
        if (inTime != null) {
          final inMinutes = inTime!.hour * 60 + inTime!.minute;
          final outMinutes = picked.hour * 60 + picked.minute;

          if (outMinutes <= inMinutes) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Out-Time must be greater than In-Time.",
                ),
              ),
            );
            return; // Reject the pick
          }
        }
      }

      setState(() {
        if (isInTime) {
          inTime = picked;
          _inTimeController.text = picked.format(context);
        } else {
          outTime = picked;
          _outTimeController.text = picked.format(context);
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (inTimeEnabled) {
        if (selectedStatus == 'Present' && (inTime == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select In-Time")),
          );
          return;
        }
      } else if (outTimeEnabled) {
        if (selectedStatus == 'Present' && (outTime == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select Out-Time")),
          );
          return;
        }
      }

      final employee = selectedEmployee!;
      final dateStr = "${selectedDate.toLocal()}".split(' ')[0];
      final inTimeStr = inTime?.format(context) ?? '';
      final outTimeStr = outTime?.format(context) ?? '';

      final attendanceData = {
        'employeeName': employee['full_name'],
        'employee_id': employee['id'],
        'date': dateStr,
        'inTime': selectedStatus == 'Present' ? inTimeStr : null,
        'outTime': selectedStatus == 'Present' ? outTimeStr : null,
        'status': selectedStatus,
      };

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/employee/attendance'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(attendanceData),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Attendance saved.")),
          );
          _resetForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${json.decode(response.body)['message']}"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      selectedEmployee = null;
      selectedDate = DateTime.now();
      inTime = null;
      outTime = null;
      selectedStatus = null;
      isExistingRecord = false;
      timesEditable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Entry"),
        backgroundColor: const Color(0xFF2E3B55),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedEmployee,
                        decoration: _inputDecoration("Select Employee"),
                        items: employees
                            .map((emp) =>
                                DropdownMenuItem<Map<String, dynamic>>(
                                  value: emp,
                                  child: Text(
                                    "${emp['full_name']} " "- ID: ${emp['id']}",
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedEmployee = value),
                        validator: (value) =>
                            value == null ? "Please select employee" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: _inputDecoration("Select Date").copyWith(
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: "${selectedDate.toLocal()}".split(' ')[0],
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: _inputDecoration("Attendance Status"),
                        items: statusOptions
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: isExistingRecord
                            ? null
                            : (value) {
                                setState(() {
                                  selectedStatus = value;
                                });
                              },
                        validator: (value) =>
                            value == null ? "Please select status" : null,
                      ),
                      const SizedBox(height: 16),
                      if (selectedStatus == 'Present') ...[
                        Row(
                          children: [
                            Visibility(
                              visible: inTimeEnabled,
                              child: Expanded(
                                child: TextFormField(
                                  readOnly: inTimereadonly,
                                  decoration: _inputDecoration("In Time")
                                      .copyWith(
                                          suffixIcon:
                                              const Icon(Icons.access_time)),
                                  controller: _inTimeController,
                                  onTap: !inTimereadonly
                                      ? () => !inTimereadonly
                                          ? _pickTime(true)
                                          : () {}
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Visibility(
                              visible: outTimeEnabled,
                              child: Expanded(
                                child: TextFormField(
                                  readOnly: outTimereadonly,
                                  decoration: _inputDecoration("Out Time")
                                      .copyWith(
                                          suffixIcon:
                                              const Icon(Icons.access_time)),
                                  controller: _outTimeController,
                                  onTap: !outTimereadonly
                                      ? () => !outTimereadonly
                                          ? _pickTime(false)
                                          : () {}
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(isExistingRecord
                            ? "Update Attendance"
                            : "Submit Attendance"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E3B55),
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed:
                            isExistingRecord && !timesEditable ? null : _submit,
                      ),
                      if (isExistingRecord)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            "Existing attendance record loaded.",
                            style: TextStyle(color: Colors.green),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
