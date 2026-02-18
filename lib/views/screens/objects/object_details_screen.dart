import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/construction_object.dart';
import '../../../data/models/worker.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../tools/tool_details_screen.dart';
import 'add_edit_object_screen.dart';

class ObjectDetailsScreen extends StatefulWidget {
  final ConstructionObject object;
  const ObjectDetailsScreen({super.key, required this.object});

  @override
  State<ObjectDetailsScreen> createState() => _ObjectDetailsScreenState();
}

class _ObjectDetailsScreenState extends State<ObjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tools tab filters
  final TextEditingController _toolsSearchController = TextEditingController();
  String _toolsSortBy = 'name';
  bool _toolsShowFavoritesOnly = false;
  
  // Workers tab filters
  final TextEditingController _workersSearchController = TextEditingController();
  String _workersSortBy = 'name';
  bool _workersShowFavoritesOnly = false;
  
  // Multi-select state
  bool _toolsSelectionMode = false;
  bool _workersSelectionMode = false;
  final Set<String> _selectedToolIds = {};
  final Set<String> _selectedWorkerIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _toolsSearchController.dispose();
    _workersSearchController.dispose();
    _selectedToolIds.clear();
    _selectedWorkerIds.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final workerProvider = Provider.of<WorkerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    var toolsOnObject =
        toolsProvider.tools.where((tool) => tool.currentLocation == widget.object.id).toList();
    var workersOnObject = workerProvider.workers
        .where((worker) => worker.assignedObjectIds.contains(widget.object.id))
        .toList();
    
    // Apply tools filters
    if (_toolsShowFavoritesOnly) {
      toolsOnObject = toolsOnObject.where((t) => t.isFavorite).toList();
    }
    if (_toolsSearchController.text.isNotEmpty) {
      final q = _toolsSearchController.text.toLowerCase();
      toolsOnObject = toolsOnObject.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.brand.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q)).toList();
    }
    // Apply tools sorting
    switch (_toolsSortBy) {
      case 'date':
        toolsOnObject.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'brand':
        toolsOnObject.sort((a, b) => a.brand.compareTo(b.brand));
        break;
      case 'name':
      default:
        toolsOnObject.sort((a, b) => a.title.compareTo(b.title));
    }
    
    // Apply workers filters
    if (_workersShowFavoritesOnly) {
      workersOnObject = workersOnObject.where((w) => w.isFavorite).toList();
    }
    if (_workersSearchController.text.isNotEmpty) {
      final q = _workersSearchController.text.toLowerCase();
      workersOnObject = workersOnObject.where((w) =>
          w.name.toLowerCase().contains(q) ||
          w.email.toLowerCase().contains(q)).toList();
    }
    // Apply workers sorting
    switch (_workersSortBy) {
      case 'date':
        workersOnObject.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'salary':
        workersOnObject.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
        break;
      case 'name':
      default:
        workersOnObject.sort((a, b) => a.name.compareTo(b.name));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _toolsSelectionMode || _workersSelectionMode
            ? Text('${_selectedToolIds.length + _selectedWorkerIds.length} выбранных',
                style: const TextStyle(color: Colors.white))
            : Text(widget.object.name, style: const TextStyle(color: Colors.white)),
        centerTitle: false,
        leading: _toolsSelectionMode || _workersSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _toolsSelectionMode = false;
                    _workersSelectionMode = false;
                    _selectedToolIds.clear();
                    _selectedWorkerIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_toolsSelectionMode || _workersSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: _selectedToolIds.isNotEmpty || _selectedWorkerIds.isNotEmpty
                  ? () => _showDeleteConfirmDialog(context,
                      toolIds: _selectedToolIds.toList(),
                      workerIds: _selectedWorkerIds.toList())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.move_to_inbox_outlined, color: Colors.blue),
              tooltip: 'Переместить',
              onPressed: _selectedToolIds.isNotEmpty || _selectedWorkerIds.isNotEmpty
                  ? () => _showMoveOptionsDialog(context,
                      toolIds: _selectedToolIds.toList(),
                      workerIds: _selectedWorkerIds.toList())
                  : null,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () => ReportService.showObjectReportTypeDialog(
                  context,
                  widget.object,
                  toolsOnObject,
                  (type) => ReportService.shareObjectReport(
                      widget.object, toolsOnObject, context, type)),
            ),
            if (auth.isAdmin)
              IconButton(
                icon: const Icon(Icons.event_note, color: Colors.white),
                onPressed: workersOnObject.isEmpty
                    ? null
                    : () => _showAddWorkDaySheet(context, workersOnObject),
              ),
            if (auth.canControlObjects)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddEditObjectScreen(object: widget.object))),
              ),
            Consumer<ObjectsProvider>(
              builder: (context, op, _) {
                final updatedObject = op.objects.firstWhere(
                  (o) => o.id == widget.object.id,
                  orElse: () => widget.object,
                );
                return IconButton(
                  icon: Icon(
                    updatedObject.isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: updatedObject.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    op.toggleFavorite(widget.object.id);
                  },
                );
              },
            ),
          ],
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Modern header with image
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 220,
            floating: true,
            pinned: false,
            backgroundColor: Colors.grey.shade100,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or gradient
                  widget.object.displayImage != null
                      ? Image(
                          image: widget.object.displayImage!.startsWith('http')
                              ? NetworkImage(widget.object.displayImage!) as ImageProvider
                              : FileImage(File(widget.object.displayImage!)),
                          fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade700,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.location_city, size: 100, color: Colors.white24),
                          ),
                        ),
                  // Overlay gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Modern stats cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and description
                  Text(
                    widget.object.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.object.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.object.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Stats grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernStatCard(
                          icon: Icons.build_circle_outlined,
                          label: 'Инструменты',
                          value: toolsOnObject.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernStatCard(
                          icon: Icons.people_outline,
                          label: 'Работники',
                          value: workersOnObject.length.toString(),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernStatCard(
                          icon: Icons.calendar_month_outlined,
                          label: 'Начало',
                          value: DateFormat('d.MM').format(widget.object.createdAt),
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Modern Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_circle_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Инструменты', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (toolsOnObject.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              toolsOnObject.length.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 20),
                        const SizedBox(width: 8),
                        Text('Работники', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (workersOnObject.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              workersOnObject.length.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tools tab
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          controller: _toolsSearchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск инструментов...',
                            prefixIcon: const Icon(Icons.search, size: 22),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Все'),
                              selected: !_toolsShowFavoritesOnly,
                              onSelected: (_) => setState(() => _toolsShowFavoritesOnly = false),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Избранные'),
                              selected: _toolsShowFavoritesOnly,
                              onSelected: (_) => setState(() => _toolsShowFavoritesOnly = !_toolsShowFavoritesOnly),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              hint: const Text('Сортировка'),
                              value: _toolsSortBy,
                              items: const [
                                DropdownMenuItem(value: 'name', child: Text('По названию')),
                                DropdownMenuItem(value: 'date', child: Text('По дате')),
                                DropdownMenuItem(value: 'brand', child: Text('По бренду')),
                              ],
                              onChanged: (v) => setState(() => _toolsSortBy = v ?? 'name'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    toolsOnObject.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(
                              icon: Icons.build,
                              title: 'На объекте нет инструментов',
                              subtitle: 'Переместите инструменты на этот объект',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tool = toolsOnObject[index];
                                final isSelected = _selectedToolIds.contains(tool.id);
                                return GestureDetector(
                                  onLongPress: () {
                                    setState(() => _toolsSelectionMode = true);
                                    setState(() => _selectedToolIds.add(tool.id));
                                  },
                                  child: _toolsSelectionMode
                                      ? Card(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                                          elevation: isSelected ? 4 : 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: isSelected
                                                ? BorderSide(color: Colors.blue.shade400, width: 2)
                                                : BorderSide.none,
                                          ),
                                          child: ListTile(
                                            leading: Checkbox(
                                              value: isSelected,
                                              onChanged: (v) {
                                                setState(() {
                                                  if (v == true) {
                                                    _selectedToolIds.add(tool.id);
                                                  } else {
                                                    _selectedToolIds.remove(tool.id);
                                                    if (_selectedToolIds.isEmpty) {
                                                      _toolsSelectionMode = false;
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text('${tool.brand} - ${tool.description}'),
                                          ),
                                        )
                                      : SelectionToolCard(
                                          tool: tool,
                                          selectionMode: false,
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      EnhancedToolDetailsScreen(tool: tool))),
                                        ),
                                );
                              },
                              childCount: toolsOnObject.length,
                            ),
                          ),
                  ],
                ),
                // Workers tab
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          controller: _workersSearchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск работников...',
                            prefixIcon: const Icon(Icons.search, size: 22),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Все'),
                              selected: !_workersShowFavoritesOnly,
                              onSelected: (_) => setState(() => _workersShowFavoritesOnly = false),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Избранные'),
                              selected: _workersShowFavoritesOnly,
                              onSelected: (_) => setState(() => _workersShowFavoritesOnly = !_workersShowFavoritesOnly),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              hint: const Text('Сортировка'),
                              value: _workersSortBy,
                              items: const [
                                DropdownMenuItem(value: 'name', child: Text('По имени')),
                                DropdownMenuItem(value: 'date', child: Text('По дате')),
                                DropdownMenuItem(value: 'salary', child: Text('По ставке')),
                              ],
                              onChanged: (v) => setState(() => _workersSortBy = v ?? 'name'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    workersOnObject.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(
                              icon: Icons.people,
                              title: 'На объекте нет работников',
                              subtitle: 'Назначьте работников на этот объект',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final worker = workersOnObject[index];
                                final isSelected = _selectedWorkerIds.contains(worker.id);
                                return GestureDetector(
                                  onLongPress: () {
                                    setState(() => _workersSelectionMode = true);
                                    setState(() => _selectedWorkerIds.add(worker.id));
                                  },
                                  child: _workersSelectionMode
                                      ? Card(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          color: isSelected ? Colors.green.shade50 : Colors.white,
                                          elevation: isSelected ? 4 : 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: isSelected
                                                ? BorderSide(color: Colors.green.shade400, width: 2)
                                                : BorderSide.none,
                                          ),
                                          child: ListTile(
                                            leading: Checkbox(
                                              value: isSelected,
                                              onChanged: (v) {
                                                setState(() {
                                                  if (v == true) {
                                                    _selectedWorkerIds.add(worker.id);
                                                  } else {
                                                    _selectedWorkerIds.remove(worker.id);
                                                    if (_selectedWorkerIds.isEmpty) {
                                                      _workersSelectionMode = false;
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text('${worker.email} • ${worker.role == 'brigadir' ? 'Бригадир' : 'Рабочий'}'),
                                          ),
                                        )
                                      : _buildWorkerCard(context, worker, workerProvider),
                                );
                              },
                              childCount: workersOnObject.length,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWorkDaySheet(BuildContext context, List<Worker> workersOnObject) {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final extraHoursController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final selectedWorkerIds = <String>{};
        DateTime selectedDate = DateTime.now();
        bool isHalfDay = false;

        return StatefulBuilder(
          builder: (sheetContext, setState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавить рабочий день',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Дата'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Полный день'),
                          selected: !isHalfDay,
                          onSelected: (selected) {
                            setState(() {
                              isHalfDay = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Полдня'),
                          selected: isHalfDay,
                          onSelected: (selected) {
                            setState(() {
                              isHalfDay = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: extraHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Доп. часы (опционально)',
                    hintText: 'Например: 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Заметка (опционально)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Работники',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...workersOnObject.map((worker) => CheckboxListTile(
                      value: selectedWorkerIds.contains(worker.id),
                      title: Text(worker.name),
                      subtitle: Text(worker.email),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedWorkerIds.add(worker.id);
                          } else {
                            selectedWorkerIds.remove(worker.id);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedWorkerIds.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Выберите работников')),
                            );
                            return;
                          }
                          final extraHours =
                              double.tryParse(extraHoursController.text.trim()) ?? 0;
                          final dayFraction = isHalfDay ? 0.5 : 1.0;
                          await workerProvider.addWorkEntries(
                            objectId: widget.object.id,
                            workerIds: selectedWorkerIds.toList(),
                            date: selectedDate,
                            dayFraction: dayFraction,
                            extraHours: extraHours,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Рабочий день добавлен')),
                          );
                        },
                        child: const Text('Добавить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
      },
    ).whenComplete(() {
      extraHoursController.dispose();
      notesController.dispose();
    });
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(
    BuildContext context,
    dynamic worker,
    WorkerProvider workerProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: worker.isFavorite
                  ? [Colors.red.shade400, Colors.red.shade300]
                  : [Colors.blue.shade400, Colors.blue.shade300],
            ),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Text(
              worker.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(worker.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(worker.email,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: worker.role == 'brigadir'
                    ? Colors.purple.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                worker.role == 'brigadir' ? 'Бригадир' : 'Рабочий',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: worker.role == 'brigadir'
                      ? Colors.purple.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        trailing: Consumer<WorkerProvider>(
          builder: (context, wp, _) {
            final currentWorker = wp.workers.firstWhere(
              (w) => w.id == worker.id,
              orElse: () => worker,
            );
            return IconButton(
              icon: Icon(
                currentWorker.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: currentWorker.isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                wp.toggleFavorite(worker.id);
              },
            );
          },
        ),
      ),
    );
  }

  void _showMoveOptionsDialog(BuildContext context,
      {required List<String> toolIds, required List<String> workerIds}) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переместить'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toolIds.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.green),
                  title: const Text('В гараж'),
                  onTap: () {
                    Navigator.pop(context);
                    _moveToolsToGarage(toolIds, toolsProvider);
                  },
                ),
              ],
              if (workerIds.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.orange),
                  title: const Text('К себе домой'),
                  onTap: () {
                    Navigator.pop(context);
                    _moveWorkersToHome(workerIds, workerProvider);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: const Text('На другой объект'),
                onTap: () {
                  Navigator.pop(context);
                  _showSelectObjectDialog(context, toolIds, workerIds);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectObjectDialog(BuildContext context, List<String> toolIds,
      List<String> workerIds) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final otherObjects =
        objectsProvider.objects.where((o) => o.id != widget.object.id).toList();

    if (otherObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет других объектов')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите объект'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: otherObjects
                .map((obj) => ListTile(
                      title: Text(obj.name),
                      subtitle: Text('${obj.description}'),
                      onTap: () {
                        Navigator.pop(context);
                        _moveItemsToObject(context, obj, toolIds, workerIds);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _moveToolsToGarage(
      List<String> toolIds, ToolsProvider toolsProvider) async {
    try {
      for (final toolId in toolIds) {
        await toolsProvider.moveTool(toolId, 'garage', 'Гараж');
      }
      setState(() {
        _toolsSelectionMode = false;
        _selectedToolIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_toolsSelectionMode инструментов перемещено в гараж')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _moveWorkersToHome(
      List<String> workerIds, WorkerProvider workerProvider) async {
    try {
      for (final workerId in workerIds) {
        final worker =
            workerProvider.workers.firstWhere((w) => w.id == workerId);
        final updated = worker.copyWith(
          assignedObjectIds: worker.assignedObjectIds
              .where((id) => id != widget.object.id)
              .toList(),
        );
        await workerProvider.updateWorker(updated);
      }
      setState(() {
        _workersSelectionMode = false;
        _selectedWorkerIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Работники отправлены домой')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _moveItemsToObject(
    BuildContext context,
    ConstructionObject targetObject,
    List<String> toolIds,
    List<String> workerIds,
  ) async {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    try {
      for (final toolId in toolIds) {
        await toolsProvider.moveTool(toolId, targetObject.id, targetObject.name);
      }

      for (final workerId in workerIds) {
        final worker =
            workerProvider.workers.firstWhere((w) => w.id == workerId);
        final objectIds = {
          ...worker.assignedObjectIds,
          targetObject.id,
        };
        final updated = worker.copyWith(
          assignedObjectIds: objectIds.toList(),
        );
        await workerProvider.updateWorker(updated);
      }

      setState(() {
        _toolsSelectionMode = false;
        _workersSelectionMode = false;
        _selectedToolIds.clear();
        _selectedWorkerIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Перемещено на объект "${targetObject.name}"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(BuildContext context,
      {required List<String> toolIds, required List<String> workerIds}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(
          'Вы уверены? Это действие нельзя отменить.\n'
          'Удаляется: ${toolIds.length} инструмент(ов), ${workerIds.length} работник(ов)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedItems(context,
                  toolIds: toolIds, workerIds: workerIds);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedItems(BuildContext context,
      {required List<String> toolIds, required List<String> workerIds}) async {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    try {
      for (final toolId in toolIds) {
        await toolsProvider.deleteTool(toolId);
      }

      for (final workerId in workerIds) {
        final worker =
            workerProvider.workers.firstWhere((w) => w.id == workerId);
        final objectIds = worker.assignedObjectIds
            .where((id) => id != widget.object.id)
            .toList();
        if (objectIds.isEmpty) {
          await workerProvider.deleteWorker(workerId);
        } else {
          final updated = worker.copyWith(assignedObjectIds: objectIds);
          await workerProvider.updateWorker(updated);
        }
      }

      setState(() {
        _toolsSelectionMode = false;
        _workersSelectionMode = false;
        _selectedToolIds.clear();
        _selectedWorkerIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено успешно')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

// Delegate for sticky tab bar in sliver
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
