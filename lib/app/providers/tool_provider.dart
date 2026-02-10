import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/app/services/firebase_service.dart';
import 'package:tooler/app/services/local_db_service.dart';
import 'package:tooler/models/tool_model.dart';

class ToolProvider with ChangeNotifier {
  final LocalDbService _localDbService;
  final FirebaseService _firebaseService;

  List<Tool> _tools = [];
  List<Tool> _filteredTools = [];
  String _searchQuery = '';
  String? _categoryFilter;
  bool _favoritesOnly = false;
  bool _isLoading = false;

  ToolProvider()
      : _localDbService = LocalDbService(),
        _firebaseService = FirebaseService();

  List<Tool> get tools => _filteredTools;
  List<Tool> get allTools => _tools;
  bool get isLoading => _isLoading;
  bool get hasTools => _tools.isNotEmpty;

  Future<void> loadTools() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local database first
      _tools = await _localDbService.getAllTools();

      // Sync with Firebase if online
      await _syncWithFirebase();

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final firebaseTools = await _firebaseService.getTools();

      // Merge local and Firebase data
      for (final firebaseTool in firebaseTools) {
        final localIndex = _tools.indexWhere((t) => t.id == firebaseTool.id);

        if (localIndex == -1) {
          // Tool exists only in Firebase, add locally
          await _localDbService.saveTool(firebaseTool);
          _tools.add(firebaseTool);
        } else {
          // Resolve conflicts (Firebase wins for now)
          if (firebaseTool.updatedAt.isAfter(_tools[localIndex].updatedAt)) {
            await _localDbService.saveTool(firebaseTool);
            _tools[localIndex] = firebaseTool;
          }
        }
      }

      // Upload local changes to Firebase
      final unsyncedTools = _tools.where((t) => !t.isSynced).toList();
      for (final tool in unsyncedTools) {
        await _firebaseService.saveTool(tool);
        await _localDbService.updateToolSyncStatus(tool.id, true);
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> addTool(Tool tool) async {
    _tools.insert(0, tool);
    await _localDbService.saveTool(tool);

    // Try to sync with Firebase
    try {
      await _firebaseService.saveTool(tool);
      await _localDbService.updateToolSyncStatus(tool.id, true);
    } catch (e) {
      debugPrint('Failed to sync tool: $e');
    }

    _applyFilters();
    notifyListeners();
  }

  Future<void> updateTool(Tool tool) async {
    final index = _tools.indexWhere((t) => t.id == tool.id);
    if (index != -1) {
      _tools[index] = tool.copyWith(updatedAt: DateTime.now());
      await _localDbService.saveTool(_tools[index]);

      // Try to sync with Firebase
      try {
        await _firebaseService.saveTool(_tools[index]);
        await _localDbService.updateToolSyncStatus(tool.id, true);
      } catch (e) {
        debugPrint('Failed to sync tool update: $e');
      }

      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId) async {
    _tools.removeWhere((t) => t.id == toolId);
    await _localDbService.deleteTool(toolId);

    // Try to delete from Firebase
    try {
      await _firebaseService.deleteTool(toolId);
    } catch (e) {
      debugPrint('Failed to delete from Firebase: $e');
    }

    _applyFilters();
    notifyListeners();
  }

  Future<void> duplicateTool(String toolId) async {
    final original = _tools.firstWhere((t) => t.id == toolId);
    final duplicate = original.duplicate();
    await addTool(duplicate);
  }

  Future<void> toggleFavorite(String toolId) async {
    final tool = _tools.firstWhere((t) => t.id == toolId);
    final updated = tool.copyWith(isFavorite: !tool.isFavorite);
    await updateTool(updated);
  }

  Future<void> moveToolToProject(
      String toolId, String? projectId, String projectName) async {
    final tool = _tools.firstWhere((t) => t.id == toolId);

    if (tool.currentProjectId != projectId) {
      final updated = tool.copyWith(
        currentProjectId: projectId,
      );

      if (projectId != null) {
        updated.addLocationHistory(projectId, projectName);
      }

      await updateTool(updated);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _applyFilters();
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTools = _tools.where((tool) {
      bool matchesSearch = tool.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          tool.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.uniqueId.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesCategory =
          _categoryFilter == null || tool.category == _categoryFilter;
      bool matchesFavorites = !_favoritesOnly || tool.isFavorite;

      return matchesSearch && matchesCategory && matchesFavorites;
    }).toList();
  }

  List<Tool> getToolsByProject(String? projectId) {
    if (projectId == null) {
      return _tools.where((t) => t.currentProjectId == null).toList();
    }
    return _tools.where((t) => t.currentProjectId == projectId).toList();
  }

  List<String> getCategories() {
    return _tools.map((t) => t.category).toSet().toList();
  }

  Tool getToolById(String id) {
    return _tools.firstWhere((t) => t.id == id);
  }
}
