/// WorkerProvider - Provider for worker management with selection and favorites

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/worker.dart';
import '../data/repositories/local_database.dart';

class WorkerProvider with ChangeNotifier {
  List<Worker> _workers = [];
  bool _isLoading = false;
  bool _selectionMode = false;

  List<Worker> get workers => List.unmodifiable(_workers);
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  List<Worker> get selectedWorkers => _workers.where((w) => w.isSelected).toList();
  bool get hasSelectedWorkers => _workers.any((w) => w.isSelected);
  List<Worker> get favoriteWorkers => _workers.where((w) => w.isFavorite).toList();

  void toggleSelectionMode() {
    HapticFeedback.mediumImpact();
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      for (var i = 0; i < _workers.length; i++) {
        _workers[i] = _workers[i].copyWith(isSelected: false);
      }
    }
    notifyListeners();
  }

  void toggleWorkerSelection(String workerId) {
    HapticFeedback.selectionClick();
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      _workers[index] = _workers[index].copyWith(isSelected: !_workers[index].isSelected);
      notifyListeners();
    }
  }

  void selectAllWorkers() {
    for (var i = 0; i < _workers.length; i++) {
      _workers[i] = _workers[i].copyWith(isSelected: true);
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String workerId) async {
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      _workers[index] = _workers[index].copyWith(isFavorite: !_workers[index].isFavorite);
      await LocalDatabase.workers.put(_workers[index].id, _workers[index]);
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteForSelected() async {
    for (final w in selectedWorkers) {
      final updated = w.copyWith(isFavorite: !w.isFavorite);
      await LocalDatabase.workers.put(updated.id, updated);
    }
    await loadWorkers();
  }

  Future<void> loadWorkers() async {
    _isLoading = true;
    notifyListeners();
    await LocalDatabase.init();
    _workers = LocalDatabase.workers.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWorker(Worker worker) async {
    _workers.add(worker);
    await LocalDatabase.workers.put(worker.id, worker);
    notifyListeners();
  }

  Future<void> updateWorker(Worker worker) async {
    final index = _workers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _workers[index] = worker;
      await LocalDatabase.workers.put(worker.id, worker);
      notifyListeners();
    }
  }

  Future<void> deleteWorker(String id) async {
    _workers.removeWhere((w) => w.id == id);
    await LocalDatabase.workers.delete(id);
    notifyListeners();
  }

  List<Worker> getWorkersOnObject(String objectId) {
    return _workers.where((w) => w.assignedObjectIds.contains(objectId)).toList();
  }

  // Move selected workers to another object
  Future<void> moveSelectedWorkers(List<String> targetObjectIds) async {
    for (final w in selectedWorkers) {
      final updated = w.copyWith(assignedObjectIds: targetObjectIds);
      await LocalDatabase.workers.put(updated.id, updated);
    }
    await loadWorkers();
    toggleSelectionMode(); // exit selection mode
  }

  // Give bonus to a worker
  Future<void> giveBonus({
    required String workerId,
    required double amount,
    required String reason,
    required String givenBy,
    String? notes,
  }) async {
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      final worker = _workers[index];
      final newTotalBonus = worker.totalBonus + amount;
      final updated = worker.copyWith(totalBonus: newTotalBonus);
      _workers[index] = updated;
      await LocalDatabase.workers.put(updated.id, updated);
      notifyListeners();
    }
  }

  // Give bonus to multiple selected workers
  Future<void> giveBonusToSelected({
    required double amount,
    required String reason,
    required String givenBy,
  }) async {
    for (final w in selectedWorkers) {
      final newTotalBonus = w.totalBonus + amount;
      final updated = w.copyWith(totalBonus: newTotalBonus);
      await LocalDatabase.workers.put(updated.id, updated);
    }
    await loadWorkers();
  }

  // Update monthly bonus allowance
  Future<void> setMonthlyBonus({
    required String workerId,
    required double monthlyAmount,
  }) async {
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      final updated = _workers[index].copyWith(monthlyBonus: monthlyAmount);
      _workers[index] = updated;
      await LocalDatabase.workers.put(updated.id, updated);
      notifyListeners();
    }
  }

  // Clear selection
  void clearSelection() {
    for (var i = 0; i < _workers.length; i++) {
      _workers[i] = _workers[i].copyWith(isSelected: false);
    }
    _selectionMode = false;
    notifyListeners();
  }
}
