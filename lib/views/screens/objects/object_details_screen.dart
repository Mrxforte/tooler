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
        title: Text(widget.object.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ReportService.showObjectReportTypeDialog(
                context,
                widget.object,
                toolsOnObject,
                (type) => ReportService.shareObjectReport(
                    widget.object, toolsOnObject, context, type)),
          ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.event_note),
              onPressed: workersOnObject.isEmpty
                  ? null
                  : () => _showAddWorkDaySheet(context, workersOnObject),
            ),
          if (auth.canControlObjects)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddEditObjectScreen(object: widget.object))),
            ),
          Consumer<ObjectsProvider>(
            builder: (context, op, _) => IconButton(
              icon: Icon(widget.object.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.object.isFavorite ? Colors.red : null),
              onPressed: () {
                HapticFeedback.mediumImpact();
                op.toggleFavorite(widget.object.id);
              },
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header with object image
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
              ),
              child: widget.object.displayImage != null
                  ? Image(
                      image: widget.object.displayImage!.startsWith('http')
                          ? NetworkImage(widget.object.displayImage!) as ImageProvider
                          : FileImage(File(widget.object.displayImage!)),
                      fit: BoxFit.cover)
                  : Center(
                      child:
                          Icon(Icons.location_city, size: 80, color: Colors.grey.shade300),
                    ),
            ),
          ),
          // Stats row (second layer)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.build,
                      label: 'Инструменты',
                      value: toolsOnObject.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.people,
                      label: 'Работники',
                      value: workersOnObject.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.calendar_today,
                      label: 'Дата',
                      value: DateFormat('dd.MM').format(widget.object.createdAt),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Object info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.object.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (widget.object.description.isNotEmpty)
                    Text(widget.object.description,
                        style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.build_circle, size: 20),
                        const SizedBox(width: 8),
                        Text('Инструменты (${toolsOnObject.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 8),
                        Text('Работники (${workersOnObject.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tab content
          if (_tabController.index == 0) ...[
            // Tools tab
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _toolsSearchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск инструментов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                        return SelectionToolCard(
                          tool: tool,
                          selectionMode: false,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EnhancedToolDetailsScreen(tool: tool))),
                        );
                      },
                      childCount: toolsOnObject.length,
                    ),
                  ),
          ] else ...[
            // Workers tab
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _workersSearchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск работников...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                        return _buildWorkerCard(context, worker, workerProvider);
                      },
                      childCount: workersOnObject.length,
                    ),
                  ),
          ],
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
                    )).toList(),
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

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center),
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
