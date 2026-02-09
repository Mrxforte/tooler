import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/l10n/app_localizations.dart';
import '../models/tool.dart';
import '../providers/tool_provider.dart';

class ToolDialog extends StatefulWidget {
  final String objectId;
  final Tool? tool;

  const ToolDialog({super.key, required this.objectId, this.tool});

  @override
  State<ToolDialog> createState() => _ToolDialogState();
}

class _ToolDialogState extends State<ToolDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tool?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.tool?.description ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.tool?.quantity.toString() ?? '1',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.tool != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.editTool : l10n.addTool),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.toolName),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.toolDescription),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: l10n.quantity),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (name.isEmpty) return;

    final provider = context.read<ToolProvider>();

    if (widget.tool != null) {
      final updatedTool = widget.tool!.copyWith(
        name: name,
        description: description,
        quantity: quantity,
      );
      provider.updateTool(updatedTool);
    } else {
      provider.addTool(widget.objectId, name, description, quantity);
    }

    Navigator.pop(context);
  }
}
