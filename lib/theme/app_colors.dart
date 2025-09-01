import 'package:flutter/material.dart';

/// Central palette for your app (shared by light & dark themes).
/// - Brand hues
/// - Surface colors
/// - Gradients
/// - Convenience helpers for Light/Dark lookups
class AppColors {
  // -------- Brand / Primary hues --------
  static const Color purple = Color(0xFF6A11CB);
  static const Color blue   = Color(0xFF2575FC);
  static const Color teal   = Color(0xFF14B8A6);
  static const Color pink   = Color(0xFFEC4899);
  static const Color amber  = Color(0xFFF59E0B);
  static const Color red    = Color(0xFFEF4444);
  static const Color info   = Color(0xFF0EA5E9); // Tailwind Sky-500
  static const Color success = Color(0xFF10B981); // Green-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color danger  = red;

  // -------- Base backgrounds --------
  // Dark
  static const Color bgBaseDark  = Color(0xFF0B1623);
  static const Color panelBgDark = Color(0xFF1A2332);
  // Light
  static const Color bgBaseLight  = Color(0xFFF7F7FB);
  static const Color panelBgLight = Colors.white;

  // -------- Surfaces / fields --------
  static const Color cardLight  = Colors.white;
  static const Color cardDark   = panelBgDark;
  static const Color fieldLight = Color(0xFFF6F7FB);
  static const Color fieldDark  = Color(0xFF243041);

  // -------- Text --------
  static const Color textPrimaryLight   = Colors.black87;
  static const Color textSecondaryLight = Colors.black54;
  static const Color textPrimaryDark    = Colors.white;
  static const Color textSecondaryDark  = Colors.white70;

  // -------- Borders / Dividers --------
  static const Color panelBorderLight = Color(0x11000000);
  static const Color panelBorderDark  = Color(0x22FFFFFF);
  static const Color dividerLight     = Color(0x22000000);
  static const Color dividerDark      = panelBorderDark;

  // -------- Gradients (brand) --------
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

  static const LinearGradient actionGradient = LinearGradient(
    colors: [Color(0xFF6EE7F9), Color(0xFFFFA36E)], // cyan → warm orange
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // -------- Background panel gradients --------
  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F1A28), bgBaseDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Helpers (pick per Brightness) =====
  static Color bgBase(Brightness b) =>
      b == Brightness.dark ? bgBaseDark : bgBaseLight;

  static Color panelBg(Brightness b) =>
      b == Brightness.dark ? panelBgDark : panelBgLight;

  static Color card(Brightness b) =>
      b == Brightness.dark ? cardDark : cardLight;

  static Color field(Brightness b) =>
      b == Brightness.dark ? fieldDark : fieldLight;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color panelBorder(Brightness b) =>
      b == Brightness.dark ? panelBorderDark : panelBorderLight;

  static Color divider(Brightness b) =>
      b == Brightness.dark ? dividerDark : dividerLight;

  static LinearGradient backgroundGradient(Brightness b) =>
      b == Brightness.dark ? backgroundGradientDark : backgroundGradientLight;
}
