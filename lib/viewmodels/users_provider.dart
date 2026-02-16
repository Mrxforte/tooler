/// UsersProvider - Extract from main.dart lines 2254-2302
/// Provider for admin user management

import 'package:flutter/material.dart';
import '../data/models/app_user.dart';

class UsersProvider with ChangeNotifier {
  // TODO: Extract full implementation from main.dart lines 2254-2302
  
  final List<AppUser> _users = [];
  bool _isLoading = false;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    throw UnimplementedError('Extract from main.dart lines 2254-2302');
  }

  Future<void> updateUserPermissions(String uid,
      {bool? canMoveTools, bool? canControlObjects}) async {
    throw UnimplementedError();
  }
}
