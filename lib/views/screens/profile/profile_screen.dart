import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'dart:convert';

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
import '../admin/admin_settings_screen.dart';
import '../workers/workers_list_screen.dart';
import '../workers/brigadier_screen.dart';
import '../tools/garage_screen.dart';
import '../tools/tool_details_screen.dart';
import '../objects/objects_list_screen.dart';
import '../../widgets/selection_tool_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
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
    if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    }
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
                color: Theme.of(context).colorScheme.primary,
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
                  _buildStatCard(
                    'Всего инструментов',
                    '${toolsProvider.totalTools}',
                    Icons.build,
                    Theme.of(context).colorScheme.primary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Scaffold(
                              appBar: AppBar(title: const Text('Все инструменты')),
                              body: Consumer<ToolsProvider>(
                                builder: (context, tp, _) => tp.tools.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.build, size: 80, color: Colors.grey.shade300),
                                            const SizedBox(height: 16),
                                            const Text('Нет инструментов',
                                                style: TextStyle(fontSize: 18, color: Colors.grey)),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: tp.tools.length,
                                        itemBuilder: (context, index) {
                                          final tool = tp.tools[index];
                                          return SelectionToolCard(
                                            tool: tool,
                                            selectionMode: false,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EnhancedToolDetailsScreen(tool: tool),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  _buildStatCard(
                    'В гараже',
                    '${toolsProvider.garageTools.length}',
                    Icons.garage,
                    const Color(0xFF10B981),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GarageScreen(),
                      ),
                    ),
                  ),
                  _buildStatCard(
                    'Объектов',
                    '${objectsProvider.totalObjects}',
                    Icons.location_city,
                    const Color(0xFFF59E0B),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObjectsListScreen(),
                      ),
                    ),
                  ),
                  _buildStatCard(
                    'Работников',
                    '${workerProvider.workers.length}',
                    Icons.people,
                    const Color(0xFF8B5CF6),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkersListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Settings Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Параметры приложения',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sync, color: Colors.blue),
                      ),
                      title: const Text('Синхронизация данных'),
                      trailing: Switch(
                        value: _syncEnabled,
                        onChanged: (v) {
                          setState(() => _syncEnabled = v);
                          _saveSetting('sync_enabled', v);
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications, color: Colors.orange),
                      ),
                      title: const Text('Уведомления'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) {
                          setState(() => _notificationsEnabled = v);
                          _saveSetting('notifications_enabled', v);
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.color_lens, color: Colors.purple),
                      ),
                      title: const Text('Тема приложения'),
                      trailing: SizedBox(
                        width: 120,
                        child: DropdownButton<String>(
                          value: _themeMode,
                          isExpanded: true,
                          underline: SizedBox.shrink(),
                          onChanged: (v) {
                            if (v != null) _changeTheme(v);
                          },
                          items: [
                            DropdownMenuItem(value: 'light', child: Text('Светлая')),
                            DropdownMenuItem(value: 'dark', child: Text('Темная')),
                            DropdownMenuItem(value: 'system', child: Text('Системная')),
                          ],
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            // Features Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Быстрые действия',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (authProvider.isAdmin) ...[
                    _buildActionCard(
                      title: 'Запросы на перемещение',
                      subtitle: 'Управляйте запросами инструментов',
                      icon: Icons.pending_actions,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminMoveRequestsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Все инструменты',
                      subtitle: 'Просмотр всех инструментов в системе',
                      icon: Icons.build_circle,
                      color: const Color(0xFF2563EB),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GarageScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Все объекты',
                      subtitle: 'Полный список объектов строительства',
                      icon: Icons.domain,
                      color: const Color(0xFF0891B2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ObjectsListScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Групповые запросы',
                      subtitle: 'Просмотрите групповые операции',
                      icon: Icons.group_work,
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminBatchMoveRequestsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Управление пользователями',
                      subtitle: 'Добавляйте и редактируйте пользователей',
                      icon: Icons.people,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Управление работниками',
                      subtitle: 'Организуйте рабочую силу',
                      icon: Icons.engineering,
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WorkersListScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Ежедневные отчеты',
                      subtitle: 'Просмотрите отчеты работников',
                      icon: Icons.assignment,
                      color: const Color(0xFF06B6D4),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDailyReportsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Настройки администратора',
                      subtitle: 'Изменить секретное слово',
                      icon: Icons.admin_panel_settings,
                      color: const Color(0xFF6366F1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
                      ),
                    ),
                  ] else if (authProvider.isBrigadir) ...[
                    _buildActionCard(
                      title: 'Мой объект',
                      subtitle: 'Управление активным объектом',
                      icon: Icons.location_city,
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BrigadierScreen()),
                      ),
                    ),
                  ],
                  _buildActionCard(
                    title: 'Уведомления',
                    subtitle: notifProvider.hasUnread
                        ? '${notifProvider.notifications.where((n) => !n.read).length} новых'
                        : 'Все уведомления прочитаны',
                    icon: Icons.notifications,
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: 'Создать отчет',
                    subtitle: 'Экспортируйте инвентаризацию в PDF',
                    icon: Icons.share,
                    color: const Color(0xFF6366F1),
                    onTap: () async {
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
                          userId: authProvider.user?.uid ?? 'local',
                        ),
                        (type) async {
                          await ReportService.shareInventoryReport(
                            toolsProvider.tools,
                            objectsProvider.objects,
                            context,
                            type,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: 'Резервная копия',
                    subtitle: 'Сохраните и поделитесь данными',
                    icon: Icons.backup,
                    color: const Color(0xFF06B6D4),
                    onTap: () async => await _createBackup(context, toolsProvider, objectsProvider),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await authProvider.signOut();
                      if (!mounted) return;
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/auth', (_) => false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red, width: 1.5),
                        color: Colors.red.withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout, color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Выйти из аккаунта',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text:
            '📱 Резервная копия Tooler\n\n📅 Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n🛠️ Инструментов: ${tp.tools.length}\n🏢 Объектов: ${op.objects.length}\n\n— Создано в Tooler App —',
      ));
      if (!context.mounted) return;
      ErrorHandler.showSuccessDialog(context, 'Резервная копия создана');
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }
}
