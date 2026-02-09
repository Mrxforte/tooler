import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/l10n/app_localizations.dart';
import '../models/tool_object.dart';
import '../models/tool.dart';
import '../providers/tool_provider.dart';
import '../widgets/tool_dialog.dart';
import '../widgets/move_tool_dialog.dart';

class ToolsScreen extends StatefulWidget {
  final ToolObject object;

  const ToolsScreen({super.key, required this.object});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToolProvider>().listenToTools(widget.object.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.object.name)),
      body: Consumer<ToolProvider>(
        builder: (context, provider, child) {
          final tools = provider.getToolsForObject(widget.object.id);

          if (tools.isEmpty) {
            return Center(child: Text(l10n.noTools));
          }

          return ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(tool.name),
                  subtitle: Text(
                    '${tool.description}\n${l10n.quantity}: ${tool.quantity}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text(l10n.editTool),
                        onTap: () => _editTool(context, tool),
                      ),
                      PopupMenuItem(
                        child: Text(l10n.moveTool),
                        onTap: () => _moveTool(context, tool),
                      ),
                      PopupMenuItem(
                        child: Text(l10n.deleteTool),
                        onTap: () => _deleteTool(context, tool.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTool(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTool(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ToolDialog(objectId: widget.object.id),
    );
  }

  void _editTool(BuildContext context, Tool tool) {
    final savedContext = context;
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: savedContext,
        builder: (context) =>
            ToolDialog(objectId: widget.object.id, tool: tool),
      );
    });
  }

  void _moveTool(BuildContext context, Tool tool) {
    final savedContext = context;
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: savedContext,
        builder: (context) => MoveToolDialog(tool: tool),
      );
    });
  }

  void _deleteTool(BuildContext context, String toolId) {
    final l10n = AppLocalizations.of(context)!;
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteTool),
          content: Text(l10n.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                context.read<ToolProvider>().deleteTool(toolId);
                Navigator.pop(context);
              },
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
    });
  }
}
