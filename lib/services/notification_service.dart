// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     // Request permission
//     await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     // Subscribe to topic so notifications are received
//     await _messaging.subscribeToTopic("newVehicles");

//     // Initialize local notifications
//     const initializationSettings = InitializationSettings(
//       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       iOS: DarwinInitializationSettings(),
//     );

//     await _localNotifications.initialize(initializationSettings);

//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showLocalNotification(message);
//     });
//   }

//   Future<String?> getToken() async {
//     return await _messaging.getToken();
//   }

//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     final notification = message.notification;
//     if (notification == null) return;

//     await _localNotifications.show(
//       notification.hashCode,
//       notification.title,
//       notification.body,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           'vehicles_channel',
//           'New Vehicles',
//           channelDescription: 'Notifications for new vehicles',
//           importance: Importance.high,
//         ),
//         iOS: const DarwinNotificationDetails(),
//       ),
//     );
//   }
// }
