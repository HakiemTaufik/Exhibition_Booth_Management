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

  void _togglePublish(Event event) {
    final updated = Event(
      id: event.id,
      organizerId: event.organizerId,
      title: event.title,
      description: event.description,
      date: event.date,
      status: event.status,
      location: event.location,
      isPublished: event.isPublished == 1 ? 0 : 1, // Flip status
      floorPlanImage: event.floorPlanImage,
    );
    FirestoreService.instance.updateEvent(updated);
  }

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
              stream: FirestoreService.instance.getAllEvents(publishedOnly: false), // Fetch EVERYTHING
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final events = snapshot.data!;
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.isPublished == 1 ? "Published" : "Draft (Hidden)"),
                      trailing: Switch(
                        value: event.isPublished == 1,
                        activeColor: Colors.green,
                        onChanged: (val) => _togglePublish(event),
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrganizerEventDashboard(user: user, event: event))),
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