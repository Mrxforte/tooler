// Tooler - Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison, unused_import, unused_local_variable

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/constants/app_constants.dart';
import 'data/adapters/hive_adapters.dart';

// Providers
import 'viewmodels/theme_provider.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/tools_provider.dart';
import 'viewmodels/objects_provider.dart';
import 'viewmodels/worker_provider.dart';
import 'viewmodels/salary_provider.dart';
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
import 'views/screens/workers/workers_list_screen.dart';
import 'views/screens/notifications/notifications_screen.dart';
import 'views/screens/profile/profile_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  tz.initializeTimeZones();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ToolAdapter());
    Hive.registerAdapter(LocationHistoryAdapter());
    Hive.registerAdapter(ConstructionObjectAdapter());
    Hive.registerAdapter(SyncItemAdapter());
    Hive.registerAdapter(MoveRequestAdapter());
    Hive.registerAdapter(BatchMoveRequestAdapter());
    Hive.registerAdapter(NotificationAdapter());
    Hive.registerAdapter(WorkerAdapter());
    Hive.registerAdapter(SalaryEntryAdapter());
    Hive.registerAdapter(AdvanceAdapter());
    Hive.registerAdapter(PenaltyAdapter());
    Hive.registerAdapter(AttendanceAdapter());
    Hive.registerAdapter(DailyWorkReportAdapter());

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDummyKeyForDevelopment',
        appId: '1:1234567890:android:abcdef123456',
        messagingSenderId: '1234567890',
        projectId: 'tooler-dev',
        storageBucket: 'tooler-dev.appspot.com',
      ),
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    final InitializationSettings settings = InitializationSettings(
        android: androidSettings, iOS: iosSettings);
    await flutterLocalNotificationsPlugin.initialize(settings: settings);

    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
        'daily-salary-reminder', 'dailySalaryReminder',
        frequency: Duration(hours: 24),
        initialDelay: _getTimeUntil7PM());

    print('App ready');
  } catch (e) {
    print('Init error: $e');
  }

  runApp(const MyApp());
}

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.grey[400],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF2563EB),
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF60A5FA),
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: const Color(0xFF60A5FA),
      unselectedItemColor: Colors.grey[600],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF60A5FA),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final prefs = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => ToolsProvider()),
            ChangeNotifierProvider(create: (_) => ObjectsProvider()),
            ChangeNotifierProvider(create: (_) => WorkerProvider()),
            ChangeNotifierProvider(create: (_) => SalaryProvider()),
            ChangeNotifierProvider(create: (_) => MoveRequestProvider()),
            ChangeNotifierProvider(create: (_) => BatchMoveRequestProvider()),
            ChangeNotifierProvider(create: (_) => UsersProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.themeMode == 'dark';
              return MaterialApp(
                title: 'Tooler',
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: _buildLightTheme(),
                darkTheme: _buildDarkTheme(),
                themeMode: themeProvider.themeMode == 'dark'
                    ? ThemeMode.dark
                    : themeProvider.themeMode == 'system'
                        ? ThemeMode.system
                        : ThemeMode.light,
                home: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return auth.isLoggedIn ? MainHome() : AuthFlow();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AuthFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onContinue: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            onComplete: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class MainHome extends StatefulWidget {
  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _navIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return GarageScreen();
      case 1:
        return ObjectsListScreen();
      case 2:
        return WorkersListScreen();
      case 3:
        return NotificationsScreen();
      case 4:
        return ProfileScreen();
      default:
        return GarageScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_navIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Sites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Workers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
