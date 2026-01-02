import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../database/firestore_service.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  // Fetch and cache user data
  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await FirestoreService.instance.getCurrentUser();
    } catch (e) {
      print("Error fetching user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}