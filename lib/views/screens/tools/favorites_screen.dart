import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../../../views/widgets/object_card.dart';
import 'tool_details_screen.dart';
import '../objects/object_details_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;
    final favoriteObjects = objectsProvider.favoriteObjects;
    
    final isToolsTab = _tabController.index == 0;
    final isSelectionMode = isToolsTab ? toolsProvider.selectionMode : objectsProvider.selectionMode;
    final hasSelected = isToolsTab ? toolsProvider.hasSelectedTools : objectsProvider.hasSelectedObjects;

    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text(isToolsTab 
                ? 'Выбрано: ${toolsProvider.selectedTools.length}'
                : 'Выбрано: ${objectsProvider.selectedObjects.length}')
            : const Text('Избранное'),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (isToolsTab) {
                    toolsProvider.toggleSelectionMode();
                  } else {
                    objectsProvider.toggleSelectionMode();
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
                if (isToolsTab) {
                  toolsProvider.toggleSelectionMode();
                } else {
                  objectsProvider.toggleSelectionMode();
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Инструменты', icon: Icon(Icons.build)),
            Tab(text: 'Объекты', icon: Icon(Icons.location_city)),
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
        ],
      ),
      floatingActionButton: isSelectionMode && hasSelected
          ? FloatingActionButton.extended(
              onPressed: () {
                if (isToolsTab) {
                  _showBatchActionsSheet(context, toolsProvider, true);
                } else {
                  _showBatchActionsSheet(context, objectsProvider, false);
                }
              },
              icon: const Icon(Icons.more_horiz),
              label: const Text('Действия'),
            )
          : null,
    );
  }

  void _showBatchActionsSheet(BuildContext context, dynamic provider, bool isTools) {
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
                if (isTools) {
                  await (provider as ToolsProvider).toggleFavoriteForSelected();
                } else {
                  await (provider as ObjectsProvider).toggleFavoriteForSelected();
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
            if (isTools) ...[
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
