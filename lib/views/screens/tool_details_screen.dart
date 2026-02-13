import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/tool.dart';
import '../../models/location_history.dart';
import '../../controllers/tools_provider.dart';
import '../../services/report_service.dart';
import 'add_edit_tool_screen.dart';

class EnhancedToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const EnhancedToolDetailsScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'tool-${tool.id}',
                child: tool.displayImage != null
                    ? Image(
                        image: tool.displayImage!.startsWith('http')
                            ? NetworkImage(tool.displayImage!) as ImageProvider
                            : FileImage(File(tool.displayImage!)),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.2),
                              theme.colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.build,
                            size: 100,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ReportService.showReportTypeDialog(context, tool, (type) {
                    ReportService.shareToolReport(tool, context, type);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => ReportService.printToolReport(tool, context),
              ),
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
                            builder: (context) => AddEditToolScreen(tool: tool),
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
                          final toolsProvider = Provider.of<ToolsProvider>(
                            context,
                            listen: false,
                          );
                          toolsProvider.duplicateTool(tool);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        'Удалить',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => _showDeleteConfirmation(context),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<ToolsProvider>(
                        builder: (context, toolsProvider, child) {
                          return IconButton(
                            icon: Icon(
                              tool.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: tool.isFavorite ? Colors.red : null,
                              size: 30,
                            ),
                            onPressed: () {
                              toolsProvider.toggleFavorite(tool.id);
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tool.brand,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        tool.uniqueId,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  if (tool.description.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Описание',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tool.description,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Details Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildDetailCard(
                        icon: Icons.location_on,
                        title: 'Местоположение',
                        value: tool.currentLocationName,
                        color: Colors.blue,
                      ),
                      _buildDetailCard(
                        icon: Icons.calendar_today,
                        title: 'Добавлен',
                        value: DateFormat('dd.MM.yyyy').format(tool.createdAt),
                        color: Colors.green,
                      ),
                      _buildDetailCard(
                        icon: Icons.update,
                        title: 'Обновлен',
                        value: DateFormat('dd.MM.yyyy').format(tool.updatedAt),
                        color: Colors.orange,
                      ),
                      _buildDetailCard(
                        icon: Icons.star,
                        title: 'Статус',
                        value: tool.isFavorite ? 'Избранный' : 'Обычный',
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location History
                  if (tool.locationHistory.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Colors.purple),
                                const SizedBox(width: 10),
                                Text(
                                  'История перемещений',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...tool.locationHistory.map((history) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.purple,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            history.locationName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat(
                                              'dd.MM.yyyy HH:mm',
                                            ).format(history.date),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Consumer<ToolsProvider>(
          builder: (context, toolsProvider, child) {
            return ElevatedButton.icon(
              onPressed: () => _showMoveDialog(context, tool),
              icon: const Icon(Icons.move_to_inbox),
              label: const Text('Переместить инструмент'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить "${tool.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final toolsProvider = Provider.of<ToolsProvider>(
                context,
                listen: false,
              );
              await toolsProvider.deleteTool(tool.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Tool tool) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? selectedLocationId = tool.currentLocation;
        String? selectedLocationName = tool.currentLocationName;
        final objects = objectsProvider.objects;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить инструмент',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Garage option
                  ListTile(
                    leading: const Icon(Icons.garage, color: Colors.blue),
                    title: const Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                        selectedLocationName = 'Гараж';
                      });
                    },
                  ),

                  const Divider(),

                  // Objects options
                  ...objects.map((object) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: Colors.orange,
                      ),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: selectedLocationId == object.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                          selectedLocationName = object.name;
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedLocationId != null &&
                                selectedLocationName != null) {
                              await toolsProvider.moveTool(
                                tool.id,
                                selectedLocationId!,
                                selectedLocationName!,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Переместить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

