import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

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
    return Consumer<ToolsProvider>(
      builder: (context, toolsProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: selectionMode
                ? () {
                    toolsProvider.toggleToolSelection(tool.id);
                  }
                : onTap,
            onLongPress: () {
              if (!selectionMode) {
                toolsProvider.toggleSelectionMode();
                toolsProvider.toggleToolSelection(tool.id);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Checkbox(
                        value: tool.isSelected,
                        onChanged: (value) {
                          toolsProvider.toggleToolSelection(tool.id);
                        },
                        shape: const CircleBorder(),
                      ),
                    ),

                  // Tool Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: tool.displayImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: tool.displayImage!.startsWith('http')
                                  ? NetworkImage(tool.displayImage!)
                                        as ImageProvider
                                  : FileImage(File(tool.displayImage!)),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.build,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.build,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!selectionMode)
                              IconButton(
                                icon: Icon(
                                  tool.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: tool.isFavorite
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  toolsProvider.toggleFavorite(tool.id);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          tool.brand,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tool.currentLocationName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!selectionMode)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Редактировать'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditToolScreen(tool: tool),
                                ),
                              );
                            },
                          ),
                        ),
                        if (tool.currentLocation == 'garage')
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.copy),
                              title: const Text('Дублировать'),
                              onTap: () {
                                Navigator.pop(context);
                                toolsProvider.duplicateTool(tool);
                              },
                            ),
                          ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.share),
                            title: const Text('Поделиться отчетом'),
                            onTap: () {
                              Navigator.pop(context);
                              ReportService.showReportTypeDialog(
                                context,
                                tool,
                                (type) {
                                  ReportService.shareToolReport(
                                    tool,
                                    context,
                                    type,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.print),
                            title: const Text('Печать отчета'),
                            onTap: () {
                              Navigator.pop(context);
                              ReportService.printToolReport(tool, context);
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Подтверждение удаления'),
                                  content: Text('Удалить "${tool.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await toolsProvider.deleteTool(tool.id);
                                      },
                                      child: const Text(
                                        'Удалить',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
