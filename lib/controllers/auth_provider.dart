import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  User? _user;
  bool _isLoading = false;
  bool _rememberMe = false;
  File? _profileImage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get rememberMe => _rememberMe;
  File? get profileImage => _profileImage;

  AuthProvider(this._prefs) {
    _rememberMe = _prefs.getBool('remember_me') ?? false;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      final savedUser = _auth.currentUser;
      if (savedUser != null && _rememberMe) {
        _user = savedUser;
      }
    } catch (e) {
      print('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      } else {
        await _prefs.remove('saved_email');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected auth error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, {
    File? profileImage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      // Save profile image
      if (profileImage != null && _user != null) {
        final imageUrl = await ImageService.uploadImage(
          profileImage,
          _user!.uid,
        );
        if (imageUrl != null) {
          _profileImage = profileImage;
          await _prefs.setString('profile_image_url', imageUrl);
        }
      }

      if (_user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .set({
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
                'userId': _user!.uid,
                'profileImageUrl': _profileImage != null
                    ? await ImageService.uploadImage(_profileImage!, _user!.uid)
                    : null,
              });
        } catch (e) {
          print('Firestore user creation error: $e');
        }
      }

      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected signup error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _profileImage = null;
      await _prefs.remove('profile_image_url');
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> setRememberMe(bool value) async {
    try {
      _rememberMe = value;
      await _prefs.setBool('remember_me', value);

      if (!value) {
        await _prefs.remove('saved_email');
      }

      notifyListeners();
    } catch (e) {
      print('Error setting remember me: $e');
    }
  }

  Future<void> setProfileImage(File image) async {
    _profileImage = image;
    if (_user != null) {
      final imageUrl = await ImageService.uploadImage(image, _user!.uid);
      if (imageUrl != null) {
        await _prefs.setString('profile_image_url', imageUrl);
      }
    }
    notifyListeners();
  }
}
