import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class ObjectDetailsScreen extends StatelessWidget {
  final ConstructionObject object;

  const ObjectDetailsScreen({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditObjectScreen(object: object),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Object Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
            ),
            child: object.displayImage != null
                ? Image(
                    image: object.displayImage!.startsWith('http')
                        ? NetworkImage(object.displayImage!) as ImageProvider
                        : FileImage(File(object.displayImage!)),
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                  ),
          ),

          // Object Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  object.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (object.description.isNotEmpty)
                  Text(
                    object.description,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.build, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Инструментов на объекте: ${toolsOnObject.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Tools on Object
          Expanded(
            child: toolsOnObject.isEmpty
                ? _buildEmptyObjectTools()
                : ListView.builder(
                    itemCount: toolsOnObject.length,
                    itemBuilder: (context, index) {
                      final tool = toolsOnObject[index];
                      return SelectionToolCard(
                        tool: tool,
                        selectionMode: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EnhancedToolDetailsScreen(tool: tool),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyObjectTools() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'На объекте нет инструментов',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Переместите инструменты на этот объект',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

