import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Hero Tier Card component for HABos.
///
/// Designed for high-impact showcase moments (Life Score, Active Focus Session, Net Worth).
/// Features subtle gradient backgrounds, ambient glow, and rounded hero geometry ([AppRadius.heroCardRadius]).
class HeroCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final BorderSide? border;
  final bool enableGlow;
  final Color? glowColor;
  final VoidCallback? onTap;

  const HeroCard({
    super.key,
    required this.child,
    this.gradient,
    this.backgroundColor,
    this.padding = AppSpacing.heroCardPadding,
    this.border,
    this.enableGlow = true,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = isDark
        ? const LinearGradient(
            colors: [
              Color(0xFF2C221D), // Dark warm charcoal with amber tint
              Color(0xFF1E1A17), // Deep graphite obsidian
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFBF4ED), // Warm ivory pearl with subtle ember undertone
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final actualGlowColor =
        glowColor ?? colorScheme.primary.withAlpha(isDark ? 28 : 18);
    final borderColor = border ??
        BorderSide(
          color: isDark
              ? colorScheme.primary.withAlpha(45)
              : colorScheme.outlineVariant.withAlpha(90),
          width: 1.0,
        );

    Widget content = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? colorScheme.surfaceContainerHigh)
            : null,
        gradient: gradient ?? defaultGradient,
        borderRadius: AppRadius.heroCardRadius,
        border: Border.all(color: borderColor.color, width: borderColor.width),
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: actualGlowColor,
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.heroCardRadius,
        child: content,
      );
    }

    return content;
  }
}
