import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../models/tool.dart';
import '../../controllers/auth_provider.dart';
import '../../controllers/tools_provider.dart';
import '../../controllers/objects_provider.dart';
import '../../services/error_handler.dart';
import '../../services/image_service.dart';
import '../../services/report_service.dart';
import '../../utils/navigator_key.dart';

// ========== MODERN PROFILE SCREEN ==========
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
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _changeTheme(String mode) async {
    setState(() {
      _themeMode = mode;
    });
    await _saveSetting('theme_mode', mode);

    // Reload the app with new theme
    if (mounted) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final myApp = MyApp();
        runApp(myApp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with gradient
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
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.isAdmin ? 'Администратор' : 'Менеджер инструментов',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (authProvider.isAdmin) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 16, color: Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Stats Grid
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
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'В гараже',
                    '${toolsProvider.garageTools.length}',
                    Icons.garage,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Объектов',
                    '${objectsProvider.totalObjects}',
                    Icons.location_city,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Избранных',
                    '${toolsProvider.favoriteTools.length}',
                    Icons.favorite,
                    Colors.red,
                  ),
                ],
              ),
            ),

            // Settings
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Настройки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Синхронизация данных'),
                      trailing: Switch(
                        value: _syncEnabled,
                        onChanged: (value) {
                          setState(() {
                            _syncEnabled = value;
                          });
                          _saveSetting('sync_enabled', value);
                          ErrorHandler.showSuccessDialog(
                            context,
                            value
                                ? 'Синхронизация включена'
                                : 'Синхронизация выключена',
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Уведомления'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _saveSetting('notifications_enabled', value);
                          ErrorHandler.showSuccessDialog(
                            context,
                            value
                                ? 'Уведомления включены'
                                : 'Уведомления выключены',
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Тема приложения'),
                      trailing: DropdownButton<String>(
                        value: _themeMode,
                        onChanged: (value) {
                          if (value != null) {
                            _changeTheme(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'light',
                            child: Text('Светлая'),
                          ),
                          DropdownMenuItem(
                            value: 'dark',
                            child: Text('Темная'),
                          ),
                          DropdownMenuItem(
                            value: 'system',
                            child: Text('Системная'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться отчетом'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _createBackup(
                        context,
                        toolsProvider,
                        objectsProvider,
                      );
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Создать резервную копию'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(AuthProvider authProvider) async {
    final file = await ImageService.pickImage();
    if (file != null) {
      await authProvider.setProfileImage(file);
      ErrorHandler.showSuccessDialog(context, 'Фото профиля обновлено');
    }
  }

  Future<void> _createBackup(
    BuildContext context,
    ToolsProvider toolsProvider,
    ObjectsProvider objectsProvider,
  ) async {
    try {
      final backupData = {
        'tools': toolsProvider.tools.map((t) => t.toJson()).toList(),
        'objects': objectsProvider.objects.map((o) => o.toJson()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = jsonEncode(backupData);
      final tempDir = await getTemporaryDirectory();
      final backupFile = File(
        '${tempDir.path}/tooler_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await backupFile.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text:
            '📱 Резервная копия Tooler\n\n'
            '📅 Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n'
            '🛠️ Инструментов: ${toolsProvider.tools.length}\n'
            '🏢 Объектов: ${objectsProvider.objects.length}\n\n'
            '— Создано в Tooler App —',
      );

      ErrorHandler.showSuccessDialog(context, 'Резервная копия создана');
    } catch (e) {
      ErrorHandler.showErrorDialog(
        context,
        'Ошибка при создании резервной копии: $e',
      );
    }
  }
}
