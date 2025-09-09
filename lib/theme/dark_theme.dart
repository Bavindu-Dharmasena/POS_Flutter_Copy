import 'package:flutter/material.dart';
import 'app_colors.dart'; // adjust path if needed (e.g., 'core/theme/app_colors.dart')

ThemeData buildDarkTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.dark,
    background: AppColors.bgBaseDark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.bgBaseDark,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
    ),

    // Cards / panels
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.panelBorderDark),
      ),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldDark,
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.panelBorderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.panelBorderDark),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.teal, width: 1.4),
      ),
      prefixIconColor: AppColors.textSecondaryDark,
      suffixIconColor: AppColors.textSecondaryDark,
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    // Dividers / icons / selection
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: .8,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),

    // Selection controls
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return AppColors.panelBorderDark;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(cs.primary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cs.primary : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cs.primary.withOpacity(.35) : Colors.white24,
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.fieldDark,
      labelStyle: const TextStyle(color: AppColors.textPrimaryDark),
      selectedColor: cs.primary.withOpacity(.20),
      secondarySelectedColor: cs.primary.withOpacity(.20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.panelBorderDark),
      ),
    ),

    // Dialogs / Menus / Snackbars
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.panelBorderDark),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.cardDark),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.panelBorderDark),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldDark,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.panelBorderDark),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF1F2937), // gray-800
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),

    // Text selection (cursor, selection color)
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cs.primary,
      selectionColor: cs.primary.withOpacity(.25),
      selectionHandleColor: cs.primary,
    ),
  );
}
