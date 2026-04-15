import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/labourer.dart';
import '../models/service_category.dart';
import 'notification_service.dart';
import 'error_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    try {
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
        final dataMap = data is Map ? data : {};
        await _saveAuthData(
          dataMap['token']?.toString(), 
          dataMap['role']?.toString(), 
          dataMap['name']?.toString(), 
          email
        );
        return {'success': true, 'data': dataMap};
      } else {
        dynamic error;
        try {
          error = jsonDecode(response.body);
        } catch (_) {
          error = null;
        }
        return {'success': false, 'message': (error is Map && error.containsKey('msg')) ? error['msg'] : 'Something went wrong'};
      }
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataMap = data is Map ? data : {};
        await _saveAuthData(
          dataMap['token']?.toString(), 
          dataMap['role']?.toString(), 
          dataMap['name']?.toString(), 
          email
        );
        // Update FCM Token
        await updateFcmToken();
        return {'success': true, 'data': dataMap};
      } else {
        dynamic error;
        try {
          error = jsonDecode(response.body);
        } catch (_) {
          error = null;
        }
        return {'success': false, 'message': (error is Map && error.containsKey('msg')) ? error['msg'] : 'Something went wrong'};
      }
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> googleLogin(
    String idToken,
    String role, {
    String action = 'login',
  }) async {
    try {
      print('ApiService: Sending POST /auth/google | role=$role, action=$action');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken, 'role': role, 'action': action}),
      );

      print('ApiService: Google Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataMap = data is Map ? data : {};
        await _saveAuthData(
          dataMap['token']?.toString(), 
          dataMap['role']?.toString(), 
          dataMap['name']?.toString(), 
          '' // email is usually in token
        );
        await updateFcmToken();
        return {'success': true, 'data': dataMap};
      } else {
        dynamic error;
        try {
          error = jsonDecode(response.body);
        } catch (_) {
          error = null;
        }
        return {
          'success': false,
          'message': (error is Map && error.containsKey('msg')) ? error['msg'] : 'Google Login failed',
          'code': (error is Map && error.containsKey('code')) ? error['code'] : null,
        };
      }
    } catch (e) {
      print('ApiService: Google Auth Network Error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('email');
    
    try {
      await GoogleSignIn().disconnect();
    } catch (e) {
      print('ApiService: Failed to disconnect from Google: $e');
    }
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

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<void> _saveAuthData(
    String? token,
    String? role,
    String? name,
    String? email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token);
    if (role != null) await prefs.setString('role', role);
    if (name != null) await prefs.setString('name', name);
    if (email != null) await prefs.setString('email', email);
  }

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
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
        throw Exception('Data error');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<bool> updateProfileName(String name) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: jsonEncode({'name': name}),
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
  static Future<Map<String, dynamic>> createBooking({
    String? labourerId,
    required String category,
    required DateTime date,
    required String bookingMode,
    int? numberOfHours,
    String? notes,
    String? address,
    String? houseNumber,
    String? landmark,
    double? latitude,
    double? longitude,
    double? amount,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
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
          'bookingMode': bookingMode,
          'numberOfHours': numberOfHours,
          'notes': notes,
          'address': address,
          'houseNumber': houseNumber,
          'landmark': landmark,
          'latitude': latitude,
          'longitude': longitude,
          'amount': amount,
          'minAmount': minAmount,
          'maxAmount': maxAmount,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Something went wrong'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getErrorMessage(e)};
    }
  }

  static Future<List<dynamic>> getUserBookings() async {
    try {
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
        throw Exception('Data error');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> getBooking(String bookingId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Booking not found');
      } else {
        throw Exception('Failed to fetch booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }


  static Future<bool> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    try {
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
    } catch (e) {
      return false;
    }
  }

  static Future<bool> acceptWorker(
    String bookingId,
    String workerId,
  ) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/accept-worker'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({'labourerId': workerId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rateWorker(String bookingId, double rating, String comment) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/rate'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService rateWorker error: $e');
      return false;
    }
  }

  // Data
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/settings'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Data error');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<List<ServiceCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ServiceCategory.fromJson(json)).toList();
      } else {
        throw Exception('Data error');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<List<Labourer>> getLabourers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/labourers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Labourer.fromJson(json)).toList();
      } else {
        throw Exception('Data error');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // Payments
  static Future<Map<String, dynamic>> createPaymentOrder(
    String bookingId,
    int amount,
  ) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/payments/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({'bookingId': bookingId, 'amount': amount}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['code'] == 'ALREADY_PAID') {
          throw Exception('ALREADY_PAID');
        }
        throw Exception(errorData['msg'] ?? 'Payment error');
      }
    } catch (e) {
      if (e.toString().contains('ALREADY_PAID')) {
        rethrow;
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<bool> verifyPayment(
    String orderId,
    String paymentId,
    String signature,
    String bookingId,
  ) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/payments/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'bookingId': bookingId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addSavedAddress(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/address'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteSavedAddress(String addressId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/address/$addressId'),
        headers: {'x-auth-token': token ?? ''},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the currently logged-in user also has an account in the
  /// opposite role (worker ↔ user). Returns the raw JSON map from the server.
  static Future<Map<String, dynamic>> checkOtherRole() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-other-role'),
        headers: {'x-auth-token': token ?? ''},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'hasOtherAccount': false};
    } catch (e) {
      return {'hasOtherAccount': false};
    }
  }

  static Future<bool> deleteAccount() async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
