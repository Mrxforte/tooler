import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

/// Pulls all Firestore collections into SQLite when called.
/// Triggered automatically whenever the device comes back online.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _syncing = false;

  Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await Future.wait([
        _pull('tools', DatabaseService.instance.replaceAllTools),
        _pull('objects', DatabaseService.instance.replaceAllObjects),
        _pull('move_requests', DatabaseService.instance.replaceAllMoveRequests),
        _pull('batch_move_requests',
            DatabaseService.instance.replaceAllBatchMoveRequests),
      ]);
    } catch (_) {
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pull(
    String collection,
    Future<void> Function(List<Map<String, dynamic>>) replace,
  ) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collection).get();
    final data = snapshot.docs.map((d) => d.data()).toList();
    await replace(data);
  }
}
