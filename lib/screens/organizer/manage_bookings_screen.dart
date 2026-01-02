import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../database/firestore_service.dart';

class ManageBookingsScreen extends StatelessWidget {
  final Event event;
  final AppUser currentUser;

  const ManageBookingsScreen({super.key, required this.event, required this.currentUser});

  void _showEditDialog(BuildContext context, Booking booking) {
    final companyCtrl = TextEditingController(text: booking.companyName);
    final industryCtrl = TextEditingController(text: booking.industry);
    final descCtrl = TextEditingController(text: booking.description);
    final addOnsCtrl = TextEditingController(text: booking.addOns);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Edit Booking Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company Name")),
              const SizedBox(height: 10),
              TextField(controller: industryCtrl, decoration: const InputDecoration(labelText: "Industry")),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: addOnsCtrl, decoration: const InputDecoration(labelText: "Add-ons")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService.instance.updateBookingAdmin(
                booking.id!,
                companyName: companyCtrl.text,
                industry: industryCtrl.text,
                description: descCtrl.text,
                addOns: addOnsCtrl.text,
              );
              if (c.mounted) Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking updated")));
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String id, String status) {
    if (status == 'Rejected') {
      final reasonCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Rejection Reason"),
          content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: "Reason")),
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
      body: StreamBuilder<List<Booking>>(
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
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(b.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                            child: Text(b.status, style: const TextStyle(fontSize: 12)),
                          ),
                          // Edit Button (Admin Only)
                          if (currentUser.role == 'Administrator')
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                              onPressed: () => _showEditDialog(context, b),
                              tooltip: "Edit (Admin Only)",
                            ),
                        ],
                      ),

                      // --- NEW: Email Display ---
                      Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          SelectableText( // Use SelectableText so they can copy it
                            b.exhibitorEmail,
                            style: TextStyle(color: Colors.blue[700], fontSize: 13),
                          ),
                        ],
                      ),
                      // --------------------------

                      const SizedBox(height: 8),
                      const Divider(),

                      Text("Booth: ${b.boothName}"),
                      Text("Industry: ${b.industry}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      Text("Add-ons: ${b.addOns}"),
                      const SizedBox(height: 4),
                      Text("Desc: ${b.description}", style: const TextStyle(fontStyle: FontStyle.italic)),

                      const SizedBox(height: 8),

                      // Action Buttons
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