// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/worker.dart';
import '../../../data/models/salary.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';
import 'add_edit_worker_screen.dart';
import 'worker_salary_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
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
    List<Worker> displayWorkers = workerProvider.workers;
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
      displayWorkers = displayWorkers.where((w) => w.assignedObjectId == _filterObject).toList();
    }
    if (_showFavoritesOnly) {
      displayWorkers = displayWorkers.where((w) => w.isFavorite).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      displayWorkers = displayWorkers.where((w) =>
          w.name.toLowerCase().contains(q) ||
          w.email.toLowerCase().contains(q) ||
          (w.nickname?.toLowerCase().contains(q) ?? false)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление работниками'),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _showFavoritesOnly ? Colors.red : null),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
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
      body: workerProvider.isLoading
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
                      FilterChip(
                        label: const Text('Все'),
                        selected: _filterRole == 'all',
                        onSelected: (_) => setState(() => _filterRole = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Рабочий'),
                        selected: _filterRole == 'worker',
                        onSelected: (_) => setState(() => _filterRole = 'worker'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Бригадир'),
                        selected: _filterRole == 'brigadir',
                        onSelected: (_) => setState(() => _filterRole = 'brigadir'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        hint: const Text('Объект'),
                        value: _filterObject,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Все объекты')),
                          ...objectsProvider.objects.map((obj) =>
                              DropdownMenuItem(value: obj.id, child: Text(obj.name))),
                        ],
                        onChanged: (v) => setState(() => _filterObject = v),
                      ),
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
                            return WorkerCard(
                              worker: worker,
                              selectionMode: workerProvider.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          WorkerSalaryScreen(worker: worker))),
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

  Widget _buildEmptyWorkers(bool isAdmin) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('Нет работников',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            if (isAdmin)
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEditWorkerScreen())),
                child: const Text('Добавить работника'),
              ),
          ],
        ),
      );

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
                  onTap: () async {
                    Navigator.pop(context);
                    // For now, just share first worker's report as sample
                    if (workerProvider.selectedWorkers.isNotEmpty) {
                      final w = workerProvider.selectedWorkers.first;
                      await ReportService.shareWorkerReport(
                          w,
                          Provider.of<SalaryProvider>(context, listen: false)
                              .getSalariesForWorker(w.id),
                          Provider.of<SalaryProvider>(context, listen: false)
                              .getAdvancesForWorker(w.id),
                          Provider.of<SalaryProvider>(context, listen: false)
                              .getPenaltiesForWorker(w.id),
                          context,
                          ReportType.pdf);
                    }
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
    String? selectedObjectId;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переместить выбранных работников'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите объект или гараж (null):'),
            DropdownButton<String>(
              value: selectedObjectId,
              hint: const Text('Выберите'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Гараж (не привязан)')),
                ...objectsProvider.objects.map((obj) =>
                    DropdownMenuItem(value: obj.id, child: Text(obj.name))),
              ],
              onChanged: (v) => setState(() => selectedObjectId = v),
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
              if (selectedObjectId != null) {
                await workerProvider.moveSelectedWorkers(selectedObjectId, 
                    objectsProvider.objects.firstWhere((o) => o.id == selectedObjectId).name);
              } else {
                await workerProvider.moveSelectedWorkers(null, 'Гараж');
              }
              Navigator.pop(context);
            },
            child: const Text('Переместить'),
          ),
        ],
      ),
    );
  }

  void _showAddSalaryDialog(BuildContext context) {
    // Simplified: just show a dialog to enter amount and type for all selected workers
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    String entryType = 'salary';
    double amount = 0;
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
                value: entryType,
                items: const [
                  DropdownMenuItem(value: 'salary', child: Text('Зарплата')),
                  DropdownMenuItem(value: 'advance', child: Text('Аванс')),
                  DropdownMenuItem(value: 'penalty', child: Text('Штраф')),
                ],
                onChanged: (v) => setState(() => entryType = v!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Сумма'),
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = double.tryParse(v) ?? 0,
              ),
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
                    await salaryProvider.addSalary(SalaryEntry(
                      id: IdGenerator.generateSalaryId(),
                      workerId: w.id,
                      date: DateTime.now(),
                      amount: amount,
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
}

// ========== WORKER CARD WITH BOUNCE ANIMATION ==========
class WorkerCard extends StatefulWidget {
  final Worker worker;
  final bool selectionMode;
  final VoidCallback onTap;

  const WorkerCard({super.key, required this.worker, required this.selectionMode, required this.onTap});

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
            _playBounceAnimation();
            if (widget.selectionMode) {
              workerProvider.toggleWorkerSelection(widget.worker.id);
            } else {
              widget.onTap();
            }
          },
          onLongPress: () {
            if (!widget.selectionMode) {
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
                    ],
                  ),
                ),
                if (!widget.selectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.worker.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: widget.worker.isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          workerProvider.toggleFavorite(widget.worker.id);
                          _playBounceAnimation();
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
        title: const Text('Удалить работника'),
        content: Text('Удалить "${worker.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<WorkerProvider>(context, listen: false).deleteWorker(worker.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
