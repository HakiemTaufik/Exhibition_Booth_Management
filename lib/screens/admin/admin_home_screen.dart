import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../database/firestore_service.dart';
import 'admin_manage_users_screen.dart';
import '../organizer/organizer_event_dashboard.dart';
import '../auth/welcome_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final AppUser user;
  const AdminHomeScreen({super.key, required this.user});

  // Logic to toggle Published/Draft status
  void _togglePublish(Event event) {
    final updated = Event(
      id: event.id,
      organizerId: event.organizerId,
      title: event.title,
      description: event.description,
      startDate: event.startDate,
      endDate: event.endDate,
      status: event.status,
      location: event.location,
      isPublished: event.isPublished == 1 ? 0 : 1, // Flip status
      floorPlanImage: event.floorPlanImage,
    );
    FirestoreService.instance.updateEvent(updated);
  }

  // --- NEW: CONFIRMATION REMINDER DIALOG ---
  void _deleteEvent(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Event?"),
        // This is the "Reminder" text
        content: const Text(
          "Are you sure you want to delete this event?\n\nThis will permanently remove all data and cannot be undone.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c), // Close dialog, do nothing
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // 1. Actually delete from database
              FirestoreService.instance.deleteEvent(eventId);
              // 2. Close the dialog
              Navigator.pop(c);
              // 3. Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Event deleted successfully"))
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushAndRemoveUntil(
                context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false),
          )
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blue),
            title: const Text("Manage Users"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageUsersScreen())),
          ),
          const Divider(),
          const Padding(padding: EdgeInsets.all(16), child: Text("All Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),

          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: FirestoreService.instance.getAllEvents(publishedOnly: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final events = snapshot.data!;

                if (events.isEmpty) return const Center(child: Text("No events found."));

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Date
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text("${event.startDate} - ${event.endDate}", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Location
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(event.location, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Status
                            Text(
                              event.isPublished == 1 ? "Published" : "Draft (Hidden)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: event.isPublished == 1 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        // --- UPDATED BUTTONS ---
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Publish Switch
                            Switch(
                              value: event.isPublished == 1,
                              activeColor: Colors.green,
                              onChanged: (val) => _togglePublish(event),
                            ),
                            // Delete Button (Calls the Reminder Dialog)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete Event",
                              onPressed: () => _deleteEvent(context, event.id!), // <--- Trigger Reminder Here
                            ),
                          ],
                        ),
                        // -----------------------

                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrganizerEventDashboard(user: user, event: event))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}