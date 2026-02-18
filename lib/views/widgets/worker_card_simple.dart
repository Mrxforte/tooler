// Simple Worker Card widget for favorites and quick views

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/worker.dart';
import '../../viewmodels/worker_provider.dart';

class WorkerCardSimple extends StatelessWidget {
  final Worker worker;
  final bool selectionMode;
  final VoidCallback onTap;

  const WorkerCardSimple({
    super.key,
    required this.worker,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: worker.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: worker.isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        color: worker.isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : null,
        child: ListTile(
          leading: selectionMode
              ? Checkbox(
                  value: worker.isSelected,
                  onChanged: (_) {
                    HapticFeedback.selectionClick();
                    workerProvider.toggleWorkerSelection(worker.id);
                  },
                )
              : CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    worker.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
          title: Text(
            worker.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            worker.role == 'brigadir' ? 'Бригадир' : 'Работник',
            style: TextStyle(
              color: worker.role == 'brigadir' ? Colors.purple : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Consumer<WorkerProvider>(
            builder: (context, wp, _) => IconButton(
              icon: Icon(
                worker.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: worker.isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                wp.toggleFavorite(worker.id);
              },
            ),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onLongPress: () {
            if (!selectionMode) {
              HapticFeedback.mediumImpact();
              workerProvider.toggleSelectionMode();
              workerProvider.toggleWorkerSelection(worker.id);
            }
          },
        ),
      ),
    );
  }
}
