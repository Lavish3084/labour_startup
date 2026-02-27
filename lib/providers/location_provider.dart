import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SavedLocation {
  final String id;
  final String label; // e.g., 'Home', 'Work'
  final String address;
  final String houseNumber;
  final String landmark;
  final double latitude;
  final double longitude;

  SavedLocation({
    required this.id,
    required this.label,
    required this.address,
    required this.houseNumber,
    required this.landmark,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'address': address,
    'houseNumber': houseNumber,
    'landmark': landmark,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    id: json['id'],
    label: json['label'],
    address: json['address'],
    houseNumber: json['houseNumber'],
    landmark: json['landmark'],
    latitude: json['latitude'],
    longitude: json['longitude'],
  );
}

class LocationProvider with ChangeNotifier {
  List<SavedLocation> _savedLocations = [];
  bool _isLoading = false;

  String? _currentAddress;
  String? _currentHouseNumber;
  String? _currentLandmark;
  double? _currentLatitude;
  double? _currentLongitude;

  List<SavedLocation> get savedLocations => _savedLocations;
  bool get isLoading => _isLoading;
  String? get currentAddress => _currentAddress;
  String? get currentHouseNumber => _currentHouseNumber;
  String? get currentLandmark => _currentLandmark;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;

  LocationProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadSavedLocations();
    await _loadCurrentAddress();
  }

  Future<String> _getScopedKey(String baseKey) async {
    final email = await ApiService.getEmail();
    if (email == null) return baseKey;
    // Sanitize email for use as key if necessary, though simple append usually works for SP
    return '${baseKey}_$email';
  }

  Future<void> _loadCurrentAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressKey = await _getScopedKey('current_address');
      final houseKey = await _getScopedKey('current_house_number');
      final landmarkKey = await _getScopedKey('current_landmark');
      final latKey = await _getScopedKey('current_latitude');
      final lonKey = await _getScopedKey('current_longitude');

      _currentAddress = prefs.getString(addressKey);
      _currentHouseNumber = prefs.getString(houseKey);
      _currentLandmark = prefs.getString(landmarkKey);
      _currentLatitude = prefs.getDouble(latKey);
      _currentLongitude = prefs.getDouble(lonKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current address: $e');
    }
  }

  Future<void> updateCurrentAddress({
    required String address,
    String? houseNumber,
    String? landmark,
    double? latitude,
    double? longitude,
  }) async {
    _currentAddress = address;
    _currentHouseNumber = houseNumber;
    _currentLandmark = landmark;
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _getScopedKey('current_address'), address);
      if (houseNumber != null) {
        await prefs.setString(
          await _getScopedKey('current_house_number'),
          houseNumber,
        );
      }
      if (landmark != null) {
        await prefs.setString(
          await _getScopedKey('current_landmark'),
          landmark,
        );
      }
      if (latitude != null) {
        await prefs.setDouble(
          await _getScopedKey('current_latitude'),
          latitude,
        );
      }
      if (longitude != null) {
        await prefs.setDouble(
          await _getScopedKey('current_longitude'),
          longitude,
        );
      }
    } catch (e) {
      debugPrint('Error persisting current address: $e');
    }
  }

  Future<void> loadSavedLocations() async {
    final email = await ApiService.getEmail();
    if (email == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load from Local first for speed
      final prefs = await SharedPreferences.getInstance();
      final String? locationsJson = prefs.getString(
        await _getScopedKey('saved_locations'),
      );
      if (locationsJson != null) {
        final List<dynamic> decoded = jsonDecode(locationsJson);
        _savedLocations =
            decoded.map((item) => SavedLocation.fromJson(item)).toList();
        notifyListeners();
      }

      // 2. Sync from Backend to ensure fresh data (Optional but recommended)
      final profile = await ApiService.getProfile();
      print(
        'LocationProvider: Profile received from backend. User has addresses: ${profile['user']?['addresses']?.length ?? 0}',
      );
      if (profile['user'] != null && profile['user']['addresses'] != null) {
        final List<dynamic> backendAddresses = profile['user']['addresses'];
        print(
          'LocationProvider: Parsing ${backendAddresses.length} addresses from backend',
        );
        _savedLocations =
            backendAddresses.map((item) {
              return SavedLocation(
                id: item['_id'],
                label: item['label'],
                address: item['address'],
                houseNumber: item['houseNumber'] ?? '',
                landmark: item['landmark'] ?? '',
                latitude: (item['latitude'] as num?)?.toDouble() ?? 0.0,
                longitude: (item['longitude'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList();
        print(
          'LocationProvider: Successfully loaded ${_savedLocations.length} locations',
        );
        await _persistLocations();
      }
    } catch (e) {
      debugPrint('Error loading saved locations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLocation(SavedLocation location) async {
    print('LocationProvider: saveLocation called for ${location.label}');
    // 1. Save to Backend
    await ApiService.addSavedAddress({
      'label': location.label,
      'address': location.address,
      'houseNumber': location.houseNumber,
      'landmark': location.landmark,
      'latitude': location.latitude,
      'longitude': location.longitude,
    });

    // 2. Refresh from backend to get the real ID or just update locally
    // For simplicity, let's just reload.
    await loadSavedLocations();
  }

  Future<void> deleteLocation(String id) async {
    // 1. Delete from Backend
    await ApiService.deleteSavedAddress(id);

    // 2. Update locally regardless
    _savedLocations.removeWhere((loc) => loc.id == id);
    notifyListeners();
    await _persistLocations();
  }

  Future<void> _persistLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _savedLocations.map((loc) => loc.toJson()).toList(),
      );
      await prefs.setString(await _getScopedKey('saved_locations'), encoded);
    } catch (e) {
      debugPrint('Error persisting locations: $e');
    }
  }

  void clearData() {
    _savedLocations = [];
    _currentAddress = null;
    _currentHouseNumber = null;
    _currentLandmark = null;
    _currentLatitude = null;
    _currentLongitude = null;
    notifyListeners();
  }
}
