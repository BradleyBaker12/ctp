import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification channels and request permissions
  static Future<void> initialize() async {
    // Skip all initialization on web
    if (kIsWeb) {
      print('Notifications disabled on web platform');
      return;
    }

    // Initialize local notifications for mobile only
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);
  }

  // Subscribe to topics based on user role
  static Future<void> subscribeToTopics(String userRole) async {
    // Skip on web
    if (kIsWeb) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Always unsubscribe from all topics first to ensure clean subscriptions
      await messaging.unsubscribeFromTopic('newVehicles');
      await messaging.unsubscribeFromTopic('newDealers');
      await messaging.unsubscribeFromTopic('newTransporters');

      if (userRole.toLowerCase() == 'dealer') {
        // Dealers get notifications about new trucks/vehicles
        await messaging.subscribeToTopic('newVehicles');
        print('Subscribed dealer to newVehicles topic');
      } else if (userRole.toLowerCase() == 'admin' ||
          userRole.toLowerCase() == 'sales representative') {
        // Admins get notifications about new users
        await messaging.subscribeToTopic('newDealers');
        await messaging.subscribeToTopic('newTransporters');
        print('Subscribed admin to newDealers and newTransporters topics');
      }
    } catch (e) {
      print('Error managing topic subscriptions: $e');
    }
  }

  // Get FCM token for direct messaging
  static Future<String?> getToken() async {
    if (kIsWeb) {
      return null;
    }

    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Show a local notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    // Skip on web
    if (kIsWeb) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'ctp_app_channel',
      'CTP Notifications',
      channelDescription: 'Commercial Trader Portal notifications',
      importance: Importance.high,
      priority: Priority.high,
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

    try {
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}
