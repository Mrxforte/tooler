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

  Future<void> _performMove() async {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

    if (_selectedLocationId == null || _selectedLocationName == null) {
      return;
    }

    // Check which tools already exist in destination
    final toolsAlreadyInDest = widget.selectedTools
        .where((tool) => tool.currentLocation == _selectedLocationId)
        .toList();

    // If some tools already exist, show warning dialog
    if (toolsAlreadyInDest.isNotEmpty) {
      final canMove = widget.selectedTools
          .where((tool) => tool.currentLocation != _selectedLocationId)
          .length;

      if (!mounted) return;

      final shouldProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Инструменты уже на месте',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  '${toolsAlreadyInDest.length} из ${widget.selectedTools.length} инструментов уже находятся в "${_selectedLocationName}":',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...toolsAlreadyInDest.take(5).map((tool) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tool.title,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (toolsAlreadyInDest.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... и ещё ${toolsAlreadyInDest.length - 5} инструментов',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),
                if (canMove > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$canMove инструментов будут перемещены',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                canMove > 0 ? 'Переместить $canMove' : 'Ничего не менять',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ) ?? false;

      if (!shouldProceed) {
        return;
      }
    }

    // Proceed with move
    setState(() => _isProcessing = true);
    try {
      toolsProvider.selectToolsByIds(
          widget.selectedTools.map((t) => t.id).toList());
      await toolsProvider.moveSelectedTools(
          _selectedLocationId!, _selectedLocationName!);

      if (!mounted) return;
      toolsProvider.clearAllSelections();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
          title: Text('Перемещение ${widget.selectedTools.length} инструментов')),
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
                      padding: const EdgeInsets.only(bottom: 80),
                      child: ListView(
                        children: [
                          Card(
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Выберите место назначения:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: const Icon(Icons.garage,
                                        color: Colors.blue),
                                    title: const Text('Гараж'),
                                    trailing: _selectedLocationId == 'garage'
                                        ? const Icon(Icons.check,
                                            color: Colors.green)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedLocationId = 'garage';
                                        _selectedLocationName = 'Гараж';
                                      });
                                    },
                                  ),
                                  const Divider(),
                                  ...objectsProvider.objects.map((obj) {
                                    // Calculate tools from selected list currently on this object
                                    final toolsCurrentlyHere = widget
                                        .selectedTools
                                        .where((t) => t.currentLocation == obj.id)
                                        .length;

                                    // Calculate updated count after move
                                    final updatedCount = _selectedLocationId ==
                                            obj.id
                                        ? obj.toolIds.length -
                                            toolsCurrentlyHere +
                                            widget.selectedTools.length
                                        : obj.toolIds.length - toolsCurrentlyHere;

                                    return ListTile(
                                      leading: const Icon(
                                          Icons.location_city,
                                          color: Colors.orange),
                                      title: Text(obj.name),
                                      subtitle: Text(
                                        _selectedLocationId == obj.id
                                            ? 'Инструментов: ${obj.toolIds.length} → ${updatedCount.clamp(0, updatedCount)}'
                                            : 'Инструментов: ${obj.toolIds.length}${toolsCurrentlyHere > 0 ? ' → ${updatedCount.clamp(0, updatedCount)}' : ''}',
                                      ),
                                      trailing: _selectedLocationId == obj.id
                                          ? const Icon(Icons.check,
                                              color: Colors.green)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedLocationId = obj.id;
                                          _selectedLocationName = obj.name;
                                        });
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          ...widget.selectedTools.map((tool) => Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      child: Icon(Icons.build,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  title: Text(tool.title),
                                  subtitle: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(tool.currentLocationName,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
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
                          border: Border(
                              top: BorderSide(color: Colors.grey.shade200)),
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
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ||
                                    _selectedLocationId == null ||
                                    _selectedLocationName == null
                                ? null
                                : () => _performMove(),
                            icon: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.check),
                            label: _isProcessing
                                ? const Text('Перемещение...')
                                : Text(
                                    'Переместить ${widget.selectedTools.length} инструментов',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
