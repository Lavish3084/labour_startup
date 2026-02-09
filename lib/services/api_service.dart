import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/labourer.dart';
import 'notification_service.dart';

class ApiService {
  static const String baseUrl = Config.baseUrl;

  // Authentication
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String role,
    String? profilePicture,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'profilePicture': profilePicture,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthData(data['token'], data['role'], data['name']);
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Signup failed'};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthData(data['token'], data['role'], data['name']);
      // Update FCM Token
      await updateFcmToken();
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Login failed'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<void> _saveAuthData(
    String token,
    String role,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('name', name);
  }

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: {'x-auth-token': token ?? ''},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<bool> updateWorkerProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/profile/worker'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> updateProfilePicture(String base64Image) async {
    final token = await getToken();
    print('Sending PUT request to $baseUrl/profile/image');
    print('Image data length: ${base64Image.length}');

    final response = await http.put(
      Uri.parse('$baseUrl/profile/image'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: jsonEncode({'profilePicture': base64Image}),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<void> updateFcmToken() async {
    final token = await NotificationService().fcmToken;
    final authToken = await getToken();

    if (token != null && authToken != null) {
      print(
        "ApiService: Updating FCM Token on server: ${token.substring(0, 10)}...",
      );
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/profile/fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': authToken,
          },
          body: jsonEncode({'fcmToken': token}),
        );
        print("ApiService: FCM update response: ${response.statusCode}");
      } catch (e) {
        print("ApiService: Failed to update FCM token: $e");
      }
    } else {
      print(
        "ApiService: Skipped FCM update. Token: ${token != null}, Auth: ${authToken != null}",
      );
    }
  }

  // Bookings
  static Future<bool> createBooking({
    String? labourerId,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: jsonEncode({
        'labourerId': labourerId,
        'category': category,
        'date': date.toIso8601String(),
        'notes': notes,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> claimBooking(String bookingId) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/claim'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getUserBookings() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/user'),
      headers: {'x-auth-token': token ?? ''},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception('Unauthorized');
    } else {
      throw Exception(
        'Failed to load bookings: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<List<dynamic>> getWorkerBookings() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/worker'),
      headers: {'x-auth-token': token ?? ''},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to load bookings: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<bool> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // Data
  static Future<List<Labourer>> getLabourers() async {
    final response = await http.get(Uri.parse('$baseUrl/labourers'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Labourer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load labourers');
    }
  }
}
