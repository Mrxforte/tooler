import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for showing
/// system push notifications. Uses the singleton from app_constants.
class PushService {
  static const _androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Уведомления об операциях с инструментами',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_notification',
    playSound: true,
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  static int _nextId = 0;

  static Future<void> show(String title, String body) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id: _nextId++ & 0x7FFFFFFF,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
