import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Centralized Reusable Card Component for HABos.
///
/// Features consistent compact geometry, soft elevation in light theme,
/// subtle inner border in dark theme, and optional press feedback.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderSide? border;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final bool enableGlow;
  final Color? glowColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.backgroundColor,
    this.border,
    this.borderRadius = 16.0,
    this.onTap,
    this.boxShadow,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);

    final defaultBgColor = widget.backgroundColor ??
        (isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest);

    final borderColor = widget.border?.color ??
        (isDark
            ? colorScheme.outlineVariant.withAlpha(35)
            : colorScheme.outlineVariant.withAlpha(50));

    final borderWidth = widget.border?.width ?? 1.0;

    final defaultShadows = widget.boxShadow ??
        (isDark
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(38),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                if (widget.enableGlow && widget.glowColor != null)
                  BoxShadow(
                    color: widget.glowColor!,
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
              ]);

    Widget cardContent = AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: defaultBgColor,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: defaultShadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
