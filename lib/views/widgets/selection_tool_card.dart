// SelectionToolCard widget for displaying tools with selection mode support

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: selectionMode 
            ? Checkbox(
                value: tool.isSelected,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  toolsProvider.toggleToolSelection(tool.id);
                },
              )
            : const Icon(Icons.build),
        title: Text(tool.title),
        subtitle: Text(tool.brand),
        trailing: IconButton(
          icon: Icon(
            tool.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: tool.isFavorite ? Colors.red : null,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            toolsProvider.toggleFavorite(tool.id);
          },
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () {
          if (!selectionMode) {
            HapticFeedback.mediumImpact();
            toolsProvider.toggleSelectionMode();
            toolsProvider.toggleToolSelection(tool.id);
          }
        },
      ),
    );
  }
}
