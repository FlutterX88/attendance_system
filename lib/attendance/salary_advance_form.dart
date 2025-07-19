import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SalaryAdvanceForm extends StatefulWidget {
  const SalaryAdvanceForm({super.key});

  @override
  State<SalaryAdvanceForm> createState() => _SalaryAdvanceFormState();
}

class _SalaryAdvanceFormState extends State<SalaryAdvanceForm> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? selectedEmployee;
  String? paymentMode;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  List<dynamic> employees = [];
  bool isLoading = true;

  final List<String> paymentModes = ['Cash', 'Bank Transfer', 'UPI'];

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

          // Check that selected employee still exists
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final dateStr = "${selectedDate.toLocal()}".split(' ')[0];
      final employee = selectedEmployee!;
      final mode = paymentMode!;
      final amount = _amountController.text;
      final remarks = _remarksController.text;

      final url = Uri.parse('http://localhost:3000/api/employee/advance');

      final body = jsonEncode({
        'employeeName': employee['full_name'],
        'employee_id': employee['id'],
        'date': dateStr,
        'amount': amount,
        'paymentMode': mode,
        'remarks': remarks,
        'status': "Pending"
      });

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Salary advance submitted successfully!"),
            ),
          );
          _formKey.currentState?.reset();
          setState(() {
            selectedEmployee = null;
            paymentMode = null;
            selectedDate = DateTime.now();
            _amountController.clear();
            _remarksController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${jsonDecode(response.body)['message']}"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error occurred: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salary Advance Entry"),
        backgroundColor: const Color(0xFF2E3B55),
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
                        "Provide Salary Advance",
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
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Advance Amount (₹)"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter amount";
                          }
                          if (double.tryParse(value) == null) {
                            return "Invalid number";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: paymentMode,
                        decoration: _inputDecoration("Payment Mode"),
                        items: paymentModes
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => paymentMode = value),
                        validator: (value) =>
                            value == null ? "Please select payment mode" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: _inputDecoration("Remarks (Optional)"),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_money),
                        label: const Text("Submit Advance"),
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
