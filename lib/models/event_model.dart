class Event {
  final String? id;
  final String organizerId;
  final String title;
  final String description;
  final String date;
  final String location;
  final String status; // Fixed: Added status field
  final int isPublished;
  final String? floorPlanImage; // Fixed: Added floorPlanImage field

  Event({
    this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.status, // Fixed: Added to constructor
    required this.isPublished,
    this.floorPlanImage, // Fixed: Added to constructor
  });

  // Convert Event to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'status': status, // Save status to DB
      'isPublished': isPublished,
      'floorPlanImage': floorPlanImage, // Save image URL to DB
    };
  }

  // Create Event from Firestore Map
  factory Event.fromMap(Map<String, dynamic> map, String documentId) {
    return Event(
      id: documentId,
      organizerId: map['organizerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'Upcoming', // Default to 'Upcoming' if null
      isPublished: map['isPublished'] ?? 0,
      floorPlanImage: map['floorPlanImage'], // Nullable
    );
  }
}