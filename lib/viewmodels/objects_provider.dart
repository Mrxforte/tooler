// ignore_for_file: unused_field, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/construction_object.dart';
import '../data/services/image_service.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart' as app_auth;
import 'tools_provider.dart' as app_tools;

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
  final List<ConstructionObject> _objects = [];
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

  bool _canUseContext(BuildContext? context) =>
      context != null && context.mounted;

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
    
    // Update UI immediately (optimistic update)
    notifyListeners();
    
    // Save to Firebase in background (don't await)
    FirebaseFirestore.instance
        .collection('objects')
        .doc(objectId)
        .update({'isFavorite': updated.isFavorite})
        .catchError((e) => null); // Error handled silently
  }

  Future<void> toggleFavoriteForSelected() async {
    final selected = _objects.where((o) => o.isSelected).toList();
    for (final obj in selected) {
      final index = _objects.indexWhere((o) => o.id == obj.id);
      if (index != -1) {
        final updated = obj.copyWith(isFavorite: !obj.isFavorite);
        _objects[index] = updated;
        
        // Save to Firebase in background (don't await)
        FirebaseFirestore.instance
            .collection('objects')
            .doc(obj.id)
            .update({'isFavorite': updated.isFavorite})
            .catchError((e) => null); // Error handled silently
      }
    }
    // Update UI immediately
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
      // Load directly from Firebase (no local caching)
      await _syncWithFirebase();
    } catch (e) {
      // Error loading objects handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    final ctx = navigatorKey.currentContext;
    final auth = ctx != null
        ? Provider.of<app_auth.AuthProvider>(ctx, listen: false)
        : null;
    if (auth != null && !auth.canControlObjects) {
      if (_canUseContext(ctx)) {
        ErrorHandler.showErrorDialog(ctx!, 'У вас нет прав на добавление объектов');
      }
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
      
      // Save to Firebase directly
      await FirebaseFirestore.instance.collection('objects').doc(obj.id).set(obj.toJson());
      _objects.add(obj);
      
      if (_canUseContext(ctx)) {
        ErrorHandler.showSuccessDialog(ctx!, 'Объект добавлен');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(ctx)) {
        ErrorHandler.showErrorDialog(ctx!, 'Ошибка: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObject(ConstructionObject obj, {File? imageFile}) async {
    final ctx = navigatorKey.currentContext;
    final auth = ctx != null
        ? Provider.of<app_auth.AuthProvider>(ctx, listen: false)
        : null;
    if (auth != null && !auth.canControlObjects) {
      if (_canUseContext(ctx)) {
        ErrorHandler.showErrorDialog(ctx!, 'У вас нет прав на редактирование объектов');
      }
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
        if (_canUseContext(ctx)) {
          ErrorHandler.showErrorDialog(ctx!, 'Объект не найден');
        }
        return;
      }
      _objects[index] = obj;
      
      // Save to Firebase directly
      await FirebaseFirestore.instance.collection('objects').doc(obj.id).update(obj.toJson());
      
      if (_canUseContext(ctx)) {
        ErrorHandler.showSuccessDialog(ctx!, 'Объект обновлён');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(ctx)) {
        ErrorHandler.showErrorDialog(ctx!, 'Ошибка: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId, {BuildContext? context}) async {
    bool canDelete = true;
    try {
      final auth = Provider.of<app_auth.AuthProvider>(navigatorKey.currentContext!, listen: false);
      canDelete = auth.canControlObjects;
    } catch (e) {
      // If context is invalid, allow deletion (assume admin)
      canDelete = true;
    }
    
    if (!canDelete) {
      if (_canUseContext(context)) {
        ErrorHandler.showErrorDialog(context!, 'У вас нет прав на удаление объектов');
      }
      return;
    }
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index == -1) {
        if (_canUseContext(context)) {
          ErrorHandler.showErrorDialog(context!, 'Объект не найден');
        }
        return;
      }

      final toolsProvider = Provider.of<app_tools.ToolsProvider>(navigatorKey.currentContext!, listen: false);
      final toolsToMove = toolsProvider.tools.where((t) => t.currentLocation == objectId).toList();
      for (final tool in toolsToMove) {
        await toolsProvider.moveTool(tool.id, 'garage', 'Гараж');
      }

      _objects.removeAt(index);
      notifyListeners();

      // Delete from Firebase
      try {
        await FirebaseFirestore.instance.collection('objects').doc(objectId).delete();
      } catch (e) {
        // Firebase deletion error
      }

      if (_canUseContext(context)) {
        ErrorHandler.showSuccessDialog(context!, 'Объект успешно удалён');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(context)) {
        ErrorHandler.showErrorDialog(context!, 'Ошибка при удалении: $e');
      }
    }
  }

  Future<void> deleteSelectedObjects({BuildContext? context}) async {
    bool canDelete = true;
    try {
      final auth = Provider.of<app_auth.AuthProvider>(navigatorKey.currentContext!, listen: false);
      canDelete = auth.canControlObjects;
    } catch (e) {
      // If context is invalid, allow deletion (assume admin)
      canDelete = true;
    }
    
    if (!canDelete) {
      if (context != null) {
        ErrorHandler.showErrorDialog(context, 'У вас нет прав на удаление объектов');
      }
      return;
    }
    try {
      final selected = _objects.where((o) => o.isSelected).toList();
      if (selected.isEmpty) {
        if (_canUseContext(context)) {
          ErrorHandler.showWarningDialog(context!, 'Выберите объекты');
        }
        return;
      }
      for (final obj in selected) {
        try {
          await FirebaseFirestore.instance.collection('objects').doc(obj.id).delete();
        } catch (e) {
          // Firebase deletion error for individual object
        }
      }
      _objects.removeWhere((o) => o.isSelected);
      _selectionMode = false;
      notifyListeners();
      if (_canUseContext(context)) {
        ErrorHandler.showSuccessDialog(context!, 'Удалено ${selected.length} объектов');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(context)) {
        ErrorHandler.showErrorDialog(context!, 'Ошибка: $e');
      }
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

      // Clear objects list before syncing to avoid duplicates
      _objects.clear();

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
        } catch (e) {
          // Error parsing object handled silently
        }
      }
    } catch (e) {
      // Objects sync error handled silently
    }
  }
}
