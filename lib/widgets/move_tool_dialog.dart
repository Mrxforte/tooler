import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/l10n/app_localizations.dart';
import '../models/tool.dart';
import '../providers/tool_provider.dart';
import '../providers/object_provider.dart';

class MoveToolDialog extends StatefulWidget {
  final Tool tool;

  const MoveToolDialog({super.key, required this.tool});

  @override
  State<MoveToolDialog> createState() => _MoveToolDialogState();
}

class _MoveToolDialogState extends State<MoveToolDialog> {
  String? _selectedObjectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.moveTool),
      content: Consumer<ObjectProvider>(
        builder: (context, provider, child) {
          final objects = provider.objects
              .where((obj) => obj.id != widget.tool.objectId)
              .toList();

          if (objects.isEmpty) {
            return Text(l10n.noObjects);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.selectTargetObject),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedObjectId,
                isExpanded: true,
                hint: Text(l10n.selectTargetObject),
                items: objects.map((obj) {
                  return DropdownMenuItem(value: obj.id, child: Text(obj.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedObjectId = value;
                  });
                },
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _selectedObjectId == null ? null : _moveTool,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _moveTool() {
    if (_selectedObjectId != null) {
      context.read<ToolProvider>().moveTool(widget.tool.id, _selectedObjectId!);
      Navigator.pop(context);
    }
  }
}
