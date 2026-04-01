import 'package:flutter/material.dart';

/// PearlHub brand colors
class PearlHubColors {
  PearlHubColors._();

  // Primary: Ocean Blue
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF38BDF8);

  // Secondary: Coral
  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryDark = Color(0xFFEA580C);
  static const Color secondaryLight = Color(0xFFFB923C);

  // Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color mist = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Vertical accents
  static const Color stayAccent = Color(0xFF8B5CF6);
  static const Color vehicleAccent = Color(0xFF06B6D4);
  static const Color eventAccent = Color(0xFFEC4899);
  static const Color propertyAccent = Color(0xFF10B981);
  static const Color taxiAccent = Color(0xFFFBBF24);
  static const Color smeAccent = Color(0xFF6366F1);
}

/// PearlHub Material 3 theme
ThemeData pearlHubTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PearlHubColors.primary,
      primary: PearlHubColors.primary,
      secondary: PearlHubColors.secondary,
      surface: PearlHubColors.surface,
      error: PearlHubColors.error,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: PearlHubColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: PearlHubColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: PearlHubColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PearlHubColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PearlHubColors.primary,
        side: const BorderSide(color: PearlHubColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PearlHubColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PearlHubColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PearlHubColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: PearlHubColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: PearlHubColors.primary,
      unselectedItemColor: PearlHubColors.mist,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PearlHubColors.primaryLight.withOpacity(0.1),
      selectedColor: PearlHubColors.primary,
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: PearlHubColors.border,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: PearlHubColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: PearlHubColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: PearlHubColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: PearlHubColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: PearlHubColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: PearlHubColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: PearlHubColors.textPrimary,
      ),
    ),
  );
}

/// Dark theme (Phase 2)
ThemeData pearlHubDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PearlHubColors.primary,
      primary: PearlHubColors.primaryLight,
      secondary: PearlHubColors.secondaryLight,
      brightness: Brightness.dark,
    ),
  );
}
