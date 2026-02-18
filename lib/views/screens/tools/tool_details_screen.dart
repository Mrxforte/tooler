// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/tool.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../core/utils/error_handler.dart';
import 'add_edit_tool_screen.dart';

class EnhancedToolDetailsScreen extends StatefulWidget {
  final Tool tool;
  const EnhancedToolDetailsScreen({super.key, required this.tool});

  @override
  State<EnhancedToolDetailsScreen> createState() => _EnhancedToolDetailsScreenState();
}

class _EnhancedToolDetailsScreenState extends State<EnhancedToolDetailsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
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
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                              theme.colorScheme.secondary.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.build,
                            size: 100,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => ReportService.showReportTypeDialog(
                  context,
                  tool,
                  (type) => ReportService.shareToolReport(tool, context, type),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => ReportService.printToolReport(tool, context),
              ),
              PopupMenuButton(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      if (auth.isAdmin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditToolScreen(tool: tool),
                          ),
                        );
                      }
                      break;
                    case 'duplicate':
                      if (tool.currentLocation == 'garage' && auth.isAdmin) {
                        Provider.of<ToolsProvider>(context, listen: false)
                            .duplicateTool(tool);
                        Navigator.pop(context);
                      }
                      break;
                    case 'delete':
                      if (auth.isAdmin) {
                        _showDeleteConfirmation(context);
                      }
                      break;
                  }
                },
                itemBuilder: (context) {
                  List<PopupMenuItem> items = [];
                  if (auth.isAdmin) {
                    items.add(const PopupMenuItem(
                        value: 'edit', child: Text('Редактировать')));
                  }
                  if (tool.currentLocation == 'garage' && auth.isAdmin) {
                    items.add(const PopupMenuItem(
                        value: 'duplicate', child: Text('Дублировать')));
                  }
                  if (auth.isAdmin) {
                    items.add(const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить', style: TextStyle(color: Colors.red))));
                  }
                  return items;
                },
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
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Consumer<ToolsProvider>(
                        builder: (context, tp, _) => IconButton(
                          icon: Icon(
                            tool.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: tool.isFavorite ? Colors.red : null,
                            size: 30,
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            tp.toggleFavorite(tool.id);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                              theme.colorScheme.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tool.brand,
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(tool.uniqueId, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (tool.description.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              theme.colorScheme.primary.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isDescriptionExpanded = !_isDescriptionExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color: theme.colorScheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Описание',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      _isDescriptionExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    tool.description,
                                    style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Colors.grey[800],
                                        letterSpacing: 0.2),
                                  ),
                                ),
                              ),
                              crossFadeState: _isDescriptionExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
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
                          color: Colors.blue),
                      _buildDetailCard(
                          icon: Icons.calendar_today,
                          title: 'Добавлен',
                          value: DateFormat('dd.MM.yyyy').format(tool.createdAt),
                          color: Colors.green),
                      _buildDetailCard(
                          icon: Icons.update,
                          title: 'Обновлен',
                          value: DateFormat('dd.MM.yyyy').format(tool.updatedAt),
                          color: Colors.orange),
                      _buildDetailCard(
                          icon: Icons.favorite,
                          title: 'Статус',
                          value: tool.isFavorite ? 'Избранный' : 'Обычный',
                          color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (tool.locationHistory.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
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
                                      color: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...tool.locationHistory.map(
                              (history) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(history.locationName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd.MM.yyyy HH:mm')
                                                .format(history.date),
                                            style: const TextStyle(
                                                fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
        child: Consumer2<ToolsProvider, AuthProvider>(
          builder: (context, tp, auth, _) => ElevatedButton.icon(
            onPressed: () => _showMoveDialog(context, tool, auth),
            icon: const Icon(Icons.move_to_inbox),
            label: Text(auth.canMoveTools ? 'Переместить инструмент' : 'Запросить перемещение'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDetailCard(
          {required IconData icon,
          required String title,
          required String value,
          required Color color}) =>
      Card(
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
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
  void _showDeleteConfirmation(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(context, 'Только администратор может удалять');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить "${widget.tool.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<ToolsProvider>(context, listen: false)
                  .deleteTool(widget.tool.id, context: context);
              await Future.delayed(const Duration(milliseconds: 2000));
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _showMoveDialog(BuildContext context, Tool tool, AuthProvider auth) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId = tool.currentLocation;
    String? selectedName = tool.currentLocationName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    auth.canMoveTools ? 'Переместить инструмент' : 'Запросить перемещение',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.garage, color: Colors.blue),
                    title: const Text('Гараж'),
                    trailing: selectedId == 'garage'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedId = 'garage';
                        selectedName = 'Гараж';
                      });
                    },
                  ),
                  const Divider(),
                  ...objectsProvider.objects.map((obj) => ListTile(
                        leading: const Icon(Icons.location_city, color: Colors.orange),
                        title: Text(obj.name),
                        subtitle: Text('${obj.toolIds.length} инструментов'),
                        trailing: selectedId == obj.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            selectedId = obj.id;
                            selectedName = obj.name;
                          });
                        },
                      )),
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
                            if (selectedId != null && selectedName != null) {
                              if (auth.canMoveTools) {
                                await toolsProvider.moveTool(
                                    tool.id, selectedId!, selectedName!);
                              } else {
                                await toolsProvider.requestMoveTool(
                                    tool.id, selectedId!, selectedName!);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: Text(auth.canMoveTools ? 'Переместить' : 'Отправить запрос'),
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
