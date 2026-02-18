// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/construction_object.dart';
import '../../../data/services/report_service.dart';
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
  
  // Advanced filters
  String _sortBy = 'name'; // name, date, tools_count
  DateTime? _createdDateFrom;
  DateTime? _createdDateTo;
  int _minToolCount = 0;
  int _maxToolCount = 100;
  List<String> _activeFilters = [];

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
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    if (objectsProvider.selectionMode) {
      objectsProvider.toggleSelectionMode();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    List<ConstructionObject> displayObjects = objectsProvider.objects;
    
    // Apply filters
    if (_showFavoritesOnly) {
      displayObjects = displayObjects.where((o) => o.isFavorite).toList();
    }
    
    // Apply date range filter
    if (_createdDateFrom != null) {
      displayObjects = displayObjects
          .where((o) => o.createdAt.isAfter(_createdDateFrom!))
          .toList();
    }
    if (_createdDateTo != null) {
      displayObjects = displayObjects
          .where((o) => o.createdAt.isBefore(_createdDateTo!.add(const Duration(days: 1))))
          .toList();
    }
    
    // Apply tool count filter
    if (_minToolCount > 0 || _maxToolCount < 100) {
      displayObjects = displayObjects
          .where((o) => o.toolIds.length >= _minToolCount && o.toolIds.length <= _maxToolCount)
          .toList();
    }
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      displayObjects = displayObjects.where((o) =>
          o.name.toLowerCase().contains(q) ||
          o.description.toLowerCase().contains(q)).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'date':
        displayObjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'tools_count':
        displayObjects.sort((a, b) => b.toolIds.length.compareTo(a.toolIds.length));
        break;
      case 'name':
      default:
        displayObjects.sort((a, b) => a.name.compareTo(b.name));
    }
    
    // Calculate active filters count
    _activeFilters.clear();
    if (_showFavoritesOnly) _activeFilters.add('Избранные');
    if (_createdDateFrom != null || _createdDateTo != null) _activeFilters.add('Дата');
    if (_minToolCount > 0 || _maxToolCount < 100) _activeFilters.add('Инструменты');
    if (_searchController.text.isNotEmpty) _activeFilters.add('Поиск');

    return Scaffold(
      appBar: AppBar(
        title: Text('Объекты (${displayObjects.length})'),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _showFavoritesOnly ? Colors.red : null),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showAdvancedFiltersPanel(context),
              ),
              if (_activeFilters.isNotEmpty && !_activeFilters.contains('Поиск'))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_activeFilters.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_activeFilters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: ElevatedButton(
                      onPressed: _clearAllFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade200,
                      ),
                      child: const Text('Сбросить фильтры'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: objectsProvider.toggleSelectionMode,
                        icon: const Icon(Icons.checklist),
                        label: Text(objectsProvider.selectionMode ? 'Отменить' : 'Выбрать'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (objectsProvider.selectionMode && displayObjects.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: objectsProvider.selectAllObjects,
                          icon: const Icon(Icons.select_all),
                          label: const Text('Все'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
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
                              objectsProvider: objectsProvider,
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
  void _clearAllFilters() {
    setState(() {
      _showFavoritesOnly = false;
      _sortBy = 'name';
      _createdDateFrom = null;
      _createdDateTo = null;
      _minToolCount = 0;
      _maxToolCount = 100;
      _searchController.clear();
    });
  }

  void _showAdvancedFiltersPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Расширенные фильтры',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sort Option
                const Text(
                  'Сортировка',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('По названию')),
                    DropdownMenuItem(value: 'date', child: Text('По дате создания')),
                    DropdownMenuItem(value: 'tools_count', child: Text('По кол-ву инструментов')),
                  ],
                  onChanged: (v) {
                    setState(() => _sortBy = v ?? 'name');
                    this.setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Tool Count Range
                const Text(
                  'Диапазон кол-ва инструментов',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Text('От $_minToolCount до $_maxToolCount'),
                    RangeSlider(
                      values: RangeValues(_minToolCount.toDouble(), _maxToolCount.toDouble()),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      labels: RangeLabels(
                        _minToolCount.toString(),
                        _maxToolCount.toString(),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _minToolCount = v.start.toInt();
                          _maxToolCount = v.end.toInt();
                        });
                        this.setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Created Date Range
                const Text(
                  'Диапазон даты создания',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _createdDateFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _createdDateFrom = date);
                            this.setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _createdDateFrom != null
                                ? '${_createdDateFrom!.day}.${_createdDateFrom!.month}.${_createdDateFrom!.year}'
                                : 'От',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _createdDateTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _createdDateTo = date);
                            this.setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _createdDateTo != null
                                ? '${_createdDateTo!.day}.${_createdDateTo!.month}.${_createdDateTo!.year}'
                                : 'До',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _clearAllFilters();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Очистить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade200,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Применить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () {
                  Navigator.pop(context);
                  _showObjectReportTypeDialog(context, objectsProvider.selectedObjects);
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
              await objectsProvider.deleteSelectedObjects(context: context);
              await Future.delayed(const Duration(milliseconds: 2000));
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showObjectReportTypeDialog(
      BuildContext context, List<ConstructionObject> selectedObjects) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите тип отчета',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF отчет'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final obj in selectedObjects) {
                    final toolsOnObject =
                        toolsProvider.tools.where((t) => t.currentLocation == obj.id).toList();
                    await ReportService.shareObjectReport(
                        obj, toolsOnObject, context, ReportType.pdf);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Текстовый отчет'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final obj in selectedObjects) {
                    final toolsOnObject =
                        toolsProvider.tools.where((t) => t.currentLocation == obj.id).toList();
                    await ReportService.shareObjectReport(
                        obj, toolsOnObject, context, ReportType.text);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Wrapper for navigation compatibility
class ObjectsListScreen extends StatelessWidget {
  const ObjectsListScreen({super.key});
  @override
  Widget build(BuildContext context) => EnhancedObjectsListScreen();
}
