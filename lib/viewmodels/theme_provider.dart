import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  String _themeMode = 'light';
  
  String get themeMode => _themeMode;
  
  set themeMode(String value) {
    _themeMode = value;
    notifyListeners();
  }
}
