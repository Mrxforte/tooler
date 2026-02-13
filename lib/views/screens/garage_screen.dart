import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class EnhancedGarageScreen extends StatefulWidget {
  const EnhancedGarageScreen({super.key});

  @override
  State<EnhancedGarageScreen> createState() => _EnhancedGarageScreenState();
}

class _EnhancedGarageScreenState extends State<EnhancedGarageScreen> {
  @override
  void initState() {
    super.initState();
    // Load tools when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ToolsProvider>(context, listen: false);
      provider.loadTools();
    });
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final garageTools = toolsProvider.garageTools;

    return Scaffold(
      body: toolsProvider.isLoading && garageTools.isEmpty
          ? _buildLoadingScreen()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient
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
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Мой Гараж',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${garageTools.length} инструментов доступно',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats cards
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                context,
                                '    Всего    ',
                                '${toolsProvider.totalTools}',
                                Icons.build,
                                Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 10),
                              _buildStatCard(
                                context,
                                'В гараже',
                                '${garageTools.length}',
                                Icons.garage,
                                Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 10),
                              _buildStatCard(
                                context,
                                'Избранные',
                                '${toolsProvider.favoriteTools.length}',
                                Icons.favorite,
                                Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditToolScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          toolsProvider.toggleSelectionMode();
                        },
                        icon: const Icon(Icons.checklist),
                        label: Text(
                          toolsProvider.selectionMode ? 'Отменить' : 'Выбрать',
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tools List
                Expanded(
                  child: garageTools.isEmpty
                      ? _buildEmptyGarage()
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: garageTools.length,
                          itemBuilder: (context, index) {
                            final tool = garageTools[index];
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
      floatingActionButton:
          toolsProvider.selectionMode && toolsProvider.hasSelectedTools
          ? FloatingActionButton.extended(
              onPressed: () {
                _showGarageSelectionActions(context);
              },
              icon: const Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
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
            'Загрузка гаража...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGarage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.garage, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Гараж пуст',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            'Добавьте инструменты в гараж',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditToolScreen(),
                ),
              );
            },
            child: const Text('Добавить первый инструмент'),
          ),
        ],
      ),
    );
  }

  void _showGarageSelectionActions(BuildContext context) {
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
                  // Share each tool report
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
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Подтверждение удаления'),
                      content: Text(
                        'Удалить выбранные $selectedCount инструментов?',
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
}
