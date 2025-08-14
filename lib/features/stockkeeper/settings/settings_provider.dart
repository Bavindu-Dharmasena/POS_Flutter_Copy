import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const double _defaultFontSize = 16.0; // Default font size
  static const bool _defaultDark = false; // Default theme

  static const _kIsDark = 'isDarkMode';
  static const _kFontSize = 'fontSize';

  ThemeMode _themeMode = _defaultDark ? ThemeMode.dark : ThemeMode.light;
  double _fontSize = _defaultFontSize;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  double get textScaleFactor => (_fontSize / 16.0).clamp(0.7, 1.7);

  SettingsController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kIsDark);
    final size = prefs.getDouble(_kFontSize);

    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    if (size != null && size >= 10.0 && size <= 30.0) {
      _fontSize = size;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, isDarkMode);
  }

  Future<void> setDark(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, value);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(10.0, 30.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, _fontSize);
  }

  Future<void> reset() async {
    _themeMode = _defaultDark ? ThemeMode.dark : ThemeMode.light;
    _fontSize = _defaultFontSize;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, _defaultDark);
    await prefs.setDouble(_kFontSize, _defaultFontSize);
  }
}
