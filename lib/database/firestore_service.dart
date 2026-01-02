import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/booking_model.dart';
import '../models/booth_model.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- AUTH & USER METHODS ---

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<void> createUserProfile(String uid, String email, String role) async {
    await _db.collection('users').doc(uid).set({'email': email, 'role': role});
  }

  // [FIX] Added Missing Method: getAllUsers
  Stream<List<AppUser>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // [FIX] Added Missing Method: deleteUser
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // --- EVENT METHODS ---

  Stream<List<Event>> getEventsForOrganizer(String uid) {
    return _db.collection('events').where('organizerId', isEqualTo: uid).snapshots()
        .map((s) => s.docs.map((d) => Event.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Event>> getAllEvents({bool publishedOnly = true}) {
    Query query = _db.collection('events');
    if (publishedOnly) query = query.where('isPublished', isEqualTo: 1);
    return query.snapshots().map((s) => s.docs.map((d) => Event.fromMap(d.data() as Map<String,dynamic>, d.id)).toList());
  }

  Future<void> createEvent(Event event) => _db.collection('events').add(event.toMap());

  Future<void> updateEvent(Event event) => _db.collection('events').doc(event.id).update(event.toMap());

  Future<void> deleteEvent(String id) => _db.collection('events').doc(id).delete();

  // --- BOOTH METHODS ---

  Stream<List<Booth>> getBoothsForEvent(String eventId) {
    return _db.collection('booths').where('eventId', isEqualTo: eventId).snapshots()
        .map((s) {
      final list = s.docs.map((d) => Booth.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> createBooth(Booth booth) => _db.collection('booths').add(booth.toMap());

  Future<void> deleteBooth(String id) => _db.collection('booths').doc(id).delete();

  // --- BOOKING METHODS ---

  Future<void> createBooking(Booking booking) async {
    final batch = _db.batch();
    final bookingRef = _db.collection('bookings').doc();
    batch.set(bookingRef, booking.toMap());

    // Set Booth to Booked
    final boothRef = _db.collection('booths').doc(booking.boothId);
    batch.update(boothRef, {'status': 'Booked'});

    await batch.commit();
  }

  Stream<List<Booking>> getBookingsForEvent(String eventId) {
    return _db.collection('bookings').where('eventId', isEqualTo: eventId).snapshots()
        .map((s) => s.docs.map((d) => Booking.fromMap(d.data(), d.id)).toList());
  }

  // [FIX] Added Missing Method: getUserBookings
  Stream<List<Booking>> getUserBookings(String userId) {
    return _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status, String? reason) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    if (status == 'Rejected' || status == 'Cancelled') {
      // If Rejected/Cancelled, we must free the booth
      final bookingSnapshot = await bookingRef.get();
      final boothId = bookingSnapshot.data()?['boothId'];

      final batch = _db.batch();
      batch.update(bookingRef, {'status': status, 'rejectionReason': reason});
      if (boothId != null) {
        batch.update(_db.collection('booths').doc(boothId), {'status': 'Available'});
      }
      await batch.commit();
    } else {
      // Just approve
      await bookingRef.update({'status': status});
    }
  }
  // Update Booking Description & Add-ons
  Future<void> updateBookingDetails(String bookingId, String description, String addOns) async {
    await _db.collection('bookings').doc(bookingId).update({
      'description': description,
      'addOns': addOns,
    });
  }
}