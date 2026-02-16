// TODO: Extract from main_backup.dart
// SelectionToolCard widget for displaying tools with selection mode support

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/tool.dart';
import '../../viewmodels/tools_provider.dart';

class SelectionToolCard extends StatelessWidget {
  final Tool tool;
  final bool selectionMode;
  final VoidCallback onTap;

  const SelectionToolCard({
    super.key,
    required this.tool,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    
    // TODO: Extract full implementation from main_backup.dart
    // This is a placeholder skeleton
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: selectionMode 
            ? Checkbox(
                value: tool.isSelected,
                onChanged: (_) {
                  toolsProvider.toggleToolSelection(tool.id);
                },
              )
            : const Icon(Icons.build),
        title: Text(tool.title),
        subtitle: Text(tool.brand),
        trailing: Icon(
          tool.isFavorite ? Icons.star : Icons.star_border,
          color: tool.isFavorite ? Colors.amber : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
