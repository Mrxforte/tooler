// ObjectCard widget for displaying construction objects

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/construction_object.dart';
import '../../viewmodels/objects_provider.dart';

class ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final VoidCallback onTap;
  final ObjectsProvider objectsProvider;
  final bool selectionMode;

  const ObjectCard({
    super.key,
    required this.object,
    required this.onTap,
    required this.objectsProvider,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: object.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: object.isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        color: object.isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : null,
        child: ListTile(
        leading: selectionMode
            ? Checkbox(
                value: object.isSelected,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  objectsProvider.toggleObjectSelection(object.id);
                },
              )
            : const Icon(Icons.location_city),
        title: Text(object.name),
        subtitle: Text(object.description),
        trailing: Consumer<ObjectsProvider>(
          builder: (context, op, _) {
            return IconButton(
              icon: Icon(
                object.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: object.isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                op.toggleFavorite(object.id);
              },
            );
          },
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () {
          if (!selectionMode) {
            HapticFeedback.mediumImpact();
            objectsProvider.toggleSelectionMode();
            objectsProvider.toggleObjectSelection(object.id);
          }
        },
      ),
      ),
    );
  }
}
