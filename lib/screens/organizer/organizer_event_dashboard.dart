import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/booth_model.dart';
import '../../database/firestore_service.dart';
import 'edit_event_screen.dart';
import 'manage_bookings_screen.dart'; // <--- ADD THIS IMPORT

class OrganizerEventDashboard extends StatefulWidget {
  final AppUser user;
  final Event event;

  const OrganizerEventDashboard({super.key, required this.user, required this.event});

  @override
  State<OrganizerEventDashboard> createState() => _OrganizerEventDashboardState();
}

class _OrganizerEventDashboardState extends State<OrganizerEventDashboard> {

  // Function to show "Add Booth" Dialog
  void _showAddBoothDialog() {
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Booth"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Booth Name (e.g. A-1)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price (RM)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                final newBooth = Booth(
                  eventId: widget.event.id!,
                  name: _nameController.text,
                  price: double.tryParse(_priceController.text) ?? 0.0,
                  status: 'Available',
                  dimensions: '3x3',
                );
                await FirestoreService.instance.createBooth(newBooth);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Function to delete booth
  void _deleteBooth(String boothId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Booth?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirestoreService.instance.deleteBooth(boothId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventScreen(user: widget.user, event: widget.event),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- TOP SECTION: EVENT DETAILS & IMAGE ---
          if (widget.event.floorPlanImage != null && widget.event.floorPlanImage!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.black12,
              child: Image.network(
                widget.event.floorPlanImage!,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.event.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.event.location, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: widget.event.isPublished == 1 ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(
                    widget.event.isPublished == 1 ? "Published" : "Draft",
                    style: TextStyle(color: widget.event.isPublished == 1 ? Colors.green : Colors.orange),
                  ),
                )
              ],
            ),
          ),

          // --- NEW BUTTON: REVIEW APPLICATIONS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assignment_ind, color: Colors.white),
                label: const Text("Review Applications / Bookings", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => ManageBookingsScreen(event: widget.event))
                  );
                },
              ),
            ),
          ),
          // ---------------------------------------

          const Divider(),

          // --- BOTTOM SECTION: BOOTH MANAGEMENT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Booths", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Manage your layout below", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Booth>>(
              stream: FirestoreService.instance.getBoothsForEvent(widget.event.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No booths added yet. Tap + to add."));
                }

                final booths = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: booths.length,
                  itemBuilder: (context, index) {
                    final booth = booths[index];
                    final isBooked = booth.status == 'Booked';

                    return GestureDetector(
                      onLongPress: () => _deleteBooth(booth.id!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.red[100] : Colors.green[100],
                          border: Border.all(color: isBooked ? Colors.red : Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(booth.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("RM${booth.price.toInt()}", style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(booth.status, style: TextStyle(fontSize: 10, color: isBooked ? Colors.red : Colors.green[800])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- ADD BOOTH BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBoothDialog,
        label: const Text("Add Booth"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}