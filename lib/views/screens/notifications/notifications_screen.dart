import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/notification.dart';
import '../../../viewmodels/notification_provider.dart';
import '../../../viewmodels/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final authProvider = context.read<AuthProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Уведомления'),
            if (notifProvider.unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifProvider.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifProvider.hasUnread)
            TextButton.icon(
              onPressed: notifProvider.markAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Все прочитаны'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            notifProvider.loadNotifications(authProvider.userId ?? ''),
        child: notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) => _NotificationCard(
                  notif: notifications[index],
                  onTap: () =>
                      notifProvider.markAsRead(notifications[index].id),
                  onDelete: () =>
                      notifProvider.deleteNotification(notifications[index].id),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final dim = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.3);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 72, color: dim),
          const SizedBox(height: 16),
          Text(
            'Нет уведомлений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: dim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Здесь появятся ваши уведомления',
            style: TextStyle(fontSize: 13, color: dim),
          ),
        ],
      ),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notif,
    required this.onTap,
    required this.onDelete,
  });

  static IconData _iconForType(String type) {
    switch (type) {
      case 'error':   return Icons.error_rounded;
      case 'success': return Icons.check_circle_rounded;
      case 'warning': return Icons.warning_rounded;
      case 'move':    return Icons.swap_horiz_rounded;
      case 'info':    return Icons.info_rounded;
      default:        return Icons.notifications_rounded;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'error':   return const Color(0xFFD32F2F);
      case 'success': return const Color(0xFF388E3C);
      case 'warning': return const Color(0xFFF57C00);
      case 'move':    return const Color(0xFF7B1FA2);
      case 'info':    return const Color(0xFF1565C0);
      default:        return const Color(0xFF0E639C);
    }
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин. назад';
    if (diff.inDays < 1) return '${diff.inHours} ч. назад';
    if (diff.inDays == 1) {
      return 'Вчера, ${DateFormat('HH:mm').format(dt)}';
    }
    return DateFormat('dd.MM.yy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(notif.type);
    final typeIcon  = _iconForType(notif.type);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    final cardBg = notif.read
        ? Theme.of(context).colorScheme.surface
        : (isDark
            ? typeColor.withValues(alpha: 0.12)
            : typeColor.withValues(alpha: 0.07));

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: notif.read ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: cardBg,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type icon badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.read
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (!notif.read) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(notif.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
