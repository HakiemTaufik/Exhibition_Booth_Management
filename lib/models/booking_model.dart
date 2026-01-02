class Booking {
  final String? id;
  final String userId;
  final String boothId;
  final String eventId;
  final String companyName;
  final String description;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Cancelled'
  final String industry;
  final String addOns;
  final String boothName; // Stored for display
  final String eventTitle; // Stored for display
  final String exhibitorEmail;
  final String? rejectionReason; // <--- NEW FIELD ADDED

  Booking({
    this.id,
    required this.userId,
    required this.boothId,
    required this.eventId,
    required this.companyName,
    required this.description,
    required this.status,
    required this.industry,
    required this.addOns,
    required this.boothName,
    required this.eventTitle,
    required this.exhibitorEmail,
    this.rejectionReason, // <--- Added to constructor
  });

  // Convert Booking to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'boothId': boothId,
      'eventId': eventId,
      'companyName': companyName,
      'description': description,
      'status': status,
      'industry': industry,
      'addOns': addOns,
      'boothName': boothName,
      'eventTitle': eventTitle,
      'exhibitorEmail': exhibitorEmail,
      'rejectionReason': rejectionReason, // <--- Save to DB
    };
  }

  // Create Booking from Firestore Map
  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      userId: map['userId'] ?? '',
      boothId: map['boothId'] ?? '',
      eventId: map['eventId'] ?? '',
      companyName: map['companyName'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Pending',
      industry: map['industry'] ?? '',
      addOns: map['addOns'] ?? '',
      boothName: map['boothName'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      exhibitorEmail: map['exhibitorEmail'] ?? '',
      rejectionReason: map['rejectionReason'], // <--- Read from DB
    );
  }
}