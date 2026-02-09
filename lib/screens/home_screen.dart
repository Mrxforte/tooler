// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tooler/l10n/app_localizations.dart';

import '../models/tool_object.dart';
import '../providers/object_provider.dart';
import '../widgets/object_dialog.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

// ignore: must_be_immutable
class HomeScreen extends StatelessWidget {
  bool mounted;

  HomeScreen({
    super.key,
    required this.mounted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.objects),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ObjectProvider>(
        builder: (context, provider, child) {
          if (provider.objects.isEmpty) {
            return Center(child: Text(l10n.noObjects));
          }

          return ListView.builder(
            itemCount: provider.objects.length,
            itemBuilder: (context, index) {
              final object = provider.objects[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(object.name),
                  subtitle: Text(object.description),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text(l10n.editObject),
                        onTap: () => _editObject(context, object),
                      ),
                      PopupMenuItem(
                        child: Text(l10n.deleteObject),
                        onTap: () => _deleteObject(context, object.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ToolsScreen(object: object),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addObject(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addObject(BuildContext context) {
    showDialog(context: context, builder: (context) => const ObjectDialog());
  }

  void _editObject(BuildContext context, ToolObject object) {
    final savedContext = context;
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        // ignore: use_build_context_synchronously
        context: savedContext,
        builder: (context) => ObjectDialog(object: object),
      );
    });
  }

  void _deleteObject(BuildContext context, String objectId) {
    final l10n = AppLocalizations.of(context)!;
    final savedContext = context;
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        // ignore: use_build_context_synchronously
        context: savedContext,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteObject),
          content: Text(l10n.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(savedContext),
              child: Text(l10n.no),
            ),
            TextButton(
              onPressed: () {
                savedContext.read<ObjectProvider>().deleteObject(objectId);
                Navigator.pop(savedContext);
              },
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
    });
  }
}
