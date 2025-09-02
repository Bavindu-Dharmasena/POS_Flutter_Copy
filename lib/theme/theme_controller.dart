import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tiny observable controller that persists the current [ThemeMode].
/// - Call [load] once before `runApp`.
/// - Read current mode via [mode].
/// - Switch with [set], [toggle], or [cycle].
/// - Listen for changes with an [AnimatedBuilder] / [ListenableBuilder].
class ThemeController extends ChangeNotifier {
  // -------- Persistence keys / string encodings --------
  static const String _prefsKey = 'themeMode'; // 'light' | 'dark' | 'system'
  static const String _light = 'light';
  static const String _dark = 'dark';
  static const String _system = 'system';

  ThemeMode _mode = ThemeMode.system;
  bool _loaded = false;

  /// Currently selected theme mode.
  ThemeMode get mode => _mode;

  /// Whether [load] has completed at least once.
  bool get isLoaded => _loaded;

  /// Returns a stable string for the current mode: 'light' | 'dark' | 'system'.
  String get modeName => _encode(_mode);

  /// Convenience flags.
  bool get isLight => _mode == ThemeMode.light;
  bool get isDark  => _mode == ThemeMode.dark;
  bool get isSystem => _mode == ThemeMode.system;

  /// Load initial mode from SharedPreferences.
  /// If nothing was saved, falls back to [fallback] (default: system).
  Future<void> load({ThemeMode fallback = ThemeMode.system}) async {
    if (_loaded) return; // idempotent
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_prefsKey);
    _mode = _decode(saved) ?? fallback;
    _loaded = true;
    notifyListeners();
  }

  /// Persist and notify listeners if the mode actually changed.
  Future<void> set(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefsKey, _encode(mode));
  }

  /// Toggle strictly between Light ↔ Dark (does not hit System).
  Future<void> toggle() =>
      set(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  /// Cycle through System → Light → Dark → System.
  Future<void> cycle() {
    final next = switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light  => ThemeMode.dark,
      ThemeMode.dark   => ThemeMode.system,
    };
    return set(next);
  }

  /// Force System mode.
  Future<void> setSystem() => set(ThemeMode.system);

  /// Pick a reasonable icon for UI toggles/menus.
  /// If you want the icon to visually reflect the *effective* look while in
  /// system mode, pass the current platform [brightness] (e.g.,
  /// `MediaQuery.platformBrightnessOf(context)`).
  IconData themeIcon({Brightness? platformBrightness}) {
    if (_mode == ThemeMode.light) return Icons.light_mode;
    if (_mode == ThemeMode.dark) return Icons.dark_mode;
    // System: choose based on platform (if provided), otherwise a generic icon.
    if (platformBrightness != null) {
      return platformBrightness == Brightness.dark
          ? Icons.dark_mode
          : Icons.light_mode;
    }
    // Fallback generic "auto" indicator
    return Icons.brightness_6;
  }

  // -------- Private helpers --------

  static String _encode(ThemeMode m) => switch (m) {
        ThemeMode.light => _light,
        ThemeMode.dark => _dark,
        ThemeMode.system => _system,
      };

  static ThemeMode? _decode(String? s) => switch (s) {
        _light => ThemeMode.light,
        _dark => ThemeMode.dark,
        _system => ThemeMode.system,
        _ => null,
      };
}
