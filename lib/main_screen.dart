// main_screen.dart
// Основной экран приложения Tooler - Русская версия

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:tooler/main.dart';
import 'dart:io';

// Глобальный ключ навигатора
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ========== ОСНОВНОЙ ЭКРАН ==========
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      await Future.wait([
        toolsProvider.loadTools(),
        objectsProvider.loadObjects(),
      ]);

      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      print('Ошибка загрузки начальных данных: $e');
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }

  final List<Widget> _screens = [
    EnhancedGarageScreen(),
    ToolsListScreen(),
    EnhancedObjectsListScreen(),
    MoveToolsScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadComplete) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Загрузка данных...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Tooler'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => _generateInventoryReport(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      floatingActionButton: _getFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.garage), label: 'Гараж'),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Инструменты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Объекты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.move_to_inbox),
            label: 'Переместить',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Widget? _getFloatingActionButton() {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    if (_selectedIndex == 0 || _selectedIndex == 1) {
      if (toolsProvider.selectionMode && toolsProvider.hasSelectedTools) {
        return FloatingActionButton.extended(
          onPressed: () => _showToolSelectionActions(context),
          icon: Icon(Icons.more_vert),
          label: Text('${toolsProvider.selectedTools.length}'),
        );
      }
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditToolScreen()),
          );
        },
        child: Icon(Icons.add),
      );
    } else if (_selectedIndex == 2) {
      if (objectsProvider.selectionMode && objectsProvider.hasSelectedObjects) {
        return FloatingActionButton.extended(
          onPressed: () => _showObjectSelectionActions(context),
          icon: Icon(Icons.more_vert),
          label: Text('${objectsProvider.selectedObjects.length}'),
        );
      }
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditObjectScreen()),
          );
        },
        child: Icon(Icons.add),
      );
    }
    return null;
  }

  void _showToolSelectionActions(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount инструментов',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.move_to_inbox, color: Colors.blue),
                title: Text('Переместить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiMoveDialog(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiDeleteDialog(context, true);
                },
              ),

              ListTile(
                leading: Icon(Icons.share, color: Colors.green),
                title: Text('Поделиться информацией'),
                onTap: () {
                  Navigator.pop(context);
                  _shareSelectedTools(context);
                },
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showObjectSelectionActions(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = objectsProvider.selectedObjects.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount объектов',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiDeleteDialog(context, false);
                },
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMultiDeleteDialog(BuildContext context, bool isTools) {
    if (isTools) {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final selectedCount = toolsProvider.selectedTools.length;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Подтверждение удаления'),
          content: Text(
            'Вы уверены, что хотите удалить выбранные $selectedCount инструментов?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await toolsProvider.deleteSelectedTools();
              },
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );
      final selectedCount = objectsProvider.selectedObjects.length;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Подтверждение удаления'),
          content: Text(
            'Вы уверены, что хотите удалить выбранные $selectedCount объектов?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await objectsProvider.deleteSelectedObjects();
              },
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _showMultiMoveDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? selectedLocationId = 'garage';

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить $selectedCount инструментов',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.deepPurple),
                    title: Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                      });
                    },
                  ),

                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      trailing: selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                        });
                      },
                    );
                  }),

                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedLocationId != null) {
                              String locationName = 'Гараж';
                              if (selectedLocationId != 'garage') {
                                final object = objectsProvider.objects
                                    .firstWhere(
                                      (o) => o.id == selectedLocationId,
                                    );
                                locationName = object.name;
                              }

                              await toolsProvider.moveSelectedTools(
                                selectedLocationId!,
                                locationName,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Переместить'),
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

  Future<void> _shareSelectedTools(BuildContext context) async {
    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final selectedTools = toolsProvider.selectedTools;

      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          context,
          'Выберите инструменты для общего доступа',
        );
        return;
      }

      String shareText = 'Список инструментов Tooler:\n\n';
      for (var i = 0; i < selectedTools.length; i++) {
        final tool = selectedTools[i];
        shareText += '${i + 1}. ${tool.title} (${tool.brand})\n';
        shareText += '   ID: ${tool.uniqueId}\n';
        shareText +=
            '   Местоположение: ${tool.currentLocation == 'garage' ? 'Гараж' : 'Объект'}\n\n';
      }

      shareText += '\nСгенерировано в приложении Tooler';

      await Share.share(shareText);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при общем доступе: $e');
    }
  }

  Future<void> _generateInventoryReport(BuildContext context) async {
    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      await ReportService.generateInventoryReport(
        toolsProvider.tools,
        objectsProvider.objects,
        context,
      );
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании отчета: $e');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                  radius: 30,
                ),
                SizedBox(height: 12),
                Text(
                  authProvider.user?.email ?? 'Гость',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Менеджер строительных инструментов',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.garage, 'Гараж', 0),
          _buildDrawerItem(Icons.build, 'Инструменты', 1),
          _buildDrawerItem(Icons.location_city, 'Объекты', 2),
          _buildDrawerItem(Icons.move_to_inbox, 'Переместить', 3),
          _buildDrawerItem(Icons.favorite, 'Избранное', 4),
          _buildDrawerItem(Icons.person, 'Профиль', 5),
          Divider(),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Создать отчет'),
            onTap: () => _generateInventoryReport(context),
          ),
          Divider(),
          // Статистика
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статистика',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Инструменты:'),
                    Text('${toolsProvider.totalTools}'),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Объекты:'),
                    Text('${objectsProvider.totalObjects}'),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Выйти'),
            onTap: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}

