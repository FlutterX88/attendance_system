import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  bool isLoading = true;
  List requests = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
          'http://localhost:3000/api/employee/requests?status=Pending');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          requests = data;
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

  Future<void> updateRequestStatus(
      int id, String status, String requestType) async {
    try {
      final url = Uri.parse('http://localhost:3000/api/employee/requests/$id');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": status, "request_type": requestType}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request $status")),
        );
        fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> approveLeaveRequest(Map<String, dynamic> req) async {
    try {
      final int employeeId = int.tryParse(req['employee_id'].toString()) ?? 0;
      final String leaveType = req['leave_type'] ?? "";
      final int year = DateTime.now().year;
      final daysRaw = req['how_many_days'];
      final days = double.tryParse(daysRaw?.toString() ?? '')?.toInt() ?? 0;

      // 1. Call takeLeave API
      final takeLeaveResp = await http.post(
        Uri.parse('http://localhost:3000/api/employee//leave/take'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "employeeId": employeeId,
          "leaveType": leaveType,
          "year": year,
          "days": days
        }),
      );

      if (takeLeaveResp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to update leave summary: ${takeLeaveResp.body}")),
        );
        return;
      }

      // 2. Insert attendance for each leave day
      final fromDate = DateTime.parse(req['from_date']);
      final toDate = DateTime.parse(req['to_date']);

      for (var date = fromDate;
          !date.isAfter(toDate);
          date = date.add(const Duration(days: 1))) {
        final attendanceResp = await http.post(
          Uri.parse('http://localhost:3000/api/employee/attendance'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "employeeName": req['full_name'],
            "employee_id": employeeId,
            "date": date.toIso8601String().substring(0, 10),
            "inTime": null,
            "outTime": null,
            "status": "Leave",
          }),
        );

        if (attendanceResp.statusCode != 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Failed to insert attendance: ${attendanceResp.body}")),
          );
        }
      }

      // 3. Update request status as Approved
      await updateRequestStatus(req['id'], "Approved", req['request_type']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error approving leave: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Pending Requests"),
        backgroundColor: const Color(0xFF2E3B55),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Text("No pending requests."),
                )
              : ListView.builder(
                  itemCount: requests.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          req['full_name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Type: ${req['request_type'] ?? ''}"),
                            if (req['reason'] != null &&
                                req['reason'].toString().isNotEmpty)
                              Text("Reason: ${req['reason']}"),
                            if (req['request_type'] == 'Leave') ...[
                              if (req['leave_type'] != null &&
                                  req['leave_type'].toString().isNotEmpty)
                                Text("Leave Type: ${req['leave_type']}"),
                              if (req['from_date'] != null)
                                Text("From Date: ${req['from_date']}"),
                              if (req['to_date'] != null)
                                Text("To Date: ${req['to_date']}"),
                              if (req['how_many_days'] != null)
                                Text("Days: ${req['how_many_days']}"),
                              if (req['requested_date'] != null)
                                Text("Requested On: ${req['requested_date']}"),
                            ],
                            if (req['amount'] != null)
                              Text("Amount: ₹${req['amount']}"),
                            if (req['payment_mode'] != null)
                              Text("Mode: ${req['payment_mode']}"),
                            Text("Date: ${req['date']}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () {
                                  if (req['request_type'] == 'Leave') {
                                    approveLeaveRequest(req);
                                  } else {
                                    updateRequestStatus(req['id'], "Approved",
                                        req['request_type']);
                                  }
                                }),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                updateRequestStatus(
                                    req['id'], "Rejected", req['request_type']);
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
