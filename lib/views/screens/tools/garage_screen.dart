// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../data/services/report_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../viewmodels/auth_provider.dart' as app_auth;
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/users_provider.dart';
import '../../widgets/selection_tool_card.dart';
import '../../widgets/custom_filter_chip.dart';
import 'add_edit_tool_screen.dart';
import 'tool_details_screen.dart';
import 'move_tools_screen.dart';
import '../admin/users_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  
  // Advanced filters
  String _sortBy = 'name'; // name, date, brand, workers_count
  String? _filterBrand;
  bool _showFavoritesOnly = false;
  DateTime? _createdDateFrom;
  DateTime? _createdDateTo;
  int _minWorkerCount = 0;
  int _maxWorkerCount = 50;
  final List<String> _activeFilters = [];
  bool _loadingTimeout = false;

  @override
  void initState() {
    super.initState();
    // Hide Android status bar for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsProvider>(context, listen: false).loadTools().catchError((_) {});
      // Timeout after 3 seconds to prevent infinite loading
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _loadingTimeout = true);
      });
    });
  }

  @override
  void dispose() {
    // Restore status bar when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _searchController.dispose();
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    if (toolsProvider.selectionMode) {
      toolsProvider.toggleSelectionMode();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final workerProvider = Provider.of<WorkerProvider>(context);
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    // Admin sees all tools, non-admin sees only garage tools
    final sourceTools = authProvider.isAdmin
        ? toolsProvider.tools
        : toolsProvider.garageTools;
    var garageTools = List<Tool>.from(sourceTools);
    
    // Get unique brands for filter
    final allBrands = (toolsProvider.tools)
        .map((t) => t.brand)
        .toSet()
        .toList()
      ..sort();
    
    // Helper function to count workers assigned to a tool's location
    int countWorkersAtLocation(String locationId) {
      return workerProvider.workers
          .where((w) => w.assignedObjectIds.contains(locationId))
          .length;
    }

    // Apply filters with null safety
    if (_filterBrand != null && _filterBrand != 'all') {
      garageTools = garageTools.where((t) => t.brand == _filterBrand).toList();
    }
    if (_showFavoritesOnly) {
      garageTools = garageTools.where((t) => t.isFavorite).toList();
    }
    if (_createdDateFrom != null) {
      garageTools = garageTools
          .where((t) => t.createdAt.isAfter(_createdDateFrom!))
          .toList();
    }
    if (_createdDateTo != null) {
      garageTools = garageTools
          .where((t) => t.createdAt.isBefore(_createdDateTo!.add(const Duration(days: 1))))
          .toList();
    }
    
    // Apply worker count filter
    if (_minWorkerCount > 0 || _maxWorkerCount < 50) {
      garageTools = garageTools
          .where((t) {
            final workerCount = countWorkersAtLocation(t.currentLocation);
            return workerCount >= _minWorkerCount && workerCount <= _maxWorkerCount;
          })
          .toList();
    }
    
    // Apply search
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      garageTools = garageTools.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.brand.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.uniqueId.toLowerCase().contains(q)).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'date':
        garageTools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'brand':
        garageTools.sort((a, b) => a.brand.compareTo(b.brand));
        break;
      case 'workers_count':
        garageTools.sort((a, b) => 
          countWorkersAtLocation(b.currentLocation).compareTo(countWorkersAtLocation(a.currentLocation))
        );
        break;
      case 'name':
      default:
        garageTools.sort((a, b) => a.title.compareTo(b.title));
    }
    
    // Calculate active filters count
    _activeFilters.clear();
    if (_filterBrand != null && _filterBrand != 'all') _activeFilters.add('Бренд');
    if (_showFavoritesOnly) _activeFilters.add('Избранные');
    if (_createdDateFrom != null || _createdDateTo != null) _activeFilters.add('Дата');
    if (_minWorkerCount > 0 || _maxWorkerCount < 50) _activeFilters.add('Работники');
    if (_searchController.text.isNotEmpty) _activeFilters.add('Поиск');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Гараж'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ) ,
      body: (toolsProvider.isLoading && garageTools.isEmpty && !_loadingTimeout)
          ? _buildLoadingScreen()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск инструментов...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      CustomFilterChip(
                        label: 'Все',
                        selected: _showFavoritesOnly == false,
                        onSelected: (_) => setState(() => _showFavoritesOnly = false),
                      ),
                      const SizedBox(width: 16),
                      CustomFilterChip(
                        label: 'Избранные',
                        icon: Icons.favorite,
                        selected: _showFavoritesOnly,
                        onSelected: (_) => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String?>(
                        hint: const Text('Бренд'),
                        value: _filterBrand,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Все')),
                          ...allBrands.map((brand) =>
                              DropdownMenuItem<String?>(value: brand, child: Text(brand))),
                        ],
                        onChanged: (v) => setState(() => _filterBrand = v),
                      ),
                      const SizedBox(width: 12),
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
                      if (_activeFilters.isNotEmpty)
                        ElevatedButton(
                          onPressed: _clearAllFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade200,
                          ),
                          child: const Text('Сбросить'),
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
                      if (toolsProvider.selectionMode && garageTools.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: toolsProvider.selectAllTools,
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
                Flexible(
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
              label: Text('Выбрано: ${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filterBrand = null;
      _showFavoritesOnly = false;
      _sortBy = 'name';
      _createdDateFrom = null;
      _createdDateTo = null;
      _minWorkerCount = 0;
      _maxWorkerCount = 50;
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
                    DropdownMenuItem(value: 'date', child: Text('По дате добавления')),
                    DropdownMenuItem(value: 'brand', child: Text('По бренду')),
                    DropdownMenuItem(value: 'workers_count', child: Text('По кол-ву работников')),
                  ],
                  onChanged: (v) {
                    setState(() => _sortBy = v ?? 'name');
                    this.setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Created Date Range
                const Text(
                  'Диапазон даты добавления',
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

                // Worker Count Range
                const Text(
                  'Диапазон кол-ва работников',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Text('От $_minWorkerCount до $_maxWorkerCount'),
                    RangeSlider(
                      values: RangeValues(_minWorkerCount.toDouble(), _maxWorkerCount.toDouble()),
                      min: 0,
                      max: 50,
                      divisions: 10,
                      labels: RangeLabels(
                        _minWorkerCount.toString(),
                        _maxWorkerCount.toString(),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _minWorkerCount = v.start.toInt();
                          _maxWorkerCount = v.end.toInt();
                        });
                        this.setState(() {});
                      },
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
            Text('Загрузка гаража...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
                  _showReportTypeDialog(context, toolsProvider.selectedTools);
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
    final count = toolsProvider.selectedTools.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы уверены, что хотите удалить $count инструментов из гаража?'),
            const SizedBox(height: 8),
            const Text(
              'Это действие нельзя отменить.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await toolsProvider.deleteSelectedTools();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
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
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
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
                  Text('• ${t.title} (${t.currentLocationName})')),
              if (selectedTools.length > 5) Text('... и еще ${selectedTools.length - 5}'),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(Icons.garage, color: Colors.blue),
                title: const Text('Гараж'),
                trailing: selectedId == 'garage' ? const Icon(Icons.check) : null,
                enabled: !isProcessing,
                onTap: () => setState(() {
                  selectedId = 'garage';
                  selectedName = 'Гараж';
                }),
              ),
              ...objectsProvider.objects.map((obj) => ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.orange),
                    title: Text(obj.name),
                    trailing: selectedId == obj.id ? const Icon(Icons.check) : null,
                    enabled: !isProcessing,
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
                      onPressed: isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing || selectedId == null
                          ? null
                          : () async {
                              setState(() => isProcessing = true);
                              try {
                                await toolsProvider.requestMoveSelectedTools(
                                    selectedTools, selectedId!, selectedName!);
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) {
                                  ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
                                }
                              } finally {
                                if (context.mounted) setState(() => isProcessing = false);
                              }
                            },
                      child: isProcessing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Отправить запрос'),
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

  void _showReportTypeDialog(BuildContext context, List<Tool> selectedTools) {
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
                  for (final tool in selectedTools) {
                    await ReportService.shareToolReport(tool, context, ReportType.pdf);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Текстовый отчет'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final tool in selectedTools) {
                    await ReportService.shareToolReport(tool, context, ReportType.text);
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
