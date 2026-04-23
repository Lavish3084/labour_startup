import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  // Derive socket URL from the API base URL by stripping '/api'
  final String _baseUrl = Config.baseUrl.replaceAll(RegExp(r'/api$'), '');

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      'https://api.justlavish.tech',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected to server at $_baseUrl');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected from server');
    });

    _socket!.onConnectError((data) {
      debugPrint('[Socket] Connection Error: $data');
    });
  }

  void joinBooking(String bookingId) {
    if (_socket == null) connect();
    _socket!.emit('join_booking', bookingId);
    debugPrint('[Socket] Joined booking room: $bookingId');
  }

  void leaveBooking(String bookingId) {
    _socket?.emit('leave_booking', bookingId);
    debugPrint('[Socket] Left booking room: $bookingId');
  }

  void onBookingUpdate(Function(dynamic) callback) {
    _socket?.on('booking_update', callback);
  }

  void onNewMessage(Function(dynamic) callback) {
    _socket?.on('new_message', callback);
  }

  void offBookingUpdate() {
    _socket?.off('booking_update');
  }

  void offNewMessage() {
    _socket?.off('new_message');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
