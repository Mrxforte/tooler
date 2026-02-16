import 'package:flutter/material.dart';
import '../data/models/notification.dart';
import '../data/repositories/local_database.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  
  bool get hasUnread => _notifications.any((n) => !n.read);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> loadNotifications(String userId) async {
    await LocalDatabase.init();
    _notifications = LocalDatabase.notifications.values
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    await LocalDatabase.notifications.put(notification.id, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      await LocalDatabase.notifications.put(id, _notifications[index]);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
      await LocalDatabase.notifications.put(_notifications[i].id, _notifications[i]);
    }
    notifyListeners();
  }
}
