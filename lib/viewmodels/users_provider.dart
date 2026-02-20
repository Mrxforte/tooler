// UsersProvider - User management for admin
// Manages user roles, permissions, and admin operations

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/app_user.dart';

class UsersProvider with ChangeNotifier {
  final List<AppUser> _users = [];
  bool _isLoading = false;
  bool _selectionMode = false;

  List<AppUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  List<AppUser> get selectedUsers => _users.where((u) => u.isSelected).toList();
  bool get hasSelectedUsers => _users.any((u) => u.isSelected);
  bool get allSelected => _users.isNotEmpty && _users.every((u) => u.isSelected);

  void toggleSelectionMode() {
    HapticFeedback.mediumImpact();
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      for (var i = 0; i < _users.length; i++) {
        _users[i] = _users[i].copyWith(isSelected: false);
      }
    }
    notifyListeners();
  }

  void toggleUserSelection(String uid) {
    HapticFeedback.selectionClick();
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isSelected: !_users[index].isSelected);
      notifyListeners();
    }
  }

  void selectAllUsers() {
    for (var i = 0; i < _users.length; i++) {
      _users[i] = _users[i].copyWith(isSelected: true);
    }
    notifyListeners();
  }

  void clearSelection() {
    for (var i = 0; i < _users.length; i++) {
      _users[i] = _users[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  Future<void> loadUsers({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Force clear cache on refresh
      if (forceRefresh) {
        _users.clear();
      }
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get(GetOptions(source: forceRefresh ? Source.server : Source.serverAndCache));
      
      _users.clear();
      for (final doc in snapshot.docs) {
        try {
          final user = AppUser.fromFirestore(doc);
          _users.add(user);
        } catch (e) {
          // Error parsing user document
          debugPrint('Error parsing user ${doc.id}: $e');
        }
      }
      
      _users.sort((a, b) => a.email.compareTo(b.email));
      
      // Auto-sync missing users from Firebase Auth
      await _syncMissingAuthUsers();
    } catch (e) {
      // Error loading users, retry with server source if needed
      debugPrint('Error loading users: $e');
      if (!forceRefresh) {
        await loadUsers(forceRefresh: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Syncs users from Firebase Auth to Firestore
  /// Creates missing Firestore documents for authenticated users
  Future<Map<String, dynamic>> syncAuthUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('syncAuthUsersToFirestore').call();
      
      // Reload users after sync
      await loadUsers(forceRefresh: true);
      
      debugPrint('Sync result: ${result.data}');
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Sync error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sync error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lists all users from Firebase Auth
  Future<List<Map<String, dynamic>>> listAuthUsers() async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('listAllAuthUsers').call();
      final users = result.data['users'] as List<dynamic>;
      return users.map((u) => Map<String, dynamic>.from(u as Map)).toList();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('List auth users error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('List auth users error: $e');
      rethrow;
    }
  }

  /// Auto-syncs missing users from Firebase Auth
  Future<void> _syncMissingAuthUsers() async {
    try {
      final authUsers = await listAuthUsers();
      final firestoreUids = _users.map((u) => u.uid).toSet();
      final missingUids = authUsers.where((u) => !firestoreUids.contains(u['uid'])).toList();
      
      if (missingUids.isNotEmpty) {
        debugPrint('Found ${missingUids.length} users missing from Firestore, syncing...');
        await syncAuthUsers();
      }
    } catch (e) {
      debugPrint('Error auto-syncing missing users: $e');
      // Silently fail - don't block the UI
    }
  }

  Future<void> updateUserPermissions(String uid,
      {bool? canMoveTools, bool? canControlObjects}) async {
    try {
      final updates = <String, dynamic>{};
      if (canMoveTools != null) updates['canMoveTools'] = canMoveTools;
      if (canControlObjects != null) updates['canControlObjects'] = canControlObjects;
      
      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);
        
        // Update local state
        final index = _users.indexWhere((u) => u.uid == uid);
        if (index != -1) {
          final user = _users[index];
          _users[index] = AppUser(
            uid: user.uid,
            email: user.email,
            role: user.role,
            canMoveTools: canMoveTools ?? user.canMoveTools,
            canControlObjects: canControlObjects ?? user.canControlObjects,
            createdAt: user.createdAt,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': newRole});
      
      // Update local state
      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        final user = _users[index];
        _users[index] = AppUser(
          uid: user.uid,
          email: user.email,
          role: newRole,
          canMoveTools: user.canMoveTools,
          canControlObjects: user.canControlObjects,
          createdAt: user.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> deleteUser(
    String uid, {
    bool deleteFromAuth = false,
    bool deleteFromFirestore = true,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('deleteUserCompletely').call({
        'uid': uid,
        'deleteFromAuth': deleteFromAuth,
        'deleteFromFirestore': deleteFromFirestore,
      });
      
      debugPrint('Delete result: ${result.data}');
      
      // Remove from local list
      _users.removeWhere((u) => u.uid == uid);
      notifyListeners();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Delete error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Delete error: $e');
      rethrow;
    }
  }

  Future<void> deleteSelectedUsers({
    bool deleteFromAuth = false,
    bool deleteFromFirestore = true,
  }) async {
    final selected = selectedUsers.toList();
    final errors = <String>[];
    
    for (final user in selected) {
      try {
        await deleteUser(
          user.uid,
          deleteFromAuth: deleteFromAuth,
          deleteFromFirestore: deleteFromFirestore,
        );
      } catch (e) {
        errors.add('${user.email}: $e');
        debugPrint('Error deleting user ${user.uid}: $e');
      }
    }
    
    _selectionMode = false;
    notifyListeners();
    
    if (errors.isNotEmpty) {
      debugPrint('Deletion errors: $errors');
    }
  }

  Future<void> updateSelectedUsersRole(String newRole) async {
    final selected = selectedUsers;
    for (final user in selected) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': newRole});
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = _users[index].copyWith(role: newRole);
        }
      } catch (e) {
        // Silent error handling
      }
    }
    notifyListeners();
  }
}
