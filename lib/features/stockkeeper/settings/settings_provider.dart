import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  /// Whether SharedPreferences finished loading.
  bool isLoaded = false;

  /// ✅ Default to DARK immediately (preference fallback is also dark).
  ThemeMode _themeMode = ThemeMode.dark;

  /// Base font size in points used for global scaling (16 => 1.0x).
  double _fontSize = 16;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get fontSize => _fontSize;

  /// Derive a safe text scale (used in MaterialApp.builder).
  double get textScaleFactor => (_fontSize / 16).clamp(0.85, 1.40);

  /// Load persisted settings.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Prefer string 'themeMode'; fall back to legacy 'isDarkMode'.
    if (prefs.containsKey('themeMode')) {
      _themeMode = _fromString(prefs.getString('themeMode') ?? 'dark');
    } else {
      final legacy = prefs.getBool('isDarkMode');
      _themeMode = (legacy == null || legacy) ? ThemeMode.dark : ThemeMode.light;
    }

    _fontSize = prefs.getDouble('fontSize') ?? 16;

    isLoaded = true;
    notifyListeners();
  }

  Future<void> setDark(bool v) => setThemeMode(v ? ThemeMode.dark : ThemeMode.light);

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _toString(m));
    await prefs.setBool('isDarkMode', m == ThemeMode.dark); // keep legacy in sync
    notifyListeners();
  }

  Future<void> setFontSize(double v) async {
    _fontSize = v.clamp(10, 30);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> reset() async {
    _themeMode = ThemeMode.dark;
    _fontSize = 16;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('themeMode');
    await prefs.remove('isDarkMode');
    await prefs.remove('fontSize');
    notifyListeners();
  }

  // Helpers
  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark:  return 'dark';
      case ThemeMode.system:return 'system';
    }
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':  return ThemeMode.light;
      case 'system': return ThemeMode.system;
      case 'dark':
      default:       return ThemeMode.dark;
    }
  }
}
