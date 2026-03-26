import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Global navigator key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
  }
}

// Initialize the FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  StreamController<RemoteMessage>? _messageStreamController;
  
  String? get fcmToken => _fcmToken;
  Stream<RemoteMessage>? get messageStream => _messageStreamController?.stream;

  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      await _setupMessageHandlers();
      
      if (kDebugMode) {
        print('✅ Notification Service initialized successfully');
        print('📱 FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing notification service: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Permission status: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
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
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        if (kDebugMode) {
          print('🔄 FCM Token refreshed: $token');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Create stream controller for message handling
    _messageStreamController = StreamController<RemoteMessage>.broadcast();

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is opened from notification (terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📨 Foreground message received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Show local notification for foreground messages
    await _showLocalNotification(message);

    // Add to stream for UI updates
    _messageStreamController?.add(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    if (kDebugMode) {
      print('📱 App opened from notification:');
      print('Title: ${message.notification?.title}');
      print('Data: ${message.data}');
    }

    // Navigate based on message data
    _navigateBasedOnMessage(message);

    // Add to stream for UI updates
    _messageStreamController?.add(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'plantpulse_channel',
      'PlantPulse Notifications',
      channelDescription: 'Notifications from PlantPulse app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'PlantPulse',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print('🔔 Local notification tapped: ${notificationResponse.payload}');
    }

    // Parse payload and navigate
    if (notificationResponse.payload != null) {
      // Simple parsing - in production, use proper JSON parsing
      final data = <String, String>{};
      final parts = notificationResponse.payload!.split(',');
      for (final part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          data[keyValue[0].trim()] = keyValue[1].trim();
        }
      }
      
      final mockMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'Local Notification',
          body: 'Tapped from local notification',
        ),
        data: data,
      );
      
      _navigateBasedOnMessage(mockMessage);
    }
  }

  void _navigateBasedOnMessage(RemoteMessage message) {
    final data = message.data;
    
    if (kDebugMode) {
      print('🧭 Navigating based on message data: $data');
    }

    // Navigate based on message data
    if (data['screen'] != null) {
      switch (data['screen']) {
        case 'dashboard':
          navigatorKey.currentState?.pushNamed('/dashboard');
          break;
        case 'profile':
          navigatorKey.currentState?.pushNamed('/profile');
          break;
        case 'plant_demo':
          navigatorKey.currentState?.pushNamed('/plant_demo');
          break;
        case 'watering_analytics':
          navigatorKey.currentState?.pushNamed('/watering-analytics');
          break;
        default:
          navigatorKey.currentState?.pushNamed('/dashboard');
      }
    } else if (data['type'] == 'watering_reminder') {
      // Navigate to dashboard for watering reminders
      navigatorKey.currentState?.pushNamed('/dashboard');
    } else {
      // Default navigation
      navigatorKey.currentState?.pushNamed('/dashboard');
    }
  }

  // Method to subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic: $e');
      }
    }
  }

  // Method to unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic: $e');
      }
    }
  }

  // Dispose method
  void dispose() {
    _messageStreamController?.close();
  }

  // Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, String>? payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'watering_reminders',
            'Watering Reminders',
            channelDescription: 'Notifications for plant watering reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload?.entries.map((e) => '${e.key}:${e.value}').join(','),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (kDebugMode) {
        print('✅ Scheduled notification: $title at $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling notification: $e');
      }
    }
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      if (kDebugMode) {
        print('✅ Cancelled notification with id: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling notification: $e');
      }
    }
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      if (kDebugMode) {
        print('✅ Cancelled all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling all notifications: $e');
      }
    }
  }
}
