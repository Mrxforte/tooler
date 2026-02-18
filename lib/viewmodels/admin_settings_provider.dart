import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// AdminSettingsProvider - Manages admin configuration settings
/// 
/// Features:
/// - Load/save admin secret word from Firestore
/// - Caching mechanism to avoid repeated Firestore reads
/// - Validation for secret word changes
/// - Error handling

class AdminSettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _cachedSecretWord;
  bool _isLoading = false;
  String? _error;
  
  static const String _defaultSecret = 'admin123';
  static const String _settingsCollection = 'app_settings';
  static const String _adminConfigDoc = 'admin_config';
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get the admin secret word
  /// Returns cached value if available, otherwise fetches from Firestore
  Future<String> getSecretWord() async {
    if (_cachedSecretWord != null) {
      return _cachedSecretWord!;
    }
    
    return await loadSecretWord();
  }
  
  /// Load secret word from Firestore
  /// Initializes with default if document doesn't exist
  Future<String> loadSecretWord() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final docRef = _firestore
          .collection(_settingsCollection)
          .doc(_adminConfigDoc);
      
      final doc = await docRef.get();
      
      if (doc.exists) {
        final data = doc.data();
        _cachedSecretWord = data?['secretWord'] as String? ?? _defaultSecret;
      } else {
        // Initialize with default secret
        await docRef.set({
          'secretWord': _defaultSecret,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _cachedSecretWord = _defaultSecret;
      }
      
      _isLoading = false;
      notifyListeners();
      return _cachedSecretWord!;
    } catch (e) {
      _error = 'Не удалось загрузить настройки: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      // Return default on error
      _cachedSecretWord = _defaultSecret;
      return _defaultSecret;
    }
  }
  
  /// Update the admin secret word in Firestore
  /// Validates new secret before saving
  Future<bool> updateSecretWord(String newSecret) async {
    // Validate
    if (newSecret.trim().isEmpty) {
      _error = 'Секретное слово не может быть пустым';
      notifyListeners();
      return false;
    }
    
    if (newSecret.length < 6) {
      _error = 'Секретное слово должно содержать минимум 6 символов';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Update in Firestore
      await _firestore
          .collection(_settingsCollection)
          .doc(_adminConfigDoc)
          .update({
        'secretWord': newSecret,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {
        // If document doesn't exist, create it
        return _firestore
            .collection(_settingsCollection)
            .doc(_adminConfigDoc)
            .set({
          'secretWord': newSecret,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Update cache
      _cachedSecretWord = newSecret;
      _error = null;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Не удалось обновить настройки: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Clear cache (useful for testing)
  void clearCache() {
    _cachedSecretWord = null;
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
