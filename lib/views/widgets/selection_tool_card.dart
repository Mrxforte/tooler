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
  final String? subtitleOverride;
  final Widget? trailingOverride;

  const SelectionToolCard({
    super.key,
    required this.tool,
    required this.selectionMode,
    required this.onTap,
    this.subtitleOverride,
    this.trailingOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolsProvider>(
      builder: (context, toolsProvider, _) {
        // Get fresh tool state from provider (using unfiltered lookup)
        final updatedTool = toolsProvider.getToolById(tool.id) ?? tool;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: updatedTool.isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: updatedTool.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            color: updatedTool.isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : null,
            child: ListTile(
            leading: selectionMode 
                ? Checkbox(
                    value: updatedTool.isSelected,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      toolsProvider.toggleToolSelection(tool.id);
                    },
                  )
                : _buildLeadingImage(context),
        title: Text(updatedTool.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitleOverride != null
            ? Text(subtitleOverride!, style: const TextStyle(fontSize: 13))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          updatedTool.currentLocationName.isNotEmpty
                              ? updatedTool.currentLocationName
                              : 'Нет локации',
                          style: const TextStyle(fontSize: 13, color: Colors.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${updatedTool.brand}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (updatedTool.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      updatedTool.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
        isThreeLine: updatedTool.description.isNotEmpty,
        trailing: trailingOverride ?? IconButton(
              icon: Icon(
                updatedTool.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: updatedTool.isFavorite ? Colors.red : null,
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
      ),
        );
      },
    );
  }

  Widget _buildLeadingImage(BuildContext context) {
    if (tool.imageUrl != null && tool.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          tool.imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        ),
      );
    } else if (tool.localImagePath != null && tool.localImagePath!.isNotEmpty) {
      final file = File(tool.localImagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.build,
        color: Colors.grey[400],
        size: 28,
      ),
    );
  }
}
