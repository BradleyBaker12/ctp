import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// Use the channel defined in main.dart
import '../main.dart' show channel, flutterLocalNotificationsPlugin;

class NotificationService {
  // Initialize notification channels and request permissions
  static Future<void> initialize() async {
    // Skip all initialization on web
    if (kIsWeb) {
      print('Notifications disabled on web platform');
      return;
    }

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // We already initialize flutterLocalNotificationsPlugin in main.dart
    // so we don't need to do it again here
    print('NotificationService initialized');
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

      // Subscribe based on role
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

  // Show a local notification - used for testing or direct notification display
  static Future<void> showNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    // Skip on web
    if (kIsWeb) {
      return;
    }

    try {
      print('Showing local notification: $title');
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond, // Use timestamp for unique ID
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      print('Local notification displayed successfully');
    } catch (e) {
      print('Error showing notification: $e');
      rethrow;
    }
  }

  // Schedule a notification for later delivery
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String payload = '',
  }) async {
    if (kIsWeb) return;

    try {
      print('Scheduling notification for ${scheduledDate.toIso8601String()}');

      // Initialize timezone data if needed
      tz_data.initializeTimeZones();

      // Convert DateTime to TZDateTime
      final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        DateTime.now().millisecond, // Unique ID
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
      rethrow;
    }
  }

  // Store a notification in Firestore for server-side processing
  static Future<String> saveNotificationToFirestore({
    String? targetUserId,
    String? fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool sendImmediately = true,
    DateTime? scheduledFor,
  }) async {
    try {
      // Get current user if targetUserId is not provided
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (targetUserId == null && currentUserId == null) {
        throw Exception('No target user specified and no user is logged in');
      }

      // If no FCM token provided, try to get one for the target user
      String? token = fcmToken;
      if (token == null && targetUserId != null) {
        // Try to get token from user document
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();

        if (userDoc.exists) {
          token = userDoc.data()?['fcmToken'];
        }
      }

      // If still no token, try to get current device token
      if (token == null) {
        token = await getToken();
      }

      final notificationData = {
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'sendImmediately': sendImmediately,
      };

      if (token != null) {
        notificationData['token'] = token;
      }

      if (targetUserId != null) {
        notificationData['targetUserId'] = targetUserId;
      }

      if (scheduledFor != null) {
        notificationData['scheduledFor'] = Timestamp.fromDate(scheduledFor);
      }

      // Add the notification to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('direct_push_notifications')
          .add(notificationData);

      print('Notification saved to Firestore with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving notification to Firestore: $e');
      rethrow;
    }
  }

  // Send a test notification using both local and Firestore methods
  static Future<void> sendTestNotification({
    String? userId,
    String? fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // First, show a local notification immediately
      await showNotification(
        title: title,
        body: body,
        payload: 'test_notification',
      );

      // Then, save to Firestore for server-side processing
      await saveNotificationToFirestore(
        targetUserId: userId,
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data,
      );

      print('Test notification sent via both methods');
    } catch (e) {
      print('Error sending test notification: $e');
      rethrow;
    }
  }

  // Send a test notification using FCM for debugging purposes
  static Future<void> sendTestFCMMessage({
    required String token,
    required String title,
    required String body,
  }) async {
    // This would typically be handled by your server or Firebase Cloud Functions
    // For testing purposes, you can use this method to debug notification issues
    print('To send a test FCM message, use your Cloud Function:');
    print('Token: $token');
    print('Title: $title');
    print('Body: $body');
  }
}
