/// UsersProvider - User management for admin
/// Manages user roles, permissions, and admin operations

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/app_user.dart';

class UsersProvider with ChangeNotifier {
  final List<AppUser> _users = [];
  bool _isLoading = false;

  List<AppUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _users.clear();
      for (final doc in snapshot.docs) {
        _users.add(AppUser.fromFirestore(doc));
      }
      _users.sort((a, b) => a.email.compareTo(b.email));
    } catch (e) {
      // Silent error handling
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete();
      
      _users.removeWhere((u) => u.uid == uid);
      notifyListeners();
    } catch (e) {
      // Silent error handling
    }
  }
}
