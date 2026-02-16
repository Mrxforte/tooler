// TODO: Extract from main_backup.dart
// ObjectCard widget for displaying construction objects

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/viewmodels/tools_provider.dart';
import '../../data/models/construction_object.dart';
import '../../viewmodels/objects_provider.dart';

class ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final VoidCallback onTap;

  const ObjectCard({
    super.key,
    required this.object,
    required this.onTap, required ToolsProvider toolsProvider, required bool selectionMode,
  });

  @override
  Widget build(BuildContext context) {
    // Removed unused objectsProvider variable
    
    // TODO: Extract full implementation from main_backup.dart
    // This is a placeholder skeleton
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.location_city),
        title: Text(object.name),
        subtitle: Text(object.description),
        trailing: Icon(
          object.isFavorite ? Icons.star : Icons.star_border,
          color: object.isFavorite ? Colors.amber : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
