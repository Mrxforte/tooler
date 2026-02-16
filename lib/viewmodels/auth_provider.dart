// ignore_for_file: unused_field

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/image_service.dart';
import '../core/utils/error_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const String _adminSecret = 'your_admin_secret_phrase'; // TODO: Change to real secret

/// AuthProvider - Handles authentication, user permissions, role management
/// 
/// FULL IMPLEMENTATION:
/// - Firebase Auth integration
/// - Role-based permissions (admin, brigadir, user)
/// - Permission checks (canMoveTools, canControlObjects)
/// - Profile image management
/// - Remember me functionality

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  User? _user;
  bool _isLoading = false;
  bool _rememberMe = false;
  File? _profileImage;
  String? _role;
  bool _canMoveTools = false;
  bool _canControlObjects = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get rememberMe => _rememberMe;
  File? get profileImage => _profileImage;
  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isBrigadir => _role == 'brigadir';
  bool get canMoveTools => _canMoveTools || isAdmin;
  bool get canControlObjects => _canControlObjects || isAdmin;

  AuthProvider(this._prefs) {
    _rememberMe = _prefs.getBool('remember_me') ?? false;
    _initializeAuth();
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _role = null;
        _canMoveTools = false;
        _canControlObjects = false;
      }
      notifyListeners();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();
      final savedUser = _auth.currentUser;
      if (savedUser != null && _rememberMe) {
        _user = savedUser;
        await _fetchUserData(savedUser.uid);
      }
    } catch (e) {
      // Error handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _role = data['role'] ?? 'user';
        _canMoveTools = data['canMoveTools'] ?? false;
        _canControlObjects = data['canControlObjects'] ?? false;
      } else {
        // Create default user doc if missing
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _user!.email,
          'role': 'user',
          'canMoveTools': false,
          'canControlObjects': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _role = 'user';
        _canMoveTools = false;
        _canControlObjects = false;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _role = 'user';
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
      if (_user != null) await _fetchUserData(_user!.uid);
      if (_rememberMe) await _prefs.setString('saved_email', email);
      return true;
    } on FirebaseAuthException catch (e) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, ErrorHandler.getFirebaseErrorMessage(e));
      return false;
    } catch (e) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Неизвестная ошибка');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail(String email, String password,
      {File? profileImage, String? adminPhrase}) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _user = userCredential.user;
      if (profileImage != null && _user != null) {
        final imageUrl = await ImageService.uploadImage(profileImage, _user!.uid);
        if (imageUrl != null) _profileImage = profileImage;
      }
      if (_user != null) {
        final role = (adminPhrase == _adminSecret) ? 'admin' : 'user';
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          'email': email,
          'role': role,
          'canMoveTools': false,
          'canControlObjects': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _role = role;
        _canMoveTools = false;
        _canControlObjects = false;
      }
      if (_rememberMe) await _prefs.setString('saved_email', email);
      return true;
    } on FirebaseAuthException catch (e) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, ErrorHandler.getFirebaseErrorMessage(e));
      return false;
    } catch (e) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Неизвестная ошибка');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _profileImage = null;
    _role = null;
    _canMoveTools = false;
    _canControlObjects = false;
    notifyListeners();
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    await _prefs.setBool('remember_me', value);
    if (!value) await _prefs.remove('saved_email');
    notifyListeners();
  }

  Future<void> setProfileImage(File image) async {
    _profileImage = image;
    if (_user != null) {
      final imageUrl = await ImageService.uploadImage(image, _user!.uid);
      if (imageUrl != null) await _prefs.setString('profile_image_url', imageUrl);
    }
    notifyListeners();
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
