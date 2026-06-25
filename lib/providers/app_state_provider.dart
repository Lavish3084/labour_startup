import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_category.dart';
import '../models/labourer.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';

class AppStateProvider with ChangeNotifier, WidgetsBindingObserver {
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

  // Language & Locale Settings
  String _languageCode = 'en';
  String? _manualLanguageCode;

  String get languageCode => _languageCode;
  String? get manualLanguageCode => _manualLanguageCode;

  AppStateProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initLanguage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _manualLanguageCode = prefs.getString('manual_language_code');
    _updateActiveLanguage();
  }

  void _updateActiveLanguage() {
    if (_manualLanguageCode != null) {
      _languageCode = _manualLanguageCode!;
    } else {
      // Get phone's system language
      final systemLocales = PlatformDispatcher.instance.locales;
      if (systemLocales.isNotEmpty) {
        final sysLang = systemLocales.first.languageCode.toLowerCase();
        if (sysLang == 'hi') {
          _languageCode = 'hi';
        } else if (sysLang == 'pa') {
          _languageCode = 'pa';
        } else {
          _languageCode = 'en'; // default for rest is English
        }
      } else {
        _languageCode = 'en';
      }
    }
    notifyListeners();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    // Dynamically update active language when device locale changes and no manual override exists
    if (_manualLanguageCode == null) {
      _updateActiveLanguage();
    }
  }

  Future<void> setManualLanguage(String? langCode) async {
    _manualLanguageCode = langCode;
    final prefs = await SharedPreferences.getInstance();
    if (langCode != null) {
      await prefs.setString('manual_language_code', langCode);
    } else {
      await prefs.remove('manual_language_code');
    }
    _updateActiveLanguage();
  }

  double _walletBalance = 0.0;
  List<dynamic> _walletTransactions = [];
  Map<String, dynamic> _settings = {};

  Map<String, dynamic>? get profileData => _profileData;
  Map<String, dynamic> get settings => _settings;
  List<dynamic> get bookings => _bookings;
  List<ServiceCategory> get categories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories.where((c) => _fuzzyMatch(_searchQuery, c.name)).toList();
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
      final bool hasWorker =
          booking['labourerId'] != null || booking['labourer'] != null;

      final success = await ApiService.updateBookingStatus(
        bookingId,
        'cancelled',
      );
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
      _bookingsError = ErrorHandler.getErrorMessage(
        e,
        action: 'Failed to load bookings',
      );
    } finally {
      _isBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    // Also load settings
    loadSettings();

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

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_settings');
    if (cachedData != null) {
      try {
        _settings = jsonDecode(cachedData);
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading cached settings: $e');
      }
    }
    await fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      final freshSettings = await ApiService.getSettings();
      _settings = freshSettings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_settings', jsonEncode(freshSettings));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching settings from API: $e');
    }
  }

  bool isCityEnabled(String? locationStr) {
    final String? enabledCitiesStr = _settings['enabledCities']?.toString();
    if (enabledCitiesStr == null || enabledCitiesStr.trim().isEmpty) {
      return true;
    }
    if (locationStr == null || locationStr.trim().isEmpty) {
      return false;
    }
    final List<String> enabledCitiesList =
        enabledCitiesStr
            .split(',')
            .map((city) => city.trim().toLowerCase())
            .where((city) => city.isNotEmpty)
            .toList();
    if (enabledCitiesList.isEmpty) {
      return true;
    }
    final String searchStr = locationStr.trim().toLowerCase();
    for (final city in enabledCitiesList) {
      if (searchStr.contains(city)) {
        return true;
      }
    }
    return false;
  }

  /// Production-ready coordinate-based zone check using Haversine formula.
  /// Returns true if the given coordinates fall inside any configured service zone.
  /// Falls back to legacy text-based check if no zones are configured.
  bool isCityEnabledByCoordinates(
    double? lat,
    double? lng, {
    String? fallbackAddress,
  }) {
    // Parse service zones from settings
    final List<Map<String, dynamic>> zones = _parseServiceZones();

    // If zones are configured, use coordinate-based Haversine check
    if (zones.isNotEmpty) {
      if (lat == null || lng == null) {
        // No coordinates available yet, fallback to text check
        return isCityEnabled(fallbackAddress);
      }
      for (final zone in zones) {
        final double? zoneLat = _toDouble(zone['lat']);
        final double? zoneLng = _toDouble(zone['lng']);
        final double radiusKm = _toDouble(zone['radiusKm']) ?? 15.0;

        if (zoneLat == null || zoneLng == null) continue;

        final double distance = _haversineKm(lat, lng, zoneLat, zoneLng);
        if (distance <= radiusKm) {
          return true;
        }
      }
      return false;
    }

    // No zones configured — fall back to legacy text-based check
    return isCityEnabled(fallbackAddress);
  }

  /// Parse serviceZones from settings. Handles both JSON string and List formats.
  List<Map<String, dynamic>> _parseServiceZones() {
    final dynamic rawZones = _settings['serviceZones'];
    if (rawZones == null) return [];

    List<dynamic> zonesList;
    if (rawZones is String) {
      try {
        zonesList = jsonDecode(rawZones);
      } catch (_) {
        return [];
      }
    } else if (rawZones is List) {
      zonesList = rawZones;
    } else {
      return [];
    }

    return zonesList.whereType<Map<String, dynamic>>().toList();
  }

  /// Haversine formula — calculates great-circle distance between two GPS points.
  /// Returns distance in kilometers. Uses dart:math for precision.
  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double deg) => deg * math.pi / 180.0;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
      _categoriesError = ErrorHandler.getErrorMessage(
        e,
        action: 'Failed to load categories',
      );
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
      _labourersError = ErrorHandler.getErrorMessage(
        e,
        action: 'Failed to load workers',
      );
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
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.remove('cached_profile');
        })
        .catchError((e) {
          debugPrint('Error clearing cached profile: $e');
        });

    notifyListeners();
  }
}

extension LocalizationExtension on BuildContext {
  String t(String en, String hi, [String? pa]) {
    try {
      final provider = Provider.of<AppStateProvider>(this);
      final lang = provider.languageCode;
      if (lang == 'hi') return hi;
      if (lang == 'pa') return pa ?? en;
      return en;
    } catch (_) {
      return en;
    }
  }

  bool get isHindi {
    try {
      final provider = Provider.of<AppStateProvider>(this);
      return provider.languageCode == 'hi';
    } catch (_) {
      return false;
    }
  }

  bool get isPunjabi {
    try {
      final provider = Provider.of<AppStateProvider>(this);
      return provider.languageCode == 'pa';
    } catch (_) {
      return false;
    }
  }

  bool get isEnglish {
    try {
      final provider = Provider.of<AppStateProvider>(this);
      return provider.languageCode == 'en';
    } catch (_) {
      return true;
    }
  }
}
