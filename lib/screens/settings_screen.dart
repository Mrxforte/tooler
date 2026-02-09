import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              ListTile(
                title: Text(l10n.language),
                trailing: DropdownButton<Locale>(
                  value: provider.locale,
                  items: [
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text(l10n.english),
                    ),
                    DropdownMenuItem(
                      value: const Locale('ru'),
                      child: Text(l10n.russian),
                    ),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      provider.setLocale(locale);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
