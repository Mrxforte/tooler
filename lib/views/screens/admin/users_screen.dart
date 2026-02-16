import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/users_provider.dart';
import '../../../viewmodels/auth_provider.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользователи')),
        body: const Center(child: Text('Только администратор может просматривать пользователей')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => usersProvider.loadUsers(),
          ),
        ],
      ),
      body: usersProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : usersProvider.users.isEmpty
              ? const Center(child: Text('Нет пользователей'))
              : ListView.builder(
                  itemCount: usersProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = usersProvider.users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              user.role == 'admin' ? Colors.red : Colors.blue,
                          child: Text(user.email[0].toUpperCase()),
                        ),
                        title: Text(user.email),
                        subtitle: Text('Роль: ${user.role}'),
                        children: [
                          SwitchListTile(
                            title: const Text('Может перемещать инструменты'),
                            value: user.canMoveTools,
                            onChanged: (value) {
                              usersProvider.updateUserPermissions(user.uid,
                                  canMoveTools: value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Может управлять объектами'),
                            value: user.canControlObjects,
                            onChanged: (value) {
                              usersProvider.updateUserPermissions(user.uid,
                                  canControlObjects: value);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
