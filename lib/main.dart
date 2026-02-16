// main.dart - Modern Tooler Construction Tool Management App (MVVM Architecture)
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

// Core
import 'core/constants/app_constants.dart';

// Data layer
import 'data/adapters/hive_adapters.dart';

// ViewModels
import 'viewmodels/theme_provider.dart';
// TODO: Uncomment after extracting full implementations
// import 'viewmodels/auth_provider.dart';
// import 'viewmodels/tools_provider.dart';
// import 'viewmodels/objects_provider.dart';
// import 'viewmodels/worker_provider.dart';
// import 'viewmodels/salary_provider.dart';
// import 'viewmodels/move_request_provider.dart';
// import 'viewmodels/batch_move_request_provider.dart';
// import 'viewmodels/users_provider.dart';

// Views - Auth Screens
import 'views/screens/auth/welcome_screen.dart';
import 'views/screens/auth/onboarding_screen.dart';
import 'views/screens/auth/auth_screen.dart';

// Views - Tool Screens
import 'views/screens/tools/add_edit_tool_screen.dart';
import 'views/screens/tools/garage_screen.dart';
import 'views/screens/tools/tool_details_screen.dart';
import 'views/screens/tools/move_tools_screen.dart';
import 'views/screens/tools/favorites_screen.dart';

// Views - Object Screens
import 'views/screens/objects/add_edit_object_screen.dart';
import 'views/screens/objects/object_details_screen.dart';
import 'views/screens/objects/objects_list_screen.dart';

// Views - Worker Screens
import 'views/screens/workers/workers_list_screen.dart';
import 'views/screens/workers/add_edit_worker_screen.dart';
import 'views/screens/workers/worker_salary_screen.dart';
import 'views/screens/workers/brigadier_screen.dart';

// Views - Admin Screens
import 'views/screens/admin/move_requests_screen.dart';
import 'views/screens/admin/batch_move_requests_screen.dart';
import 'views/screens/admin/users_screen.dart';
import 'views/screens/admin/daily_reports_screen.dart';

// Views - Other Screens
import 'views/screens/notifications/notifications_screen.dart';
import 'views/screens/profile/profile_screen.dart';
import 'views/screens/search/search_screen.dart';

// ========== FIREBASE & APP INITIALIZATION ==========
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize timezone for scheduled notifications
  tz.initializeTimeZones();

  try {
    await Hive.initFlutter();
    
    // Register all Hive adapters
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

    // Initialize Firebase
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDummyKeyForDevelopment',
        appId: '1:1234567890:android:abcdef123456',
        messagingSenderId: '1234567890',
        projectId: 'tooler-dev',
        storageBucket: 'tooler-dev.appspot.com',
      ),
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    // Initialize WorkManager for background tasks
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
        'daily-salary-reminder', 'dailySalaryReminder',
        frequency: Duration(hours: 24),
        initialDelay: _getTimeUntil7PM());

    print('Firebase initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}

Duration _getTimeUntil7PM() {
  final now = DateTime.now();
  var scheduledTime = DateTime(now.year, now.month, now.day, 19, 0, 0);
  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(Duration(days: 1));
  }
  return scheduledTime.difference(now);
}

// ========== APP ROOT ==========
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
            // TODO: Uncomment after extracting full provider implementations
            // ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
            // ChangeNotifierProvider(create: (_) => NotificationProvider()),
            // ChangeNotifierProvider(create: (_) => ToolsProvider()),
            // ChangeNotifierProvider(create: (_) => ObjectsProvider()),
            // ChangeNotifierProvider(create: (_) => WorkerProvider()),
            // ChangeNotifierProvider(create: (_) => SalaryProvider()),
            // ChangeNotifierProvider(create: (_) => MoveRequestProvider()),
            // ChangeNotifierProvider(create: (_) => BatchMoveRequestProvider()),
            // ChangeNotifierProvider(create: (_) => UsersProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Tooler - Construction Tool Manager',
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  useMaterial3: true,
                  brightness: themeProvider.themeMode == 'dark' 
                      ? Brightness.dark 
                      : Brightness.light,
                ),
                home: _buildHome(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    // TODO: After providers are extracted, implement proper auth flow:
    // - Check if first time (SharedPreferences)  
    // - WelcomeScreen → OnboardingScreen → AuthScreen → MainScreen
    // - For now, showing welcome screen for demonstration
    
    return WelcomeScreen(
      onContinue: () {
        // Navigate to onboarding or auth screen
        // This will work fully once AuthProvider is extracted
      },
    );
  }
}

// ========== NOTES ==========
// This main.dart is the entry point with clean MVVM structure.
// 
// ✅ COMPLETED:
// - All 9 data models (moved to lib/data/models/)
// - All 13 Hive adapters (moved to lib/data/adapters/)
// - All services (moved to lib/data/services/)
// - All 22 screens (moved to lib/views/screens/)
// - Clean main.dart (~200 lines vs original 9,519 lines)
//
// ⏳ NEXT STEPS:
// 1. Extract full provider implementations from main_backup.dart
//    - Use line references in each provider file
//    - Complete AuthProvider, ToolsProvider, ObjectsProvider, etc.
// 2. Extract reusable widgets to lib/views/widgets/
//    - SelectionToolCard, ObjectCard, WorkerCard, etc.
// 3. Uncomment provider imports above
// 4. Implement proper routing/navigation
// 5. Test thoroughly
//
// Original file size: 9,519 lines
// New main.dart: ~200 lines
// Reduction: ~98%!
// 
// See MVVM_REFACTORING_GUIDE.md for detailed extraction instructions.
