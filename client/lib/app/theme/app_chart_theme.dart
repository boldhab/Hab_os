import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_semantic_colors.dart';

/// Centralized chart styling and theming utility for HABos.
/// Provides consistent colors, typography, gradients, grid borders,
/// and tooltip styling for data visualizations.
class AppChartTheme {
  AppChartTheme._();

  /// Subtle grid border/line color for cartesian coordinate systems
  static Color gridLineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant.withAlpha(35);
  }

  /// Axis line color
  static Color axisLineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant.withAlpha(70);
  }

  /// Axis tick label style (Inter 11sp muted)
  static TextStyle axisLabelStyle(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(200),
    );
  }

  /// Axis title / legend style (Inter 12sp medium)
  static TextStyle axisTitleStyle(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// Primary Warm Ember linear gradient for charts & sparklines
  static LinearGradient emberGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.primary,
        colorScheme.primary.withAlpha(160),
      ],
    );
  }

  /// Solar Gold linear gradient for secondary highlights
  static LinearGradient goldGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.tertiary,
        colorScheme.tertiary.withAlpha(160),
      ],
    );
  }

  /// Terracotta linear gradient for habits/streaks
  static LinearGradient terracottaGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.secondary,
        colorScheme.secondary.withAlpha(160),
      ],
    );
  }

  /// Semantic success gradient for completion & positive cashflow
  static LinearGradient successGradient(BuildContext context) {
    final semantics = AppSemanticColors.of(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        semantics.success,
        semantics.success.withAlpha(160),
      ],
    );
  }
}
