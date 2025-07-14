import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAssignLeaveWorkScreen extends StatefulWidget {
  const AdminAssignLeaveWorkScreen({super.key});

  @override
  State<AdminAssignLeaveWorkScreen> createState() =>
      _AdminAssignLeaveWorkScreenState();
}

class _AdminAssignLeaveWorkScreenState
    extends State<AdminAssignLeaveWorkScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? selectedEmployee;
  final TextEditingController _leaveTypeController = TextEditingController();
  final TextEditingController _totalEntitlementController =
      TextEditingController();
  final TextEditingController _carryForwardController = TextEditingController();

  final TextEditingController _yearController =
      TextEditingController(text: DateTime.now().year.toString());
  final TextEditingController _monthController =
      TextEditingController(text: DateTime.now().month.toString());
  final TextEditingController _requiredHoursController =
      TextEditingController();

  List<dynamic> employees = [];
  bool isLoading = true;

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

          if (selectedEmployee != null) {
            final exists =
                employees.any((e) => e['id'] == selectedEmployee?['id']);
            if (!exists) selectedEmployee = null;
          }
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

  Future<void> saveLeaveSummary() async {
    final url = Uri.parse('http://localhost:3000/api/employee/leave/summary');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "employeeId": selectedEmployee!['id'],
        "leave_type": _leaveTypeController.text,
        "year": int.parse(_yearController.text),
        "total_entitlement":
            double.tryParse(_totalEntitlementController.text) ?? 0,
        "carry_forward": double.tryParse(_carryForwardController.text) ?? 0,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Leave summary saved.")),
      );
      clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  }

  Future<void> saveWorkSummary() async {
    final url =
        Uri.parse('http://localhost:3000/api/employee/workhours/summary');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "employeeId": selectedEmployee!['id'],
        "year": int.parse(_yearController.text),
        "month": int.parse(_monthController.text),
        "required_hours": double.tryParse(_requiredHoursController.text) ?? 0,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Work summary saved.")),
      );
      clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  }

  void clearForm() {
    setState(() {
      _leaveTypeController.clear();
      _totalEntitlementController.clear();
      _carryForwardController.clear();
      _requiredHoursController.clear();
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      saveLeaveSummary();
      saveWorkSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Leave & Work Hours"),
 
      ),
      backgroundColor: const Color(0xFFF4F4F4),
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
                      const Text(
                        "Assign Leave & Work Hours",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3B55),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedEmployee,
                        decoration: _inputDecoration("Select Employee"),
                        items: employees
                            .map(
                                (emp) => DropdownMenuItem<Map<String, dynamic>>(
                                      value: emp,
                                      child: Text(
                                          "${emp['full_name']} - ID: ${emp['id']}"),
                                    ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedEmployee = value),
                        validator: (value) =>
                            value == null ? "Please select employee" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _leaveTypeController,
                        decoration: _inputDecoration("Leave Type (e.g. CL)"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Please enter leave type"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totalEntitlementController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Total Leave Entitlement"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter entitlement";
                          }
                          if (double.tryParse(value) == null) {
                            return "Invalid number";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _carryForwardController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Carry Forward Leave"),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Year"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Please enter year"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _monthController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Month"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Please enter month"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _requiredHoursController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _inputDecoration("Required Work Hours (Monthly)"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter required hours";
                          }
                          if (double.tryParse(value) == null) {
                            return "Invalid number";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Assignments"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E3B55),
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: _submitForm,
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
