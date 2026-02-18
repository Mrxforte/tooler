// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/batch_move_request_provider.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/notification_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';
import '../../../data/models/notification.dart';

class AdminBatchMoveRequestsScreen extends StatelessWidget {
  const AdminBatchMoveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batchProvider = Provider.of<BatchMoveRequestProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final pending = batchProvider.pendingRequests;

    return Scaffold(
      appBar: AppBar(title: Text('Групповые запросы (${pending.length})')),
      body: RefreshIndicator(
        onRefresh: () => batchProvider.loadRequests(),
        child: pending.isEmpty
            ? const Center(child: Text('Нет ожидающих групповых запросов'))
            : ListView.builder(
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final req = pending[index];
                final tools =
                    toolsProvider.tools.where((t) => req.toolIds.contains(t.id)).toList();
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title:
                        Text('${req.toolIds.length} инструментов → ${req.toLocationName}'),
                    subtitle: Text('от ${req.requestedBy}'),
                    children: [
                      ...tools.map((t) => ListTile(
                            leading: const Icon(Icons.build, size: 20),
                            title: Text(t.title),
                            subtitle: Text('Текущее: ${t.currentLocationName}'),
                          )),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Отклонить'),
                            onPressed: () async {
                              await batchProvider.updateRequestStatus(req.id, 'rejected');
                              final notif = AppNotification(
                                id: IdGenerator.generateNotificationId(),
                                title: 'Групповой запрос отклонён',
                                body:
                                    'Перемещение ${tools.length} инструментов в ${req.toLocationName} отклонено',
                                type: 'batch_move_rejected',
                                relatedId: req.id,
                                userId: req.requestedBy,
                              );
                              await notifProvider.addNotification(notif);
                              ErrorHandler.showWarningDialog(context, 'Запрос отклонён');
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Одобрить'),
                            onPressed: () async {
                              for (final tool in tools) {
                                await toolsProvider.moveTool(
                                    tool.id, req.toLocationId, req.toLocationName);
                              }
                              await batchProvider.updateRequestStatus(req.id, 'approved');
                              final notif = AppNotification(
                                id: IdGenerator.generateNotificationId(),
                                title: 'Групповой запрос одобрен',
                                body:
                                    '${tools.length} инструментов перемещены в ${req.toLocationName}',
                                type: 'batch_move_approved',
                                relatedId: req.id,
                                userId: req.requestedBy,
                              );
                              await notifProvider.addNotification(notif);
                              ErrorHandler.showSuccessDialog(
                                  context, 'Запрос одобрен, инструменты перемещены');
                            },
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ),
    
    );
  }
}
