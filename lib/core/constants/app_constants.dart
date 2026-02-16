import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ========== APP CONSTANTS ==========
const String adminSecret = 'admin123';

const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
