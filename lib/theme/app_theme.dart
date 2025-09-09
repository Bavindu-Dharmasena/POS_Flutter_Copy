import 'package:flutter/material.dart';

/// Base darks you already used
const kBgBase  = Color(0xFF0B1623);
const kPanelBg = Color(0xFF1A2332);

/// A ThemeExtension so you can access gradients & accent colors via:
/// final g = Theme.of(context).extension<AppPalette>()!;
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final Color success;
  final Color warning;
  final Color info;
  final Color fieldLight; // pastel fill (light)
  final Color fieldDark;  // pastel fill (dark)

  const AppPalette({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.success,
    required this.warning,
    required this.info,
    required this.fieldLight,
    required this.fieldDark,
  });

  @override
  AppPalette copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
    Color? success,
    Color? warning,
    Color? info,
    Color? fieldLight,
    Color? fieldDark,
  }) {
    return AppPalette(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      fieldLight: fieldLight ?? this.fieldLight,
      fieldDark: fieldDark ?? this.fieldDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primaryGradient: LinearGradient(
        colors: [
          Color.lerp(primaryGradient.colors.first,  other.primaryGradient.colors.first,  t)!,
          Color.lerp(primaryGradient.colors.last,   other.primaryGradient.colors.last,   t)!,
        ],
        begin: primaryGradient.begin, end: primaryGradient.end,
      ),
      secondaryGradient: LinearGradient(
        colors: [
          Color.lerp(secondaryGradient.colors.first, other.secondaryGradient.colors.first, t)!,
          Color.lerp(secondaryGradient.colors.last,  other.secondaryGradient.colors.last,  t)!,
        ],
        begin: secondaryGradient.begin, end: secondaryGradient.end,
      ),
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info:    Color.lerp(info,    other.info,    t)!,
      fieldLight: Color.lerp(fieldLight, other.fieldLight, t)!,
      fieldDark:  Color.lerp(fieldDark,  other.fieldDark,  t)!,
    );
  }
}

/// ————————————————————————— LIGHT THEME —————————————————————————

ThemeData buildLightTheme(double baseFont) {
  // Colorful seed with strong harmonized palette (violet/purple/blue).
  final cs = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C3AED), // Violet-600
    brightness: Brightness.light,
  ).copyWith(
    primary:   const Color(0xFF6A11CB), // Purple
    secondary: const Color(0xFF2575FC), // Blue
    tertiary:  const Color(0xFF14B8A6), // Teal
    surface: Colors.white,
    surfaceContainerHighest: Colors.white,
  );

  final palette = const AppPalette(
    primaryGradient: LinearGradient(
      colors: [Color(0xFF2575FC), Color(0xFF6A11CB)], // blue → purple
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF6A11CB), Color(0xFFEC4899)], // purple → pink
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    info:    Color(0xFF0EA5E9),
    fieldLight: Color(0xFFF6F7FB), // pastel input fill
    fieldDark: Color(0xFF243041),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: cs,
    extensions: [palette],
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    appBarTheme: AppBarTheme(
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.fieldLight,
      hintStyle: const TextStyle(color: Colors.black54),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.primary,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
    iconTheme: IconThemeData(color: cs.primary),
    textTheme: Typography.blackMountainView,
  );
}

/// ————————————————————————— DARK THEME —————————————————————————

ThemeData buildDarkTheme(double baseFont) {
  final cs = ColorScheme.fromSeed(
    seedColor: const Color(0xFF60A5FA), // Blue-400 seed (harmonizes others)
    brightness: Brightness.dark,
  ).copyWith(
    primary:  const Color(0xFF60A5FA), // vivid blue
    secondary: const Color(0xFF8B5CF6), // violet
    tertiary:  const Color(0xFF22D3EE), // cyan/teal
    surface: kPanelBg,
    surfaceContainerHighest: kPanelBg,
  );

  final palette = const AppPalette(
    primaryGradient: LinearGradient(
      colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)], // cyan → violet
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFF472B6)], // violet → pink
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    info:    Color(0xFF38BDF8),
    fieldLight: Color(0xFFF6F7FB),
    fieldDark: Color(0xFF243041), // dark pastel for inputs
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    extensions: [palette],
    scaffoldBackgroundColor: kBgBase,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgBase,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: kPanelBg,
      elevation: 8,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kPanelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.fieldDark,
      hintStyle: const TextStyle(color: Colors.white70),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(.18)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.secondary,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(.12),
      thickness: 1,
    ),
    iconTheme: IconThemeData(color: cs.tertiary),
    textTheme: Typography.whiteMountainView,
  );
}
