// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/construction_object.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../views/widgets/object_card.dart';
import 'object_details_screen.dart';
import 'add_edit_object_screen.dart';

class EnhancedObjectsListScreen extends StatefulWidget {
  const EnhancedObjectsListScreen({super.key});
  @override
  State<EnhancedObjectsListScreen> createState() =>
      _EnhancedObjectsListScreenState();
}
class _EnhancedObjectsListScreenState extends State<EnhancedObjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObjectsProvider>(context, listen: false).loadObjects();
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    List<ConstructionObject> displayObjects = objectsProvider.objects;
    if (_showFavoritesOnly) {
      displayObjects = objectsProvider.favoriteObjects;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Объекты (${displayObjects.length})'),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _showFavoritesOnly ? Colors.red : null),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => objectsProvider.loadObjects(forceRefresh: true))
        ],
      ),
      body: objectsProvider.isLoading && objectsProvider.objects.isEmpty
          ? _buildLoadingScreen()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск объектов...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: objectsProvider.setSearchQuery,
                  ),
                ),
                Expanded(
                  child: displayObjects.isEmpty
                      ? _buildEmptyObjectsScreen(auth.canControlObjects, _showFavoritesOnly)
                      : ListView.builder(
                          itemCount: displayObjects.length,
                          itemBuilder: (context, index) {
                            final object = displayObjects[index];
                            return ObjectCard(
                              object: object,
                              toolsProvider: toolsProvider,
                              selectionMode: objectsProvider.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ObjectDetailsScreen(object: object))),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: objectsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: objectsProvider.hasSelectedObjects
                  ? () => _showObjectSelectionActions(context)
                  : null,
              icon: const Icon(Icons.more_vert),
              label: Text('${objectsProvider.selectedObjects.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : (auth.canControlObjects
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddEditObjectScreen())),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add),
                )
              : null),
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
            Text('Загрузка объектов...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
  Widget _buildEmptyObjectsScreen(bool canControl, bool favoritesOnly) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(favoritesOnly ? 'Нет избранных объектов' : 'Нет объектов',
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            if (canControl && !favoritesOnly)
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddEditObjectScreen())),
                child: const Text('Добавить объект'),
              ),
          ],
        ),
      );
  void _showObjectSelectionActions(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final selectedCount = objectsProvider.selectedObjects.length;
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
              Text('Выбрано: $selectedCount объектов',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  objectsProvider.toggleFavoriteForSelected();
                },
              ),
              if (auth.canControlObjects)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить выбранные'),
                  onTap: () {
                    Navigator.pop(context);
                    _showObjectsDeleteDialog(context);
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
  void _showObjectsDeleteDialog(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
            'Удалить выбранные ${objectsProvider.selectedObjects.length} объектов?\n\nИнструменты на этих объектах будут перемещены в гараж.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await objectsProvider.deleteSelectedObjects();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
