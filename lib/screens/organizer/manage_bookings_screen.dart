import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../database/firestore_service.dart';

class ManageBookingsScreen extends StatelessWidget {
  final Event event;
  const ManageBookingsScreen({super.key, required this.event});

  void _updateStatus(BuildContext context, String id, String status) {
    if (status == 'Rejected') {
      final reasonCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Rejection Reason"),
          content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: "Reason (e.g. Competitor conflict)")),
          actions: [
            ElevatedButton(
              onPressed: () {
                FirestoreService.instance.updateBookingStatus(id, 'Rejected', reasonCtrl.text);
                Navigator.pop(context);
              },
              child: const Text("Reject"),
            )
          ],
        ),
      );
    } else {
      FirestoreService.instance.updateBookingStatus(id, status, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review Applications")),
      body: StreamBuilder(
        stream: FirestoreService.instance.getBookingsForEvent(event.id!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return const Center(child: Text("No applications yet"));

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                            child: Text(b.status, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Details
                      Text("Booth: ${b.boothName}"),
                      Text("Industry: ${b.industry}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      Text("Add-ons: ${b.addOns}"),
                      const SizedBox(height: 4),
                      Text("Desc: ${b.description}", style: const TextStyle(fontStyle: FontStyle.italic)),

                      const Divider(),
                      // Actions
                      if (b.status == 'Pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, b.id!, 'Rejected'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("Reject"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _updateStatus(context, b.id!, 'Approved'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Approve"),
                            ),
                          ],
                        ),
                      if (b.status == 'Approved')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _updateStatus(context, b.id!, 'Cancelled'),
                            child: const Text("Force Cancel", style: TextStyle(color: Colors.red)),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}