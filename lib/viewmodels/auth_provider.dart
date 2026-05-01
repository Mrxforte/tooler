import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/image_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  String? _userId;
  String? _username;
  String? _role;
  bool _isLoading = false;
  File? _profileImage;

  String? get userId => _userId;
  String? get username => _username;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userId != null;
  bool get isAdmin => _role == 'admin';
  bool get isBrigadir => _role == 'brigadir';
  bool get canMoveTools => isAdmin;
  bool get canControlObjects => isAdmin;
  bool get rememberMe => false;
  File? get profileImage => _profileImage;

  AuthProvider(this._prefs) {
    _userId = _prefs.getString('user_id');
    _username = _prefs.getString('username');
    _role = _prefs.getString('user_role');
  }

  /// Returns null on success, error message string on failure.
  Future<String?> register(
    String username,
    String code, {
    String? adminPhrase,
  }) async {
    final trimmedUser = username.trim();
    if (trimmedUser.isEmpty) return 'Введите имя пользователя';
    if (code.length != 8) return 'Код должен быть ровно 8 символов';

    _isLoading = true;
    notifyListeners();

    try {
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: trimmedUser)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return 'Имя пользователя уже занято';
      }

      final role =
          (adminPhrase?.trim() == 'admin123') ? 'admin' : 'user';

      final docRef = await FirebaseFirestore.instance.collection('users').add({
        'username': trimmedUser,
        'code': code,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _saveSession(docRef.id, trimmedUser, role);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Произошла ошибка. Попробуйте снова.';
    }
  }

  /// Returns null on success, error message string on failure.
  Future<String?> login(String username, String code) async {
    final trimmedUser = username.trim();
    if (trimmedUser.isEmpty) return 'Введите имя пользователя';
    if (code.isEmpty) return 'Введите код';

    _isLoading = true;
    notifyListeners();

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: trimmedUser)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return 'Пользователь не найден';
      }

      final doc = query.docs.first;
      final data = doc.data();

      if (data['code'] != code) {
        _isLoading = false;
        notifyListeners();
        return 'Неверный код';
      }

      final role = data['role'] as String? ?? 'user';
      await _saveSession(doc.id, trimmedUser, role);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Произошла ошибка. Попробуйте снова.';
    }
  }

  Future<void> _saveSession(
    String userId,
    String username,
    String role,
  ) async {
    _userId = userId;
    _username = username;
    _role = role;
    await _prefs.setString('user_id', userId);
    await _prefs.setString('username', username);
    await _prefs.setString('user_role', role);
  }

  Future<void> signOut() async {
    _userId = null;
    _username = null;
    _role = null;
    _profileImage = null;
    await _prefs.remove('user_id');
    await _prefs.remove('username');
    await _prefs.remove('user_role');
    notifyListeners();
  }

  Future<void> setProfileImage(File image) async {
    _profileImage = image;
    notifyListeners();
    if (_userId != null) {
      await ImageService.uploadImage(image, _userId!);
    }
  }

  Future<void> setRememberMe(bool value) async {}
}
