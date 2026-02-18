// ignore_for_file: unused_field

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/construction_object.dart';
import '../data/models/sync_item.dart';
import '../data/repositories/local_database.dart';
import '../data/services/image_service.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart' as app_auth;

/// ObjectsProvider - Provider for construction objects management
/// 
/// FULL IMPLEMENTATION:
/// - CRUD operations with permission checks  
/// - Search and sort functionality
/// - Selection mode
/// - Favorites for objects
/// - Firebase sync

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ObjectsProvider with ChangeNotifier {
  List<ConstructionObject> _objects = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _selectionMode = false;

  List<ConstructionObject> get objects => _getFilteredObjects();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  List<ConstructionObject> get selectedObjects =>
      _objects.where((o) => o.isSelected).toList();
  bool get hasSelectedObjects => _objects.any((o) => o.isSelected);
  int get totalObjects => _objects.length;
  // NEW: Favorites
  List<ConstructionObject> get favoriteObjects => _objects.where((o) => o.isFavorite).toList();

  void toggleSelectionMode() {
    HapticFeedback.mediumImpact();
    _selectionMode = !_selectionMode;
    if (!_selectionMode) _deselectAllObjects();
    notifyListeners();
  }
  void toggleObjectSelection(String objectId) {
    HapticFeedback.selectionClick();
    final index = _objects.indexWhere((o) => o.id == objectId);
    if (index != -1) {
      _objects[index] =
          _objects[index].copyWith(isSelected: !_objects[index].isSelected);
      notifyListeners();
    }
  }
  void selectAllObjects() {
    for (var i = 0; i < _objects.length; i++) {
      _objects[i] = _objects[i].copyWith(isSelected: true);
    }
    notifyListeners();
  }
  void _deselectAllObjects() {
    for (var i = 0; i < _objects.length; i++) {
      _objects[i] = _objects[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  // NEW: Toggle favorite for object
  Future<void> toggleFavorite(String objectId) async {
    final index = _objects.indexWhere((o) => o.id == objectId);
    if (index == -1) return;
    final updated = _objects[index].copyWith(isFavorite: !_objects[index].isFavorite);
    _objects[index] = updated;
    await LocalDatabase.objects.put(updated.id, updated);
    await _addToSyncQueue(action: 'update', collection: 'objects', data: updated.toJson());
    notifyListeners();
  }

  Future<void> toggleFavoriteForSelected() async {
    final selected = _objects.where((o) => o.isSelected).toList();
    for (final obj in selected) {
      final updated = obj.copyWith(isFavorite: !obj.isFavorite);
      await LocalDatabase.objects.put(updated.id, updated);
      await _addToSyncQueue(action: 'update', collection: 'objects', data: updated.toJson());
    }
    await loadObjects();
    notifyListeners();
  }

  List<ConstructionObject> _getFilteredObjects() {
    if (_searchQuery.isEmpty) return _sortObjects(List.from(_objects));
    final q = _searchQuery.toLowerCase();
    return _sortObjects(_objects
        .where((o) =>
            o.name.toLowerCase().contains(q) ||
            o.description.toLowerCase().contains(q))
        .toList());
  }

  List<ConstructionObject> _sortObjects(List<ConstructionObject> list) {
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'date':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'toolCount':
          cmp = a.toolIds.length.compareTo(b.toolIds.length);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  void setSort(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  Future<void> loadObjects({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      await LocalDatabase.init();
      final cached = LocalDatabase.objects.values.toList();
      if (cached.isNotEmpty) _objects = cached.whereType<ConstructionObject>().toList();
      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) {
        await _syncWithFirebase();
      }
    } catch (e) {
      // Error loading objects handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    final auth = Provider.of<app_auth.AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на добавление объектов');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (obj.name.isEmpty) throw Exception('Введите название');
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          obj = obj.copyWith(imageUrl: url);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path);
        }
      }
      _objects.add(obj);
      await LocalDatabase.objects.put(obj.id, obj);
      await _addToSyncQueue(action: 'create', collection: 'objects', data: obj.toJson());
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Объект добавлен');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObject(ConstructionObject obj, {File? imageFile}) async {
    final auth = Provider.of<app_auth.AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на редактирование объектов');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (obj.name.isEmpty) throw Exception('Введите название');
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          obj = obj.copyWith(imageUrl: url, localImagePath: null);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }
      final index = _objects.indexWhere((o) => o.id == obj.id);
      if (index == -1) {
        ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Объект не найден');
        return;
      }
      _objects[index] = obj;
      await LocalDatabase.objects.put(obj.id, obj);
      await _addToSyncQueue(action: 'update', collection: 'objects', data: obj.toJson());
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Объект обновлён');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId) async {
    final auth = Provider.of<app_auth.AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на удаление объектов');
      return;
    }
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index == -1) {
        ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Объект не найден');
        return;
      }
      _objects.removeAt(index);
      await LocalDatabase.objects.delete(objectId);
      await _addToSyncQueue(action: 'delete', collection: 'objects', data: {'id': objectId});
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Объект удалён');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedObjects() async {
    final auth = Provider.of<app_auth.AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на удаление объектов');
      return;
    }
    try {
      final selected = _objects.where((o) => o.isSelected).toList();
      if (selected.isEmpty) {
        ErrorHandler.showWarningDialog(
            navigatorKey.currentContext!, 'Выберите объекты');
        return;
      }
      for (final obj in selected) {
        await LocalDatabase.objects.delete(obj.id);
        await _addToSyncQueue(action: 'delete', collection: 'objects', data: {'id': obj.id});
      }
      _objects.removeWhere((o) => o.isSelected);
      _selectionMode = false;
      ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!, 'Удалено ${selected.length} объектов');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _addToSyncQueue(
      {required String action,
      required String collection,
      required Map<String, dynamic> data}) async {
    try {
      await LocalDatabase.syncQueue.put('${DateTime.now().millisecondsSinceEpoch}',
          SyncItem(
              id: '${DateTime.now().millisecondsSinceEpoch}',
              action: action,
              collection: collection,
              data: data));
    } catch (e) {
      // Sync queue error handled silently
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Determine if admin
      bool isAdmin = false;
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          isAdmin = (userDoc.data()?['role'] ?? 'user') == 'admin';
        }
      } catch (e) {
        // Admin status check handled silently
      }

      // Admin sees all objects, others only their own
      Query query = FirebaseFirestore.instance.collection('objects');
      if (!isAdmin) {
        query = query.where('userId', isEqualTo: user.uid);
      }
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        try {
          final obj = ConstructionObject.fromJson(doc.data() as Map<String, dynamic>);
          _objects.add(obj);
          await LocalDatabase.objects.put(obj.id, obj);
        } catch (e) {
          // Error parsing object handled silently
        }
      }
    } catch (e) {
      // Objects sync error handled silently
    }
  }
}
