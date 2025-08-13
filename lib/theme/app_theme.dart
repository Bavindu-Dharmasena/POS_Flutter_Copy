import 'package:flutter/material.dart';

const kBgBase = Color(0xFF0B1623); // your dark base
const kPanelBg = Color(0xFF1A2332);

// Keep the parameter to match your call site, but we don't scale here.
// (Scaling is handled in MyApp's MediaQuery.textScaleFactor.)
ThemeData buildLightTheme(double _baseFont) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB),
    brightness: Brightness.light,
  );

  return ThemeData(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.grey.shade100,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // IMPORTANT: no fontSizeFactor here (some styles have null fontSize)
    textTheme: Typography.blackMountainView,
    useMaterial3: true,
  );
}

ThemeData buildDarkTheme(double _baseFont) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF60A5FA),
    brightness: Brightness.dark,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kBgBase,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgBase,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: kPanelBg,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: kPanelBg),
    // IMPORTANT: no fontSizeFactor here (some styles have null fontSize)
    textTheme: Typography.whiteMountainView,
    useMaterial3: true,
  );
}
