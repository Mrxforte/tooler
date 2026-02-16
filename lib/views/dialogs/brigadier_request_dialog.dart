import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/brigadier_request_model.dart';
import '../../viewmodels/brigadier_request_provider.dart';
import '../../viewmodels/auth_provider.dart';

class BrigadierRequestDialog extends StatefulWidget {
  final String objectId;
  final RequestType requestType;
  final String title;
  final String description;
  final VoidCallback? onRequestCreated;

  const BrigadierRequestDialog({
    required this.objectId,
    required this.requestType,
    required this.title,
    required this.description,
    this.onRequestCreated,
  });

  @override
  State<BrigadierRequestDialog> createState() => _BrigadierRequestDialogState();
}

class _BrigadierRequestDialogState extends State<BrigadierRequestDialog> {
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _createRequest() {
    final reason = _reasonController.text.trim();

    final currentUser = context.read<AuthProvider>().user;
    final requestProvider = context.read<BrigadierRequestProvider>();

    requestProvider
        .createRequest(
          brigadierId: currentUser?.uid ?? 'unknown',
          objectId: widget.objectId,
          type: widget.requestType,
          data: {
            'requestType': widget.requestType.toString().split('.').last,
            'timestamp': DateTime.now().toIso8601String(),
          },
          reason: reason.isNotEmpty ? reason : null,
        )
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Запрос отправлен администратору')),
          );
          widget.onRequestCreated?.call();
          Navigator.pop(context);
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.request_page,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ваш запрос будет отправлен администратору для одобрения',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Reason field
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Причина запроса (опционально)',
                  hintText: 'Опишите, почему вам нужно это действие',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _createRequest,
                    icon: const Icon(Icons.send),
                    label: const Text('Отправить запрос'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
