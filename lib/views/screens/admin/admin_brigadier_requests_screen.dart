import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/brigadier_request_model.dart';
import '../../../viewmodels/brigadier_request_provider.dart';
import '../../../viewmodels/auth_provider.dart';

class AdminBrigadierRequestsScreen extends StatefulWidget {
  const AdminBrigadierRequestsScreen({super.key});

  @override
  State<AdminBrigadierRequestsScreen> createState() => _AdminBrigadierRequestsScreenState();
}

class _AdminBrigadierRequestsScreenState extends State<AdminBrigadierRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrigadierRequestProvider>().loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запросы от бригадиров'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ожидающие'),
            Tab(text: 'Одобрено'),
            Tab(text: 'Отклонено'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(RequestStatus.pending, primaryColor),
          _buildRequestList(RequestStatus.approved, primaryColor),
          _buildRequestList(RequestStatus.rejected, primaryColor),
        ],
      ),
    );
  }

  Widget _buildRequestList(RequestStatus status, Color primaryColor) {
    return Consumer<BrigadierRequestProvider>(
      builder: (context, requestProvider, _) {
        final requests = status == RequestStatus.pending
            ? requestProvider.pendingRequests
            : status == RequestStatus.approved
                ? requestProvider.approvedRequests
                : requestProvider.rejectedRequests;

        if (requestProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет запросов',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, primaryColor, context);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    BrigadierRequest request,
    Color primaryColor,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: _getStatusColor(request.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRequestTypeLabel(request.type),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusLabel(request.status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(request.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Request details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Бригадир: ${request.brigadierId}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Объект: ${request.objectId}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Создано: ${_formatDate(request.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (request.reason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Причина:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      request.reason!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Actions
            if (request.status == RequestStatus.pending) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _rejectRequest(context, request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Отклонить'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _approveRequest(context, request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Одобрить'),
                  ),
                ],
              ),
            ] else if (request.status == RequestStatus.approved) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Одобрено ${request.resolvedBy} ${_formatDate(request.resolvedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (request.status == RequestStatus.rejected) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Отклонено ${request.resolvedBy}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (request.rejectionReason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Причина отклонения: ${request.rejectionReason}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _approveRequest(BuildContext context, BrigadierRequest request) {
    final currentUser = context.read<AuthProvider>().user;
    context.read<BrigadierRequestProvider>().approveRequest(
      requestId: request.id,
      adminId: currentUser?.uid ?? 'unknown',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Запрос одобрен')),
    );
  }

  void _rejectRequest(BuildContext context, BrigadierRequest request) {
    showDialog(
      context: context,
      builder: (context) => _buildRejectionDialog(context, request),
    );
  }

  Widget _buildRejectionDialog(BuildContext context, BrigadierRequest request) {
    final controller = TextEditingController();

    return AlertDialog(
      title: const Text('Отклонить запрос'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Причина отклонения',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final currentUser = context.read<AuthProvider>().user;
            context.read<BrigadierRequestProvider>().rejectRequest(
              requestId: request.id,
              adminId: currentUser?.uid ?? 'unknown',
              rejectionReason: controller.text.trim(),
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Запрос отклонен')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Отклонить'),
        ),
      ],
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.hourglass_empty;
      case RequestStatus.approved:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Ожидает одобрения';
      case RequestStatus.approved:
        return 'Одобрено';
      case RequestStatus.rejected:
        return 'Отклонено';
    }
  }

  String _getRequestTypeLabel(RequestType type) {
    switch (type) {
      case RequestType.addWorker:
        return 'Добавить рабочего';
      case RequestType.removeWorker:
        return 'Удалить рабочего';
      case RequestType.addTool:
        return 'Добавить инструмент';
      case RequestType.removeTool:
        return 'Удалить инструмент';
      case RequestType.moveWorker:
        return 'Переместить рабочего';
      case RequestType.moveTool:
        return 'Переместить инструмент';
      case RequestType.changeSalary:
        return 'Изменить зарплату';
      case RequestType.giveBonus:
        return 'Выдать бонус';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
