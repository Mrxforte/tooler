import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tooler/app/constants/app_constants.dart';
import 'package:tooler/app/providers/auth_provider.dart';
import 'package:tooler/app/providers/language_provider.dart';
import 'package:tooler/app/providers/theme_provider.dart';
import 'package:tooler/features/auth/screens/login_screen.dart';
import 'package:tooler/features/onboarding/onboarding_screen.dart';
import 'package:tooler/main_screen.dart';
import 'package:tooler/app/theme/app_theme.dart';
import 'package:tooler/generated/l10n.dart';

class ToolerApp extends StatelessWidget {
  const ToolerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, LanguageProvider, AuthProvider>(
      builder: (context, themeProvider, languageProvider, authProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tooler',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _buildHome(authProvider),
        );
      },
    );
  }

  Widget _buildHome(AuthProvider authProvider) {
    if (authProvider.isFirstLaunch) {
      return const OnboardingScreen();
    } else if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    } else {
      return const MainScreen();
    }
  }
}
