import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/worker.dart';
import '../../../viewmodels/worker_provider.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name';
  final Set<String> _selectedWorkerIds = {};
  bool _selectionMode = false;

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
    _selectedWorkerIds.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _selectionMode
            ? Text('${_selectedWorkerIds.length} выбранных',
                style: const TextStyle(color: Colors.white))
            : const Text('Управление рабочими',
                style: TextStyle(color: Colors.white)),
        centerTitle: false,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedWorkerIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _selectedWorkerIds.isNotEmpty
                  ? () => _showDeleteConfirmDialog(context)
                  : null,
            ),
        ],
      ),
      body: Consumer<WorkerProvider>(
        builder: (context, workerProvider, _) {
          var workers = [...workerProvider.workers];

          // Apply search
          if (_searchController.text.isNotEmpty) {
            final q = _searchController.text.toLowerCase();
            workers = workers
                .where((w) =>
                    w.name.toLowerCase().contains(q) ||
                    w.email.toLowerCase().contains(q) ||
                    (w.nickname?.toLowerCase().contains(q) ?? false))
                .toList();
          }

          // Apply sorting
          switch (_sortBy) {
            case 'role':
              workers.sort((a, b) => a.role.compareTo(b.role));
              break;
            case 'rate':
              workers.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
              break;
            case 'date':
              workers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
            case 'name':
            default:
              workers.sort((a, b) => a.name.compareTo(b.name));
          }

          if (workers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Нет рабочих',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте рабочих через экран добавления',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск рабочих...',
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
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      DropdownButton<String>(
                        hint: const Text('Сортировка'),
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('По имени')),
                          DropdownMenuItem(value: 'role', child: Text('По роли')),
                          DropdownMenuItem(value: 'rate', child: Text('По ставке')),
                          DropdownMenuItem(value: 'date', child: Text('По дате')),
                        ],
                        onChanged: (v) => setState(() => _sortBy = v ?? 'name'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final worker = workers[index];
                    final isSelected = _selectedWorkerIds.contains(worker.id);
                    return GestureDetector(
                      onLongPress: () {
                        setState(() => _selectionMode = true);
                        setState(() => _selectedWorkerIds.add(worker.id));
                      },
                      child: _selectionMode
                          ? _buildSelectableWorkerCard(
                              context, worker, isSelected, workerProvider)
                          : _buildWorkerCard(context, worker, workerProvider),
                    );
                  },
                  childCount: workers.length,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkerDialog(context),
        tooltip: 'Добавить рабочего',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSelectableWorkerCard(
    BuildContext context,
    Worker worker,
    bool isSelected,
    WorkerProvider workerProvider,
  ) {
    return Card(
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
                _selectedWorkerIds.add(worker.id);
              } else {
                _selectedWorkerIds.remove(worker.id);
                if (_selectedWorkerIds.isEmpty) {
                  _selectionMode = false;
                }
              }
            });
          },
        ),
        title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${worker.email} • ${worker.role == 'brigadir' ? 'Бригадир' : 'Рабочий'}'),
      ),
    );
  }

  Widget _buildWorkerCard(
    BuildContext context,
    Worker worker,
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
              colors: worker.role == 'brigadir'
                  ? [Colors.purple.shade400, Colors.purple.shade300]
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
            Text(worker.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
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
                const SizedBox(width: 8),
                Text(
                  '${worker.hourlyRate}/ч • ${worker.dailyRate}/день',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditWorkerDialog(context, worker);
            } else if (value == 'permissions') {
              _showPermissionsDialog(context, worker, workerProvider);
            } else if (value == 'delete') {
              _showDeleteWorkerConfirmDialog(context, worker);
            } else if (value == 'toggle_role') {
              _toggleWorkerRole(context, worker, workerProvider);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'permissions', child: Text('Права доступа')),
            const PopupMenuItem(value: 'toggle_role', child: Text('Изменить роль')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(
    BuildContext context,
    Worker worker,
    WorkerProvider workerProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Права доступа: ${worker.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Роль работника определяет его права:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildPermissionInfo('Рабочий', [
                '✓ Регистрация рабочих дней',
                '✓ Просмотр своих объектов',
                '✗ Добавление объектов',
                '✗ Управление работниками',
              ]),
              const SizedBox(height: 12),
              _buildPermissionInfo('Бригадир', [
                '✓ Регистрация рабочих дней',
                '✓ Просмотр своих объектов',
                '✓ Управление работниками',
                '✓ Подготовка отчетов',
                '✗ Добавление объектов',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionInfo(String role, List<String> permissions) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...permissions.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.startsWith('✓') ? Colors.green : Colors.red,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showAddWorkerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final nicknameController = TextEditingController();
    final phoneController = TextEditingController();
    final hourlyRateController = TextEditingController(text: '50');
    final dailyRateController = TextEditingController(text: '400');
    String selectedRole = 'worker';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить рабочего'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Введите имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Прозвище (опционально)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон (опционально)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hourlyRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Часовая ставка',
                  hintText: '50',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dailyRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Дневная ставка',
                  hintText: '400',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
                  isExpanded: true,
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'worker', child: Text('Рабочий')),
                    DropdownMenuItem(value: 'brigadir', child: Text('Бригадир')),
                  ],
                  onChanged: (v) => setState(() => selectedRole = v ?? 'worker'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните обязательные поля'),
                  ),
                );
                return;
              }

              try {
                final workerProvider =
                    Provider.of<WorkerProvider>(context, listen: false);
                final newWorker = Worker(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  email: emailController.text.trim(),
                  name: nameController.text.trim(),
                  nickname: nicknameController.text.trim().isEmpty
                      ? null
                      : nicknameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  hourlyRate: double.tryParse(hourlyRateController.text) ?? 50,
                  dailyRate: double.tryParse(dailyRateController.text) ?? 400,
                  role: selectedRole,
                );
                await workerProvider.addWorker(newWorker);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Рабочий "${newWorker.name}" добавлен'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkerDialog(BuildContext context, Worker worker) {
    final nameController = TextEditingController(text: worker.name);
    final emailController = TextEditingController(text: worker.email);
    final hourlyRateController =
        TextEditingController(text: worker.hourlyRate.toString());
    final dailyRateController =
        TextEditingController(text: worker.dailyRate.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать рабочего'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hourlyRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Часовая ставка',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dailyRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Дневная ставка',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final workerProvider =
                    Provider.of<WorkerProvider>(context, listen: false);
                final updated = worker.copyWith(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  hourlyRate: double.tryParse(hourlyRateController.text) ?? worker.hourlyRate,
                  dailyRate: double.tryParse(dailyRateController.text) ?? worker.dailyRate,
                );
                await workerProvider.updateWorker(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Рабочий успешно обновлён'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _toggleWorkerRole(
    BuildContext context,
    Worker worker,
    WorkerProvider workerProvider,
  ) {
    final newRole = worker.role == 'brigadir' ? 'worker' : 'brigadir';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Text(
          'Вы уверены? Роль будет изменена на "${newRole == 'brigadir' ? 'Бригадир' : 'Рабочий'}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updated = worker.copyWith(role: newRole);
                await workerProvider.updateWorker(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Роль изменена на "${newRole == 'brigadir' ? 'Бригадир' : 'Рабочий'}"',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWorkerConfirmDialog(BuildContext context, Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить рабочего'),
        content: Text(
          'Вы уверены? Это действие нельзя отменить.\nУдаляется: ${worker.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final workerProvider =
                    Provider.of<WorkerProvider>(context, listen: false);
                await workerProvider.deleteWorker(worker.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Рабочий "${worker.name}" удалён'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить рабочих'),
        content: Text(
          'Вы уверены в удалении ${_selectedWorkerIds.length} рабочих? '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final workerProvider =
                    Provider.of<WorkerProvider>(context, listen: false);
                for (final workerId in _selectedWorkerIds) {
                  await workerProvider.deleteWorker(workerId);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {
                  _selectionMode = false;
                  _selectedWorkerIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Рабочие удалены'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