// ========== ЭКРАН ГАРАЖА ==========
class EnhancedGarageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Мой Гараж',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${toolsProvider.garageTools.length} инструментов доступно',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      context,
                      'Всего',
                      '${toolsProvider.totalTools}',
                      Icons.build,
                    ),
                    _buildStatCard(
                      context,
                      'В гараже',
                      '${toolsProvider.garageTools.length}',
                      Icons.garage,
                    ),
                    _buildStatCard(
                      context,
                      'Избранные',
                      '${toolsProvider.favoriteTools.length}',
                      Icons.favorite,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Быстрые действия
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditToolScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Добавить'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    toolsProvider.toggleSelectionMode();
                  },
                  icon: Icon(Icons.checklist),
                  label: Text(
                    toolsProvider.selectionMode ? 'Отменить' : 'Выбрать',
                  ),
                ),
              ],
            ),
          ),

          // Список инструментов
          Expanded(
            child: toolsProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : toolsProvider.garageTools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.garage, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'Гараж пуст',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Добавьте инструменты в гараж',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditToolScreen(),
                              ),
                            );
                          },
                          child: Text('Добавить первый инструмент'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: toolsProvider.garageTools.length,
                    itemBuilder: (context, index) {
                      final tool = toolsProvider.garageTools[index];
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
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ========== ЭКРАН СПИСКА ИНСТРУМЕНТОВ ==========
class ToolsListScreen extends StatefulWidget {
  @override
  _ToolsListScreenState createState() => _ToolsListScreenState();
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
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Все инструменты (${toolsProvider.totalTools})'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => toolsProvider.loadTools(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск инструментов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                toolsProvider.setSearchQuery(value);
              },
            ),
          ),

          // Индикатор активных фильтров
          if (toolsProvider.filterLocation != 'all' ||
              toolsProvider.filterBrand != 'all' ||
              toolsProvider.filterFavorites)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(toolsProvider),
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                  TextButton(
                    onPressed: () => toolsProvider.clearAllFilters(),
                    child: Text('Очистить', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Фильтры-чипсы
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSortChip('По дате', 'date', toolsProvider),
                _buildSortChip('По имени', 'name', toolsProvider),
                _buildSortChip('По бренду', 'brand', toolsProvider),
                _buildSortChip('В гараже', 'location', toolsProvider),
                _buildSortChip('Избранное', 'favorite', toolsProvider),
              ],
            ),
          ),

          Divider(height: 1),

          // Список инструментов
          Expanded(
            child: toolsProvider.isLoading && toolsProvider.tools.isEmpty
                ? Center(child: CircularProgressIndicator())
                : toolsProvider.tools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'Нет инструментов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditToolScreen(),
                              ),
                            );
                          },
                          child: Text('Добавить инструмент'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => toolsProvider.loadTools(),
                    child: ListView.builder(
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
              icon: Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditToolScreen()),
                );
              },
              child: Icon(Icons.add),
            ),
    );
  }

  String _getActiveFiltersText(ToolsProvider provider) {
    List<String> filters = [];

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

  Widget _buildSortChip(String label, String type, ToolsProvider provider) {
    bool isSelected = false;

    if (type == 'date') {
    } else if (type == 'location') {
      isSelected = provider.filterLocation == 'garage';
    } else if (type == 'favorite') {
      isSelected = provider.filterFavorites;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (type == 'date') {
            provider.setSort('date', false);
          } else if (type == 'name') {
            provider.setSort('name', true);
          } else if (type == 'brand') {
            provider.setSort('brand', true);
          } else if (type == 'location') {
            provider.setFilterLocation(selected ? 'garage' : 'all');
          } else if (type == 'favorite') {
            provider.setFilterFavorites(selected);
          }
        },
      ),
    );
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
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Фильтры инструментов',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Фильтр по местоположению
                  ExpansionTile(
                    title: Text('Местоположение'),
                    children: [
                      RadioListTile<String>(
                        title: Text('Все'),
                        value: 'all',
                        groupValue: toolsProvider.filterLocation,
                        onChanged: (value) {
                          setState(() {});
                          toolsProvider.setFilterLocation(value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: Text('Гараж'),
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

                  // Фильтр по бренду
                  ExpansionTile(
                    title: Text('Бренд'),
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

                  // Фильтр избранного
                  SwitchListTile(
                    title: Text('Только избранные'),
                    value: toolsProvider.filterFavorites,
                    onChanged: (value) {
                      toolsProvider.setFilterFavorites(value);
                    },
                  ),

                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => toolsProvider.clearAllFilters(),
                          child: Text('Сбросить все'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Применить'),
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
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount инструментов',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.move_to_inbox, color: Colors.blue),
                title: Text('Переместить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiMoveDialog(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiDeleteDialog(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.share, color: Colors.green),
                title: Text('Поделиться информацией'),
                onTap: () {
                  Navigator.pop(context);
                  _shareSelectedTools(context);
                },
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
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
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить выбранные $selectedCount инструментов? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await toolsProvider.deleteSelectedTools();
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMultiMoveDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? selectedLocationId = 'garage';

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить $selectedCount инструментов',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.blue),
                    title: Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                      });
                    },
                  ),

                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      trailing: selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                        });
                      },
                    );
                  }),

                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedLocationId != null) {
                              String locationName = 'Гараж';
                              if (selectedLocationId != 'garage') {
                                final object = objectsProvider.objects
                                    .firstWhere(
                                      (o) => o.id == selectedLocationId,
                                      orElse: () => ConstructionObject(
                                        id: 'garage',
                                        name: 'Гараж',
                                        description: '',
                                      ),
                                    );
                                locationName = object.name;
                              }

                              await toolsProvider.moveSelectedTools(
                                selectedLocationId!,
                                locationName,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Переместить'),
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

  Future<void> _shareSelectedTools(BuildContext context) async {
    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final selectedTools = toolsProvider.selectedTools;

      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          context,
          'Выберите инструменты для общего доступа',
        );
        return;
      }

      String shareText = 'Список инструментов Tooler:\n\n';
      for (var i = 0; i < selectedTools.length; i++) {
        final tool = selectedTools[i];
        shareText += '${i + 1}. ${tool.title} (${tool.brand})\n';
        shareText += '   ID: ${tool.uniqueId}\n';
        shareText +=
            '   Местоположение: ${tool.currentLocation == 'garage' ? 'Гараж' : 'Объект'}\n\n';
      }

      shareText += '\nСгенерировано в приложении Tooler';

      await Share.share(shareText);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при общем доступе: $e');
    }
  }
}

