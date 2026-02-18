// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../data/services/report_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../viewmodels/auth_provider.dart' as app_auth;
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../widgets/selection_tool_card.dart';
import '../../widgets/custom_filter_chip.dart';
import 'add_edit_tool_screen.dart';
import 'move_tools_screen_launcher.dart';
import 'tool_details_screen.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedGarageScreen();
  }
}

class EnhancedGarageScreen extends StatefulWidget {
  const EnhancedGarageScreen({super.key});
  @override
  State<EnhancedGarageScreen> createState() => _EnhancedGarageScreenState();
}

class _EnhancedGarageScreenState extends State<EnhancedGarageScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _sortBy = 'name';
  String? _filterBrand;
  bool _showFavoritesOnly = false;
  DateTime? _createdDateFrom;
  DateTime? _createdDateTo;
  final List<String> _activeFilters = [];
  bool _loadingTimeout = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsProvider>(
        context,
        listen: false,
      ).loadTools().catchError((_) {});
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _loadingTimeout = true);
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final authProvider = Provider.of<app_auth.AuthProvider>(context);

    final sourceTools = authProvider.isAdmin
        ? toolsProvider.tools
        : toolsProvider.garageTools;
    var garageTools = List<Tool>.from(sourceTools);

    final allBrands = (toolsProvider.tools).map((t) => t.brand).toSet().toList()
      ..sort();

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
          .where(
            (t) => t.createdAt.isBefore(
              _createdDateTo!.add(const Duration(days: 1)),
            ),
          )
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      garageTools = garageTools
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.brand.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q) ||
                t.uniqueId.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'date':
        garageTools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'brand':
        garageTools.sort((a, b) => a.brand.compareTo(b.brand));
        break;
      case 'name':
      default:
        garageTools.sort((a, b) => a.title.compareTo(b.title));
    }

    final selectedGarageTools = garageTools
        .where((tool) => tool.isSelected)
        .toList();

    _activeFilters.clear();
    if (_filterBrand != null && _filterBrand != 'all')
      _activeFilters.add('Бренд');
    if (_showFavoritesOnly) _activeFilters.add('Избранные');
    if (_createdDateFrom != null || _createdDateTo != null)
      _activeFilters.add('Дата');
    if (_searchController.text.isNotEmpty) _activeFilters.add('Поиск');

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Гараж')),
      body: RefreshIndicator(
        onRefresh: () => toolsProvider.loadTools(forceRefresh: true),
        child:
            (toolsProvider.isLoading && garageTools.isEmpty && !_loadingTimeout)
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                          onSelected: (_) =>
                              setState(() => _showFavoritesOnly = false),
                        ),
                        const SizedBox(width: 16),
                        CustomFilterChip(
                          label: 'Избранные',
                          icon: Icons.favorite,
                          selected: _showFavoritesOnly,
                          onSelected: (_) => setState(
                            () => _showFavoritesOnly = !_showFavoritesOnly,
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String?>(
                          hint: const Text('Бренд'),
                          value: _filterBrand,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Все'),
                            ),
                            ...allBrands.map(
                              (brand) => DropdownMenuItem<String?>(
                                value: brand,
                                child: Text(brand),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterBrand = v),
                        ),
                        const SizedBox(width: 12),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.tune),
                              onPressed: () =>
                                  _showAdvancedFiltersPanel(context),
                            ),
                            if (_activeFilters.isNotEmpty &&
                                !_activeFilters.contains('Поиск'))
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (authProvider.isAdmin)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddEditToolScreen(),
                                ),
                              );
                              if (!mounted) return;
                              await Provider.of<ToolsProvider>(
                                context,
                                listen: false,
                              ).loadTools(forceRefresh: true);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        if (authProvider.isAdmin) const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: toolsProvider.toggleSelectionMode,
                          icon: const Icon(Icons.checklist),
                          label: Text(
                            toolsProvider.selectionMode
                                ? 'Отменить'
                                : 'Выбрать',
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (toolsProvider.selectionMode &&
                            garageTools.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Only select visible/filtered garage tools
                              final visibleToolIds = garageTools
                                  .map((t) => t.id)
                                  .toList();
                              toolsProvider.selectToolsByIds(visibleToolIds);
                            },
                            icon: const Icon(Icons.select_all),
                            label: const Text('Все'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            key: const PageStorageKey('garage_tools_list'),
                            padding: const EdgeInsets.all(8),
                            itemCount: garageTools.length,
                            itemBuilder: (context, index) {
                              final tool = garageTools[index];
                              return SelectionToolCard(
                                key: ValueKey(tool.id),
                                tool: tool,
                                selectionMode: toolsProvider.selectionMode,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EnhancedToolDetailsScreen(tool: tool),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton:
          toolsProvider.selectionMode && selectedGarageTools.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showGarageSelectionActions(context, selectedGarageTools),
              icon: const Icon(Icons.more_vert),
              label: Text('Выбрано: ${selectedGarageTools.length}'),
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
      _searchController.clear();
    });
    ErrorHandler.showInfoDialog(context, 'Фильтры сброшены');
  }

  void _showAdvancedFiltersPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Сортировка',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'name',
                        child: Text('По названию'),
                      ),
                      DropdownMenuItem(
                        value: 'date',
                        child: Text('По дате добавления'),
                      ),
                      DropdownMenuItem(
                        value: 'brand',
                        child: Text('По бренду'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        this.setState(() => _sortBy = v);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
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
                              this.setState(() => _createdDateFrom = date);
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
                              this.setState(() => _createdDateTo = date);
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
      ),
    );
  }

  Widget _buildLoadingScreen() => Center(
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

  Widget _buildEmptyGarage(bool isAdmin) => Center(
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
        if (isAdmin)
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditToolScreen(),
              ),
            ),
            child: const Text('Добавить первый инструмент'),
          ),
      ],
    ),
  );

  Future<void> _showMoveMultipleToolsDialog(
    BuildContext context,
    ToolsProvider toolsProvider,
    ObjectsProvider objectsProvider,
  ) async {
    String? selectedLocationId;
    String? selectedLocationName;
    bool isMoving = false;

    // Load objects first
    try {
      await objectsProvider.loadObjects(forceRefresh: true);
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showErrorDialog(context, 'Ошибка загрузки объектов: $e');
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Переместить ${toolsProvider.selectedTools.length} инструментов',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выберите место назначения:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Garage option
                RadioListTile<String>(
                  title: const Text('Гараж'),
                  subtitle: const Text('Вернуть в основной гараж'),
                  value: 'garage',
                  groupValue: selectedLocationId,
                  onChanged: isMoving
                      ? null
                      : (value) {
                          setState(() {
                            selectedLocationId = value;
                            selectedLocationName = 'Гараж';
                          });
                        },
                ),
                // Objects list
                ...objectsProvider.objects.map(
                  (obj) => RadioListTile<String>(
                    title: Text(obj.name),
                    subtitle: Text('Инструментов: ${obj.toolIds.length}'),
                    value: obj.id,
                    groupValue: selectedLocationId,
                    onChanged: isMoving
                        ? null
                        : (value) {
                            setState(() {
                              selectedLocationId = value;
                              selectedLocationName = obj.name;
                            });
                          },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isMoving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: (selectedLocationId == null || isMoving)
                  ? null
                  : () async {
                      setState(() => isMoving = true);
                      try {
                        // Move the tools
                        await toolsProvider.moveSelectedTools(
                          selectedLocationId!,
                          selectedLocationName!,
                        );

                        if (!dialogContext.mounted) return;

                        // Close dialog with success
                        Navigator.pop(dialogContext);

                        // Refresh garage screen
                        this.setState(() {});
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        setState(() => isMoving = false);
                        // Error is already shown by moveSelectedTools
                      }
                    },
              child: isMoving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Переместить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGarageSelectionActions(
    BuildContext context,
    List<Tool> selectedGarageTools,
  ) {
    final screenContext = context;
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedTools = List<Tool>.from(selectedGarageTools);

    if (selectedTools.isEmpty) {
      ErrorHandler.showWarningDialog(context, 'Выберите инструменты');
      return;
    }

    showModalBottomSheet(
      context: screenContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Действия (${selectedTools.length} инструментов)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                  title: const Text('Переместить инструменты'),
                  subtitle: const Text('Переместить выбранные инструменты'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      showMoveToolsScreen(this.context, selectedTools);
                    });
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить инструменты'),
                  subtitle: const Text('Удалить выбранные инструменты'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (screenContext.mounted) {
                      _showDeleteConfirmation(
                        screenContext,
                        toolsProvider,
                        selectedTools,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Создать отчет'),
                  subtitle: const Text('PDF отчет по инструментам'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (screenContext.mounted) {
                      _showReportTypeDialog(screenContext, selectedTools);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.pink),
                  title: const Text('Добавить в избранное'),
                  subtitle: const Text('Пометить как избранные'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    for (var tool in selectedTools) {
                      toolsProvider.toggleFavorite(tool.id);
                    }
                    toolsProvider.selectToolsByIds([]);
                    setState(() {});
                    ErrorHandler.showSuccessDialog(
                      screenContext,
                      'Добавлено в избранное',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportTypeDialog(BuildContext context, List<Tool> selectedTools) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Выберите формат отчета',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('PDF отчет'),
                  subtitle: const Text('Красиво оформленный отчет'),
                  onTap: () {
                    final ctx = context;
                    Navigator.pop(context);
                    if (ctx.mounted) {
                      _generateAndShareReport(
                        ctx,
                        selectedTools,
                        ReportType.pdf,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.text_fields, color: Colors.blue),
                  title: const Text('Текстовый отчет'),
                  subtitle: const Text('Простой текстовый формат'),
                  onTap: () {
                    final ctx = context;
                    Navigator.pop(context);
                    if (ctx.mounted) {
                      _generateAndShareReport(
                        ctx,
                        selectedTools,
                        ReportType.text,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndShareReport(
    BuildContext context,
    List<Tool> selectedTools,
    ReportType reportType,
  ) async {
    final progressContext = context;
    bool progressDialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          progressDialogShown = true;
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    reportType == ReportType.pdf
                        ? 'Создание PDF отчета...'
                        : 'Создание текстового отчета...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Add timeout to prevent infinite loading
      try {
        await ReportService.shareMultipleToolsReport(
          selectedTools,
          context,
          reportType,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException(
              'Время ожидания истекло. Пожалуйста, повторите попытку.',
            );
          },
        );
      } catch (e) {
        if (progressDialogShown && progressContext.mounted) {
          Navigator.of(progressContext, rootNavigator: true).pop();
          progressDialogShown = false;
        }
        rethrow;
      }

      if (progressDialogShown && progressContext.mounted) {
        Navigator.of(progressContext, rootNavigator: true).pop();
        progressDialogShown = false;
        ErrorHandler.showSuccessDialog(
          progressContext,
          reportType == ReportType.pdf
              ? 'PDF отчет готов!'
              : 'Текстовый отчет готов!',
        );
      }
    } catch (e) {
      if (progressDialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressDialogShown = false;
      }
      if (context.mounted) {
        ErrorHandler.showErrorDialog(
          context,
          'Ошибка при создании отчета: $e',
        );
      }
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ToolsProvider toolsProvider,
    List<Tool> selectedTools,
  ) {
    final authProvider = Provider.of<app_auth.AuthProvider>(
      context,
      listen: false,
    );

    if (!authProvider.isAdmin) {
      ErrorHandler.showErrorDialog(
        context,
        'Только администратор может удалять инструменты',
      );
      return;
    }

    // save the outer context so we don't accidentally use a dialog's context
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены? Это действие нельзя отменить.\n'
          'Удаляется: ${selectedTools.length} инструмент(ов)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              // close the confirmation dialog first
              Navigator.pop(dialogCtx);

              // return early if the screen has been popped as well
              if (!mounted || !outerContext.mounted) return;

              try {
                // show progress dialog using the outer (screen) context
                showDialog(
                  context: outerContext,
                  barrierDismissible: false,
                  builder: (progressCtx) => WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          const Text('Удаление инструментов...'),
                        ],
                      ),
                    ),
                  ),
                );

                final selectedToolsSnapshot = List<Tool>.from(selectedTools);
                for (var tool in selectedToolsSnapshot) {
                  if (!outerContext.mounted) break;
                  await toolsProvider.deleteTool(tool.id);
                }

                if (outerContext.mounted) {
                  Navigator.pop(outerContext); // Close progress dialog
                  toolsProvider.clearAllSelections();
                  setState(() {});
                  ErrorHandler.showSuccessDialog(
                    outerContext,
                    'Удалено ${selectedToolsSnapshot.length} инструмент(ов)',
                  );
                }
              } catch (e) {
                if (outerContext.mounted) {
                  Navigator.pop(outerContext); // Close progress dialog
                  ErrorHandler.showErrorDialog(
                    outerContext,
                    'Ошибка при удалении: $e',
                  );
                }
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
