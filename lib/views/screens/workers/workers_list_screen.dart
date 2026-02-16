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

// ========== WORKER CARD ==========
class WorkerCard extends StatelessWidget {
  final Worker worker;
  final bool selectionMode;
  final VoidCallback onTap;

  const WorkerCard({super.key, required this.worker, required this.selectionMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: selectionMode
            ? () => workerProvider.toggleWorkerSelection(worker.id)
            : onTap,
        onLongPress: () {
          if (!selectionMode) {
            workerProvider.toggleSelectionMode();
            workerProvider.toggleWorkerSelection(worker.id);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (selectionMode)
                Checkbox(
                  value: worker.isSelected,
                  onChanged: (_) => workerProvider.toggleWorkerSelection(worker.id),
                ),
              CircleAvatar(
                backgroundColor: worker.isFavorite ? Colors.red : Colors.blue,
                child: Text(worker.name[0].toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(worker.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Row(
                      children: [
                        const Icon(Icons.work, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(worker.role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(worker.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: worker.isFavorite ? Colors.red : null),
                      onPressed: () => workerProvider.toggleFavorite(worker.id),
                    ),
                    if (auth.isAdmin)
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                          const PopupMenuItem(value: 'salary', child: Text('Зарплата')),
                          const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditWorkerScreen(worker: worker)));
                          } else if (value == 'salary') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerSalaryScreen(worker: worker)));
                          } else if (value == 'delete') {
                            _showDeleteDialog(context, worker);
                          }
                        },
                      ),
                  ],
                ),
            ],
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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
