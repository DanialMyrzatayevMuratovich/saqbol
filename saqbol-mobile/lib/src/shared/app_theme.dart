import 'package:flutter/material.dart';

/// SaqBol dark theme — the same tokens the web dashboard uses.
///
/// Verdict colours are validated against the card surface (#151E32): inside the
/// OKLCH lightness band, above the chroma floor, >= 3:1 contrast. Red/amber
/// separation under deuteranopia is dE 6.1, which is only sound alongside a
/// second encoding — every verdict therefore ships with an icon and a label.
class AppColors {
  const AppColors._();

  static const background = Color(0xFF0B1120);
  static const surface = Color(0xFF151E32);
  static const surfaceRaised = Color(0xFF1C2740);
  static const border = Color(0xFF24304D);

  static const foreground = Color(0xFFE8EDF7);
  static const muted = Color(0xFF94A3C4);

  static const accent = Color(0xFF22D3EE);
  static const accentStrong = Color(0xFF06B6D4);

  static const scam = Color(0xFFF43F5E);
  static const suspicious = Color(0xFFAD7A00);
  static const safe = Color(0xFF0D9488);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    // Cyan is a light hue: ink on top of it must be dark, not white.
    onPrimary: AppColors.background,
    secondary: AppColors.accentStrong,
    onSecondary: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.foreground,
    error: AppColors.scam,
    onError: AppColors.foreground,
    outline: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.muted,
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.surfaceRaised,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: TextStyle(color: AppColors.foreground),
    ),
  );
}
