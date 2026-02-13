import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/tool.dart';
import '../models/location_history.dart';
import '../models/sync_item.dart';
import '../services/local_database.dart';
import '../services/image_service.dart';
import '../services/error_handler.dart';
import '../utils/navigator_key.dart';

class ToolsProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _selectionMode = false;

  // Filter properties
  String _filterLocation = 'all';
  String _filterBrand = 'all';
  bool _filterFavorites = false;

  List<Tool> get tools => _getFilteredTools();
  List<Tool> get garageTools =>
      _tools.where((t) => t.currentLocation == 'garage').toList();
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();
  List<Tool> get selectedTools => _tools.where((t) => t.isSelected).toList();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  bool get hasSelectedTools => _tools.any((t) => t.isSelected);
  int get totalTools => _tools.length;

  // Filter getters
  String get filterLocation => _filterLocation;
  String get filterBrand => _filterBrand;
  bool get filterFavorites => _filterFavorites;

  // Get unique brands for filter
  List<String> get uniqueBrands {
    final brands = _tools.map((t) => t.brand).toSet().toList();
    brands.sort();
    return ['all', ...brands];
  }

  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      _deselectAllTools();
    }
    notifyListeners();
  }

  void toggleToolSelection(String toolId) {
    try {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = _tools[index].copyWith(
          isSelected: !_tools[index].isSelected,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling tool selection: $e');
    }
  }

  void selectAllTools() {
    try {
      for (var i = 0; i < _tools.length; i++) {
        _tools[i] = _tools[i].copyWith(isSelected: true);
      }
      notifyListeners();
    } catch (e) {
      print('Error selecting all tools: $e');
    }
  }

  void _deselectAllTools() {
    try {
      for (var i = 0; i < _tools.length; i++) {
        _tools[i] = _tools[i].copyWith(isSelected: false);
      }
      notifyListeners();
    } catch (e) {
      print('Error deselecting all tools: $e');
    }
  }

  // Filter methods
  void setFilterLocation(String location) {
    try {
      _filterLocation = location;
      notifyListeners();
    } catch (e) {
      print('Error setting filter location: $e');
    }
  }

  void setFilterBrand(String brand) {
    try {
      _filterBrand = brand;
      notifyListeners();
    } catch (e) {
      print('Error setting filter brand: $e');
    }
  }

  void setFilterFavorites(bool value) {
    try {
      _filterFavorites = value;
      notifyListeners();
    } catch (e) {
      print('Error setting filter favorites: $e');
    }
  }

  void clearAllFilters() {
    try {
      _filterLocation = 'all';
      _filterBrand = 'all';
      _filterFavorites = false;
      _searchQuery = '';
      notifyListeners();
    } catch (e) {
      print('Error clearing filters: $e');
    }
  }

  List<Tool> _getFilteredTools() {
    try {
      List<Tool> filtered = List.from(_tools);

      // Apply location filter
      if (_filterLocation != 'all') {
        filtered = filtered
            .where((tool) => tool.currentLocation == _filterLocation)
            .toList();
      }

      // Apply brand filter
      if (_filterBrand != 'all') {
        filtered = filtered
            .where((tool) => tool.brand == _filterBrand)
            .toList();
      }

      // Apply favorites filter
      if (_filterFavorites) {
        filtered = filtered.where((tool) => tool.isFavorite).toList();
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((tool) {
          return tool.title.toLowerCase().contains(query) ||
              tool.brand.toLowerCase().contains(query) ||
              tool.uniqueId.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query);
        }).toList();
      }

      return _sortTools(filtered);
    } catch (e) {
      print('Error filtering tools: $e');
      return _sortTools(List.from(_tools));
    }
  }

  List<Tool> _sortTools(List<Tool> tools) {
    try {
      tools.sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.title.compareTo(b.title);
            break;
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'brand':
            comparison = a.brand.compareTo(b.brand);
            break;
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }
        return _sortAscending ? comparison : -comparison;
      });

      return tools;
    } catch (e) {
      print('Error sorting tools: $e');
      return tools;
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

  Future<void> loadTools({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();

      // Lazy loading - show cached data first
      final cachedTools = LocalDatabase.tools.values.toList();
      if (cachedTools.isNotEmpty) {
        _tools = cachedTools.where((tool) => tool != null).toList();
      }

      // Then sync with Firebase in background
      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) {
        await _syncWithFirebase();
        await LocalDatabase.saveCacheTimestamp();
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      print('Error loading tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните все обязательные поля');
      }

      // Upload image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool = tool.copyWith(imageUrl: imageUrl);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path);
        }
      }

      _tools.add(tool);
      await LocalDatabase.tools.put(tool.id, tool);

      await _addToSyncQueue(
        action: 'create',
        collection: 'tools',
        data: tool.toJson(),
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext,
        'Инструмент успешно добавлен',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось добавить инструмент: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните все обязательные поля');
      }

      // Upload new image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool = tool.copyWith(imageUrl: imageUrl, localImagePath: null);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }

      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        await LocalDatabase.tools.put(tool.id, tool);

        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: tool.toJson(),
        );

        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext,
          'Инструмент успешно обновлен',
        );
      } else {
        throw Exception('Инструмент не найден');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось обновить инструмент: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext,
          'Инструмент не найден',
        );
        return;
      }

      _tools.removeAt(toolIndex);
      await LocalDatabase.tools.delete(toolId);

      await _addToSyncQueue(
        action: 'delete',
        collection: 'tools',
        data: {'id': toolId},
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext,
        'Инструмент успешно удален',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось удалить инструмент: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedTools() async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();

      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext,
          'Выберите инструменты для удаления',
        );
        return;
      }

      for (final tool in selectedTools) {
        await LocalDatabase.tools.delete(tool.id);
        await _addToSyncQueue(
          action: 'delete',
          collection: 'tools',
          data: {'id': tool.id},
        );
      }

      _tools.removeWhere((t) => t.isSelected);
      _selectionMode = false;

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext,
        'Удалено ${selectedTools.length} инструментов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось удалить инструменты: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateTool(Tool original) async {
    try {
      // Count how many copies already exist
      final copyCount =
          _tools
              .where(
                (t) =>
                    t.title.startsWith(original.title) &&
                    t.title.contains('Копия'),
              )
              .length +
          1;

      final newTool = original.duplicate(copyCount);
      await addTool(newTool);
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось дублировать инструмент: ${e.toString()}',
      );
    }
  }

  Future<void> moveTool(
    String toolId,
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext,
          'Инструмент не найден',
        );
        return;
      }

      final tool = _tools[toolIndex];
      final oldLocationId = tool.currentLocation;
      final oldLocationName = tool.currentLocationName;

      final updatedTool = tool.copyWith(
        locationHistory: [
          ...tool.locationHistory,
          LocationHistory(
            date: DateTime.now(),
            locationId: oldLocationId,
            locationName: oldLocationName,
          ),
        ],
        currentLocation: newLocationId,
        currentLocationName: newLocationName,
        updatedAt: DateTime.now(),
        isSelected: false,
      );

      await updateTool(updatedTool);

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext,
        'Инструмент перемещен в $newLocationName',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось переместить инструмент: ${e.toString()}',
      );
    }
  }

  Future<void> moveSelectedTools(
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();

      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext,
          'Выберите инструменты для перемещения',
        );
        return;
      }

      for (final tool in selectedTools) {
        final oldLocationId = tool.currentLocation;
        final oldLocationName = tool.currentLocationName;
        final updatedTool = tool.copyWith(
          locationHistory: [
            ...tool.locationHistory,
            LocationHistory(
              date: DateTime.now(),
              locationId: oldLocationId,
              locationName: oldLocationName,
            ),
          ],
          currentLocation: newLocationId,
          currentLocationName: newLocationName,
          updatedAt: DateTime.now(),
          isSelected: false,
        );

        await LocalDatabase.tools.put(updatedTool.id, updatedTool);
        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: updatedTool.toJson(),
        );
      }

      await loadTools();
      _selectionMode = false;

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext,
        'Перемещено ${selectedTools.length} инструментов в $newLocationName',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось переместить инструменты: ${e.toString()}',
      );
    }
  }

  Future<void> toggleFavorite(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) return;

      final tool = _tools[toolIndex];
      final updatedTool = tool.copyWith(isFavorite: !tool.isFavorite);
      
      // Update locally without showing dialog or loading state
      _tools[toolIndex] = updatedTool;
      await LocalDatabase.tools.put(updatedTool.id, updatedTool);
      
      // Add to sync queue
      await _addToSyncQueue(
        action: 'update',
        collection: 'tools',
        data: updatedTool.toJson(),
      );
      
      notifyListeners();
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось обновить статус избранного',
      );
    }
  }

  Future<void> toggleFavoriteForSelected() async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();
      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext,
          'Выберите инструменты',
        );
        return;
      }

      for (final tool in selectedTools) {
        final updatedTool = tool.copyWith(isFavorite: !tool.isFavorite);
        await LocalDatabase.tools.put(updatedTool.id, updatedTool);
        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: updatedTool.toJson(),
        );
      }

      await loadTools();
      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext,
        'Обновлено ${selectedTools.length} инструментов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext,
        'Не удалось обновить статус избранного',
      );
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

      final syncItems = LocalDatabase.syncQueue.values.toList();

      // Send local changes to Firebase
      for (final item in syncItems) {
        try {
          final docRef = FirebaseFirestore.instance
              .collection('tools')
              .doc(item.data['id'] as String);

          switch (item.action) {
            case 'create':
            case 'update':
              await docRef.set(item.data, SetOptions(merge: true));
              break;
            case 'delete':
              await docRef.delete();
              break;
          }

          await LocalDatabase.syncQueue.delete(item.id);
        } catch (e) {
          print('Error syncing item ${item.id}: $e');
        }
      }

      // Pull changes from Firebase
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('tools')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in snapshot.docs) {
          final toolData = doc.data();
          final tool = Tool.fromJson({...toolData, 'id': doc.id});
          await LocalDatabase.tools.put(tool.id, tool);
        }
      } catch (e) {
        print('Error pulling from Firebase: $e');
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}
