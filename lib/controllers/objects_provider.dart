import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/construction_object.dart';
import '../models/sync_item.dart';
import '../services/local_database.dart';
import '../services/image_service.dart';
import '../services/error_handler.dart';
import '../utils/navigator_key.dart';

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

  void toggleSelectionMode() {
    try {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _deselectAllObjects();
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling selection mode: $e');
    }
  }

  void toggleObjectSelection(String objectId) {
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index != -1) {
        _objects[index] = _objects[index].copyWith(
          isSelected: !_objects[index].isSelected,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling object selection: $e');
    }
  }

  void selectAllObjects() {
    try {
      for (var i = 0; i < _objects.length; i++) {
        _objects[i] = _objects[i].copyWith(isSelected: true);
      }
      notifyListeners();
    } catch (e) {
      print('Error selecting all objects: $e');
    }
  }

  void _deselectAllObjects() {
    try {
      for (var i = 0; i < _objects.length; i++) {
        _objects[i] = _objects[i].copyWith(isSelected: false);
      }
      notifyListeners();
    } catch (e) {
      print('Error deselecting all objects: $e');
    }
  }

  List<ConstructionObject> _getFilteredObjects() {
    try {
      if (_searchQuery.isEmpty) {
        return _sortObjects(List.from(_objects));
      }

      final query = _searchQuery.toLowerCase();
      final filtered = _objects.where((obj) {
        return obj.name.toLowerCase().contains(query) ||
            obj.description.toLowerCase().contains(query);
      }).toList();

      return _sortObjects(filtered);
    } catch (e) {
      print('Error filtering objects: $e');
      return _sortObjects(List.from(_objects));
    }
  }

  List<ConstructionObject> _sortObjects(List<ConstructionObject> objects) {
    try {
      objects.sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'toolCount':
            comparison = a.toolIds.length.compareTo(b.toolIds.length);
            break;
          default:
            comparison = a.name.compareTo(b.name);
        }
        return _sortAscending ? comparison : -comparison;
      });

      return objects;
    } catch (e) {
      print('Error sorting objects: $e');
      return objects;
    }
  }

  void setSearchQuery(String query) {
    try {
      _searchQuery = query;
      notifyListeners();
    } catch (e) {
      print('Error setting search query: $e');
    }
  }

  void setSort(String sortBy, bool ascending) {
    try {
      _sortBy = sortBy;
      _sortAscending = ascending;
      notifyListeners();
    } catch (e) {
      print('Error setting sort: $e');
    }
  }

  Future<void> loadObjects({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();

      // Lazy loading
      final cachedObjects = LocalDatabase.objects.values.toList();
      if (cachedObjects.isNotEmpty) {
        _objects = cachedObjects.where((obj) => obj != null).toList();
      }

      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) {
        await _syncWithFirebase();
        await LocalDatabase.saveCacheTimestamp();
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      print('Error loading objects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (obj.name.isEmpty) {
        throw Exception('Название объекта обязательно');
      }

      // Upload image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj = obj.copyWith(imageUrl: imageUrl);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path);
        }
      }

      _objects.add(obj);
      await LocalDatabase.objects.put(obj.id, obj);

      await _addToSyncQueue(
        action: 'create',
        collection: 'objects',
        data: obj.toJson(),
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Объект успешно добавлен',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось добавить объект: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (obj.name.isEmpty) {
        throw Exception('Название объекта обязательно');
      }

      // Upload new image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj = obj.copyWith(imageUrl: imageUrl, localImagePath: null);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }

      final index = _objects.indexWhere((o) => o.id == obj.id);
      if (index == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Объект не найден',
        );
        return;
      }

      _objects[index] = obj;
      await LocalDatabase.objects.put(obj.id, obj);

      await _addToSyncQueue(
        action: 'update',
        collection: 'objects',
        data: obj.toJson(),
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Объект успешно обновлен',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось обновить объект: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId) async {
    try {
      final objectIndex = _objects.indexWhere((o) => o.id == objectId);
      if (objectIndex == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Объект не найден',
        );
        return;
      }

      _objects.removeAt(objectIndex);
      await LocalDatabase.objects.delete(objectId);

      await _addToSyncQueue(
        action: 'delete',
        collection: 'objects',
        data: {'id': objectId},
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Объект успешно удален',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить объект: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedObjects() async {
    try {
      final selectedObjects = _objects.where((o) => o.isSelected).toList();

      if (selectedObjects.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!,
          'Выберите объекты для удаления',
        );
        return;
      }

      for (final object in selectedObjects) {
        await LocalDatabase.objects.delete(object.id);
        await _addToSyncQueue(
          action: 'delete',
          collection: 'objects',
          data: {'id': object.id},
        );
      }

      _objects.removeWhere((o) => o.isSelected);
      _selectionMode = false;

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Удалено ${selectedObjects.length} объектов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить объекты: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final syncItem = SyncItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        action: action,
        collection: collection,
        data: data,
      );
      await LocalDatabase.syncQueue.put(syncItem.id, syncItem);
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Pull changes from Firebase
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('objects')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in snapshot.docs) {
          final objectData = doc.data();
          final object = ConstructionObject.fromJson({
            ...objectData,
            'id': doc.id,
          });
          await LocalDatabase.objects.put(object.id, object);
        }
      } catch (e) {
        print('Firebase sync error: $e');
      }
    } catch (e) {
      print('Objects sync error: $e');
    }
  }
}
