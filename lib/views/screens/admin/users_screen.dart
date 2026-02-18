import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользователи')),
        body: const Center(
            child: Text('Только администратор может просматривать пользователей')),
      );
    }

    // Apply filters
    var filteredUsers = usersProvider.users;
    if (_filterRole != 'all') {
      filteredUsers =
          filteredUsers.where((u) => u.role == _filterRole).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredUsers =
          filteredUsers.where((u) => u.email.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: usersProvider.selectionMode
            ? Text('Выбрано: ${usersProvider.selectedUsers.length}')
            : const Text('Управление пользователями'),
        elevation: 0,
        leading: usersProvider.selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => usersProvider.toggleSelectionMode(),
              )
            : null,
        actions: [
          if (usersProvider.selectionMode) ...[
            if (usersProvider.hasSelectedUsers)
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'Выбрать все',
                onPressed: () => usersProvider.selectAllUsers(),
              ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Выбрать',
              onPressed: () => usersProvider.toggleSelectionMode(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => usersProvider.loadUsers(),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск по email...',
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Все'),
                        selected: _filterRole == 'all',
                        onSelected: (_) => setState(() => _filterRole = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Администраторы'),
                        selected: _filterRole == 'admin',
                        onSelected: (_) => setState(() => _filterRole = 'admin'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Пользователи'),
                        selected: _filterRole == 'user',
                        onSelected: (_) => setState(() => _filterRole = 'user'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Бригадиры'),
                        selected: _filterRole == 'brigadir',
                        onSelected: (_) => setState(() => _filterRole = 'brigadir'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: usersProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(context, user, usersProvider);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: usersProvider.selectionMode && usersProvider.hasSelectedUsers
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'delete_selected',
                  onPressed: () => _showBatchDeleteDialog(context, usersProvider),
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.delete),
                  label: Text('Удалить (${usersProvider.selectedUsers.length})'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'change_role_selected',
                  onPressed: () => _showBatchRoleChangeDialog(context, usersProvider),
                  backgroundColor: Colors.blue,
                  icon: const Icon(Icons.group),
                  label: const Text('Изменить роль'),
                ),
              ],
            )
          : null,
    );
  }

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
                ? 'Не найдено пользователей с поиском "$_searchQuery"'
                : 'Пока никто не зарегистрирован',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    dynamic user,
    UsersProvider usersProvider,
  ) {
    final roleColor = _getRoleColor(user.role);
    final roleLabel = _getRoleLabel(user.role);

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
                  onChanged: (_) => usersProvider.toggleUserSelection(user.uid),
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
                      user.email[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
          title: Text(user.email,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (user.canMoveTools || user.canControlObjects)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Разрешения',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildPermissionSwitch(
                    context: context,
                    title: 'Может перемещать инструменты',
                    icon: Icons.info_outline,
                    subtitle: 'Разрешить этому пользователю перемещать инструменты',
                    value: user.canMoveTools,
                    onChanged: (value) => usersProvider.updateUserPermissions(
                      user.uid,
                      canMoveTools: value,
                    ),
                  ),
                  const Divider(),
                  _buildPermissionSwitch(
                    context: context,
                    title: 'Может управлять объектами',
                    icon: Icons.business,
                    subtitle: 'Разрешить этому пользователю создавать и редактировать объекты',
                    value: user.canControlObjects,
                    onChanged: (value) => usersProvider.updateUserPermissions(
                      user.uid,
                      canControlObjects: value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Информация', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildInfoRow('Email:', user.email),
                        _buildInfoRow('UID:', user.uid),
                        _buildInfoRow(
                          'Разрешения:',
                          user.canMoveTools && user.canControlObjects
                              ? 'Все'
                              : user.canMoveTools
                                  ? 'Перемещение'
                                  : user.canControlObjects
                                      ? 'Объекты'
                                      : 'Нет',
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
    required BuildContext context,
    required String title,
    required IconData icon,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showUserActionsMenu(
    BuildContext context,
    dynamic user,
    UsersProvider usersProvider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
              'Действия с пользователем',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
              title: const Text('Выдать права администратора'),
              subtitle: user.role == 'admin'
                  ? const Text('Уже администратор')
                  : null,
              enabled: user.role != 'admin',
              onTap: user.role == 'admin'
                  ? null
                  : () {
                      Navigator.pop(context);
                      _showConfirmDialog(
                        context,
                        'Выдать права администратора?',
                        'Это даст пользователю полный доступ к системе',
                        () => usersProvider.updateUserRole(user.uid, 'admin'),
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.purple),
              title: const Text('Сделать бригадиром'),
              subtitle: user.role == 'brigadir'
                  ? const Text('Уже бригадир')
                  : null,
              enabled: user.role != 'brigadir',
              onTap: user.role == 'brigadir'
                  ? null
                  : () {
                      Navigator.pop(context);
                      _showConfirmDialog(
                        context,
                        'Сделать бригадиром?',
                        'Бригадир может управлять работниками на объектах',
                        () => usersProvider.updateUserRole(user.uid, 'brigadir'),
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Обычный пользователь'),
              subtitle:
                  user.role == 'user' ? const Text('Уже пользователь') : null,
              enabled: user.role != 'user',
              onTap: user.role == 'user'
                  ? null
                  : () {
                      Navigator.pop(context);
                      _showConfirmDialog(
                        context,
                        'Понизить роль?',
                        'Пользователь потеряет расширенные права',
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
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  'Удалить пользователя?',
                  'Это действие нельзя отменить',
                  () => usersProvider.deleteUser(user.uid),
                  isDangerous: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : Colors.blue,
            ),
            child: Text(isDangerous ? 'Удалить' : 'Подтвердить'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'brigadir':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'brigadir':
        return 'Бригадир';
      default:
        return 'Пользователь';
    }
  }

  void _showBatchDeleteDialog(BuildContext context, UsersProvider usersProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранных пользователей?'),
        content: Text(
          'Вы уверены, что хотите удалить ${usersProvider.selectedUsers.length} пользователей?\n\n'
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await usersProvider.deleteSelectedUsers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пользователи удалены'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showBatchRoleChangeDialog(BuildContext context, UsersProvider usersProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выберите новую роль для ${usersProvider.selectedUsers.length} пользователей:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Администратор'),
              onTap: () async {
                Navigator.pop(context);
                await usersProvider.updateSelectedUsersRole('admin');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Роль изменена на "Администратор"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.purple),
              title: const Text('Бригадир'),
              onTap: () async {
                Navigator.pop(context);
                await usersProvider.updateSelectedUsersRole('brigadir');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Роль изменена на "Бригадир"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Пользователь'),
              onTap: () async {
                Navigator.pop(context);
                await usersProvider.updateSelectedUsersRole('user');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Роль изменена на "Пользователь"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}
