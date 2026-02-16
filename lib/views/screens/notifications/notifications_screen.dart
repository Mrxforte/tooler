import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../viewmodels/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (notifProvider.hasUnread)
            TextButton(
                onPressed: () => notifProvider.markAllRead(),
                child: const Text('Прочитать все'))
        ],
      ),
      body: notifProvider.notifications.isEmpty
          ? const Center(child: Text('Нет уведомлений'))
          : ListView.builder(
              itemCount: notifProvider.notifications.length,
              itemBuilder: (context, index) {
                final notif = notifProvider.notifications[index];
                return ListTile(
                  leading: Icon(notif.read ? Icons.notifications_none : Icons.notifications_active,
                      color: notif.read ? Colors.grey : Colors.blue),
                  title: Text(notif.title,
                      style: TextStyle(
                          fontWeight: notif.read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(notif.body),
                  trailing: Text(DateFormat('dd.MM HH:mm').format(notif.timestamp)),
                  onTap: () => notifProvider.markAsRead(notif.id),
                );
              },
            ),
    );
  }
}
