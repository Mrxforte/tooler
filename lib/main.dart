// Tooler - Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison, unused_import, unused_local_variable

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
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
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  tz.initializeTimeZones();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check with fallback for connectivity issues
    try {
      await FirebaseAppCheck.instance.activate(
        // Use Debug provider for development - use Play Integrity in production
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        // Use reCAPTCHA for web
        // webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        // For iOS when configured: appleProvider: AppleProvider.appAttest,
      );
    } catch (e) {
      print('Firebase App Check initialization failed: $e');
      print('Using fallback without App Check');
    }

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
            ChangeNotifierProvider(create: (_) => AdminSettingsProvider()),
            ChangeNotifierProxyProvider<AdminSettingsProvider, AuthProvider>(
              create: (context) => AuthProvider(
                prefs,
                Provider.of<AdminSettingsProvider>(context, listen: false),
              ),
              update: (context, adminSettings, previousAuth) => previousAuth ?? AuthProvider(
                prefs,
                adminSettings,
              ),
            ),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => ToolsProvider()),
            ChangeNotifierProvider(create: (_) => ObjectsProvider()),
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
                routes: {
                  '/home': (_) => const MainHome(),
                  '/auth': (_) => const AuthFlow(),
                },
                home: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    // Show loading spinner while auth is initializing
                    if (auth.isLoading) {
                      return Scaffold(
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
                    // Show main app or auth flow based on login state
                    return auth.isLoggedIn ? const MainHome() : const AuthFlow();
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
  const AuthFlow({super.key});
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
  const MainHome({super.key});
  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    // Data loading is now lazy - each screen loads its own data when accessed
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
      body: _buildScreen(_navIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          // Dismiss any active selection modes when switching tabs
          final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
          final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
          
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
