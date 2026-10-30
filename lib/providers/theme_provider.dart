import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._storage) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _loadTheme() {
    final saved = _storage.getThemeMode();
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme(BuildContext context) {
    final dark = isDarkMode(context);
    _themeMode = dark ? ThemeMode.light : ThemeMode.dark;
    _storage.setThemeMode(dark ? 'light' : 'dark');
    notifyListeners();
  }
}
