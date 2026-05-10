import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/models/notification.dart';
import '../core/utils/id_generator.dart';
import '../core/services/push_service.dart';

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
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs
            .map((doc) {
              try {
                return AppNotification.fromJson(doc.data());
              } catch (_) {
                return null;
              }
            })
            .whereType<AppNotification>()
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      },
      onError: (_) {},     // Firestore index errors are non-fatal — local cache still works
      cancelOnError: false,
    );
  }

  Future<void> addNotification(AppNotification notification) async {
    // Optimistic insert — UI updates immediately without waiting for stream.
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

  /// Creates or increments an existing recent notification of the same type.
  /// If a notification with the same [type] and [userId] was created within
  /// the last 5 minutes, its title gets a ×N counter and it floats to the top.
  /// Otherwise a fresh notification is created. Also fires a push notification.
  Future<void> smartAdd({
    required String title,
    required String body,
    required String type,
    required String userId,
    String? relatedId,
  }) async {
    final sameType = _notifications
        .where((n) => n.type == type && n.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (sameType.isNotEmpty) {
      final last = sameType.first;
      if (DateTime.now().difference(last.timestamp).inMinutes < 5) {
        final match = RegExp(r' \(×(\d+)\)$').firstMatch(last.title);
        final count = match != null ? int.parse(match.group(1)!) + 1 : 2;
        final base  = last.title.replaceAll(RegExp(r' \(×\d+\)$'), '');
        final newTitle = '$base (×$count)';

        final updated = last.copyWith(
          title: newTitle,
          body: body,
          timestamp: DateTime.now(),
          read: false,
        );

        final idx = _notifications.indexWhere((n) => n.id == last.id);
        if (idx != -1) {
          _notifications[idx] = updated;
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          notifyListeners();
          PushService.show(newTitle, body);
          try {
            await FirebaseFirestore.instance
                .collection(_collection)
                .doc(last.id)
                .update({
              'title': newTitle,
              'body': body,
              'timestamp': updated.timestamp.toIso8601String(),
              'read': false,
            });
          } catch (_) {}
        }
        return;
      }
    }

    // No recent match — create a fresh notification.
    final notif = AppNotification(
      id: IdGenerator.generateNotificationId(),
      title: title,
      body: body,
      type: type,
      userId: userId,
      relatedId: relatedId,
    );
    PushService.show(title, body);
    await addNotification(notif);
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    required String userId,
    String? relatedId,
  }) async {
    await smartAdd(
      title: title,
      body: body,
      type: type,
      userId: userId,
      relatedId: relatedId,
    );
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
          .delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
