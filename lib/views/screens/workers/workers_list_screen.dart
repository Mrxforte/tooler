// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/worker.dart';
import '../../../data/models/salary.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';
import '../../widgets/custom_filter_chip.dart';
import 'add_edit_worker_screen.dart';
import 'worker_salary_screen.dart';
import 'worker_details_screen.dart';

class WorkersListScreen extends StatefulWidget {
  const WorkersListScreen({super.key});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterRole = 'all';
  String? _filterObject;
  bool _showFavoritesOnly = false;
  
  // Advanced filters
  String _sortBy = 'name'; // name, date, salary
  double _minHourlyRate = 0;
  double _maxHourlyRate = 1000;
  DateTime? _hireDateFrom;
  DateTime? _hireDateTo;
  final List<String> _activeFilters = [];
  bool _loadingTimeout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers().catchError((_) {});
      Provider.of<ObjectsProvider>(context, listen: false).loadObjects().catchError((_) {});
      // Timeout after 3 seconds to prevent infinite loading
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _loadingTimeout = true);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    if (workerProvider.selectionMode) {
      workerProvider.toggleSelectionMode();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin && !auth.isBrigadir) {
      return Scaffold(
        appBar: AppBar(title: const Text('Работники')),
        body: const Center(child: Text('У вас нет доступа к этому разделу')),
      );
    }

    // For brigadier, show only workers on his object
    List<Worker> displayWorkers = List<Worker>.from(workerProvider.workers);
    if (auth.isBrigadir) {
      // Assuming brigadier's assigned object is stored somewhere; we need to fetch.
      // For now, we'll just show all (you need to implement logic to get brigadier's object).
      // This is a placeholder.
    }

    // Apply filters
    if (_filterRole != 'all') {
      displayWorkers = displayWorkers.where((w) => w.role == _filterRole).toList();
    }
    if (_filterObject != null) {
      displayWorkers = displayWorkers
          .where((w) => w.assignedObjectIds.contains(_filterObject))
          .toList();
    }
    if (_showFavoritesOnly) {
      displayWorkers = displayWorkers.where((w) => w.isFavorite).toList();
    }
    
    // Advanced filters
    if (_minHourlyRate > 0 || _maxHourlyRate < 1000) {
      displayWorkers = displayWorkers
          .where((w) => w.hourlyRate >= _minHourlyRate && w.hourlyRate <= _maxHourlyRate)
          .toList();
    }
    if (_hireDateFrom != null) {
      displayWorkers = displayWorkers
          .where((w) => w.createdAt.isAfter(_hireDateFrom!))
          .toList();
    }
    if (_hireDateTo != null) {
      displayWorkers = displayWorkers
          .where((w) => w.createdAt.isBefore(_hireDateTo!.add(const Duration(days: 1))))
          .toList();
    }
    
    // Apply search
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      displayWorkers = displayWorkers.where((w) =>
          w.name.toLowerCase().contains(q) ||
          w.email.toLowerCase().contains(q) ||
          (w.nickname?.toLowerCase().contains(q) ?? false)).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'date':
        displayWorkers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'salary':
        displayWorkers.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
        break;
      case 'name':
      default:
        displayWorkers.sort((a, b) => a.name.compareTo(b.name));
    }
    
    // Calculate active filters count
    _activeFilters.clear();
    if (_filterRole != 'all') _activeFilters.add('Роль');
    if (_filterObject != null) _activeFilters.add('Объект');
    if (_showFavoritesOnly) _activeFilters.add('Избранные');
    if (_minHourlyRate > 0 || _maxHourlyRate < 1000) _activeFilters.add('Ставка');
    if (_hireDateFrom != null || _hireDateTo != null) _activeFilters.add('Дата');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление работниками'),
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
              if (_activeFilters.isNotEmpty)
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
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AddEditWorkerScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => workerProvider.loadWorkers(),
          ),
        ],
      ),
      body: (workerProvider.isLoading && !_loadingTimeout)
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск работников...',
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
                        selected: _filterRole == 'all',
                        onSelected: (_) => setState(() => _filterRole = 'all'),
                      ),
                      const SizedBox(width: 16),
                      CustomFilterChip(
                        label: 'Рабочий',
                        selected: _filterRole == 'worker',
                        icon: Icons.work,
                        onSelected: (_) => setState(() => _filterRole = 'worker'),
                      ),
                      const SizedBox(width: 16),
                      CustomFilterChip(
                        label: 'Бригадир',
                        selected: _filterRole == 'brigadir',
                        icon: Icons.admin_panel_settings,
                        onSelected: (_) => setState(() => _filterRole = 'brigadir'),
                      ),
                      const SizedBox(width: 16),
                      if (objectsProvider.objects.isNotEmpty)
                        DropdownButton<String?>(
                          hint: const Text('Объект'),
                          value: _filterObject,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Все объекты')),
                            ...objectsProvider.objects.map((obj) =>
                                DropdownMenuItem<String?>(value: obj.id, child: Text(obj.name))),
                          ],
                          onChanged: (v) => setState(() => _filterObject = v),
                        ),
                      const SizedBox(width: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: workerProvider.toggleSelectionMode,
                        icon: const Icon(Icons.checklist),
                        label: Text(workerProvider.selectionMode ? 'Отменить' : 'Выбрать'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (workerProvider.selectionMode && displayWorkers.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: workerProvider.selectAllWorkers,
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
                  child: displayWorkers.isEmpty
                      ? _buildEmptyWorkers(auth.isAdmin)
                      : ListView.builder(
                          itemCount: displayWorkers.length,
                          itemBuilder: (context, index) {
                            final worker = displayWorkers[index];
                            final objectNames = _getWorkerObjectNames(worker, objectsProvider);
                            return WorkerCard(
                              worker: worker,
                              objectNames: objectNames,
                              selectionMode: workerProvider.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          WorkerDetailsScreen(worker: worker))),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: workerProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: workerProvider.hasSelectedWorkers
                  ? () => _showWorkerSelectionActions(context)
                  : null,
              icon: const Icon(Icons.more_vert),
              label: Text('${workerProvider.selectedWorkers.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : (auth.isAdmin
              ? FloatingActionButton(
                  onPressed: () => workerProvider.toggleSelectionMode(),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.checklist),
                )
              : null),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filterRole = 'all';
      _filterObject = null;
      _showFavoritesOnly = false;
      _sortBy = 'name';
      _minHourlyRate = 0;
      _maxHourlyRate = 1000;
      _hireDateFrom = null;
      _hireDateTo = null;
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
                    DropdownMenuItem(value: 'name', child: Text('По имени')),
                    DropdownMenuItem(value: 'date', child: Text('По дате найма')),
                    DropdownMenuItem(value: 'salary', child: Text('По ставке')),
                  ],
                  onChanged: (v) {
                    setState(() => _sortBy = v ?? 'name');
                    this.setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Hourly Rate Range
                const Text(
                  'Диапазон почасовой ставки',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Text('От ${_minHourlyRate.toStringAsFixed(2)} до ${_maxHourlyRate.toStringAsFixed(2)}'),
                    RangeSlider(
                      values: RangeValues(_minHourlyRate, _maxHourlyRate),
                      min: 0,
                      max: 1000,
                      divisions: 100,
                      labels: RangeLabels(
                        _minHourlyRate.toStringAsFixed(0),
                        _maxHourlyRate.toStringAsFixed(0),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _minHourlyRate = v.start;
                          _maxHourlyRate = v.end;
                        });
                        this.setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hire Date Range
                const Text(
                  'Диапазон даты найма',
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
                            initialDate: _hireDateFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _hireDateFrom = date);
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
                            _hireDateFrom != null
                                ? '${_hireDateFrom!.day}.${_hireDateFrom!.month}.${_hireDateFrom!.year}'
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
                            initialDate: _hireDateTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _hireDateTo = date);
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
                            _hireDateTo != null
                                ? '${_hireDateTo!.day}.${_hireDateTo!.month}.${_hireDateTo!.year}'
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

  Widget _buildEmptyWorkers(bool isAdmin) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text('Нет работников',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Добавьте работников для начала работы',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEditWorkerScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Добавить работника'),
              ),
          ],
        ),
      );

  List<String> _getWorkerObjectNames(Worker worker, ObjectsProvider objectsProvider) {
    if (worker.assignedObjectIds.isEmpty) return ['Гараж'];
    return worker.assignedObjectIds
        .map((id) {
          try {
            final obj = objectsProvider.objects
                .firstWhere((o) => o.id == id);
            return obj.name;
          } catch (e) {
            return 'Архив';
          }
        })
        .toList();
  }

  void _showWorkerSelectionActions(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final selectedCount = workerProvider.selectedWorkers.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Выбрано: $selectedCount работников',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  workerProvider.toggleFavoriteForSelected();
                },
              ),
              if (auth.isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                  title: const Text('Переместить на объект'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMoveWorkersDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments, color: Colors.green),
                  title: const Text('Добавить зарплату'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddSalaryDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text('Создать отчет'),
                  onTap: () {
                    Navigator.pop(context);
                    _showWorkerReportTypeDialog(context, workerProvider.selectedWorkers);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMoveWorkersDialog(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final selectedObjectIds = <String>[];
    bool isProcessing = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Переместить выбранных работников'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите один или несколько объектов (пусто = гараж):'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                height: 220,
                child: ListView(
                  children: objectsProvider.objects.map((obj) {
                    final selected = selectedObjectIds.contains(obj.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(obj.name),
                      dense: true,
                      onChanged: isProcessing ? null : (value) {
                        if (value == null) return;
                        setState(() {
                          if (value) {
                            selectedObjectIds.add(obj.id);
                          } else {
                            selectedObjectIds.remove(obj.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setState(() => isProcessing = true);
                      try {
                        await workerProvider.moveSelectedWorkers(
                            List<String>.from(selectedObjectIds));
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Переместить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSalaryDialog(BuildContext context) {
    // Simplified: just show a dialog to enter amount and type for all selected workers
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    String entryType = 'salary';
    double amount = 0;
    double hoursWorked = 0;
    double bonus = 0;
    String reason = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить финансовую запись'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: entryType,
                items: const [
                  DropdownMenuItem(value: 'salary', child: Text('Зарплата')),
                  DropdownMenuItem(value: 'advance', child: Text('Аванс')),
                  DropdownMenuItem(value: 'penalty', child: Text('Штраф')),
                ],
                onChanged: (v) => setState(() => entryType = v!),
              ),
              if (entryType != 'salary')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Сумма'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => amount = double.tryParse(v) ?? 0,
                ),
              if (entryType == 'salary') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Часы работы'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => hoursWorked = double.tryParse(v) ?? 0,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Бонус (на работника)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => bonus = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Сумма считается по формуле: часы * ставка + бонус',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
              TextFormField(
                decoration: InputDecoration(labelText: entryType == 'salary' ? 'Примечание' : 'Причина'),
                onChanged: (v) => reason = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                for (final w in workerProvider.selectedWorkers) {
                  if (entryType == 'salary') {
                    final calculatedAmount = (hoursWorked * w.hourlyRate) + bonus;
                    await salaryProvider.addSalary(SalaryEntry(
                      id: IdGenerator.generateSalaryId(),
                      workerId: w.id,
                      date: DateTime.now(),
                      hoursWorked: hoursWorked,
                      amount: calculatedAmount,
                      notes: reason,
                    ));
                  } else if (entryType == 'advance') {
                    await salaryProvider.addAdvance(Advance(
                      id: IdGenerator.generateAdvanceId(),
                      workerId: w.id,
                      date: DateTime.now(),
                      amount: amount,
                      reason: reason,
                    ));
                  } else if (entryType == 'penalty') {
                    await salaryProvider.addPenalty(Penalty(
                      id: IdGenerator.generatePenaltyId(),
                      workerId: w.id,
                      date: DateTime.now(),
                      amount: amount,
                      reason: reason,
                    ));
                  }
                }
                Navigator.pop(context);
                ErrorHandler.showSuccessDialog(context, 'Записи добавлены');
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerReportTypeDialog(BuildContext context, List<Worker> workers) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Создать отчет (${workers.length})'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              ErrorHandler.showSuccessDialog(context, 'Функция отчета будет добавлена позже');
            },
            child: const Text('Сводный отчет'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              ErrorHandler.showSuccessDialog(context, 'Функция отчета будет добавлена позже');
            },
            child: const Text('Отчет по зарплатам'),
          ),
        ],
      ),
    );
  }
}

// ========== WORKER CARD WITH BOUNCE ANIMATION ==========
class WorkerCard extends StatefulWidget {
  final Worker worker;
  final List<String> objectNames;
  final bool selectionMode;
  final VoidCallback onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    required this.objectNames,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playBounceAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: widget.worker.isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _playBounceAnimation();
            if (widget.selectionMode) {
              workerProvider.toggleWorkerSelection(widget.worker.id);
            } else {
              widget.onTap();
            }
          },
          onLongPress: () {
            if (!widget.selectionMode) {
              HapticFeedback.mediumImpact();
              workerProvider.toggleSelectionMode();
              workerProvider.toggleWorkerSelection(widget.worker.id);
              _playBounceAnimation();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (widget.selectionMode)
                  Checkbox(
                    value: widget.worker.isSelected,
                    onChanged: (_) {
                      workerProvider.toggleWorkerSelection(widget.worker.id);
                      _playBounceAnimation();
                    },
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.worker.isFavorite
                          ? [Colors.red.shade400, Colors.red.shade300]
                          : [Colors.blue.shade400, Colors.blue.shade300],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.worker.isFavorite
                            ? Colors.red.shade400.withValues(alpha: 0.3)
                            : Colors.blue.shade400.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text(
                      widget.worker.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.worker.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.worker.role == 'brigadir'
                              ? Colors.purple.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.worker.role == 'brigadir'
                                  ? Icons.admin_panel_settings
                                  : Icons.work,
                              size: 12,
                              color: widget.worker.role == 'brigadir'
                                  ? Colors.purple.shade700
                                  : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.worker.role == 'brigadir' ? 'Бригадир' : 'Рабочий',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: widget.worker.role == 'brigadir'
                                    ? Colors.purple.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.objectNames.join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!widget.selectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<WorkerProvider>(
                        builder: (context, wp, _) {
                          final currentWorker = wp.workers.firstWhere(
                            (w) => w.id == widget.worker.id,
                            orElse: () => widget.worker,
                          );
                          return IconButton(
                            icon: Icon(
                              currentWorker.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: currentWorker.isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              wp.toggleFavorite(widget.worker.id);
                              _playBounceAnimation();
                            },
                          );
                        },
                      ),
                      if (auth.isAdmin)
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Редактировать'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'salary',
                              child: Row(
                                children: [
                                  Icon(Icons.attach_money, size: 18),
                                  SizedBox(width: 8),
                                  Text('Зарплата'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Удалить', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditWorkerScreen(worker: widget.worker),
                                ),
                              );
                            } else if (value == 'salary') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkerSalaryScreen(worker: widget.worker),
                                ),
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, widget.worker);
                            }
                          },
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

  void _showDeleteDialog(BuildContext context, Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить работника: ${worker.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Это действие не может быть отменено.'),
            SizedBox(height: 16),
            Text('Все данные о работнике будут удалены:', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('• Запись о работнике'),
            Text('• Зарплата и бонусы'),
            Text('• История посещаемости'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Provider.of<WorkerProvider>(context, listen: false).deleteWorker(worker.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Работник "${worker.name}" удален'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ошибка при удалении работника'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
}
