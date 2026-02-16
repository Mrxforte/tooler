// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../data/services/report_service.dart';
import '../../../viewmodels/auth_provider.dart' as app_auth;
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../widgets/selection_tool_card.dart';
import 'add_edit_tool_screen.dart';
import 'tool_details_screen.dart';
import 'move_tools_screen.dart';

// Export safe alias for main.dart
class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return EnhancedGarageScreen();
  }
}

class EnhancedGarageScreen extends StatefulWidget {
  const EnhancedGarageScreen({super.key});
  @override
  State<EnhancedGarageScreen> createState() => _EnhancedGarageScreenState();
}

class _EnhancedGarageScreenState extends State<EnhancedGarageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsProvider>(context, listen: false).loadTools();
    });
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final garageTools = toolsProvider.garageTools;

    return Scaffold(
      body: toolsProvider.isLoading && garageTools.isEmpty
          ? _buildLoadingScreen()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Мой Гараж',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('${garageTools.length} инструментов доступно',
                          style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(context, '    Всего    ',
                                  '${toolsProvider.totalTools}', Icons.build,
                                  Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 10),
                              _buildStatCard(context, 'В гараже',
                                  '${garageTools.length}', Icons.garage,
                                  Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 10),
                              _buildStatCard(context, 'Избранные',
                                  '${toolsProvider.favoriteTools.length}',
                                  Icons.favorite, Colors.white.withOpacity(0.2)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (authProvider.isAdmin)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const AddEditToolScreen())),
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (authProvider.isAdmin) const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: toolsProvider.toggleSelectionMode,
                        icon: const Icon(Icons.checklist),
                        label: Text(toolsProvider.selectionMode ? 'Отменить' : 'Выбрать'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: garageTools.isEmpty
                      ? _buildEmptyGarage(authProvider.isAdmin)
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: garageTools.length,
                          itemBuilder: (context, index) {
                            final tool = garageTools[index];
                            return SelectionToolCard(
                              tool: tool,
                              selectionMode: toolsProvider.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EnhancedToolDetailsScreen(tool: tool))),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: toolsProvider.selectionMode && toolsProvider.hasSelectedTools
          ? FloatingActionButton.extended(
              onPressed: () => _showGarageSelectionActions(context),
              icon: const Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 20),
            Text('Загрузка гаража...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );

  Widget _buildStatCard(BuildContext context, String title, String value,
          IconData icon, Color backgroundColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      );

  Widget _buildEmptyGarage(bool isAdmin) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.garage, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text('Гараж пуст',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 10),
            Text('Добавьте инструменты в гараж',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 20),
            if (isAdmin)
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddEditToolScreen())),
                child: const Text('Добавить первый инструмент'),
              ),
          ],
        ),
      );

  void _showGarageSelectionActions(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final auth = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
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
              Text('Выбрано: $selectedCount инструментов',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  toolsProvider.toggleFavoriteForSelected();
                },
              ),
              if (auth.canMoveTools) ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                  title: const Text('Переместить выбранные'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MoveToolsScreen(selectedTools: toolsProvider.selectedTools)));
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.orange),
                  title: const Text('Запросить перемещение'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBatchMoveRequestDialog(context, toolsProvider.selectedTools);
                  },
                ),
              ],
              if (auth.isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить выбранные'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMultiDeleteDialog(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final tool in toolsProvider.selectedTools) {
                    await ReportService.shareToolReport(tool, context, ReportType.text);
                  }
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMultiDeleteDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content:
            Text('Удалить выбранные ${toolsProvider.selectedTools.length} инструментов?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await toolsProvider.deleteSelectedTools();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBatchMoveRequestDialog(BuildContext context, List<Tool> selectedTools) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId;
    String? selectedName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
              Text('Запрос перемещения (${selectedTools.length} инструментов)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...selectedTools.take(5).map((t) =>
                  Text('• ${t.title} (${t.currentLocationName})')).toList(),
              if (selectedTools.length > 5) Text('... и еще ${selectedTools.length - 5}'),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(Icons.garage, color: Colors.blue),
                title: const Text('Гараж'),
                trailing: selectedId == 'garage' ? const Icon(Icons.check) : null,
                onTap: () => setState(() {
                  selectedId = 'garage';
                  selectedName = 'Гараж';
                }),
              ),
              ...objectsProvider.objects.map((obj) => ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.orange),
                    title: Text(obj.name),
                    trailing: selectedId == obj.id ? const Icon(Icons.check) : null,
                    onTap: () => setState(() {
                      selectedId = obj.id;
                      selectedName = obj.name;
                    }),
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
                      onPressed: selectedId == null
                          ? null
                          : () async {
                              await toolsProvider.requestMoveSelectedTools(
                                  selectedTools, selectedId!, selectedName!);
                              Navigator.pop(context);
                            },
                      child: const Text('Отправить запрос'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
