import 'package:flutter/material.dart';
import 'package:tooler/app/services/firebase_service.dart';
import 'package:tooler/app/services/local_db_service.dart';
import 'package:tooler/models/project_model.dart';

class ProjectProvider with ChangeNotifier {
  final LocalDbService _localDbService;
  final FirebaseService _firebaseService;

  List<Project> _projects = [];
  bool _isLoading = false;

  ProjectProvider()
      : _localDbService = LocalDbService(),
        _firebaseService = FirebaseService();

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get hasProjects => _projects.isNotEmpty;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local database
      _projects = await _localDbService.getAllProjects();

      // Sync with Firebase
      await _syncWithFirebase();
    } catch (e) {
      debugPrint('Error loading projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final firebaseProjects = await _firebaseService.getProjects();

      for (final firebaseProject in firebaseProjects) {
        final localIndex =
            _projects.indexWhere((p) => p.id == firebaseProject.id);

        if (localIndex == -1) {
          await _localDbService.saveProject(firebaseProject);
          _projects.add(firebaseProject);
        } else {
          if (firebaseProject.updatedAt
              .isAfter(_projects[localIndex].updatedAt)) {
            await _localDbService.saveProject(firebaseProject);
            _projects[localIndex] = firebaseProject;
          }
        }
      }

      // Upload local changes
      final unsyncedProjects = _projects.where((p) => !p.isSynced).toList();
      for (final project in unsyncedProjects) {
        await _firebaseService.saveProject(project);
        await _localDbService.updateProjectSyncStatus(project.id, true);
      }
    } catch (e) {
      debugPrint('Project sync error: $e');
    }
  }

  Future<void> addProject(Project project) async {
    _projects.add(project);
    await _localDbService.saveProject(project);

    try {
      await _firebaseService.saveProject(project);
      await _localDbService.updateProjectSyncStatus(project.id, true);
    } catch (e) {
      debugPrint('Failed to sync project: $e');
    }

    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project.copyWith(updatedAt: DateTime.now());
      await _localDbService.saveProject(_projects[index]);

      try {
        await _firebaseService.saveProject(_projects[index]);
        await _localDbService.updateProjectSyncStatus(project.id, true);
      } catch (e) {
        debugPrint('Failed to sync project update: $e');
      }

      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await _localDbService.deleteProject(projectId);

    try {
      await _firebaseService.deleteProject(projectId);
    } catch (e) {
      debugPrint('Failed to delete project from Firebase: $e');
    }

    notifyListeners();
  }

  Future<void> addToolToProject(String projectId, String toolId) async {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final updated = project.copyWith(toolIds: [...project.toolIds, toolId]);
    await updateProject(updated);
  }

  Future<void> removeToolFromProject(String projectId, String toolId) async {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final updatedToolIds = List<String>.from(project.toolIds)..remove(toolId);
    final updated = project.copyWith(toolIds: updatedToolIds);
    await updateProject(updated);
  }

  Future<void> moveMultipleTools(
      List<String> toolIds, String? fromProjectId, String toProjectId) async {
    for (final toolId in toolIds) {
      await removeToolFromProject(fromProjectId ?? '', toolId);
      await addToolToProject(toProjectId, toolId);
    }
    notifyListeners();
  }

  Project getProjectById(String id) {
    return _projects.firstWhere((p) => p.id == id);
  }
}
