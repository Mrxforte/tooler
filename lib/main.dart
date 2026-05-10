// Tooler - Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison, unused_import, unused_local_variable
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/views/screens/tools/favorites_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/constants/app_constants.dart';
import 'firebase_options.dart';

import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'views/widgets/offline_banner.dart';

// Providers
import 'viewmodels/theme_provider.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/admin_settings_provider.dart';
import 'viewmodels/tools_provider.dart';
import 'viewmodels/objects_provider.dart';
import 'viewmodels/move_request_provider.dart';
import 'viewmodels/batch_move_request_provider.dart';
import 'viewmodels/users_provider.dart';
import 'viewmodels/notification_provider.dart';

// Screens
import 'views/screens/auth/welcome_screen.dart';
import 'views/screens/auth/onboarding_screen.dart';
import 'views/screens/auth/auth_screen.dart';
import 'views/screens/tools/garage_screen.dart';
import 'views/screens/objects/objects_list_screen.dart';
import 'views/screens/notifications/notifications_screen.dart';
import 'views/screens/profile/profile_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  tz.initializeTimeZones();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence — works without internet,
    // queues writes and syncs automatically when connection is restored
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (!kIsWeb) {
      // App Check — debug provider for Android (not needed on web)
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        );
      } catch (e) {
        print('Firebase App Check initialization failed: $e');
      }

      // Local notifications & background tasks — isolated so a missing icon
      // or permission denial doesn't break the Firebase init above.
      try {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('ic_notification');
        final InitializationSettings settings = InitializationSettings(
          android: androidSettings,
          iOS: DarwinInitializationSettings(),
        );
        await flutterLocalNotificationsPlugin.initialize(settings: settings);

        Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
        Workmanager().registerPeriodicTask(
          'daily-salary-reminder',
          'dailySalaryReminder',
          frequency: const Duration(hours: 24),
          initialDelay: _getTimeUntil7PM(),
        );
      } catch (e) {
        print('Notifications/Workmanager init failed: $e');
      }
    }

    print('App ready');
  } catch (e) {
    print('Init error: $e');
  }

  runApp(const MyApp());
}

ThemeData _buildLightTheme() {
  const primary = Color(0xFF0E639C);
  const background = Color(0xFFF3F3F3);
  const surface = Color(0xFFFFFFFF);
  const onSurface = Color(0xFF1E1E1E);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: Color(0xFF1177BB),
      onSecondary: Colors.white,
      background: background,
      onBackground: onSurface,
      surface: surface,
      onSurface: onSurface,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    fontFamily: 'Robo',
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey[400],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const primary = Color(0xFF0E639C);
  const background = Color(0xFF1E1E1E);
  const surface = Color(0xFF252526);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      secondary: Color(0xFF3794FF),
      onSecondary: Colors.white,
      background: background,
      onBackground: Colors.white,
      surface: surface,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: surface,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    fontFamily: 'Robo',
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: const Color(0xFF3794FF),
      unselectedItemColor: Colors.grey[600],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
    ),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async => true);
}

Duration _getTimeUntil7PM() {
  final now = DateTime.now();
  var time = DateTime(now.year, now.month, now.day, 19, 0, 0);
  if (time.isBefore(now)) time = time.add(Duration(days: 1));
  return time.difference(now);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Cache the future so it's not recreated on every rebuild
  final Future<SharedPreferences> _prefsFuture = SharedPreferences.getInstance();

  // Cache themes so they're not rebuilt on every ThemeProvider change
  final ThemeData _lightTheme = _buildLightTheme();
  final ThemeData _darkTheme = _buildDarkTheme();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Define stub routes so web doesn't warn about unknown initial route
            routes: {
              '/': (_) => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
              '/home': (_) => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
              '/auth': (_) => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
            },
          );
        }

        final prefs = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ConnectivityService()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AdminSettingsProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => ToolsProvider()),
            ChangeNotifierProvider(create: (_) => ObjectsProvider()),
            ChangeNotifierProvider(create: (_) => MoveRequestProvider()),
            ChangeNotifierProvider(create: (_) => BatchMoveRequestProvider()),
            ChangeNotifierProvider(create: (_) => UsersProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Tooler',
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: _lightTheme,
                darkTheme: _darkTheme,
                themeMode: themeProvider.themeMode == 'dark'
                    ? ThemeMode.dark
                    : themeProvider.themeMode == 'system'
                    ? ThemeMode.system
                    : ThemeMode.light,
                routes: {
                  '/home': (_) => const MainHome(),
                  '/auth': (_) => const AuthFlow(),
                },
                home: const _ConnectivitySyncWatcher(child: _AuthGate()),
              );
            },
          ),
        );
      },
    );
  }
}

