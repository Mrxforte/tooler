import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tooler/app/providers/tool_provider.dart';
import 'package:tooler/app/providers/project_provider.dart';

class SyncProvider with ChangeNotifier {
  final ToolProvider _toolProvider;
  final ProjectProvider _projectProvider;

  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingChanges = 0;

  SyncProvider(this._toolProvider, this._projectProvider) {
    _initConnectivity();
    _checkPendingChanges();
  }

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingChanges => _pendingChanges;

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    final status = await connectivity.checkConnectivity();
    _updateConnectionStatus(status);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();

    if (_isOnline && _pendingChanges > 0) {
      syncData();
    }
  }

  void _checkPendingChanges() {
    // This should check local DB for unsynced items
    _pendingChanges = 0; // Implement actual count
    notifyListeners();
  }

  Future<void> syncData() async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await Future.wait([
        _toolProvider.loadTools(),
        _projectProvider.loadProjects(),
      ]);

      _pendingChanges = 0;
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void incrementPendingChanges() {
    _pendingChanges++;
    notifyListeners();
  }
}
