class Booth {
  final String? id;
  final String eventId;
  final String name;
  final double price;
  final String status; // 'Available', 'Booked'
  final String dimensions;

  Booth({
    this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.status,
    required this.dimensions,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'price': price,
      'status': status,
      'dimensions': dimensions,
    };
  }

  // Create from Firestore
  factory Booth.fromMap(Map<String, dynamic> map, String documentId) {
    return Booth(
      id: documentId,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      status: map['status'] ?? 'Available',
      dimensions: map['dimensions'] ?? '3x3',
    );
  }
}