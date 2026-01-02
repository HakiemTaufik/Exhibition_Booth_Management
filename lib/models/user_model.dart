class AppUser {
  final String? id; // Firebase UID
  final String email;
  final String role; // 'Exhibitor', 'Organizer', 'Administrator'

  AppUser({this.id, required this.email, required this.role});

  Map<String, dynamic> toMap() => {'email': email, 'role': role};

  static AppUser fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      id: docId,
      email: map['email'] ?? '',
      role: map['role'] ?? 'Exhibitor',
    );
  }
}