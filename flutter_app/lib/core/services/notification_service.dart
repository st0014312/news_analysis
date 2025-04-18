import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_logger.dart';

/// Service for handling push notifications
class NotificationService {
  /// Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Flutter Local Notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Stream controller for notification taps
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of notification taps
  Stream<Map<String, dynamic>> get notificationTaps =>
      _notificationTapController.stream;

  /// Constructor
  NotificationService() {
    _init();
  }

  /// Initialize notification services
  Future<void> _init() async {
    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Initialize local notifications
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );
      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Configure notification channels for Android
      if (Platform.isAndroid) {
        await _configureAndroidChannels();
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial notification (app opened from terminated state)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      AppLogger.i('Notification service initialized');
    } catch (e) {
      AppLogger.e('Error initializing notification service', error: e);
    }
  }

  /// Configure notification channels for Android
  Future<void> _configureAndroidChannels() async {
    const channelId = 'financial_news_channel';
    const channelName = 'Financial News';
    const channelDescription = 'Notifications for financial news updates';

    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.i('Received foreground message: ${message.messageId}');

    // Extract notification data
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      await _showLocalNotification(
        id: notification.hashCode,
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: jsonEncode(data),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.i('Notification tapped: ${message.messageId}');

    // Extract data
    final data = message.data;

    // Add to stream
    _notificationTapController.add(data);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'financial_news_channel',
      'Financial News',
      channelDescription: 'Notifications for financial news updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle local notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    AppLogger.i('Local notification tapped: ${response.id}');

    // Extract payload
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _notificationTapController.add(data);
      } catch (e) {
        AppLogger.e('Error parsing notification payload', error: e);
      }
    }
  }

  /// Handle iOS local notification (deprecated but required for iOS < 10)
  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    AppLogger.i('iOS local notification received: $id');

    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _notificationTapController.add(data);
      } catch (e) {
        AppLogger.e('Error parsing notification payload', error: e);
      }
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      AppLogger.e('Error getting FCM token', error: e);
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.i('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.e('Error subscribing to topic: $topic', error: e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.e('Error unsubscribing from topic: $topic', error: e);
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      AppLogger.e('Error showing local notification', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will be called when the app is in the background or terminated
  // It needs to be a top-level function

  // Initialize Firebase if needed (for background handling)
  // await Firebase.initializeApp();

  print('Handling background message: ${message.messageId}');
}
