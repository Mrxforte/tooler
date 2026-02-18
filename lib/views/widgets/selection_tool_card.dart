// SelectionToolCard widget for displaying tools with selection mode support

import 'dart:io';
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
      elevation: tool.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tool.isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        color: tool.isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : null,
        child: ListTile(
        leading: selectionMode 
            ? Checkbox(
                value: tool.isSelected,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  toolsProvider.toggleToolSelection(tool.id);
                },
              )
            : _buildLeadingImage(context),
        title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(tool.brand, style: const TextStyle(fontSize: 13)),
            if (tool.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tool.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        isThreeLine: tool.description.isNotEmpty,
        trailing: Consumer<ToolsProvider>(
          builder: (context, tp, _) {
            return IconButton(
              icon: Icon(
                tool.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: tool.isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                tp.toggleFavorite(tool.id);
              },
            );
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
      ),
    );
  }

  Widget _buildLeadingImage(BuildContext context) {
    if (tool.displayImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image(
            image: tool.displayImage!.startsWith('http')
                ? NetworkImage(tool.displayImage!) as ImageProvider
                : FileImage(File(tool.displayImage!)),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconFallback(context);
            },
          ),
        ),
      );
    }
    return _buildIconFallback(context);
  }

  Widget _buildIconFallback(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.build_circle,
        size: 32,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