/// Listens for connectivity-restored events and triggers a full
/// Firestore → SQLite sync, then reloads all data providers.
class _ConnectivitySyncWatcher extends StatefulWidget {
  final Widget child;
  const _ConnectivitySyncWatcher({required this.child});

  @override
  State<_ConnectivitySyncWatcher> createState() =>
      _ConnectivitySyncWatcherState();
}

class _ConnectivitySyncWatcherState extends State<_ConnectivitySyncWatcher> {
  ConnectivityService? _connectivity;
  bool _wasOnline = true;
  bool _initialized = false;
  Timer? _autoRefreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _connectivity = context.read<ConnectivityService>();
      _wasOnline = _connectivity!.isOnline;
      _connectivity!.addListener(_onConnectivityChanged);
      _startAutoRefresh();
    }
  }

  /// Refreshes data from Firestore every 20 seconds when online.
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_connectivity?.isOnline == true && mounted) {
        _syncAndReload();
      }
    });
  }

  void _onConnectivityChanged() {
    final isOnline = _connectivity!.isOnline;
    if (isOnline && !_wasOnline) {
      // Just came online — sync immediately, then resume periodic refresh
      _syncAndReload();
      _startAutoRefresh();
    }
    _wasOnline = isOnline;
  }

  Future<void> _syncAndReload() async {
    await SyncService.instance.syncAll();
    if (!mounted) return;
    context.read<ToolsProvider>().loadTools(forceRefresh: true);
    context.read<ObjectsProvider>().loadObjects(forceRefresh: true);
    context.read<MoveRequestProvider>().loadRequests();
    context.read<BatchMoveRequestProvider>().loadRequests();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _connectivity?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Separate widget so Consumer<AuthProvider> doesn't rebuild MaterialApp
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return auth.isLoggedIn ? const MainHome() : const AuthFlow();
  }
}

class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});
  @override
  Widget build(BuildContext context) => const AuthScreen();
}

class MainHome extends StatefulWidget {
  const MainHome({super.key});
  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _navIndex = 0;
  bool _notificationsStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationsStarted) {
      _notificationsStarted = true;
      final userId = context.read<AuthProvider>().userId;
      final notifProvider = context.read<NotificationProvider>();
      if (userId != null) {
        notifProvider.loadNotifications(userId);
      }
      // Register so providers can push notifications without a BuildContext.
      NotificationService.register(notifProvider);
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return GarageScreen();
      case 1:
        return ObjectsListScreen();
      case 2:
        return FavoritesScreen();
      case 3:
        return ProfileScreen();
      default:
        return GarageScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineBanner(child: _buildScreen(_navIndex)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          // Dismiss any active selection modes when switching tabs
          final toolsProvider = Provider.of<ToolsProvider>(
            context,
            listen: false,
          );
          final objectsProvider = Provider.of<ObjectsProvider>(
            context,
            listen: false,
          );

          if (toolsProvider.selectionMode) {
            toolsProvider.toggleSelectionMode();
          }
          if (objectsProvider.selectionMode) {
            objectsProvider.toggleSelectionMode();
          }

          setState(() => _navIndex = index);
        },
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: 'Гараж',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Объекты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
