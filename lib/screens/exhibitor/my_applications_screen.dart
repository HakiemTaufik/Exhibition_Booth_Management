import 'package:flutter/material.dart';
import '../../database/firestore_service.dart';
import '../../models/booking_model.dart';

class MyApplicationsScreen extends StatefulWidget {
  final String userId;
  const MyApplicationsScreen({super.key, required this.userId});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {

  // Logic to Cancel Application
  Future<void> _cancelApplication(String bookingId) async {
    bool confirm = await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Cancel Application?"),
          content: const Text("This cannot be undone."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Back")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(c, true),
                child: const Text("Confirm Cancel")
            ),
          ],
        )
    ) ?? false;

    if (confirm) {
      await FirestoreService.instance.updateBookingStatus(bookingId, 'Cancelled', "User requested cancellation");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Cancelled")));
    }
  }

  // Logic to Edit Application (Only if Pending)
  void _editApplication(Booking booking) {
    final descCtrl = TextEditingController(text: booking.description);
    final addOnsCtrl = TextEditingController(text: booking.addOns);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Application"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 10),
            TextField(controller: addOnsCtrl, decoration: const InputDecoration(labelText: "Add-ons")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Using the method added to FirestoreService
              await FirestoreService.instance.updateBookingDetails(booking.id!, descCtrl.text, addOnsCtrl.text);

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated Successfully")));
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Applications")),
      body: StreamBuilder<List<Booking>>(
        stream: FirestoreService.instance.getUserBookings(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return const Center(child: Text("No applications yet."));

          return ListView.builder(
            itemCount: bookings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final b = bookings[index];
              final isPending = b.status == 'Pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.eventTitle ?? "Event", style: const TextStyle(fontWeight: FontWeight.bold)),
                          _statusChip(b.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Booth: ${b.boothName}"),
                      Text("Date: ${b.startDate}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("Industry: ${b.industry}"),

                      // --- ADDED: SHOW DESCRIPTION ---
                      // This ensures Exhibitor sees updates made by Admin
                      Text("Desc: ${b.description}", style: const TextStyle(fontStyle: FontStyle.italic)),
                      // -------------------------------

                      Text("Add-ons: ${b.addOns}"),
                      if (b.status == 'Rejected') Text("Reason: ${b.rejectionReason}", style: const TextStyle(color: Colors.red)),

                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPending)
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text("Edit"),
                              onPressed: () => _editApplication(b),
                            ),
                          if (isPending || b.status == 'Approved')
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              label: const Text("Cancel", style: TextStyle(color: Colors.red)),
                              onPressed: () => _cancelApplication(b.id!),
                            ),
                        ],
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

  Widget _statusChip(String status) {
    Color c = Colors.orange;
    if (status == 'Approved') c = Colors.green;
    if (status == 'Rejected' || status == 'Cancelled') c = Colors.red;
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: c,
      padding: EdgeInsets.zero,
    );
  }
}