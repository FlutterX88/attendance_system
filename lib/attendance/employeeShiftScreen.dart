import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmployeeShiftScreen extends StatefulWidget {
  const EmployeeShiftScreen({super.key});

  @override
  State<EmployeeShiftScreen> createState() => _EmployeeShiftScreenState();
}

class _EmployeeShiftScreenState extends State<EmployeeShiftScreen> {
  List<dynamic> employees = [];
  List<dynamic> shifts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    fetchShifts();
  }

  Future<void> fetchEmployees() async {
    final url = Uri.parse('http://localhost:3000/api/employee/emplist');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        employees = jsonDecode(response.body);
      });
    }
  }

  Future<void> fetchShifts() async {
    final url = Uri.parse('http://localhost:3000/api/employee/shift');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        shifts = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  Future<void> addOrUpdateShift({
    int? id,
    required int employeeId,
    required String shiftName,
    required String startTime,
    required String endTime,
    required String shiftType,
  }) async {
    final url = id == null
        ? Uri.parse('http://localhost:3000/api/employee/shift')
        : Uri.parse('http://localhost:3000/api/employee/shift/$id');

    final body = jsonEncode({
      "employeeId": employeeId,
      "shiftName": shiftName,
      "startTime": startTime,
      "endTime": endTime,
      "shiftType": shiftType
    });

    final response = id == null
        ? await http.post(url,
            headers: {'Content-Type': 'application/json'}, body: body)
        : await http.put(url,
            headers: {'Content-Type': 'application/json'}, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift saved.")),
      );
      fetchShifts();
    } else {
      debugPrint(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save shift.")),
      );
    }
  }

  Future<void> deleteShift(int id) async {
    final url = Uri.parse('http://localhost:3000/api/employee/shift/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift deleted.")),
      );
      fetchShifts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete shift.")),
      );
    }
  }

  void showShiftForm({Map<String, dynamic>? existing}) {
    final formKey = GlobalKey<FormState>();
    int? id = existing?['id'];
    int employeeId = existing?['employee_id'] ?? employees.first['id'];
    final shiftNameController =
        TextEditingController(text: existing?['shift_name'] ?? '');
    final startTimeController =
        TextEditingController(text: existing?['start_time'] ?? '');
    final endTimeController =
        TextEditingController(text: existing?['end_time'] ?? '');
    String shiftType = existing?['shift_type'] ?? 'Day';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? "Add Shift" : "Edit Shift"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: employeeId,
                  items: employees
                      .map<DropdownMenuItem<int>>((e) => DropdownMenuItem(
                            value: e['id'],
                            child: Text(e['full_name']),
                          ))
                      .toList(),
                  onChanged: (val) => employeeId = val!,
                  decoration: const InputDecoration(labelText: "Employee"),
                ),
                TextFormField(
                  controller: shiftNameController,
                  decoration: const InputDecoration(labelText: "Shift Name"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter shift name" : null,
                ),
                TextFormField(
                  controller: startTimeController,
                  decoration:
                      const InputDecoration(labelText: "Start Time (HH:mm)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter start time" : null,
                ),
                TextFormField(
                  controller: endTimeController,
                  decoration:
                      const InputDecoration(labelText: "End Time (HH:mm)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter end time" : null,
                ),
                DropdownButtonFormField<String>(
                  value: shiftType,
                  items: ["Day", "Night"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => shiftType = val!,
                  decoration: const InputDecoration(labelText: "Shift Type"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                addOrUpdateShift(
                  id: id,
                  employeeId: employeeId,
                  shiftName: shiftNameController.text,
                  startTime: startTimeController.text,
                  endTime: endTimeController.text,
                  shiftType: shiftType,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Shifts"),
        backgroundColor: const Color(0xFF2E3B55),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showShiftForm(),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final s = shifts[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                        "${s['shift_name']} (${s['shift_type']}) - ${s['start_time']} to ${s['end_time']}"),
                    subtitle: Text("Employee: ${s['full_name']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showShiftForm(existing: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteShift(s['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
