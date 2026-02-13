// main.dart - Modern Tooler Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Config
import 'config/firebase_config.dart';

// Models
import 'models/construction_object.dart';
import 'models/location_history.dart';
import 'models/sync_item.dart';
import 'models/tool.dart';

// Controllers
import 'controllers/auth_provider.dart';
import 'controllers/objects_provider.dart';
import 'controllers/tools_provider.dart';

// Services
import 'services/error_handler.dart';
import 'services/image_service.dart';
import 'services/local_database.dart';
import 'services/report_service.dart';

// Utils
import 'utils/hive_adapters.dart';
import 'utils/id_generator.dart';
import 'utils/navigator_key.dart';

// Screens
import 'views/screens/add_edit_object_screen.dart';
import 'views/screens/add_edit_tool_screen.dart';
import 'views/screens/auth_screen.dart';
import 'views/screens/favorites_screen.dart';
import 'views/screens/garage_screen.dart';
import 'views/screens/main_screen.dart';
import 'views/screens/move_tools_screen.dart';
import 'views/screens/object_details_screen.dart';
import 'views/screens/objects_list_screen.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/search_screen.dart';
import 'views/screens/tool_details_screen.dart';
import 'views/screens/tools_list_screen.dart';
import 'views/screens/welcome_screen.dart';

// Widgets
import 'views/widgets/object_card.dart';
import 'views/widgets/selection_tool_card.dart';

// ========== FIREBASE INITIALIZATION ==========
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(ToolAdapter());
    Hive.registerAdapter(LocationHistoryAdapter());
    Hive.registerAdapter(ConstructionObjectAdapter());
    Hive.registerAdapter(SyncItemAdapter());

    // Initialize Firebase
    await Firebase.initializeApp(
      options: FirebaseConfig.options,
    );

    print('Firebase initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
    // Continue with offline mode
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Ошибка загрузки приложения')),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        final prefs = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
            ChangeNotifierProvider(create: (_) => ToolsProvider()),
            ChangeNotifierProvider(create: (_) => ObjectsProvider()),
            Provider.value(value: prefs),
          ],
          child: Consumer<SharedPreferences>(
            builder: (context, prefs, child) {
              final themeMode = prefs.getString('theme_mode') ?? 'light';

              return MaterialApp(
                title: 'Tooler',
                theme: _buildLightTheme(),
                darkTheme: _buildDarkTheme(),
                themeMode: themeMode == 'dark'
                    ? ThemeMode.dark
                    : themeMode == 'system'
                    ? ThemeMode.system
                    : ThemeMode.light,
                navigatorKey: navigatorKey,
                home: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final seenWelcome = prefs.getBool('seen_welcome') ?? false;
                    if (!seenWelcome) {
                      return WelcomeScreen(
                        onContinue: () async {
                          await prefs.setBool('seen_welcome', true);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                          );
                        },
                      );
                    }

                    if (!authProvider.isLoggedIn) {
                      final seenOnboarding =
                          prefs.getBool('seen_onboarding') ?? false;
                      if (!seenOnboarding) {
                        return OnboardingScreen(
                          onComplete: () async {
                            await prefs.setBool('seen_onboarding', true);
                          },
                        );
                      }
                      return const AuthScreen();
                    }

                    return const MainScreen();
                  },
                ),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }

  // GitHub-like Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF24292e), // GitHub dark header
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF24292e), // GitHub dark
        secondary: Color(0xFF0366d6), // GitHub blue
        surface: Color(0xFFffffff),
        background: Color(0xFFf6f8fa), // GitHub light background
        error: Color(0xFFd73a49), // GitHub red
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF24292e), // GitHub dark header
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0366d6), // GitHub blue
        unselectedItemColor: const Color(0xFF586069), // GitHub gray
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF2ea44f), // GitHub green
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF2ea44f), // GitHub green
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF24292e),
          side: const BorderSide(color: Color(0xFFe1e4e8)), // GitHub border
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFe1e4e8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFe1e4e8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF0366d6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFe1e4e8)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFe1e4e8),
        thickness: 1,
        space: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF24292e),
        unselectedLabelColor: Color(0xFF586069),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFFf9826c), width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF24292e),
          fontWeight: FontWeight.w600,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF24292e),
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        displaySmall: TextStyle(
          color: Color(0xFF24292e),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF24292e),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF24292e),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF586069),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF24292e),
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF24292e),
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF586069),
          fontSize: 12,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFf6f8fa),
        labelStyle: const TextStyle(color: Color(0xFF24292e), fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFe1e4e8)),
        ),
      ),
    );
  }

  // GitHub Dark Theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0d1117), // GitHub dark background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF58a6ff), // GitHub dark blue
        secondary: Color(0xFF1f6feb), // GitHub dark accent
        surface: Color(0xFF161b22), // GitHub dark surface
        background: Color(0xFF0d1117), // GitHub dark background
        error: Color(0xFFf85149), // GitHub dark red
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF161b22), // GitHub dark surface
        iconTheme: const IconThemeData(color: Color(0xFFc9d1d9)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFc9d1d9),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF161b22),
        selectedItemColor: const Color(0xFF58a6ff), // GitHub dark blue
        unselectedItemColor: const Color(0xFF8b949e), // GitHub dark gray
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF238636), // GitHub dark green
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF238636), // GitHub dark green
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFc9d1d9),
          side: const BorderSide(
            color: Color(0xFF30363d),
          ), // GitHub dark border
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0d1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF30363d)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF30363d)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF58a6ff), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF161b22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF30363d)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF21262d),
        thickness: 1,
        space: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF58a6ff),
        unselectedLabelColor: Color(0xFF8b949e),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFFf78166), width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFc9d1d9),
          fontWeight: FontWeight.w600,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          color: Color(0xFFc9d1d9),
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        displaySmall: TextStyle(
          color: Color(0xFFc9d1d9),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFc9d1d9),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFc9d1d9),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF8b949e),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFc9d1d9),
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFc9d1d9),
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF8b949e),
          fontSize: 12,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF21262d),
        labelStyle: const TextStyle(color: Color(0xFFc9d1d9), fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF30363d)),
        ),
      ),
    );
  }
}
