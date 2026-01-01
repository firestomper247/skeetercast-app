import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'api_config.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance._showNotification(message);
}

/// Notification Service - handles push notifications and local notifications
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  // Lazy initialization - don't access FirebaseMessaging until Firebase is initialized
  FirebaseMessaging? _messaging;
  FirebaseMessaging get messaging => _messaging ??= FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  bool _initialized = false;
  String? _fcmToken;

  // Notification channels
  static const AndroidNotificationChannel weatherChannel = AndroidNotificationChannel(
    'weather_alerts',
    'Weather Alerts',
    description: 'Severe weather and marine alerts for saved locations',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel buddyChannel = AndroidNotificationChannel(
    'buddy_notifications',
    'Fishing Buddies',
    description: 'Friend requests, messages, and buddy updates',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
    'system_notifications',
    'System Announcements',
    description: 'Maintenance notices and important updates',
    importance: Importance.defaultImportance,
  );

  // Fish On! channel with custom reel drag sound
  static const AndroidNotificationChannel fishOnChannel = AndroidNotificationChannel(
    'fish_on_alerts',
    'Fish On! Alerts',
    description: 'Urgent alerts when a buddy hooks up - screaming drag sound!',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('fish_on'),
  );

  /// Initialize notifications - call from main.dart
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize Firebase
    await Firebase.initializeApp();

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from notification)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels (Android only)
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(weatherChannel);
      await androidPlugin?.createNotificationChannel(buddyChannel);
      await androidPlugin?.createNotificationChannel(systemChannel);
      await androidPlugin?.createNotificationChannel(fishOnChannel);
    }
  }

  /// Register device token with server
  Future<void> registerToken() async {
    if (_fcmToken == null) return;

    try {
      await _api.post(
        '${ApiConfig.authBase}/api/device-token',
        data: {
          'token': _fcmToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      debugPrint('Device token registered with server');
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  /// Unregister token (on logout)
  Future<void> unregisterToken() async {
    if (_fcmToken == null) return;

    try {
      await _api.delete('${ApiConfig.authBase}/api/device-token/$_fcmToken');
    } catch (e) {
      debugPrint('Failed to unregister token: $e');
    }
  }

  void _onTokenRefresh(String token) {
    _fcmToken = token;
    registerToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _showNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Handle navigation based on notification type
    final type = message.data['type'];
    final payload = message.data;

    // This would navigate to appropriate screen
    // For now just log it - we'll add navigation context later
    switch (type) {
      case 'weather_alert':
        // Navigate to cities screen
        break;
      case 'fish_on':
        // Navigate to buddies screen with location
        break;
      case 'buddy_request':
      case 'buddy_accepted':
      case 'buddy_message':
        // Navigate to buddies screen
        break;
      case 'system':
        // Show announcement
        break;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Handle notification tap from local notification
        debugPrint('Local notification tapped: $data');
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? 'system';

    AndroidNotificationChannel channel;
    int notificationId;

    switch (type) {
      case 'weather_alert':
        channel = weatherChannel;
        notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        break;
      case 'fish_on':
        // Special Fish On! alert with screaming drag sound
        channel = fishOnChannel;
        notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        break;
      case 'buddy_request':
      case 'buddy_accepted':
      case 'buddy_message':
        channel = buddyChannel;
        notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        break;
      default:
        channel = systemChannel;
        notificationId = 0;
    }

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Subscribe to topic (e.g., for broadcast announcements)
  Future<void> subscribeToTopic(String topic) async {
    await messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await messaging.unsubscribeFromTopic(topic);
  }
}
