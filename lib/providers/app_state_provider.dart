import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_category.dart';
import '../models/labourer.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';

class AppStateProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;
  List<dynamic> _bookings = [];
  List<ServiceCategory> _categories = [];
  int _selectedTab = 0;
  String _searchQuery = '';
  List<dynamic> _labourers = [];
  bool _isProfileLoading = false;
  bool _isBookingsLoading = false;
  bool _isCategoriesLoading = false;
  bool _isLabourersLoading = false;
  String? _profileError;
  String? _bookingsError;
  String? _categoriesError;
  String? _labourersError;
  double _walletBalance = 0.0;
  List<dynamic> _walletTransactions = [];

  Map<String, dynamic>? get profileData => _profileData;
  List<dynamic> get bookings => _bookings;
  List<ServiceCategory> get categories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where((c) => _fuzzyMatch(_searchQuery, c.name))
        .toList();
  }

  bool _fuzzyMatch(String query, String target) {
    query = query.toLowerCase();
    target = target.toLowerCase();
    
    if (target.contains(query)) return true;
    
    int queryIdx = 0;
    for (int targetIdx = 0; targetIdx < target.length; targetIdx++) {
      if (queryIdx < query.length && target[targetIdx] == query[queryIdx]) {
        queryIdx++;
      }
    }
    return queryIdx == query.length;
  }
  int get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;
  List<dynamic> get labourers => _labourers;
  bool get isProfileLoading => _isProfileLoading;
  bool get isBookingsLoading => _isBookingsLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  bool get isLabourersLoading => _isLabourersLoading;
  String? get profileError => _profileError;
  String? get bookingsError => _bookingsError;
  String? get categoriesError => _categoriesError;
  String? get labourersError => _labourersError;
  double get walletBalance => _walletBalance;
  List<dynamic> get walletTransactions => _walletTransactions;

  Future<void> fetchProfile() async {
    _isProfileLoading = true;
    _profileError = null;

    // Try to load from local cache first
    if (_profileData == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('cached_profile');
        if (cachedData != null) {
          _profileData = jsonDecode(cachedData);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error loading cached profile: $e');
      }
    } else {
      notifyListeners();
    }

    try {
      final freshProfile = await ApiService.getProfile();
      _profileData = freshProfile;

      // Save to local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_profile', jsonEncode(freshProfile));

      // Also fetch wallet balance if profile succeeds
      fetchWalletBalance();
    } catch (e) {
      _profileError = ErrorHandler.getErrorMessage(e);
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      _walletBalance = await ApiService.getWalletBalance();
      _walletTransactions = await ApiService.getWalletTransactions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
    }
  }

  Future<bool> cancelBooking(Map<String, dynamic> booking) async {
    try {
      final String bookingId = booking['_id'];
      final bool hasWorker = booking['labourerId'] != null || booking['labourer'] != null;
      
      final success = await ApiService.updateBookingStatus(bookingId, 'cancelled');
      if (success) {
        if (!hasWorker) {
          // Simulate refund if no worker was assigned
          // In a real app, the backend should do this and we just refresh balance
          await fetchWalletBalance();
        }
        await fetchBookings();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
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

  Future<void> fetchLabourers() async {
    _isLabourersLoading = true;
    _labourersError = null;
    notifyListeners();

    try {
      final fetchedLabourers = await ApiService.getLabourers();
      _labourers = fetchedLabourers.map((l) => l.toJson()).toList();
    } catch (e) {
      _labourersError = ErrorHandler.getErrorMessage(e, action: 'Failed to load workers');
    } finally {
      _isLabourersLoading = false;
      notifyListeners();
    }
  }

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearData() {
    _profileData = null;
    _bookings = [];
    _profileError = null;
    _bookingsError = null;
    _searchQuery = '';
    
    // Clear local cache asynchronously
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('cached_profile');
    }).catchError((e) {
      debugPrint('Error clearing cached profile: $e');
    });
    
    notifyListeners();
  }
}
