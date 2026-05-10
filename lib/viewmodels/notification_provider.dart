import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/models/notification.dart';
import '../core/utils/id_generator.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  bool get hasUnread => _notifications.any((n) => !n.read);
  int get unreadCount => _notifications.where((n) => !n.read).length;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  static const _collection = 'notifications';

  Future<void> loadNotifications(String userId) async {
    await _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) {
            try {
              return AppNotification.fromJson(doc.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();
      notifyListeners();
    });
  }

  Future<void> addNotification(AppNotification notification) async {
    // Optimistic insert so the UI updates immediately without waiting for stream
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.insert(0, notification);
      notifyListeners();
    }
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(notification.id)
          .set(notification.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    required String userId,
    String? relatedId,
  }) async {
    final notification = AppNotification(
      id: IdGenerator.generateNotificationId(),
      title: title,
      body: body,
      type: type,
      userId: userId,
      relatedId: relatedId,
    );
    await addNotification(notification);
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
    }
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(id)
          .update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final unread = _notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in unread) {
        batch.update(
          FirebaseFirestore.instance.collection(_collection).doc(n.id),
          {'read': true},
        );
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(id)
          .delete()
          ;
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