// ========== ЭКРАН ДЕТАЛЕЙ ИНСТРУМЕНТА ==========
class EnhancedToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const EnhancedToolDetailsScreen({Key? key, required this.tool})
    : super(key: key);

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
                            ? NetworkImage(tool.displayImage!)
                            : FileImage(File(tool.displayImage!))
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.build,
                            size: 100,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () => _shareTool(context),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
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
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Дублировать'),
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
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('Создать PDF отчет'),
                      onTap: () {
                        Navigator.pop(context);
                        ReportService.generateToolReport(tool, context);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
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
                          style: TextStyle(
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
                            ),
                            onPressed: () {
                              toolsProvider.toggleFavorite(tool.id);
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
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
                      SizedBox(width: 10),
                      Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(tool.uniqueId, style: TextStyle(color: Colors.grey)),
                    ],
                  ),

                  SizedBox(height: 20),

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
                          SizedBox(height: 10),
                          Text(
                            tool.description.isNotEmpty
                                ? tool.description
                                : 'Описание отсутствует',
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

                  SizedBox(height: 20),

                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildDetailCard(
                        icon: Icons.location_on,
                        title: 'Местоположение',
                        value: tool.currentLocation == 'garage'
                            ? 'Гараж'
                            : 'На объекте',
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
                        icon: Icons.history,
                        title: 'История',
                        value: '${tool.locationHistory.length} записей',
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

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
                                Icon(Icons.history, color: Colors.purple),
                                SizedBox(width: 10),
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
                            SizedBox(height: 10),
                            ...tool.locationHistory.map((history) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            history.locationName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            DateFormat(
                                              'dd.MM.yyyy HH:mm',
                                            ).format(history.date),
                                            style: TextStyle(
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

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Consumer<ToolsProvider>(
          builder: (context, toolsProvider, child) {
            return ElevatedButton.icon(
              onPressed: () => _showMoveDialog(context, tool),
              icon: Icon(Icons.move_to_inbox),
              label: Text('Переместить инструмент'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
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
                SizedBox(width: 8),
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
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
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

  Future<void> _shareTool(BuildContext context) async {
    try {
      await ReportService.generateToolReport(tool, context);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при общем доступе: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить "${tool.title}"? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
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
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
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
        final objects = objectsProvider.objects;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить инструмент',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.blue),
                    title: Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                      });
                    },
                  ),
                  Divider(),
                  ...objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                        });
                      },
                    );
                  }),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedLocationId != null) {
                              String locationName = 'Гараж';
                              if (selectedLocationId != 'garage') {
                                final object = objects.firstWhere(
                                  (o) => o.id == selectedLocationId,
                                  orElse: () => ConstructionObject(
                                    id: 'garage',
                                    name: 'Гараж',
                                    description: '',
                                  ),
                                );
                                locationName = object.name;
                              }

                              await toolsProvider.moveTool(
                                tool.id,
                                selectedLocationId!,
                                locationName,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Переместить'),
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

// ========== ЭКРАН СПИСКА ОБЪЕКТОВ ==========
class EnhancedObjectsListScreen extends StatefulWidget {
  @override
  _EnhancedObjectsListScreenState createState() =>
      _EnhancedObjectsListScreenState();
}

class _EnhancedObjectsListScreenState extends State<EnhancedObjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ObjectsProvider>(context, listen: false);
      provider.loadObjects();
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Объекты (${objectsProvider.totalObjects})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => objectsProvider.loadObjects(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск объектов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                objectsProvider.setSearchQuery(value);
              },
            ),
          ),

          // Список объектов
          Expanded(
            child: objectsProvider.isLoading && objectsProvider.objects.isEmpty
                ? Center(child: CircularProgressIndicator())
                : objectsProvider.objects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Нет объектов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditObjectScreen(),
                              ),
                            );
                          },
                          child: Text('Добавить объект'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => objectsProvider.loadObjects(),
                    child: ListView.builder(
                      itemCount: objectsProvider.objects.length,
                      itemBuilder: (context, index) {
                        final object = objectsProvider.objects[index];
                        return ObjectCard(
                          object: object,
                          toolsProvider: toolsProvider,
                          selectionMode: objectsProvider.selectionMode,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ObjectDetailsScreen(object: object),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: objectsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (objectsProvider.hasSelectedObjects) {
                  _showObjectSelectionActions(context);
                }
              },
              icon: Icon(Icons.more_vert),
              label: Text('${objectsProvider.selectedObjects.length}'),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditObjectScreen(),
                  ),
                );
              },
              child: Icon(Icons.add),
            ),
    );
  }

  void _showObjectSelectionActions(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = objectsProvider.selectedObjects.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount объектов',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Подтверждение удаления'),
                      content: Text(
                        'Вы уверены, что хотите удалить выбранные $selectedCount объектов?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await objectsProvider.deleteSelectedObjects();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========== КАРТОЧКА ОБЪЕКТА ==========
class ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final ToolsProvider toolsProvider;
  final bool selectionMode;
  final VoidCallback onTap;

  const ObjectCard({
    Key? key,
    required this.object,
    required this.toolsProvider,
    required this.selectionMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Consumer<ObjectsProvider>(
      builder: (context, objectsProvider, child) {
        return InkWell(
          onTap: selectionMode
              ? () {
                  objectsProvider.toggleObjectSelection(object.id);
                }
              : onTap,
          onLongPress: () {
            if (!selectionMode) {
              objectsProvider.toggleSelectionMode();
              objectsProvider.selectObject(object.id);
            }
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  if (selectionMode)
                    Checkbox(
                      value: object.isSelected,
                      onChanged: (value) {
                        objectsProvider.toggleObjectSelection(object.id);
                      },
                    ),
                  SizedBox(width: 8),
                  // Изображение объекта
                  if (object.displayImage != null)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: object.displayImage!.startsWith('http')
                              ? NetworkImage(object.displayImage!)
                              : FileImage(File(object.displayImage!))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_city,
                          color: Colors.orange.withOpacity(0.5),
                          size: 30,
                        ),
                      ),
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        if (object.description.isNotEmpty)
                          Text(
                            object.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.build, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${toolsOnObject.length} инструментов',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!selectionMode)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Редактировать'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditObjectScreen(object: object),
                                ),
                              );
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Подтверждение удаления'),
                                  content: Text('Удалить "${object.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await objectsProvider.deleteObject(
                                          object.id,
                                        );
                                      },
                                      child: Text(
                                        'Удалить',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== ЭКРАН ДЕТАЛЕЙ ОБЪЕКТА ==========
class ObjectDetailsScreen extends StatelessWidget {
  final ConstructionObject object;

  const ObjectDetailsScreen({Key? key, required this.object}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditObjectScreen(object: object),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Изображение объекта
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[100]),
            child: object.displayImage != null
                ? Image(
                    image: object.displayImage!.startsWith('http')
                        ? NetworkImage(object.displayImage!)
                        : FileImage(File(object.displayImage!))
                              as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                  ),
          ),

          // Информация об объекте
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  object.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (object.description.isNotEmpty)
                  Text(
                    object.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.build, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Инструментов на объекте: ${toolsOnObject.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(),

          // Инструменты на объекте
          Expanded(
            child: toolsOnObject.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build, size: 60, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(
                          'На объекте нет инструментов',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Переместите инструменты на этот объект',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: toolsOnObject.length,
                    itemBuilder: (context, index) {
                      final tool = toolsOnObject[index];
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
          ),
        ],
      ),
    );
  }
}

// ========== ЭКРАН ПЕРЕМЕЩЕНИЯ ИНСТРУМЕНТОВ ==========
class MoveToolsScreen extends StatefulWidget {
  @override
  _MoveToolsScreenState createState() => _MoveToolsScreenState();
}

class _MoveToolsScreenState extends State<MoveToolsScreen> {
  String? _selectedLocationId;
  final List<String> _selectedToolIds = [];

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final garageTools = toolsProvider.garageTools;

    return Scaffold(
      appBar: AppBar(title: Text('Перемещение инструментов')),
      body: Column(
        children: [
          // Выбор места назначения
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выберите место назначения:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  // Гараж
                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.blue),
                    title: Text('Гараж'),
                    trailing: _selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLocationId = 'garage';
                      });
                    },
                  ),
                  Divider(),
                  // Объекты
                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: _selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLocationId = object.id;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Доступные инструменты
          Expanded(
            child: garageTools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.garage, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'В гараже нет инструментов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Все инструменты уже на объектах',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: garageTools.length,
                    itemBuilder: (context, index) {
                      final tool = garageTools[index];
                      final isSelected = _selectedToolIds.contains(tool.id);

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedToolIds.add(tool.id);
                              } else {
                                _selectedToolIds.remove(tool.id);
                              }
                            });
                          },
                          title: Text(tool.title),
                          subtitle: Text(tool.brand),
                          secondary: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.build,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Кнопка перемещения
          if (_selectedLocationId != null && _selectedToolIds.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedLocationId == null) {
                    ErrorHandler.showWarningDialog(
                      context,
                      'Выберите место назначения',
                    );
                    return;
                  }

                  if (_selectedToolIds.isEmpty) {
                    ErrorHandler.showWarningDialog(
                      context,
                      'Выберите инструменты для перемещения',
                    );
                    return;
                  }

                  String locationName = 'Гараж';
                  if (_selectedLocationId != 'garage') {
                    final object = objectsProvider.objects.firstWhere(
                      (o) => o.id == _selectedLocationId,
                      orElse: () => ConstructionObject(
                        id: 'garage',
                        name: 'Гараж',
                        description: '',
                      ),
                    );
                    locationName = object.name;
                  }

                  await toolsProvider.moveSelectedTools(
                    _selectedLocationId!,
                    locationName,
                  );

                  setState(() {
                    _selectedToolIds.clear();
                    _selectedLocationId = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Переместить ${_selectedToolIds.length} инструментов',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ========== ЭКРАН ИЗБРАННОГО ==========
class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;

    return Scaffold(
      appBar: AppBar(title: Text('Избранное (${favoriteTools.length})')),
      body: favoriteTools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Нет избранных инструментов',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Добавьте инструменты в избранное',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
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
}

// ========== ЭКРАН ПРОФИЛЯ ==========
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Шапка профиля
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      authProvider.user?.email ?? 'Гость',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Менеджер инструментов',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Статистика
            Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatCard(
                    'Всего инструментов',
                    '${toolsProvider.totalTools}',
                    Icons.build,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'В гараже',
                    '${toolsProvider.garageTools.length}',
                    Icons.garage,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Объектов',
                    '${objectsProvider.totalObjects}',
                    Icons.location_city,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Избранных',
                    '${toolsProvider.favoriteTools.length}',
                    Icons.favorite,
                    Colors.red,
                  ),
                ],
              ),
            ),

            // Настройки
            Card(
              margin: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('Синхронизация данных'),
                    trailing: Switch(value: true, onChanged: (value) {}),
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Уведомления'),
                    trailing: Switch(value: true, onChanged: (value) {}),
                  ),
                  ListTile(
                    leading: Icon(Icons.dark_mode),
                    title: Text('Темная тема'),
                    trailing: Switch(value: false, onChanged: (value) {}),
                  ),
                ],
              ),
            ),

            // Действия
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ReportService.generateInventoryReport(
                        toolsProvider.tools,
                        objectsProvider.objects,
                        context,
                      );
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Создать отчет PDF'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Функция резервного копирования
                      ErrorHandler.showSuccessDialog(
                        context,
                        'Резервная копия создана',
                      );
                    },
                    icon: Icon(Icons.backup),
                    label: Text('Создать резервную копию'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AuthScreen()),
                      );
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
