// ObjectCard widget for displaying construction objects

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '
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
        trailing: IconButton(
          icon: Icon(
            object.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: object.isFavorite ? Colors.red : null,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            objectsProvider.toggleFavorite(object.id);
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
    );
  }
}
