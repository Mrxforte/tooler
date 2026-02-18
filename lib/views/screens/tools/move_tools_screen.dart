// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';

class MoveToolsScreen extends StatefulWidget {
  final List<Tool> selectedTools;
  const MoveToolsScreen({super.key, required this.selectedTools});
  @override
  _MoveToolsScreenState createState() => _MoveToolsScreenState();
}
class _MoveToolsScreenState extends State<MoveToolsScreen> {
  String? _selectedLocationId;
  String? _selectedLocationName;
  bool _isProcessing = false;
  bool _isLoadingObjects = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadObjects();
    });
  }

  Future<void> _loadObjects() async {
    if (mounted) {
      setState(() {
        _isLoadingObjects = true;
        _loadError = null;
      });
    }
    try {
      final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
      await objectsProvider.loadObjects(forceRefresh: true);
      if (mounted) {
        setState(() => _isLoadingObjects = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingObjects = false;
          _loadError = 'Ошибка загрузки объектов';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: Text('Перемещение ${widget.selectedTools.length} инструментов')),
      body: _isLoadingObjects
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadObjects,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80), // leave space for button
            child: ListView(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Выберите место назначения:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.garage, color: Colors.blue),
                          title: const Text('Гараж'),
                          trailing: _selectedLocationId == 'garage'
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedLocationId = 'garage';
                              _selectedLocationName = 'Гараж';
                            });
                          },
                        ),
                        const Divider(),
                        ...objectsProvider.objects.map((obj) => ListTile(
                              leading: const Icon(Icons.location_city, color: Colors.orange),
                              title: Text(obj.name),
                              subtitle: Text('Инструментов: ${obj.toolIds.length}'),
                              trailing: _selectedLocationId == obj.id
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedLocationId = obj.id;
                                  _selectedLocationName = obj.name;
                                });
                              },
                            )),
                      ],
                    ),
                  ),
                ),
                ...widget.selectedTools.map((tool) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(Icons.build,
                                color: Theme.of(context).colorScheme.primary)),
                        title: Text(tool.title),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(tool.currentLocationName,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isProcessing || _selectedLocationId == null || _selectedLocationName == null
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          try {
                            // Select tools in provider
                            toolsProvider.selectToolsByIds(widget.selectedTools.map((t) => t.id).toList());
                            // Move the selected tools
                            await toolsProvider.moveSelectedTools(
                                _selectedLocationId!, _selectedLocationName!);
                            
                            if (!mounted) return;
                            // Clear selection (should already be done by provider, but just to be sure)
                            toolsProvider.clearAllSelections();
                            // Return to previous screen
                            Navigator.pop(context);
                          } catch (e) {
                            if (!mounted) return;
                            // Error dialog is already shown by the provider
                            setState(() => _isProcessing = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Переместить ${widget.selectedTools.length} инструментов'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
