import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../../../views/widgets/object_card.dart';
import '../../widgets/worker_card_simple.dart';
import 'tool_details_screen.dart';
import '../objects/object_details_screen.dart';
import '../workers/worker_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load workers data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Clear selection modes when leaving
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    
    if (toolsProvider.selectionMode) {
      toolsProvider.toggleSelectionMode();
    }
    if (objectsProvider.selectionMode) {
      objectsProvider.toggleSelectionMode();
    }
    if (workerProvider.selectionMode) {
      workerProvider.toggleSelectionMode();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final workerProvider = Provider.of<WorkerProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;
    final favoriteObjects = objectsProvider.favoriteObjects;
    final favoriteWorkers = workerProvider.favoriteWorkers;
    
    final currentTab = _tabController.index;
    final isSelectionMode = currentTab == 0
        ? toolsProvider.selectionMode
        : currentTab == 1
            ? objectsProvider.selectionMode
            : workerProvider.selectionMode;
    final hasSelected = currentTab == 0
        ? toolsProvider.hasSelectedTools
        : currentTab == 1
            ? objectsProvider.hasSelectedObjects
            : workerProvider.hasSelectedWorkers;

    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text(currentTab == 0
                ? 'Выбрано: ${toolsProvider.selectedTools.length}'
                : currentTab == 1
                    ? 'Выбрано: ${objectsProvider.selectedObjects.length}'
                    : 'Выбрано: ${workerProvider.selectedWorkers.length}')
            : const Text('Избранное'),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (currentTab == 0) {
                    toolsProvider.toggleSelectionMode();
                  } else if (currentTab == 1) {
                    objectsProvider.toggleSelectionMode();
                  } else {
                    workerProvider.toggleSelectionMode();
                  }
                },
              )
            : null,
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Выбрать',
              onPressed: () {
                if (currentTab == 0) {
                  toolsProvider.toggleSelectionMode();
                } else if (currentTab == 1) {
                  objectsProvider.toggleSelectionMode();
                } else {
                  workerProvider.toggleSelectionMode();
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: Colors.amber[700],
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.amber[700],
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Инструменты', icon: Icon(Icons.build)),
            Tab(text: 'Объекты', icon: Icon(Icons.location_city)),
            Tab(text: 'Работники', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tools tab
          favoriteTools.isEmpty
              ? _buildEmptyFavorites(Icons.build, 'Нет избранных инструментов')
              : ListView.builder(
                  itemCount: favoriteTools.length,
                  itemBuilder: (context, index) {
                    if (index >= favoriteTools.length) return SizedBox.shrink();
                    final tool = favoriteTools[index];
                    return SelectionToolCard(
                      tool: tool,
                      selectionMode: toolsProvider.selectionMode,
                      onTap: toolsProvider.selectionMode
                          ? () => toolsProvider.toggleToolSelection(tool.id)
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EnhancedToolDetailsScreen(tool: tool))),
                    );
                  },
                ),
          // Objects tab
          favoriteObjects.isEmpty
              ? _buildEmptyFavorites(Icons.location_city, 'Нет избранных объектов')
              : ListView.builder(
                  itemCount: favoriteObjects.length,
                  itemBuilder: (context, index) {
                    if (index >= favoriteObjects.length) return SizedBox.shrink();
                    final object = favoriteObjects[index];
                    return ObjectCard(
                      object: object,
                      objectsProvider: objectsProvider,
                      selectionMode: objectsProvider.selectionMode,
                      onTap: objectsProvider.selectionMode
                          ? () => objectsProvider.toggleObjectSelection(object.id)
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ObjectDetailsScreen(object: object))),
                    );  
                  },
                ),
          // Workers tab
          favoriteWorkers.isEmpty
              ? _buildEmptyFavorites(Icons.person, 'Нет избранных работников')
              : ListView.builder(
                  itemCount: favoriteWorkers.length,
                  itemBuilder: (context, index) {
                    if (index >= favoriteWorkers.length) return const SizedBox.shrink();
                    final worker = favoriteWorkers[index];
                    return WorkerCardSimple(
                      worker: worker,
                      selectionMode: workerProvider.selectionMode,
                      onTap: workerProvider.selectionMode
                          ? () => workerProvider.toggleWorkerSelection(worker.id)
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WorkerDetailsScreen(worker: worker))),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: isSelectionMode && hasSelected
          ? FloatingActionButton.extended(
              onPressed: () {
                if (currentTab == 0) {
                  _showBatchActionsSheet(context, toolsProvider, 'tools');
                } else if (currentTab == 1) {
                  _showBatchActionsSheet(context, objectsProvider, 'objects');
                } else {
                  _showBatchActionsSheet(context, workerProvider, 'workers');
                }
              },
              icon: const Icon(Icons.more_horiz),
              label: const Text('Действия'),
            )
          : null,
    );
  }

  void _showBatchActionsSheet(BuildContext context, dynamic provider, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Групповые действия',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: Colors.red),
              title: const Text('Убрать из избранного'),
              onTap: () async {
                Navigator.pop(context);
                if (type == 'tools') {
                  await (provider as ToolsProvider).toggleFavoriteForSelected();
                } else if (type == 'objects') {
                  await (provider as ObjectsProvider).toggleFavoriteForSelected();
                } else {
                  await (provider as WorkerProvider).toggleFavoriteForSelected();
                }
                if (context.mounted) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Убрано из избранного'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            if (type == 'tools') ...[
              ListTile(
                leading: const Icon(Icons.drive_file_move, color: Colors.blue),
                title: const Text('Переместить'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement move logic if needed
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites(IconData icon, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(text, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
}
