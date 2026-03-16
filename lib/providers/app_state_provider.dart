import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';

class AppStateProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;
  List<dynamic> _bookings = [];
  List<ServiceCategory> _categories = [];
  bool _isProfileLoading = false;
  bool _isBookingsLoading = false;
  bool _isCategoriesLoading = false;
  String? _profileError;
  String? _bookingsError;
  String? _categoriesError;

  Map<String, dynamic>? get profileData => _profileData;
  List<dynamic> get bookings => _bookings;
  List<ServiceCategory> get categories => _categories;
  bool get isProfileLoading => _isProfileLoading;
  bool get isBookingsLoading => _isBookingsLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get profileError => _profileError;
  String? get bookingsError => _bookingsError;
  String? get categoriesError => _categoriesError;

  Future<void> fetchProfile() async {
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      _profileData = await ApiService.getProfile();
    } catch (e) {
      _profileError = ErrorHandler.getErrorMessage(e);
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
      _bookingsError = ErrorHandler.getErrorMessage(e, action: 'Failed to load bookings');
    } finally {
      _isBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    // Load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_categories');
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedData);
        _categories =
            decoded.map((json) => ServiceCategory.fromJson(json)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading cached categories: $e');
      }
    }

    // Always fetch from API in background
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    _isCategoriesLoading = true;
    _categoriesError = null;
    // Don't notify listeners here if we already have cached data to avoid UI jump
    if (_categories.isEmpty) notifyListeners();

    try {
      final freshCategories = await ApiService.getCategories();
      _categories = freshCategories;

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await prefs.setString('cached_categories', encoded);
    } catch (e) {
      _categoriesError = ErrorHandler.getErrorMessage(e, action: 'Failed to load categories');
    } finally {
      _isCategoriesLoading = false;
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
