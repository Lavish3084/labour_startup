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
        error.toString().contains('SocketException') || 
        error.toString().contains('Connection failed') ||
        error.toString().contains('Network is unreachable')) {
      message = 'Internet error. Please check your connection.';
    } else if (error is HttpException || error.toString().contains('HttpException')) {
      message = 'Server connection error. Please try again.';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Connection timed out. Please try again.';
    } else {
      message = 'Something went wrong. Please try again later.';
    }

    if (action != null && action.isNotEmpty) {
      return '$action: $message';
    }

    return message;
  }
}
