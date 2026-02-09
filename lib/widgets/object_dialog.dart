import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/l10n/app_localizations.dart';
import '../models/tool_object.dart';
import '../providers/object_provider.dart';

class ObjectDialog extends StatefulWidget {
  final ToolObject? object;

  const ObjectDialog({super.key, this.object});

  @override
  State<ObjectDialog> createState() => _ObjectDialogState();
}

class _ObjectDialogState extends State<ObjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.object?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.object?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.object != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.editObject : l10n.addObject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.objectName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: l10n.toolDescription),
            maxLines: 3,
          ),
        ],
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

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.objectName)),
      );
      return;
    }

    final provider = context.read<ObjectProvider>();

    if (widget.object != null) {
      final updatedObject = widget.object!.copyWith(
        name: name,
        description: description,
      );
      provider.updateObject(updatedObject);
    } else {
      provider.addObject(name, description);
    }

    Navigator.pop(context);
  }
}
