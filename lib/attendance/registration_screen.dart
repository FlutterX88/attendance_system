import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:attendance_system/attendance/loginScreen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _joinDateController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _leaveEntitlementController =
      TextEditingController();
  final TextEditingController _dailyHoursController = TextEditingController();
  final TextEditingController _monthlyHoursController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedWorkType;

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> workTypes = ['Full-Time', 'Part-Time', 'Contract'];

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('http://localhost:3000/api/employee/register');

    final data = {
      "fullName": _fullNameController.text,
      "email": _emailController.text,
      "phone": _phoneController.text,
      "password": _passwordController.text,
      "dob": _dobController.text,
      "gender": _selectedGender,
      "bloodGroup": _selectedBloodGroup,
      "joinDate": _joinDateController.text,
      "department": _departmentController.text,
      "designation": _designationController.text,
      "experience": _experienceController.text,
      "basicSalary": _salaryController.text,
      "workType": _selectedWorkType,
      "address": _addressController.text,
      "city": _cityController.text,
      "state": _stateController.text,
      "zip": _zipController.text,
      "emergencyContactName": _emergencyNameController.text,
      "emergencyContactNumber": _emergencyPhoneController.text,
      "annualLeaveEntitlement":
          double.tryParse(_leaveEntitlementController.text) ?? 0,
      "requiredWorkHoursDaily":
          double.tryParse(_dailyHoursController.text) ?? 0,
      "requiredWorkHoursMonthly":
          double.tryParse(_monthlyHoursController.text) ?? 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final jsonBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonBody['message'] ?? "Registration failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Registration'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSection(
                    title: "Personal Details",
                    children: [
                      _buildTextField("Full Name", _fullNameController),
                      _buildTextField("Email", _emailController,
                          inputType: TextInputType.emailAddress,
                          autofillHint: AutofillHints.email),
                      _buildTextField("Phone Number", _phoneController,
                          inputType: TextInputType.phone,
                          autofillHint: AutofillHints.telephoneNumber),
                      _buildTextField("Password", _passwordController,
                          isPassword: true),
                      _buildTextField(
                          "Confirm Password", _confirmPasswordController,
                          isPassword: true),
                      _buildDateField("Date of Birth", _dobController),
                      _buildDropdownField("Gender", _selectedGender,
                          ['Male', 'Female', 'Other'], (val) {
                        setState(() => _selectedGender = val);
                      }),
                      _buildDropdownField(
                          "Blood Group", _selectedBloodGroup, bloodGroups,
                          (val) {
                        setState(() => _selectedBloodGroup = val);
                      }),
                    ],
                    isWide: isWide,
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: "Company & Employment Details",
                    children: [
                      _buildDateField("Join Date", _joinDateController),
                      _buildTextField("Department", _departmentController),
                      _buildTextField("Designation", _designationController),
                      _buildTextField(
                          "Experience (Years)", _experienceController),
                      _buildTextField("Basic Salary", _salaryController,
                          inputType: TextInputType.number),
                      _buildDropdownField(
                          "Work Type", _selectedWorkType, workTypes, (val) {
                        setState(() => _selectedWorkType = val);
                      }),
                      _buildTextField("Annual Leave Entitlement (Days)",
                          _leaveEntitlementController,
                          inputType: TextInputType.number),
                      _buildTextField(
                          "Work Hours Required Daily", _dailyHoursController,
                          inputType: TextInputType.number),
                      _buildTextField("Work Hours Required Monthly",
                          _monthlyHoursController,
                          inputType: TextInputType.number),
                    ],
                    isWide: isWide,
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: "Address & Emergency Contact",
                    children: [
                      _buildTextField("Address", _addressController),
                      _buildTextField("City", _cityController),
                      _buildTextField("State", _stateController),
                      _buildTextField("ZIP / PIN", _zipController),
                      _buildTextField(
                          "Emergency Contact Name", _emergencyNameController),
                      _buildTextField(
                          "Emergency Contact Number", _emergencyPhoneController,
                          inputType: TextInputType.phone),
                    ],
                    isWide: isWide,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Register"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isWide,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: children
                  .map((child) => SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: child,
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false,
      TextInputType? inputType,
      String? autofillHint}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      autofillHints: autofillHint != null ? [autofillHint] : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      onTap: () => _selectDate(context, controller),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Select $label' : null,
    );
  }
}
