// ignore_for_file: unused_field, unused_import

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
  bool get allSelected =>
      _users.isNotEmpty && _users.every((u) => u.isSelected);

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
      _users[index] = _users[index].copyWith(
        isSelected: !_users[index].isSelected,
      );
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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      _users.clear();
      for (final doc in snapshot.docs) {
        try {
          final user = AppUser.fromFirestore(doc);
          _users.add(user);
        } catch (e) {
          debugPrint('Error parsing user ${doc.id}: $e');
        }
      }

      _users.sort((a, b) => a.email.compareTo(b.email));
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (!forceRefresh) {
        await loadUsers(forceRefresh: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CREATE ──────────────────────────────────────────────────────────────────

  Future<void> createUser({
    required String email,
    required String name,
    required String role,
    bool canMoveTools = false,
    bool canControlObjects = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc();
      final user = AppUser(
        uid: docRef.id,
        email: email.trim(),
        name: name.trim(),
        role: role,
        canMoveTools: canMoveTools,
        canControlObjects: canControlObjects,
      );
      await docRef.set(user.toFirestore());
      _users.add(user);
      _users.sort((a, b) => a.email.compareTo(b.email));
    } catch (e) {
      debugPrint('Create user error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  Future<void> editUser(AppUser updated) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updated.uid)
          .update(updated.toFirestore());
      final index = _users.indexWhere((u) => u.uid == updated.uid);
      if (index != -1) {
        _users[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Edit user error: $e');
      rethrow;
    }
  }

  Future<void> updateUserPermissions(
    String uid, {
    bool? canMoveTools,
    bool? canControlObjects,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (canMoveTools != null) updates['canMoveTools'] = canMoveTools;
      if (canControlObjects != null) {
        updates['canControlObjects'] = canControlObjects;
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);

        final index = _users.indexWhere((u) => u.uid == uid);
        if (index != -1) {
          _users[index] = _users[index].copyWith(
            canMoveTools: canMoveTools,
            canControlObjects: canControlObjects,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Update permissions error: $e');
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
      });

      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = _users[index].copyWith(role: newRole);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update role error: $e');
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
        debugPrint('Update selected role error: $e');
      }
    }
    notifyListeners();
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<void> deleteUser(
    String uid, {
    bool deleteFromAuth = false,
    bool deleteFromFirestore = true,
  }) async {
    try {
      if (deleteFromFirestore) {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }

      if (deleteFromAuth) {
        try {
          final functions = FirebaseFunctions.instance;
          await functions.httpsCallable('deleteUserCompletely').call({
            'uid': uid,
            'deleteFromAuth': true,
            'deleteFromFirestore': false,
          });
        } catch (e) {
          debugPrint('Auth delete error: $e');
          if (!deleteFromFirestore) rethrow;
        }
      }

      _users.removeWhere((u) => u.uid == uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete user error: $e');
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

  // ── SYNC (Auth → Firestore) ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> syncAuthUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('syncAuthUsersToFirestore')
          .call();

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
}
