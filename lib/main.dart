import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tooler/app/app.dart';
import 'package:tooler/app/constants/app_constants.dart';
import 'package:tooler/app/providers/auth_provider.dart';
import 'package:tooler/app/providers/language_provider.dart';
import 'package:tooler/app/providers/sync_provider.dart';
import 'package:tooler/app/providers/theme_provider.dart';
import 'package:tooler/app/providers/tool_provider.dart';
import 'package:tooler/app/providers/project_provider.dart';
import 'package:tooler/app/services/firebase_service.dart';
import 'package:tooler/app/services/local_db_service.dart';
import 'package:tooler/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await LocalDbService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const ToolerApp(),
    ),
  );
}
