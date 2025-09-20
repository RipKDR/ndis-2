import 'package:flutter/material.dart';

// Expanded collection of design tokens and theme helpers inspired by
// Material 3 and shadcn/ui patterns. Designed for accessibility, motion,
// and composability across the NDIS Connect app.
class DesignTokens {
  // Spacing scale (8pt grid)
  static const double spacingXs = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacing = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXl = 32.0;

  // Radii
  static const double radiusSm = 8.0;
  static const double radius = 12.0;
  static const double radiusLg = 20.0;

  // Elevations
  static const double elevationLow = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 12.0;

  // Color tokens (seeded via ColorScheme.fromSeed but kept here for reference)
  static const Color seedPrimary = Color(0xFF2D6CDF);
  static const Color accent = Color(0xFF00BFA6);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Motion tokens
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionBase = Duration(milliseconds: 250);
  static const Duration motionLong = Duration(milliseconds: 400);

  // Accessibility guidance
  // Minimum tappable target (44pt) and recommended contrast helpers
  static const double minTappableSize = 44.0;

  // Design system theme builder. Supports dark mode and high contrast.
  static ThemeData themeData({bool highContrast = false, bool dark = false}) {
    final brightness = dark ? Brightness.dark : Brightness.light;

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedPrimary, brightness: brightness),
      useMaterial3: true,
      brightness: brightness,
    );

    // Accessibility: if high contrast is requested, adjust key colors.
    if (highContrast) {
      final hc = base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: Colors.black,
          onPrimary: Colors.yellow,
          secondary: Colors.black,
        ),
        textTheme: base.textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
      );
      return _applyTokens(hc);
    }

    return _applyTokens(base);
  }

  // Internal: apply typography, component shapes and motion presets
  static ThemeData _applyTokens(ThemeData base) {
    final colorScheme = base.colorScheme;

    final textTheme = base.textTheme.copyWith(
      displayLarge:
          base.textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
      displayMedium:
          base.textTheme.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      // Use surface as the recommended scaffold background replacement for background
      scaffoldBackgroundColor: colorScheme.surface,
      // onSurface is the recommended replacement for onBackground
      textTheme:
          textTheme.apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          elevation: elevationMedium,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: elevationLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: const EdgeInsets.all(spacingSmall),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // surfaceVariant is deprecated; use surfaceContainerHighest for newer Material naming.
        // Use withAlpha to set equivalent opacity (~60% -> 153 alpha).
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(153),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.surface,
          contentTextStyle: textTheme.bodyMedium),
    );
  }
}
