import 'package:flutter/material.dart';
import '../data/models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  
  bool get hasUnread => _notifications.any((n) => !n.read);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> loadNotifications(String userId) async {
    // Load notifications from Firebase only (no local caching)
    _notifications = [];
    notifyListeners();
  }

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
  }
}
