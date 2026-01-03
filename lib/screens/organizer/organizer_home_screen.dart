import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../database/firestore_service.dart';
import 'edit_event_screen.dart';
import 'organizer_event_dashboard.dart';
import '../auth/welcome_screen.dart';

class OrganizerHomeScreen extends StatelessWidget {
  final AppUser user;
  const OrganizerHomeScreen({super.key, required this.user});

  // --- DELETE CONFIRMATION DIALOG ---
  void _deleteEvent(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("This cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirestoreService.instance.deleteEvent(eventId);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Event deleted successfully")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  // ----------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Exhibitions"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        // --- FIXED: Changed 'getEventsByOrganizer' to 'getEventsForOrganizer' ---
        stream: FirestoreService.instance.getEventsForOrganizer(user.id!),
        // -----------------------------------------------------------------------
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditEventScreen(user: user))),
                child: const Text("Create First Event"),
              ),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final event = events[index];

              // --- DATE FORMATTING LOGIC ---
              String formattedDate = "${event.startDate} - ${event.endDate}";
              try {
                // Parse "08/01/2026" -> Display "Jan 08, 2026"
                final inputFormat = DateFormat("d/M/yyyy");
                DateTime start = inputFormat.parse(event.startDate);
                DateTime end = inputFormat.parse(event.endDate);

                final outputFormat = DateFormat('MMM dd, yyyy');
                formattedDate = "${outputFormat.format(start)} - ${outputFormat.format(end)}";
              } catch (e) {
                // Ignore errors, keep original string
              }
              // --------------------------------

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),

                  // Use the FORMATTED date here
                  subtitle: Text("$formattedDate • ${event.status}"),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEvent(context, event.id!),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => OrganizerEventDashboard(user: user, event: event)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditEventScreen(user: user))),
        child: const Icon(Icons.add),
      ),
    );
  }
}