import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SalaryComponentsMaster extends StatefulWidget {
  const SalaryComponentsMaster({super.key});

  @override
  State<SalaryComponentsMaster> createState() => _SalaryComponentsMasterState();
}

class _SalaryComponentsMasterState extends State<SalaryComponentsMaster> {
  List<Map<String, dynamic>> components = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComponents();
  }

  Future<void> fetchComponents() async {
    setState(() => isLoading = true);
    final url =
        Uri.parse('http://localhost:3000/api/employee/salary-components');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        components = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveAllComponents() async {
    // validate rows
    final validComponents = components.where((c) {
      final nameOk = (c["name"] as String?)?.trim().isNotEmpty ?? false;
      final typeOk =
          (c["component_type"] as String?)?.trim().isNotEmpty ?? false;
      return nameOk && typeOk;
    }).toList();

    if (validComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid components to save.")),
      );
      return;
    }

    final url =
        Uri.parse('http://localhost:3000/api/employee/salary-components');

    final componentsForApi = validComponents
        .map((c) => {
              "name": c["name"],
              "component_type": c["component_type"],
              "employee_percentage": c["employee_percentage"],
              "employer_percentage": c["employer_percentage"],
              "remarks": c["remarks"],
              "active": c["active"]
            })
        .toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"components": componentsForApi}),
    );

    print(componentsForApi);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Components saved successfully.")),
      );
      fetchComponents();
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  }

  Future<void> deleteComponent(int id) async {
    final url =
        Uri.parse('http://localhost:3000/api/employee/salary-components/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Component deleted.")),
      );
      fetchComponents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete component.")),
      );
    }
  }

  void addNewComponent() {
    setState(() {
      components.insert(0, {
        "id": null,
        "name": "",
        "component_type": "Deduction",
        "employee_percentage": 0.0,
        "employer_percentage": 0.0,
        "remarks": "",
        "active": true
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E3B55),
        title: const Text(
          "Salary Components Master",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 24),
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
                child: Column(
                  children: [
                    Expanded(
                      child: components.isEmpty
                          ? const Center(
                              child: Text(
                                "No components added yet.",
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: components.length,
                              itemBuilder: (context, index) {
                                final comp = components[index];
                                return _buildComponentCard(comp, index);
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: addNewComponent,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Component"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E3B55),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 45),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: saveAllComponents,
                          icon: const Icon(Icons.save),
                          label: const Text("Save All Changes"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 45),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildComponentCard(Map<String, dynamic> comp, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: comp['name'],
                    decoration: const InputDecoration(
                      labelText: "Component Name *",
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    onChanged: (val) => comp['name'] = val.trim(),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Component name is required.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: comp['component_type'],
                    decoration: const InputDecoration(labelText: "Type"),
                    items: ['Deduction', 'Allowance']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        comp['component_type'] = val;
                      });
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: comp['employee_percentage']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: "Employee %",
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) =>
                        comp['employee_percentage'] = double.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: comp['employer_percentage']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: "Employer %",
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) =>
                        comp['employer_percentage'] = double.tryParse(val) ?? 0,
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: comp['remarks'] ?? '',
              decoration: const InputDecoration(labelText: "Remarks"),
              onChanged: (val) => comp['remarks'] = val,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (comp['id'] != null)
                  ElevatedButton.icon(
                    onPressed: () => deleteComponent(comp['id']),
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        components.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text("Remove"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
