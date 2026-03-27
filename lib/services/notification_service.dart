import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../main.dart'; // Import navigatorKey
import '../screens/main_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // 1. Request Permissions
    await _requestPermission();

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: iOS setup includes requesting permissions for alerts, badges, and sounds
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print("Notification tapped: ${details.payload}");
        _handleNotificationClick(details.payload);
      },
    );

    // 4. Get Messaging Token
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print("NotificationService: Initial FCM Token: $_fcmToken");
    } catch (e) {
      print("NotificationService: Failed to get FCM token: $e");
    }

    // 5. Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("NotificationService: FCM Token Refreshed: $newToken");
      _fcmToken = newToken;
      // TODO: Ideally trigger a callback to update server if user is logged in
    });

    // 6. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('NotificationService: Got a message whilst in the foreground!');
      print('NotificationService: Message data: ${message.data}');

      if (message.notification != null) {
        print(
          'NotificationService: Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // 7. Handle initial message if app was terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("NotificationService: App started from terminated state via notification");
      // We need a small delay to ensure navigator is ready
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationClick(null); // Simple redirect to bookings for now
      });
    }

    // 8. Handle click when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("NotificationService: App opened from background via notification");
      _handleNotificationClick(null); // Simple redirect to bookings for now
    });
  }

  void _handleNotificationClick(String? payload) {
    // For now, always navigate to the Bookings tab (index 1)
    if (navigatorKey.currentState != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Provider.of<AppStateProvider>(context, listen: false).setTab(1);
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel', // channel id
          'High Importance Notifications', // channel name
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }
}
