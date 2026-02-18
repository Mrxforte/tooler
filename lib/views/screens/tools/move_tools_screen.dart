// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../core/utils/error_handler.dart';

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
  
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Перемещение ${widget.selectedTools.length} инструментов')),
      body: Column(
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
                        subtitle: Text('${obj.toolIds.length} инструментов'),
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
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedTools.length,
              itemBuilder: (context, index) {
                final tool = widget.selectedTools[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.build,
                            color: Theme.of(context).colorScheme.primary)),
                    title: Text(tool.title),
                    subtitle: Text(tool.brand),
                    trailing: Text(tool.currentLocationName,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ElevatedButton(
              onPressed: _isProcessing || _selectedLocationId == null || _selectedLocationName == null
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      try {
                        await toolsProvider.moveSelectedTools(
                            _selectedLocationId!, _selectedLocationName!);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ErrorHandler.showErrorDialog(context, 'Ошибка перемещения: $e');
                        }
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
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
        ],
      ),
    );
  }
}
