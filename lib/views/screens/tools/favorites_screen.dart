import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../../../views/widgets/object_card.dart';
import 'tool_details_screen.dart';
import '../objects/object_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;
    final favoriteObjects = objectsProvider.favoriteObjects;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Избранное'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Инструменты', icon: Icon(Icons.build)),
              Tab(text: 'Объекты', icon: Icon(Icons.location_city)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tools tab
            favoriteTools.isEmpty
                ? _buildEmptyFavorites(Icons.build, 'Нет избранных инструментов')
                : ListView.builder(
                    itemCount: favoriteTools.length,
                    itemBuilder: (context, index) {
                      final tool = favoriteTools[index];
                      return SelectionToolCard(
                        tool: tool,
                        selectionMode: false,
                        onTap: () => Navigator.push(
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
                      final object = favoriteObjects[index];
                      return ObjectCard(
                        object: object,
                        toolsProvider: toolsProvider,
                        selectionMode: false,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ObjectDetailsScreen(object: object))),
                      );
                    },
                  ),
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
