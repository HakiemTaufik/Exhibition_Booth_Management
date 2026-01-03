import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../database/firestore_service.dart';
import '../../models/event_model.dart';
import 'event_details_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guest Access")),
      body: Column(
        children: [
          // Styled Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search Events",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: FirestoreService.instance.getAllEvents(publishedOnly: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final events = snapshot.data!.where((e) => e.title.toLowerCase().contains(_search.toLowerCase())).toList();

                if (events.isEmpty) return const Center(child: Text("No matching events"));

                return ListView.builder(
                  itemCount: events.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];

                    // --- DATE FORMATTING ---
                    String formattedDate = "${event.startDate} - ${event.endDate}";
                    try {
                      final inputFormat = DateFormat("d/M/yyyy");
                      DateTime start = inputFormat.parse(event.startDate);
                      DateTime end = inputFormat.parse(event.endDate);
                      final outputFormat = DateFormat('MMM dd, yyyy');
                      formattedDate = "${outputFormat.format(start)} - ${outputFormat.format(end)}";
                    } catch (e) {
                      // Ignore errors
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Image Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: (event.floorPlanImage != null &&
                                      event.floorPlanImage!.isNotEmpty &&
                                      event.floorPlanImage!.startsWith('http'))
                                      ? event.floorPlanImage!
                                      : "https://via.placeholder.com/150",

                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                      width: 60, height: 60, color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                      width: 60, height: 60, color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey)
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Left Side: Event Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),

                                    // Date Row (FIXED: Added Expanded to prevent overflow)
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Expanded( // <--- THIS FIXES THE OVERFLOW
                                          child: Text(
                                            formattedDate,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Location Row (FIXED: Added Expanded)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                                        const SizedBox(width: 6),
                                        Expanded( // <--- THIS FIXES THE OVERFLOW
                                          child: Text(
                                            event.location,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8), // Padding between text and badge

                              // Right Side: Status Badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      event.status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[800]),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}