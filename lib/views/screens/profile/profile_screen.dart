// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/tool.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/notification_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/theme_provider.dart';
import '../../../data/services/image_service.dart';
import '../../../data/services/report_service.dart';
import '../../../core/utils/error_handler.dart';
import '../notifications/notifications_screen.dart';
import '../admin/move_requests_screen.dart';
import '../admin/batch_move_requests_screen.dart';
import '../admin/users_screen.dart';
import '../admin/daily_reports_screen.dart';
import '../workers/workers_list_screen.dart';
import '../workers/brigadier_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  bool _syncEnabled = true;
  bool _notificationsEnabled = true;
  String _themeMode = 'light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncEnabled = prefs.getBool('sync_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _themeMode = prefs.getString('theme_mode') ?? 'light';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    else if (value is String) prefs.setString(key, value);
  }

  Future<void> _changeTheme(String mode) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.themeMode = mode;
    await _saveSetting('theme_mode', mode);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final workerProvider = Provider.of<WorkerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              ),
              if (notifProvider.hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: authProvider.profileImage != null
                              ? FileImage(authProvider.profileImage!)
                              : null,
                          child: authProvider.profileImage == null
                              ? Icon(Icons.person, size: 60,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, size: 15,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: () => _pickProfileImage(authProvider),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      authProvider.user?.email ?? 'Гость',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text('Менеджер инструментов', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatCard('Всего инструментов', '${toolsProvider.totalTools}',
                      Icons.build, Colors.blue),
                  _buildStatCard('В гараже', '${toolsProvider.garageTools.length}',
                      Icons.garage, Colors.green),
                  _buildStatCard('Объектов', '${objectsProvider.totalObjects}',
                      Icons.location_city, Colors.orange),
                  _buildStatCard('Работников', '${workerProvider.workers.length}',
                      Icons.people, Colors.purple),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Настройки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Синхронизация данных'),
                      trailing: Switch(
                        value: _syncEnabled,
                        onChanged: (v) {
                          setState(() => _syncEnabled = v);
                          _saveSetting('sync_enabled', v);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Уведомления'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) {
                          setState(() => _notificationsEnabled = v);
                          _saveSetting('notifications_enabled', v);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Тема приложения'),
                      trailing: DropdownButton<String>(
                        value: _themeMode,
                        onChanged: (v) {
                          if (v != null) _changeTheme(v);
                        },
                        items: const [
                          DropdownMenuItem(value: 'light', child: Text('Светлая')),
                          DropdownMenuItem(value: 'dark', child: Text('Темная')),
                          DropdownMenuItem(value: 'system', child: Text('Системная')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (authProvider.isAdmin) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminMoveRequestsScreen())),
                      icon: const Icon(Icons.pending_actions),
                      label: const Text('Запросы на перемещение'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminBatchMoveRequestsScreen())),
                      icon: const Icon(Icons.group_work),
                      label: const Text('Групповые запросы'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminUsersScreen())),
                      icon: const Icon(Icons.people),
                      label: const Text('Управление пользователями'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WorkersListScreen())),
                      icon: const Icon(Icons.engineering),
                      label: const Text('Управление работниками'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminDailyReportsScreen())),
                      icon: const Icon(Icons.assignment),
                      label: const Text('Ежедневные отчеты'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else if (authProvider.isBrigadir) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BrigadierScreen())),
                      icon: const Icon(Icons.location_city),
                      label: const Text('Мой объект'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                    icon: const Icon(Icons.notifications),
                    label: Text('Уведомления ${notifProvider.hasUnread ? '(Новые)' : ''}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ReportService.showReportTypeDialog(
                          context,
                          Tool(
                              id: 'inventory',
                              title: 'Инвентаризация',
                              description: '',
                              brand: '',
                              uniqueId: '',
                              currentLocation: '',
                              currentLocationName: '',
                              userId: authProvider.user?.uid ?? 'local'),
                          (type) async {
                        await ReportService.shareInventoryReport(
                            toolsProvider.tools, objectsProvider.objects, context, type);
                      });
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться отчетом'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async => await _createBackup(
                        context, toolsProvider, objectsProvider),
                    icon: const Icon(Icons.backup),
                    label: const Text('Создать резервную копию'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Future<void> _pickProfileImage(AuthProvider auth) async {
    final file = await ImageService.pickImage();
    if (file != null) {
      await auth.setProfileImage(file);
      ErrorHandler.showSuccessDialog(context, 'Фото профиля обновлено');
    }
  }

  Future<void> _createBackup(BuildContext context, ToolsProvider tp, ObjectsProvider op) async {
    try {
      final backupData = {
        'tools': tp.tools.map((t) => t.toJson()).toList(),
        'objects': op.objects.map((o) => o.toJson()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'version': '1.0'
      };
      final jsonStr = jsonEncode(backupData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tooler_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)],
          text:
              '📱 Резервная копия Tooler\n\n📅 Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n🛠️ Инструментов: ${tp.tools.length}\n🏢 Объектов: ${op.objects.length}\n\n— Создано в Tooler App —');
      ErrorHandler.showSuccessDialog(context, 'Резервная копия создана');
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }
}
