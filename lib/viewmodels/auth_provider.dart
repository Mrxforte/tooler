import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/image_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  bool _isUnlocked = false;
  String? _userId;
  XFile? _profileImage;

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
  XFile? get profileImage => _profileImage;

  AuthProvider(this._prefs) {
    // Prefer the old 'user_id' key so existing Firestore data keeps loading.
    // Fall back to 'local_user_id', then generate a fresh one.
    _userId =
        _prefs.getString('user_id') ?? _prefs.getString('local_user_id');
    _userId ??= 'local_${DateTime.now().millisecondsSinceEpoch}';
    // Always persist under both keys so tools_provider can find it.
    _prefs.setString('user_id', _userId!);
    _prefs.setString('local_user_id', _userId!);
    if (_prefs.getString('secret_word') == null) {
      _prefs.setString('secret_word', _defaultSecretWord);
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> unlock(String word) async {
    final stored = _prefs.getString('secret_word') ?? _defaultSecretWord;
    if (word.trim() != stored) return 'Неверное секретное слово';
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {
      // Offline or Firebase unavailable — still allow local access
    }
    _isUnlocked = true;
    notifyListeners();
    return null;
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setProfileImage(XFile image) async {
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
