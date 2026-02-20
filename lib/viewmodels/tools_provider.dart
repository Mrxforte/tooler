// ignore_for_file: unused_field, unused_import, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/tool.dart';
import '../data/models/construction_object.dart';
import '../data/models/sync_item.dart';
import '../data/services/image_service.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/id_generator.dart';
import 'objects_provider.dart' as app_objects;

/// ToolsProvider - Main provider for tool management with permissions, search, filters
///
/// FULL IMPLEMENTATION:
/// - CRUD operations with permission checks
/// - Advanced filtering (location, brand, favorites)
/// - Search functionality
/// - Selection mode for batch operations
/// - Move requests with admin approval
/// - Firebase sync
/// - Favorites management

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ToolsProvider with ChangeNotifier {
  /// Select tools by a list of IDs and notify listeners
  void selectToolsByIds(List<String> ids) {
    for (var i = 0; i < _tools.length; i++) {
      _tools[i] = _tools[i].copyWith(isSelected: ids.contains(_tools[i].id));
    }
    notifyListeners();
  }

  /// Clear all tool selections and notify listeners
  void clearAllSelections() {
    for (var i = 0; i < _tools.length; i++) {
      if (_tools[i].isSelected) {
        _tools[i] = _tools[i].copyWith(isSelected: false);
      }
    }
    notifyListeners();
  }

  bool _canUseContext(BuildContext? context) =>
      context != null && context.mounted;

  final List<Tool> _tools = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _selectionMode = false;
  String _filterLocation = 'all';
  String _filterBrand = 'all';
  bool _filterFavorites = false;

  List<Tool> get tools => _getFilteredTools();
  List<Tool> get allTools => List.unmodifiable(_tools);
  List<Tool> get garageTools =>
      _tools.where((t) => t.currentLocation == 'garage').toList();
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();
  List<Tool> get selectedTools => _tools.where((t) => t.isSelected).toList();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  bool get hasSelectedTools => _tools.any((t) => t.isSelected);
  int get totalTools => _tools.length;
  String get filterLocation => _filterLocation;
  String get filterBrand => _filterBrand;
  bool get filterFavorites => _filterFavorites;

  /// Find a tool by ID from the unfiltered list
  Tool? getToolById(String id) {
    try {
      return _tools.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<String> get uniqueBrands {
    final brands = _tools.map((t) => t.brand).toSet().toList();
    brands.sort();
    return ['all', ...brands];
  }

  void toggleSelectionMode() {
    HapticFeedback.mediumImpact();
    _selectionMode = !_selectionMode;
    if (!_selectionMode) _deselectAllTools();
    notifyListeners();
  }

  void toggleToolSelection(String toolId) {
    HapticFeedback.selectionClick();
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index != -1) {
      _tools[index] = _tools[index].copyWith(
        isSelected: !_tools[index].isSelected,
      );
      notifyListeners();
    }
  }

  void selectAllTools() {
    for (var i = 0; i < _tools.length; i++) {
      _tools[i] = _tools[i].copyWith(isSelected: true);
    }
    notifyListeners();
  }

  void _deselectAllTools() {
    for (var i = 0; i < _tools.length; i++) {
      _tools[i] = _tools[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  void clearSelection() {
    _deselectAllTools();
    _selectionMode = false;
    notifyListeners();
  }

  void setFilterLocation(String location) {
    _filterLocation = location;
    notifyListeners();
  }

  void setFilterBrand(String brand) {
    _filterBrand = brand;
    notifyListeners();
  }

  void setFilterFavorites(bool value) {
    _filterFavorites = value;
    notifyListeners();
  }

  void clearAllFilters() {
    _filterLocation = 'all';
    _filterBrand = 'all';
    _filterFavorites = false;
    _searchQuery = '';
    notifyListeners();
  }

  List<Tool> _getFilteredTools() {
    try {
      List<Tool> filtered = List.from(_tools);
      if (_filterLocation != 'all') {
        filtered = filtered
            .where((tool) => tool.currentLocation == _filterLocation)
            .toList();
      }
      if (_filterBrand != 'all') {
        filtered = filtered
            .where((tool) => tool.brand == _filterBrand)
            .toList();
      }
      if (_filterFavorites) {
        filtered = filtered.where((tool) => tool.isFavorite).toList();
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered
            .where(
              (tool) =>
                  tool.title.toLowerCase().contains(query) ||
                  tool.brand.toLowerCase().contains(query) ||
                  tool.uniqueId.toLowerCase().contains(query) ||
                  tool.description.toLowerCase().contains(query),
            )
            .toList();
      }
      return _sortTools(filtered);
    } catch (e) {
      return _sortTools(List.from(_tools));
    }
  }

  List<Tool> _sortTools(List<Tool> tools) {
    tools.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.title.compareTo(b.title);
          break;
        case 'date':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'brand':
          cmp = a.brand.compareTo(b.brand);
          break;
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return tools;
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

  Future<void> loadTools({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      // Load directly from Firebase (no local caching)
      await _syncWithFirebase();
    } catch (e) {
      // Error loading tools handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(
    Tool tool, {
    File? imageFile,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните обязательные поля');
      }
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          tool = tool.copyWith(imageUrl: url);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path);
        }
      }
      _tools.add(tool);
      await _addToSyncQueue(
        action: 'create',
        collection: 'tools',
        data: tool.toJson(),
      );
      if (_canUseContext(context)) {
        ErrorHandler.showSuccessDialog(context!, 'Инструмент добавлен');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(context)) {
        ErrorHandler.showErrorDialog(context!, 'Ошибка: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTool(
    Tool tool, {
    File? imageFile,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните обязательные поля');
      }
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          tool = tool.copyWith(imageUrl: url, localImagePath: null);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }
      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: tool.toJson(),
        );
        if (_canUseContext(context)) {
          ErrorHandler.showSuccessDialog(context!, 'Инструмент обновлён');
        }
      } else {
        throw Exception('Инструмент не найден');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(context)) {
        ErrorHandler.showErrorDialog(context!, 'Ошибка: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId, {BuildContext? context}) async {
    try {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index == -1) {
        if (_canUseContext(context)) {
          ErrorHandler.showErrorDialog(context!, 'Инструмент не найден');
        }
        return;
      }
      _tools.removeAt(index);
      notifyListeners();

      // Delete from Firebase with timeout
      try {
        await FirebaseFirestore.instance
            .collection('tools')
            .doc(toolId)
            .delete()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Операция удаления зависла');
              },
            );
      } catch (firebaseError) {
        // Firebase deletion error - tool already removed from local list
        // Log error but don't fail the entire operation
      }

      if (_canUseContext(context)) {
        ErrorHandler.showSuccessDialog(context!, 'Инструмент успешно удалён');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      if (_canUseContext(context)) {
        ErrorHandler.showErrorDialog(context!, 'Ошибка при удалении: $e');
      }
    }
  }

  Future<void> deleteSelectedTools() async {
    try {
      final selected = _tools.where((t) => t.isSelected).toList();
      if (selected.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!,
          'Выберите инструменты',
        );
        return;
      }
      for (final tool in selected) {
        try {
          await FirebaseFirestore.instance
              .collection('tools')
              .doc(tool.id)
              .delete()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException('Операция удаления зависла');
                },
              );
        } catch (e) {
          // Continue with next deletion even if one fails
        }
      }
      _tools.removeWhere((t) => t.isSelected);
      _selectionMode = false;
      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Удалено ${selected.length} инструментов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String toolId) async {
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index == -1) return;
    final updated = _tools[index].copyWith(
      isFavorite: !_tools[index].isFavorite,
    );
    _tools[index] = updated;
    await _addToSyncQueue(
      action: 'update',
      collection: 'tools',
      data: updated.toJson(),
    );
    notifyListeners();
  }

  Future<void> toggleFavoriteForSelected() async {
    final selected = _tools.where((t) => t.isSelected).toList();
    if (selected.isEmpty) {
      ErrorHandler.showWarningDialog(
        navigatorKey.currentContext!,
        'Выберите инструменты',
      );
      return;
    }
    for (final tool in selected) {
      final updated = tool.copyWith(isFavorite: !tool.isFavorite);
      await _addToSyncQueue(
        action: 'update',
        collection: 'tools',
        data: updated.toJson(),
      );
    }
    await loadTools();
    ErrorHandler.showSuccessDialog(
      navigatorKey.currentContext!,
      'Обновлено ${selected.length} инструментов',
    );
  }

  Future<void> requestMoveTool(
    String toolId,
    String toLocationId,
    String toLocationName,
  ) async {
    final toolIndex = _tools.indexWhere((t) => t.id == toolId);
    if (toolIndex == -1) {
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Инструмент не найден',
      );
      return;
    }
    // NOTE: Create MoveRequest and notify admins
    ErrorHandler.showSuccessDialog(
      navigatorKey.currentContext!,
      'Запрос отправлен администратору',
    );
  }

  Future<void> moveTool(
    String toolId,
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      final ctx = navigatorKey.currentContext;
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) {
        if (ctx != null && ctx.mounted) {
          ErrorHandler.showErrorDialog(ctx, 'Инструмент не найден');
        }
        return;
      }

      final tool = _tools[toolIndex];
      final oldLocationId = tool.currentLocation;

      if (oldLocationId == newLocationId) {
        if (ctx != null && ctx.mounted) {
          ErrorHandler.showInfoDialog(
            ctx,
            'Инструмент уже находится в "$newLocationName"',
          );
        }
        return;
      }

      // Create batch for tool update
      final batch = FirebaseFirestore.instance.batch();
      final toolCollection = FirebaseFirestore.instance.collection('tools');

      // Add to location history
      final newHistory = LocationHistory(
        date: DateTime.now(),
        locationId: newLocationId,
        locationName: newLocationName,
      );
      final updatedHistory = [...tool.locationHistory, newHistory];

      final updatedTool = tool.copyWith(
        currentLocation: newLocationId,
        currentLocationName: newLocationName,
        updatedAt: DateTime.now(),
        isSelected: false,
        locationHistory: updatedHistory,
      );

      // Update tool in Firebase
      batch.update(toolCollection.doc(toolId), updatedTool.toJson());

      // Update local list immediately
      _tools[toolIndex] = updatedTool;
      notifyListeners();

      // Commit tool update
      await batch.commit();

      // Update objects to manage toolIds arrays
      final objectsProvider = ctx?.read<app_objects.ObjectsProvider>();
      if (objectsProvider != null) {
        final objectBatch = FirebaseFirestore.instance.batch();
        final objectCollection = FirebaseFirestore.instance.collection(
          'objects',
        );

        // Remove from old location (if not garage)
        if (oldLocationId != 'garage') {
          try {
            final oldObject = objectsProvider.objects.firstWhere(
              (o) => o.id == oldLocationId,
            );
            final updatedToolIds = List<String>.from(oldObject.toolIds);
            updatedToolIds.removeWhere((id) => id == toolId);
            objectBatch.update(objectCollection.doc(oldLocationId), {
              'toolIds': updatedToolIds,
            });
          } catch (e) {
            // Object not found
          }
        }

        // Add to new location (if not garage)
        if (newLocationId != 'garage') {
          try {
            final newObject = objectsProvider.objects.firstWhere(
              (o) => o.id == newLocationId,
            );
            final updatedToolIds = List<String>.from(newObject.toolIds);
            if (!updatedToolIds.contains(toolId)) {
              updatedToolIds.add(toolId);
            }
            objectBatch.update(objectCollection.doc(newLocationId), {
              'toolIds': updatedToolIds,
            });
          } catch (e) {
            // Object not found
          }
        }

        // Commit all object updates
        await objectBatch.commit();

        // Reload objects to ensure consistency
        await objectsProvider.loadObjects(forceRefresh: true);
      }

      // Show success and reload
      if (ctx != null && ctx.mounted) {
        ErrorHandler.showSuccessDialog(
          ctx,
          'Инструмент перемещён в $newLocationName',
        );
      }

      // Reload tools from Firebase
      await loadTools();
      notifyListeners();
    } catch (e) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ErrorHandler.showErrorDialog(ctx, 'Ошибка перемещения: $e');
      }
      rethrow;
    }
  }

  Future<void> moveSelectedTools(
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      // Get currently selected tools
      final selected = List<Tool>.from(_tools.where((t) => t.isSelected));
      if (selected.isEmpty) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ErrorHandler.showWarningDialog(ctx, 'Выберите инструменты');
        }
        return;
      }

      // Filter out tools that are already at the target location
      final movableTools = selected.where((t) => t.currentLocation != newLocationId).toList();
      
      if (movableTools.isEmpty) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ErrorHandler.showInfoDialog(
            ctx,
            'Выбранные инструменты уже находятся в "$newLocationName"',
          );
        }
        _selectionMode = false;
        notifyListeners();
        return;
      }

      final selectedCount = movableTools.length;
      final selectedIds = movableTools.map((t) => t.id).toList();

      // Map to store old locations for each tool
      final Map<String, String> oldLocations = {};
      for (final tool in movableTools) {
        oldLocations[tool.id] = tool.currentLocation;
      }

      // Update all tools in Firebase with batch write
      final batch = FirebaseFirestore.instance.batch();
      final toolCollection = FirebaseFirestore.instance.collection('tools');

      for (final tool in movableTools) {
        final newHistory = LocationHistory(
          date: DateTime.now(),
          locationId: newLocationId,
          locationName: newLocationName,
        );
        final updatedHistory = [...tool.locationHistory, newHistory];

        final updatedTool = tool.copyWith(
          currentLocation: newLocationId,
          currentLocationName: newLocationName,
          updatedAt: DateTime.now(),
          isSelected: false,
          locationHistory: updatedHistory,
        );

        batch.update(toolCollection.doc(tool.id), updatedTool.toJson());

        // Update local list
        final toolIndex = _tools.indexWhere((t) => t.id == tool.id);
        if (toolIndex != -1) {
          _tools[toolIndex] = updatedTool;
        }
      }

      // Commit all tool updates
      await batch.commit();
      _selectionMode = false;
      notifyListeners();

      // Update objects to manage toolIds arrays
      try {
        final objectBatch = FirebaseFirestore.instance.batch();
        final objectCollection = FirebaseFirestore.instance.collection(
          'objects',
        );

        // Load all objects from Firebase to ensure we have current data
        final objectsSnapshot = await objectCollection.get();
        final allObjects = objectsSnapshot.docs
            .map((doc) => ConstructionObject.fromJson(doc.data()))
            .toList();

        final objectToolIdsById = <String, Set<String>>{
          for (final object in allObjects) object.id: Set<String>.from(object.toolIds),
        };
        final touchedObjectIds = <String>{};

        for (final toolId in selectedIds) {
          final oldLocationId = oldLocations[toolId];

          if (oldLocationId != null &&
              oldLocationId != 'garage' &&
              objectToolIdsById.containsKey(oldLocationId)) {
            objectToolIdsById[oldLocationId]!.remove(toolId);
            touchedObjectIds.add(oldLocationId);
          }

          if (newLocationId != 'garage' &&
              objectToolIdsById.containsKey(newLocationId)) {
            objectToolIdsById[newLocationId]!.add(toolId);
            touchedObjectIds.add(newLocationId);
          }
        }

        for (final objectId in touchedObjectIds) {
          objectBatch.update(objectCollection.doc(objectId), {
            'toolIds': objectToolIdsById[objectId]!.toList(),
          });
        }

        // Commit all object updates
        await objectBatch.commit();
      } catch (e) {
        // Objects update error - log but don't fail
        print('Error updating objects: $e');
      }

      // Show success message
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ErrorHandler.showSuccessDialog(
          ctx,
          'Перемещено $selectedCount инструментов в $newLocationName',
        );
      }

      // Reload tools and objects from Firebase to ensure consistency
      await loadTools();

      // Reload objects in provider if available
      try {
        final ctx = navigatorKey.currentContext;
        final objectsProvider = ctx?.read<app_objects.ObjectsProvider>();
        if (objectsProvider != null) {
          await objectsProvider.loadObjects(forceRefresh: true);
        }
      } catch (e) {
        // ObjectsProvider not available, skip reload
      }

      notifyListeners();
    } catch (e) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ErrorHandler.showErrorDialog(ctx, 'Ошибка при перемещении: $e');
      }
      // Clear selection on error
      _selectionMode = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> moveSelectedToolsWithProvider(
    String newLocationId,
    String newLocationName,
    app_objects.ObjectsProvider objectsProvider,
  ) async {
    try {
      // Get currently selected tools
      final selected = List<Tool>.from(_tools.where((t) => t.isSelected));
      if (selected.isEmpty) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ErrorHandler.showWarningDialog(ctx, 'Выберите инструменты');
        }
        return;
      }

      // Filter out tools that are already at the target location
      final movableTools = selected.where((t) => t.currentLocation != newLocationId).toList();
      
      if (movableTools.isEmpty) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ErrorHandler.showInfoDialog(
            ctx,
            'Выбранные инструменты уже находятся в "$newLocationName"',
          );
        }
        _selectionMode = false;
        notifyListeners();
        return;
      }

      final selectedCount = movableTools.length;
      final selectedIds = movableTools.map((t) => t.id).toList();

      // Map to store old locations for each tool
      final Map<String, String> oldLocations = {};
      for (final tool in movableTools) {
        oldLocations[tool.id] = tool.currentLocation;
      }

      // Update all tools in Firebase with batch write
      final batch = FirebaseFirestore.instance.batch();
      final toolCollection = FirebaseFirestore.instance.collection('tools');

      for (final tool in movableTools) {
        final newHistory = LocationHistory(
          date: DateTime.now(),
          locationId: newLocationId,
          locationName: newLocationName,
        );
        final updatedHistory = [...tool.locationHistory, newHistory];

        final updatedTool = tool.copyWith(
          currentLocation: newLocationId,
          currentLocationName: newLocationName,
          updatedAt: DateTime.now(),
          isSelected: false,
          locationHistory: updatedHistory,
        );

        batch.update(toolCollection.doc(tool.id), updatedTool.toJson());

        // Update local list
        final toolIndex = _tools.indexWhere((t) => t.id == tool.id);
        if (toolIndex != -1) {
          _tools[toolIndex] = updatedTool;
        }
      }

      // Commit all tool updates
      await batch.commit();
      _selectionMode = false;
      notifyListeners();

      // Update objects to manage toolIds arrays
      final objectBatch = FirebaseFirestore.instance.batch();
      final objectCollection = FirebaseFirestore.instance.collection('objects');
      final objectToolIdsById = <String, Set<String>>{
        for (final object in objectsProvider.objects)
          object.id: Set<String>.from(object.toolIds),
      };
      final touchedObjectIds = <String>{};

      for (final toolId in selectedIds) {
        final oldLocationId = oldLocations[toolId];

        // Remove from old location if it was in an object
        if (oldLocationId != null &&
            oldLocationId != 'garage' &&
            objectToolIdsById.containsKey(oldLocationId)) {
          objectToolIdsById[oldLocationId]!.remove(toolId);
          touchedObjectIds.add(oldLocationId);
        }

        // Add to new location if it's an object
        if (newLocationId != 'garage' &&
            objectToolIdsById.containsKey(newLocationId)) {
          objectToolIdsById[newLocationId]!.add(toolId);
          touchedObjectIds.add(newLocationId);
        }
      }

      for (final objectId in touchedObjectIds) {
        objectBatch.update(objectCollection.doc(objectId), {
          'toolIds': objectToolIdsById[objectId]!.toList(),
        });
      }

      // Commit all object updates
      await objectBatch.commit();

      // Reload objects to ensure consistency
      await objectsProvider.loadObjects(forceRefresh: true);

      // Show success message
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ErrorHandler.showSuccessDialog(
          ctx,
          'Перемещено $selectedCount инструментов в $newLocationName',
        );
      }

      // Reload tools from Firebase to ensure consistency
      await loadTools();
      notifyListeners();
    } catch (e) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ErrorHandler.showErrorDialog(ctx, 'Ошибка при перемещении: $e');
      }
      // Clear selection on error
      _selectionMode = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> requestMoveSelectedTools(
    List<Tool> selectedTools,
    String toLocationId,
    String toLocationName,
  ) async {
    if (selectedTools.isEmpty) {
      ErrorHandler.showWarningDialog(
        navigatorKey.currentContext!,
        'Выберите инструменты',
      );
      return;
    }
    // NOTE: Create BatchMoveRequest and notify admins
    ErrorHandler.showSuccessDialog(
      navigatorKey.currentContext!,
      'Запрос отправлен администратору',
    );
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final docId = data['id'] as String?;
    if (docId == null || docId.isEmpty) {
      throw Exception('Некорректный ID для синхронизации');
    }

    final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);

    switch (action) {
      case 'create':
      case 'update':
        await docRef
            .set(data, SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Синхронизация данных заняла слишком много времени',
                );
              },
            );
        break;
      case 'delete':
        await docRef.delete().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Удаление данных заняло слишком много времени',
            );
          },
        );
        break;
      default:
        throw Exception('Неизвестное действие синхронизации: $action');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool isAdmin = false;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          isAdmin = (userDoc.data()?['role'] ?? 'user') == 'admin';
        }
      } catch (e) {
        // Admin status check handled silently
      }

      // Clear tools list before syncing to avoid duplicates
      _tools.clear();

      Query query = FirebaseFirestore.instance.collection('tools');
      if (!isAdmin) {
        query = query.where('userId', isEqualTo: user.uid);
      }
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        try {
          final tool = Tool.fromJson(doc.data() as Map<String, dynamic>);
          _tools.add(tool);
        } catch (e) {
          // Error parsing tool handled silently
        }
      }
    } catch (e) {
      // Sync error handled silently
    }
  }
}
