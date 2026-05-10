import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/app_user.dart';
import '../../../viewmodels/users_provider.dart';
import '../../../viewmodels/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filterRole = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'email';
  DateTime? _createdDateFrom;
  DateTime? _createdDateTo;
  String _permissionsFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersProvider>(context, listen: false)
          .loadUsers(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'brigadir':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'brigadir':
        return 'Бригадир';
      default:
        return 'Пользователь';
    }
  }

  List<AppUser> _applyFilters(List<AppUser> all) {
    var list = List<AppUser>.from(all);

    if (_filterRole != 'all') {
      list = list.where((u) => u.role == _filterRole).toList();
    }
    if (_permissionsFilter != 'all') {
      list = list.where((u) {
        switch (_permissionsFilter) {
          case 'can_move':
            return u.canMoveTools;
          case 'can_control':
            return u.canControlObjects;
          case 'both':
            return u.canMoveTools && u.canControlObjects;
          default:
            return true;
        }
      }).toList();
    }
    if (_createdDateFrom != null) {
      list = list.where((u) => u.createdAt.isAfter(_createdDateFrom!)).toList();
    }
    if (_createdDateTo != null) {
      list = list
          .where((u) => u.createdAt
              .isBefore(_createdDateTo!.add(const Duration(days: 1))))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((u) =>
              u.email.toLowerCase().contains(q) ||
              u.name.toLowerCase().contains(q))
          .toList();
    }
    switch (_sortBy) {
      case 'date':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'role':
        list.sort((a, b) => a.role.compareTo(b.role));
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
      default:
        list.sort((a, b) => a.email.compareTo(b.email));
    }
    return list;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterRole != 'all') count++;
    if (_permissionsFilter != 'all') count++;
    if (_createdDateFrom != null || _createdDateTo != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _filterRole = 'all';
      _sortBy = 'email';
      _createdDateFrom = null;
      _createdDateTo = null;
      _permissionsFilter = 'all';
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // ── CREATE dialog ────────────────────────────────────────────────────────────

  void _showCreateUserDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'user';
    bool canMove = false;
    bool canControl = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Добавить пользователя'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Введите email' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Роль',
                      prefixIcon: Icon(Icons.shield),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Пользователь')),
                      DropdownMenuItem(value: 'brigadir', child: Text('Бригадир')),
                      DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                    ],
                    onChanged: (v) =>
                        setDlgState(() => selectedRole = v ?? 'user'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Может перемещать'),
                    value: canMove,
                    onChanged: (v) => setDlgState(() => canMove = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Управление объектами'),
                    value: canControl,
                    onChanged: (v) => setDlgState(() => canControl = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await Provider.of<UsersProvider>(context, listen: false)
                      .createUser(
                    email: emailCtrl.text,
                    name: nameCtrl.text,
                    role: selectedRole,
                    canMoveTools: canMove,
                    canControlObjects: canControl,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пользователь добавлен'),
                        backgroundColor: Colors.green,
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
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  // ── EDIT dialog ──────────────────────────────────────────────────────────────

  void _showEditUserDialog(AppUser user) {
    final emailCtrl = TextEditingController(text: user.email);
    final nameCtrl = TextEditingController(text: user.name);
    String selectedRole = user.role;
    bool canMove = user.canMoveTools;
    bool canControl = user.canControlObjects;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Редактировать пользователя'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Введите email' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Роль',
                      prefixIcon: Icon(Icons.shield),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Пользователь')),
                      DropdownMenuItem(value: 'brigadir', child: Text('Бригадир')),
                      DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                    ],
                    onChanged: (v) =>
                        setDlgState(() => selectedRole = v ?? 'user'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Может перемещать'),
                    value: canMove,
                    onChanged: (v) => setDlgState(() => canMove = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Управление объектами'),
                    value: canControl,
                    onChanged: (v) => setDlgState(() => canControl = v),
                  ),
                  const SizedBox(height: 8),
                  // Read-only info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UID:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(user.uid, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Создан:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  final updated = user.copyWith(
                    email: emailCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    role: selectedRole,
                    canMoveTools: canMove,
                    canControlObjects: canControl,
                  );
                  await Provider.of<UsersProvider>(context, listen: false)
                      .editUser(updated);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пользователь обновлён'),
                        backgroundColor: Colors.green,
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
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользователи')),
        body: const Center(
            child:
                Text('Только администратор может просматривать пользователей')),
      );
    }

    final filteredUsers = _applyFilters(usersProvider.users);

    return Scaffold(
      appBar: AppBar(
        title: usersProvider.selectionMode
            ? Text('Выбрано: ${usersProvider.selectedUsers.length}')
            : const Text('Управление пользователями'),
        leading: usersProvider.selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => usersProvider.toggleSelectionMode(),
              )
            : null,
        actions: [
          if (usersProvider.selectionMode) ...[
            IconButton(
              icon: Icon(usersProvider.allSelected
                  ? Icons.deselect
                  : Icons.select_all),
              tooltip: usersProvider.allSelected ? 'Снять выбор' : 'Выбрать все',
              onPressed: () => usersProvider.allSelected
                  ? usersProvider.clearSelection()
                  : usersProvider.selectAllUsers(),
            ),
          ] else ...[
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Фильтры',
                  onPressed: () => _showAdvancedFiltersPanel(context),
                ),
                if (_activeFilterCount > 0)
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
                        '$_activeFilterCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Выбрать',
              onPressed: () => usersProvider.toggleSelectionMode(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => usersProvider.loadUsers(forceRefresh: true),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => usersProvider.loadUsers(forceRefresh: true),
        child: Column(
          children: [
            // Search + role chips
            Container(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по email или имени...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in {
                          'all': 'Все',
                          'admin': 'Администраторы',
                          'brigadir': 'Бригадиры',
                          'user': 'Пользователи',
                        }.entries) ...[
                          FilterChip(
                            label: Text(entry.value),
                            selected: _filterRole == entry.key,
                            onSelected: (_) =>
                                setState(() => _filterRole = entry.key),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_activeFilterCount > 0 || _searchQuery.isNotEmpty)
                          ElevatedButton(
                            onPressed: _clearAllFilters,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade200),
                            child: const Text('Сбросить'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Stats row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Всего: ${filteredUsers.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Из базы: ${usersProvider.users.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: usersProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) => _buildUserCard(
                              context, filteredUsers[index], usersProvider),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: usersProvider.selectionMode &&
              usersProvider.hasSelectedUsers
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'delete_selected',
                    onPressed: () =>
                        _showBatchDeleteDialog(context, usersProvider),
                    backgroundColor: Colors.red,
                    icon: const Icon(Icons.delete),
                    label: Text(
                      'Удалить (${usersProvider.selectedUsers.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'change_role_selected',
                    onPressed: () =>
                        _showBatchRoleChangeDialog(context, usersProvider),
                    backgroundColor: Colors.blue,
                    icon: const Icon(Icons.group),
                    label: const Text(
                      'Изменить роль',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : FloatingActionButton.extended(
              heroTag: 'add_user',
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить'),
            ),
    );
  }

  // ── user card ────────────────────────────────────────────────────────────────

  Widget _buildUserCard(
      BuildContext context, AppUser user, UsersProvider usersProvider) {
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleLabel(user.role);
    final displayName =
        user.name.isNotEmpty ? user.name : user.email.split('@').first;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: usersProvider.selectionMode
              ? Checkbox(
                  value: user.isSelected,
                  onChanged: (_) =>
                      usersProvider.toggleUserSelection(user.uid),
                )
              : Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [roleColor.withValues(alpha: 0.8), roleColor],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundColor: roleColor,
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user.name.isNotEmpty)
                Text(user.email,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: roleColor),
                    ),
                  ),
                  if (user.canMoveTools || user.canControlObjects) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Разрешения',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: usersProvider.selectionMode
                ? null
                : () => _showUserActionsMenu(context, user, usersProvider),
          ),
          onExpansionChanged: usersProvider.selectionMode
              ? (_) => usersProvider.toggleUserSelection(user.uid)
              : null,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildPermissionSwitch(
                    title: 'Может перемещать инструменты',
                    icon: Icons.swap_horiz,
                    value: user.canMoveTools,
                    onChanged: (v) => usersProvider.updateUserPermissions(
                        user.uid,
                        canMoveTools: v),
                  ),
                  const Divider(),
                  _buildPermissionSwitch(
                    title: 'Может управлять объектами',
                    icon: Icons.business,
                    value: user.canControlObjects,
                    onChanged: (v) => usersProvider.updateUserPermissions(
                        user.uid,
                        canControlObjects: v),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Информация',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (user.name.isNotEmpty)
                          _infoRow('Имя:', user.name),
                        _infoRow('Email:', user.email),
                        _infoRow('UID:', user.uid),
                        _infoRow(
                          'Зарегистрирован:',
                          '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
                        ),
                      ],
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

  Widget _buildPermissionSwitch({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      secondary: Icon(icon),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── action menu ──────────────────────────────────────────────────────────────

  void _showUserActionsMenu(
      BuildContext context, AppUser user, UsersProvider usersProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name.isNotEmpty ? user.name : user.email,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            // Edit
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.teal),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditUserDialog(user);
              },
            ),
            const Divider(),
            // Role shortcuts
            ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Сделать администратором'),
              enabled: user.role != 'admin',
              subtitle: user.role == 'admin'
                  ? const Text('Уже администратор')
                  : null,
              onTap: user.role == 'admin'
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _confirmAction(
                        'Выдать права администратора?',
                        'Пользователь получит полный доступ.',
                        () => usersProvider.updateUserRole(user.uid, 'admin'),
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.purple),
              title: const Text('Сделать бригадиром'),
              enabled: user.role != 'brigadir',
              subtitle:
                  user.role == 'brigadir' ? const Text('Уже бригадир') : null,
              onTap: user.role == 'brigadir'
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _confirmAction(
                        'Сделать бригадиром?',
                        '',
                        () =>
                            usersProvider.updateUserRole(user.uid, 'brigadir'),
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Обычный пользователь'),
              enabled: user.role != 'user',
              subtitle:
                  user.role == 'user' ? const Text('Уже пользователь') : null,
              onTap: user.role == 'user'
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _confirmAction(
                        'Понизить роль?',
                        'Пользователь потеряет расширенные права.',
                        () => usersProvider.updateUserRole(user.uid, 'user'),
                      );
                    },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade600),
              title: const Text('Удалить пользователя',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteOptionsDialog(context, usersProvider, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: message.isNotEmpty ? Text(message) : null,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  // ── delete dialogs ───────────────────────────────────────────────────────────

  void _showDeleteOptionsDialog(
      BuildContext context, UsersProvider usersProvider, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text(
          '"${user.name.isNotEmpty ? user.name : user.email}"\n\nВыберите откуда удалить:',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Только из БД'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _runDelete(
                () => usersProvider.deleteUser(user.uid,
                    deleteFromFirestore: true, deleteFromAuth: false),
                'Удалён из Firestore',
              );
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Полностью'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _runDelete(
                () => usersProvider.deleteUser(user.uid,
                    deleteFromFirestore: true, deleteFromAuth: true),
                'Полностью удалён из системы',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBatchDeleteDialog(
      BuildContext context, UsersProvider usersProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранных пользователей?'),
        content: Text(
            'Будет удалено ${usersProvider.selectedUsers.length} пользователей.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Только из БД'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _runDelete(
                () => usersProvider.deleteSelectedUsers(
                    deleteFromFirestore: true, deleteFromAuth: false),
                'Удалены из Firestore',
              );
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Полностью'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _runDelete(
                () => usersProvider.deleteSelectedUsers(
                    deleteFromFirestore: true, deleteFromAuth: true),
                'Полностью удалены из системы',
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _runDelete(
      Future<void> Function() action, String successMsg) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(successMsg),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  // ── batch role change ────────────────────────────────────────────────────────

  void _showBatchRoleChangeDialog(
      BuildContext context, UsersProvider usersProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Выберите новую роль для ${usersProvider.selectedUsers.length} пользователей:'),
            const SizedBox(height: 16),
            for (final entry in {
              'admin': ('Администратор', Icons.admin_panel_settings, Colors.red),
              'brigadir': ('Бригадир', Icons.group, Colors.purple),
              'user': ('Пользователь', Icons.person, Colors.blue),
            }.entries)
              ListTile(
                leading: Icon(entry.value.$2, color: entry.value.$3),
                title: Text(entry.value.$1),
                onTap: () async {
                  Navigator.pop(ctx);
                  await usersProvider.updateSelectedUsersRole(entry.key);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Роль изменена на "${entry.value.$1}"'),
                      backgroundColor: Colors.green,
                    ));
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
        ],
      ),
    );
  }

  // ── advanced filters ─────────────────────────────────────────────────────────

  void _showAdvancedFiltersPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Расширенные фильтры',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Сортировка',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'email', child: Text('По email')),
                    DropdownMenuItem(value: 'name', child: Text('По имени')),
                    DropdownMenuItem(
                        value: 'date', child: Text('По дате регистрации')),
                    DropdownMenuItem(value: 'role', child: Text('По роли')),
                  ],
                  onChanged: (v) {
                    setS(() => _sortBy = v ?? 'email');
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                const Text('Фильтр по доступам',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _permissionsFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Все')),
                    DropdownMenuItem(
                        value: 'can_move',
                        child: Text('Могут перемещать')),
                    DropdownMenuItem(
                        value: 'can_control',
                        child: Text('Управляют объектами')),
                    DropdownMenuItem(
                        value: 'both', child: Text('Оба доступа')),
                  ],
                  onChanged: (v) {
                    setS(() => _permissionsFilter = v ?? 'all');
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                const Text('Диапазон даты регистрации',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: _createdDateFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setS(() => _createdDateFrom = date);
                            setState(() {});
                          }
                        },
                        child: _dateBox(_createdDateFrom, 'От'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: _createdDateTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setS(() => _createdDateTo = date);
                            setState(() {});
                          }
                        },
                        child: _dateBox(_createdDateTo, 'До'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _clearAllFilters();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Сбросить'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade200),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check),
                      label: const Text('Применить'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade200),
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

  Widget _dateBox(DateTime? date, String placeholder) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(date != null
          ? '${date.day}.${date.month}.${date.year}'
          : placeholder),
    );
  }

  // ── empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Нет пользователей',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Не найдено пользователей: "$_searchQuery"'
                : 'Нажмите + чтобы добавить пользователя',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
