class Event {
  final String? id;
  final String organizerId;
  final String title;
  final String description;
  final String location;
  final String status;
  final int isPublished;
  final String? floorPlanImage;

  // --- CHANGED: Split 'date' into start and end ---
  final String startDate;
  final String endDate;

  Event({
    this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.isPublished,
    this.floorPlanImage,
    // --- REQUIRED IN CONSTRUCTOR ---
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'isPublished': isPublished,
      'floorPlanImage': floorPlanImage,
      // --- SAVE TO DB ---
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, String documentId) {
    return Event(
      id: documentId,
      organizerId: map['organizerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'Upcoming',
      isPublished: map['isPublished'] ?? 0,
      floorPlanImage: map['floorPlanImage'],
      // --- READ FROM DB (Fallback to 'date' if old data exists) ---
      startDate: map['startDate'] ?? map['date'] ?? '',
      endDate: map['endDate'] ?? map['date'] ?? '',
    );
  }
}