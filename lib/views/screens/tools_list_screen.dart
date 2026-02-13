import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class ToolsListScreen extends StatefulWidget {
  const ToolsListScreen({super.key});

  @override
  State<ToolsListScreen> createState() => _ToolsListScreenState();
}

class _ToolsListScreenState extends State<ToolsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ToolsProvider>(context, listen: false);
      provider.loadTools();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Все инструменты (${toolsProvider.totalTools})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => toolsProvider.loadTools(forceRefresh: true),
          ),
        ],
      ),
      body: toolsProvider.isLoading && toolsProvider.tools.isEmpty
          ? _buildLoadingScreen()
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск инструментов...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      toolsProvider.setSearchQuery(value);
                    },
                  ),
                ),

                // Active filters indicator
                if (toolsProvider.filterLocation != 'all' ||
                    toolsProvider.filterBrand != 'all' ||
                    toolsProvider.filterFavorites)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getActiveFiltersText(toolsProvider),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => toolsProvider.clearAllFilters(),
                          child: const Text(
                            'Очистить',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: toolsProvider.tools.isEmpty
                      ? _buildEmptyToolsScreen()
                      : ListView.builder(
                          itemCount: toolsProvider.tools.length,
                          itemBuilder: (context, index) {
                            final tool = toolsProvider.tools[index];
                            return SelectionToolCard(
                              tool: tool,
                              selectionMode: toolsProvider.selectionMode,
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
                ),
              ],
            ),
      floatingActionButton: toolsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (toolsProvider.hasSelectedTools) {
                  _showSelectionActions(context);
                }
              },
              icon: const Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditToolScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Загрузка инструментов...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyToolsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'Нет инструментов',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditToolScreen(),
                ),
              );
            },
            child: const Text('Добавить инструмент'),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText(ToolsProvider provider) {
    final filters = <String>[];

    if (provider.filterLocation != 'all') {
      filters.add(
        provider.filterLocation == 'garage' ? 'В гараже' : 'На объекте',
      );
    }

    if (provider.filterBrand != 'all') {
      filters.add('Бренд: ${provider.filterBrand}');
    }

    if (provider.filterFavorites) {
      filters.add('Избранные');
    }

    return filters.join(', ');
  }

  void _showFilterDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                    'Фильтры инструментов',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location filter
                  ExpansionTile(
                    title: const Text('Местоположение'),
                    children: [
                      RadioListTile<String>(
                        title: const Text('Все'),
                        value: 'all',
                        groupValue: toolsProvider.filterLocation,
                        onChanged: (value) {
                          setState(() {});
                          toolsProvider.setFilterLocation(value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Гараж'),
                        value: 'garage',
                        groupValue: toolsProvider.filterLocation,
                        onChanged: (value) {
                          setState(() {});
                          toolsProvider.setFilterLocation(value!);
                        },
                      ),
                      ...objectsProvider.objects.map(
                        (object) => RadioListTile<String>(
                          title: Text(object.name),
                          value: object.id,
                          groupValue: toolsProvider.filterLocation,
                          onChanged: (value) {
                            setState(() {});
                            toolsProvider.setFilterLocation(value!);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Brand filter
                  ExpansionTile(
                    title: const Text('Бренд'),
                    children: toolsProvider.uniqueBrands
                        .map(
                          (brand) => RadioListTile<String>(
                            title: Text(brand == 'all' ? 'Все' : brand),
                            value: brand,
                            groupValue: toolsProvider.filterBrand,
                            onChanged: (value) {
                              setState(() {});
                              toolsProvider.setFilterBrand(value!);
                            },
                          ),
                        )
                        .toList(),
                  ),

                  // Favorites filter
                  SwitchListTile(
                    title: const Text('Только избранные'),
                    value: toolsProvider.filterFavorites,
                    onChanged: (value) {
                      toolsProvider.setFilterFavorites(value);
                    },
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => toolsProvider.clearAllFilters(),
                          child: const Text('Сбросить все'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Применить'),
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

  void _showSelectionActions(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
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
              Text(
                'Выбрано: $selectedCount инструментов',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  toolsProvider.toggleFavoriteForSelected();
                },
              ),

              ListTile(
                leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                title: const Text('Переместить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MoveToolsScreen(
                        selectedTools: toolsProvider.selectedTools,
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final tool in toolsProvider.selectedTools) {
                    await ReportService.shareToolReport(
                      tool,
                      context,
                      ReportType.text,
                    );
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiDeleteDialog(context);
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
    final selectedCount = toolsProvider.selectedTools.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить выбранные $selectedCount инструментов?',
        ),
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
}
