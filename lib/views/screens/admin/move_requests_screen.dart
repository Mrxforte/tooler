// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../data/models/app_notification.dart';
import '../../../viewmodels/move_request_provider.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/notification_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';

class AdminMoveRequestsScreen extends StatelessWidget {
  const AdminMoveRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final reqProvider = Provider.of<MoveRequestProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final pending = reqProvider.pendingRequests;
    return Scaffold(
      appBar: AppBar(title: Text('Запросы на перемещение (${pending.length})')),
      body: pending.isEmpty
          ? const Center(child: Text('Нет ожидающих запросов'))
          : ListView.builder(
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final req = pending[index];
                Tool? tool;
                try {
                  tool = toolsProvider.tools.firstWhere((t) => t.id == req.toolId);
                } catch (e) {
                  tool = null;
                }
                if (tool == null) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(tool.title),
                    subtitle:
                        Text('${req.fromLocationName} → ${req.toLocationName} от ${req.requestedBy}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await toolsProvider.moveTool(
                                req.toolId, req.toLocationId, req.toLocationName);
                            await reqProvider.updateRequestStatus(req.id, 'approved');
                            final notif = AppNotification(
                              id: IdGenerator.generateNotificationId(),
                              title: 'Запрос одобрен',
                              body: 'Перемещение ${tool!.title} в ${req.toLocationName} подтверждено',
                              type: 'move_approved',
                              relatedId: req.id,
                              userId: req.requestedBy,
                            );
                            await notifProvider.addNotification(notif);
                            ErrorHandler.showSuccessDialog(context, 'Запрос одобрен');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await reqProvider.updateRequestStatus(req.id, 'rejected');
                            final notif = AppNotification(
                              id: IdGenerator.generateNotificationId(),
                              title: 'Запрос отклонен',
                              body: 'Перемещение ${tool!.title} в ${req.toLocationName} отклонено',
                              type: 'move_rejected',
                              relatedId: req.id,
                              userId: req.requestedBy,
                            );
                            await notifProvider.addNotification(notif);
                            ErrorHandler.showWarningDialog(context, 'Запрос отклонен');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
