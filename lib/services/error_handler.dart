import 'dart:io';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  /// Returns a user-friendly error message based on the exception.
  /// [action] is an optional prefix like "Booking failed" or "Signup failed".
  static String getErrorMessage(dynamic error, {String? action}) {
    if (kDebugMode) {
      print('ErrorHandler caught error: $error');
    }

    String message;
    if (error is SocketException || 
        error is HttpException ||
        error.toString().contains('SocketException') || 
        error.toString().contains('Connection failed') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('Internet error')) {
      message = 'Internet error';
    } else {
      message = 'Something went wrong';
    }

    if (action != null && action.isNotEmpty) {
      return '$action: $message';
    }
    return message;
  }
}
