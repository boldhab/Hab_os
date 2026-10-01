import 'package:flutter/material.dart';

/// Hand-crafted design palette for HABos.
///
/// Palette direction:
/// - Neutral base: Deep warm charcoal / graphite (obsidian undertones, avoiding cold sterile grays or pure black/white).
/// - Accent / Primary: Warm ember / burnished amber (momentum, fire, streaks — HABos's core metaphor).
/// - Secondary: Warm terracotta / bronze.
/// - Tertiary: Solar gold / luminous flame.
class AppColors {
  AppColors._();

  /// Primary brand accent color (HABos Warm Ember Red)
  static const Color primaryRed = Color(0xFFC44614);

  // ── Light Theme Explicit ColorScheme ───────────────────────────────────────
  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    // Accent Ember
    primary: Color(0xFFC44614),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDBCF),
    onPrimaryContainer: Color(0xFF3B1000),

    // Terracotta Bronze
    secondary: Color(0xFF785646),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6DCD1),
    onSecondaryContainer: Color(0xFF2C160B),

    // Solar Gold
    tertiary: Color(0xFF865900),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDF9E),
    onTertiaryContainer: Color(0xFF2B1700),

    // Error
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Warm Charcoal Neutrals (Surface hierarchy)
    surface: Color(0xFFF6F1ED),
    onSurface: Color(0xFF1E1B18),
    onSurfaceVariant: Color(0xFF534C46),

    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2EAE4),
    surfaceContainer: Color(0xFFEAE2DB),
    surfaceContainerHigh: Color(0xFFE2D8D1),
    surfaceContainerHighest: Color(0xFFD9D0C8),

    outline: Color(0xFF857C74),
    outlineVariant: Color(0xFFD2C9C1),
    shadow: Color(0x1A000000),
    scrim: Color(0x33000000),
    inverseSurface: Color(0xFF332F2C),
    onInverseSurface: Color(0xFFF6F0EA),
    inversePrimary: Color(0xFFFF8B56),
  );

  // ── Dark Theme Explicit ColorScheme ────────────────────────────────────────
  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Radiant Ember Flame
    primary: Color(0xFFFF8B56),
    onPrimary: Color(0xFF501900),
    primaryContainer: Color(0xFF762900),
    onPrimaryContainer: Color(0xFFFFDBCF),

    // Luminous Terracotta
    secondary: Color(0xFFE8BEAC),
    onSecondary: Color(0xFF452A1C),
    secondaryContainer: Color(0xFF5E3F30),
    onSecondaryContainer: Color(0xFFF6DCD1),

    // Luminous Solar Gold
    tertiary: Color(0xFFFDB933),
    onTertiary: Color(0xFF462D00),
    tertiaryContainer: Color(0xFF654200),
    onTertiaryContainer: Color(0xFFFFDF9E),

    // Error
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Deep Obsidian / Graphite Charcoal (Surface hierarchy)
    surface: Color(0xFF120F0E),
    onSurface: Color(0xFFECE7E2),
    onSurfaceVariant: Color(0xFFAFA7A0),

    surfaceContainerLowest: Color(0xFF0D0B0A),
    surfaceContainerLow: Color(0xFF191614),
    surfaceContainer: Color(0xFF211E1B),
    surfaceContainerHigh: Color(0xFF2A2623),
    surfaceContainerHighest: Color(0xFF332F2C),

    outline: Color(0xFF7C736B),
    outlineVariant: Color(0xFF443D37),
    shadow: Color(0x33000000),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFFECE7E2),
    onInverseSurface: Color(0xFF1E1B18),
    inversePrimary: Color(0xFFC44614),
  );

  // ── Gradient Assets for Hero Moments ───────────────────────────────────────
  static const emberGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFC44614), Color(0xFF9A3412)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroCardDarkGradient = LinearGradient(
    colors: [Color(0xFF2C2724), Color(0xFF201D1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroCardLightGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF3EFEA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
