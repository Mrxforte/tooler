import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/image_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  bool _isUnlocked = false;
  String? _userId;
  File? _profileImage;

  static const _defaultSecretWord = 'admin123';

  String? get userId => _userId;
  String? get username => 'Admin';
  String? get role => 'admin';
  bool get isLoading => false;
  bool get isLoggedIn => _isUnlocked;
  bool get isAdmin => true;
  bool get isBrigadir => false;
  bool get canMoveTools => true;
  bool get canControlObjects => true;
  bool get rememberMe => false;
  File? get profileImage => _profileImage;

  AuthProvider(this._prefs) {
    _userId = _prefs.getString('local_user_id');
    if (_userId == null) {
      _userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _prefs.setString('local_user_id', _userId!);
    }
    if (_prefs.getString('secret_word') == null) {
      _prefs.setString('secret_word', _defaultSecretWord);
    }
  }

  /// Returns null on success, error message on failure.
  String? unlock(String word) {
    final stored = _prefs.getString('secret_word') ?? _defaultSecretWord;
    if (word.trim() == stored) {
      _isUnlocked = true;
      notifyListeners();
      return null;
    }
    return 'Неверное секретное слово';
  }

  /// Returns null on success, error message on failure.
  String? changeSecretWord(String currentWord, String newWord) {
    final stored = _prefs.getString('secret_word') ?? _defaultSecretWord;
    if (currentWord.trim() != stored) return 'Неверное текущее слово';
    if (newWord.trim().isEmpty) return 'Новое слово не может быть пустым';
    _prefs.setString('secret_word', newWord.trim());
    notifyListeners();
    return null;
  }

  Future<void> signOut() async {
    _isUnlocked = false;
    _profileImage = null;
    notifyListeners();
  }

  Future<void> setProfileImage(File image) async {
    _profileImage = image;
    notifyListeners();
    if (_userId != null) {
      await ImageService.uploadImage(image, _userId!);
    }
  }

  // Kept for backward compatibility
  Future<String?> login(String username, String code) async => null;
  Future<String?> register(
    String username,
    String code, {
    String? adminPhrase,
  }) async => null;
  Future<void> setRememberMe(bool value) async {}
}
