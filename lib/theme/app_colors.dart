import 'package:flutter/material.dart';

/// Central palette for your app (light + dark shared constants).
/// Use these for building theme, custom widgets, gradients, etc.
class AppColors {
  // Brand / primary hues
  static const Color purple = Color(0xFF6A11CB);
  static const Color blue   = Color(0xFF2575FC);
  static const Color teal   = Color(0xFF14B8A6);
  static const Color pink   = Color(0xFFEC4899);
  static const Color amber  = Color(0xFFF59E0B);
  static const Color red    = Color(0xFFEF4444);

  // Base dark backgrounds
  static const Color bgBase  = Color(0xFF0B1623);
  static const Color panelBg = Color(0xFF1A2332);

  // Surfaces / fields
  static const Color cardLight = Colors.white;
  static const Color cardDark  = panelBg;
  static const Color fieldLight = Color(0xFFF6F7FB); // pastel field background
  static const Color fieldDark  = Color(0xFF243041);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blue, purple], // Blue → Purple
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [purple, pink], // Purple → Pink
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanVioletGradient = LinearGradient(
    colors: [teal, purple], // Teal → Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic colors
  static const Color success = Color(0xFF10B981); // Green-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color info    = Color(0xFF0EA5E9);

  static var backgroundGradient; // Sky-500
}
