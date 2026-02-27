import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppStateProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;
  List<dynamic> _bookings = [];
  bool _isProfileLoading = false;
  bool _isBookingsLoading = false;
  String? _profileError;
  String? _bookingsError;

  Map<String, dynamic>? get profileData => _profileData;
  List<dynamic> get bookings => _bookings;
  bool get isProfileLoading => _isProfileLoading;
  bool get isBookingsLoading => _isBookingsLoading;
  String? get profileError => _profileError;
  String? get bookingsError => _bookingsError;

  Future<void> fetchProfile() async {
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      _profileData = await ApiService.getProfile();
    } catch (e) {
      _profileError = e.toString();
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookings() async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();

    try {
      _bookings = await ApiService.getUserBookings();
    } catch (e) {
      _bookingsError = e.toString();
    } finally {
      _isBookingsLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _profileData = null;
    _bookings = [];
    _profileError = null;
    _bookingsError = null;
    notifyListeners();
  }
}
