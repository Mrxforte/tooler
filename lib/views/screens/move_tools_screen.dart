import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

// ========== MOVE TOOLS SCREEN ==========
class MoveToolsScreen extends StatefulWidget {
  final List<Tool> selectedTools;

  const MoveToolsScreen({super.key, required this.selectedTools});

  @override
  _MoveToolsScreenState createState() => _MoveToolsScreenState();
}

class _MoveToolsScreenState extends State<MoveToolsScreen> {
  String? _selectedLocationId;
  String? _selectedLocationName;

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Перемещение ${widget.selectedTools.length} инструментов'),
      ),
      body: Column(
        children: [
          // Location Selector
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите место назначения:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Garage option
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

                  // Objects options
                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: Colors.orange,
                      ),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: _selectedLocationId == object.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLocationId = object.id;
                          _selectedLocationName = object.name;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Selected Tools List
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedTools.length,
              itemBuilder: (context, index) {
                final tool = widget.selectedTools[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.build,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(tool.title),
                    subtitle: Text(tool.brand),
                    trailing: Text(
                      tool.currentLocationName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),

          // Move Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedLocationId == null ||
                    _selectedLocationName == null) {
                  ErrorHandler.showWarningDialog(
                    context,
                    'Выберите место назначения',
                  );
                  return;
                }

                await toolsProvider.moveSelectedTools(
                  _selectedLocationId!,
                  _selectedLocationName!,
                );

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Переместить ${widget.selectedTools.length} инструментов',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
