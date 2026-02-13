import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final ToolsProvider toolsProvider;
  final bool selectionMode;
  final VoidCallback onTap;

  const ObjectCard({
    super.key,
    required this.object,
    required this.toolsProvider,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Consumer<ObjectsProvider>(
      builder: (context, objectsProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: selectionMode
                ? () {
                    objectsProvider.toggleObjectSelection(object.id);
                  }
                : onTap,
            onLongPress: () {
              if (!selectionMode) {
                objectsProvider.toggleSelectionMode();
                objectsProvider.toggleObjectSelection(object.id);
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
                        value: object.isSelected,
                        onChanged: (value) {
                          objectsProvider.toggleObjectSelection(object.id);
                        },
                        shape: const CircleBorder(),
                      ),
                    ),

                  // Object Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withOpacity(0.1),
                          Colors.orange.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: object.displayImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: object.displayImage!.startsWith('http')
                                  ? NetworkImage(object.displayImage!)
                                        as ImageProvider
                                  : FileImage(File(object.displayImage!)),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.location_city,
                                    color: Colors.orange,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.location_city,
                              color: Colors.orange,
                              size: 30,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        if (object.description.isNotEmpty)
                          Text(
                            object.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(
                              Icons.build,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${toolsOnObject.length} инструментов',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
                                      AddEditObjectScreen(object: object),
                                ),
                              );
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
                                  content: Text('Удалить "${object.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await objectsProvider.deleteObject(
                                          object.id,
                                        );
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
