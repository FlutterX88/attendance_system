import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SalaryComponentsViewScreen extends StatefulWidget {
  const SalaryComponentsViewScreen({super.key});

  @override
  State<SalaryComponentsViewScreen> createState() =>
      _SalaryComponentsViewScreenState();
}

class _SalaryComponentsViewScreenState
    extends State<SalaryComponentsViewScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      appBar: AppBar(

        title: const Text(
          "Salary Components",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : components.isEmpty
              ? const Center(child: Text("No salary components found."))
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
                    child: ListView.builder(
                      itemCount: components.length,
                      itemBuilder: (context, index) {
                        final comp = components[index];
                        return _buildComponentTile(comp);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildComponentTile(Map<String, dynamic> comp) {
    final isAllowance = comp['component_type'] == 'Allowance';
    final color = isAllowance ? Colors.green.shade50 : Colors.red.shade50;

    final borderColor =
        isAllowance ? Colors.green.shade300 : Colors.red.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comp['name'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isAllowance ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoChip("Type", comp['component_type']),
              const SizedBox(width: 12),
              _infoChip("Emp %", "${comp['employee_percentage'] ?? 0}"),
              const SizedBox(width: 12),
              _infoChip("Empr %", "${comp['employer_percentage'] ?? 0}"),
            ],
          ),
          if ((comp['remarks'] ?? "").toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comp['remarks'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
