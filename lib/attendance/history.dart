import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AllRequestsScreen extends StatefulWidget {
  const AllRequestsScreen({super.key});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  bool isLoading = true;
  List requests = [];

  String selectedStatus = "All";
  final List<String> statusOptions = ["All", "Pending", "Approved", "Rejected"];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);

    try {
      const baseUrl = 'http://localhost:3000/api/employee/all-requests';
      final url = selectedStatus == "All"
          ? Uri.parse(baseUrl)
          : Uri.parse("$baseUrl?status=$selectedStatus");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          requests = jsonDecode(response.body);
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade600;
      case 'Rejected':
        return Colors.red.shade600;
      case 'Pending':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E3B55),
        automaticallyImplyLeading: true,
        title: Container(
          height: 60,
          color: const Color(0xFF2E3B55),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Text(
                "All Employee Requests",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                      fetchRequests();
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFEFF2F7),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              // Title Bar

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : requests.isEmpty
                          ? Center(
                              child: Text(
                                "No requests found.",
                                style: theme.textTheme.titleMedium,
                              ),
                            )
                          : _buildTable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFF2E3B55),
          ),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Reason')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Payment Mode')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Status')),
          ],
          rows: requests.map((req) {
            return DataRow(
              cells: [
                DataCell(Text(req['employee_name'] ?? '')),
                DataCell(Text(req['request_type'] ?? '')),
                DataCell(Text(req['reason'] ?? '')),
                DataCell(
                    Text(req['amount'] != null ? "₹${req['amount']}" : '')),
                DataCell(Text(req['payment_mode'] ?? '')),
                DataCell(Text(req['date'] ?? '')),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(req['status'] ?? ''),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    req['status'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
