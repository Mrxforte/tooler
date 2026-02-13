import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/tools_provider.dart';
import '../widgets/selection_tool_card.dart';
import 'tool_details_screen.dart';

// ========== FAVORITES SCREEN ==========
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;

    return Scaffold(
      appBar: AppBar(title: Text('Избранное (${favoriteTools.length})')),
      body: favoriteTools.isEmpty
          ? _buildEmptyFavoritesScreen()
          : ListView.builder(
              itemCount: favoriteTools.length,
              itemBuilder: (context, index) {
                final tool = favoriteTools[index];
                return SelectionToolCard(
                  tool: tool,
                  selectionMode: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnhancedToolDetailsScreen(tool: tool),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyFavoritesScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'Нет избранных инструментов',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Добавьте инструменты в избранное',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
