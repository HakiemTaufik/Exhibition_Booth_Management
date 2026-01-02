import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../database/firestore_service.dart';
import 'edit_event_screen.dart';
import 'organizer_event_dashboard.dart';
import '../auth/welcome_screen.dart';

class OrganizerHomeScreen extends StatelessWidget {
  final AppUser user;
  const OrganizerHomeScreen({super.key, required this.user});

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
        stream: FirestoreService.instance.getEventsForOrganizer(user.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditEventScreen(user: user))),
                child: const Text("Create Event"),
              ),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // [FIXED] Use startDate and endDate here
                  subtitle: Text("${event.startDate} - ${event.endDate} • ${event.status}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirestoreService.instance.deleteEvent(event.id!),
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