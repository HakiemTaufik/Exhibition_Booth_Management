class AppUser {
  final String? id; // Firebase UID
  final String email;
  final String role; // 'Exhibitor', 'Organizer', 'Administrator'
  final bool isDisabled; // --- NEW FIELD ---

  AppUser({
    this.id,
    required this.email,
    required this.role,
    this.isDisabled = false, // Default is active
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'isDisabled': isDisabled, // --- SAVE TO DB ---
    };
  }

  static AppUser fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      id: docId,
      email: map['email'] ?? '',
      role: map['role'] ?? 'Exhibitor',
      isDisabled: map['isDisabled'] ?? false, // --- READ FROM DB ---
    );
  }
}