import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Distinctive typography system for HABos.
///
/// Features:
/// - Display / Headline / Title / Big Numerals: [GoogleFonts.outfit]
///   Geometric, tech-forward, and premium with distinct modern numerals.
/// - Body / Label / Captions: [GoogleFonts.inter]
///   High legibility at small sizes, optimal x-height for productivity apps.
class AppTypography {
  AppTypography._();

  /// Explicit font fallback stack supporting Latin and Ethiopic (Amharic) glyphs cleanly.
  static const List<String> ethiopicFontFallback = [
    'Noto Sans Ethiopic',
    'Abyssinica SIL',
    'Nyala',
    'Roboto',
    'sans-serif',
  ];

  /// Builds a cohesive [TextTheme] combining Outfit for headings/numerals and Inter for body/labels.
  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final baseTextTheme = ThemeData.light().textTheme;

    // Display & Headline styles with Outfit
    final displayLarge = GoogleFonts.outfit(
      textStyle: baseTextTheme.displayLarge,
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      color: colorScheme.onSurface,
    );

    final displayMedium = GoogleFonts.outfit(
      textStyle: baseTextTheme.displayMedium,
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: colorScheme.onSurface,
    );

    final displaySmall = GoogleFonts.outfit(
      textStyle: baseTextTheme.displaySmall,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      color: colorScheme.onSurface,
    );

    final headlineLarge = GoogleFonts.outfit(
      textStyle: baseTextTheme.headlineLarge,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: colorScheme.onSurface,
    );

    final headlineMedium = GoogleFonts.outfit(
      textStyle: baseTextTheme.headlineMedium,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.15,
      color: colorScheme.onSurface,
    );

    final headlineSmall = GoogleFonts.outfit(
      textStyle: baseTextTheme.headlineSmall,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    );

    final titleLarge = GoogleFonts.outfit(
      textStyle: baseTextTheme.titleLarge,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    );

    final titleMedium = GoogleFonts.outfit(
      textStyle: baseTextTheme.titleMedium,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: colorScheme.onSurface,
    );

    final titleSmall = GoogleFonts.outfit(
      textStyle: baseTextTheme.titleSmall,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: colorScheme.onSurface,
    );

    // Body & Label styles with Inter
    final bodyLarge = GoogleFonts.inter(
      textStyle: baseTextTheme.bodyLarge,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    );

    final bodyMedium = GoogleFonts.inter(
      textStyle: baseTextTheme.bodyMedium,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    );

    final bodySmall = GoogleFonts.inter(
      textStyle: baseTextTheme.bodySmall,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: colorScheme.onSurfaceVariant,
    );

    final labelLarge = GoogleFonts.inter(
      textStyle: baseTextTheme.labelLarge,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: colorScheme.onSurface,
    );

    final labelMedium = GoogleFonts.inter(
      textStyle: baseTextTheme.labelMedium,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: colorScheme.onSurfaceVariant,
    );

    final labelSmall = GoogleFonts.inter(
      textStyle: baseTextTheme.labelSmall,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: colorScheme.onSurfaceVariant,
    );

    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ).apply(
      fontFamilyFallback: ethiopicFontFallback,
    );
  }

  /// Specific helper for large numeral displays (Life Score, GPA, Countdown timer, Net Balance).
  /// Automatically enables tabular figures to prevent horizontal jitter during updates.
  static TextStyle statNumeral({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
      color: color,
      fontFeatures: fontFeatures ?? const [FontFeature.tabularFigures()],
    ).copyWith(
      fontFamilyFallback: ethiopicFontFallback,
    );
  }

  /// Enforces tabular numbers on any text style.
  static TextStyle tabular(TextStyle style) {
    return style.copyWith(
      fontFeatures: [
        ...?style.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  /// Monospace style for identifiers, temporary passwords, codes, and tech values.
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    ).copyWith(
      fontFamilyFallback: ethiopicFontFallback,
    );
  }

  // ── Context Typography Helpers ─────────────────────────────────────────────
  static TextStyle h1(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium ??
      const TextStyle(fontSize: 45);
  static TextStyle h2(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium ??
      const TextStyle(fontSize: 28);
  static TextStyle h3(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall ??
      const TextStyle(fontSize: 24);
  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20);
  static TextStyle titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  static TextStyle titleSmall(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall ?? const TextStyle(fontSize: 14);
  static TextStyle bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
  static TextStyle bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
  static TextStyle labelLarge(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14);
  static TextStyle labelMedium(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
  static TextStyle labelSmall(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);

  // ── Semantic Role Accessors ────────────────────────────────────────────────
  /// Main Page Title (text-2xl / text-3xl, font-bold, tracking-tight)
  static TextStyle pageTitle(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.headlineMedium ?? const TextStyle(fontSize: 28)).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Section Heading (text-lg / text-xl, font-semibold)
  static TextStyle sectionHeading(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20)).copyWith(
        fontWeight: FontWeight.w600,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Card Title (text-base / text-lg, font-semibold)
  static TextStyle cardTitle(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 16)).copyWith(
        fontWeight: FontWeight.w600,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Dialog Heading (text-lg, font-semibold / font-bold)
  static TextStyle dialogTitle(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20)).copyWith(
        fontWeight: FontWeight.w700,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Dialog Subtitle / Supporting description (text-sm, text-muted-foreground)
  static TextStyle dialogSubtitle(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(180),
      );

  /// Form Label (text-sm, font-medium)
  static TextStyle formLabel(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
        fontWeight: FontWeight.w500,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      );

  /// Caption and metadata (text-xs, text-muted-foreground)
  static TextStyle caption(BuildContext context, {Color? color}) =>
      (Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(190),
      );

  /// Micro-label or compact badge (10sp, font-bold, uppercase tracking)
  static TextStyle micro(BuildContext context, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ).copyWith(
        fontFamilyFallback: ethiopicFontFallback,
      );
}
