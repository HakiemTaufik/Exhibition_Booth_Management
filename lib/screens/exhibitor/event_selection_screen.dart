import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../database/firestore_service.dart';
import 'booth_selection_screen.dart';

class EventSelectionScreen extends StatefulWidget {
  final AppUser user;
  const EventSelectionScreen({super.key, required this.user});

  @override
  State<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  String _search = "";
  String _filter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Browse Events")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: "Search", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: FirestoreService.instance.getAllEvents(publishedOnly: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Client-side filtering
                final events = snapshot.data!.where((e) {
                  final matchTitle = e.title.toLowerCase().contains(_search.toLowerCase());
                  final matchStatus = _filter == "All" || e.status == _filter;
                  return matchTitle && matchStatus;
                }).toList();

                if (events.isEmpty) return const Center(child: Text("No matching events"));

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.location),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BoothSelectionScreen(user: widget.user, event: event))),
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