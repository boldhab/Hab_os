import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum AppBadgeSize { compact, regular }

/// Standardized pill/badge component for HABos.
///
/// Ensures consistent 11sp font size, full pill radius ([AppRadius.pillRadius]),
/// and harmonious semantic or brand color styling across all screens.
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final bool isOutlined;
  final AppBadgeSize size;
  final VoidCallback? onTap;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.isOutlined = false,
    this.size = AppBadgeSize.regular,
    this.onTap,
  });

  /// Factory constructor for semantic success (completed, positive, streak active)
  factory AppBadge.success({
    Key? key,
    required String label,
    IconData? icon,
    AppBadgeSize size = AppBadgeSize.regular,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final semantics = AppSemanticColors.of(context);
    return AppBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: semantics.successContainer,
      textColor: semantics.onSuccessContainer,
      borderColor: semantics.success.withAlpha(50),
      size: size,
      onTap: onTap,
    );
  }

  /// Factory constructor for semantic warning (pending, due soon, streak at risk)
  factory AppBadge.warning({
    Key? key,
    required String label,
    IconData? icon,
    AppBadgeSize size = AppBadgeSize.regular,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final semantics = AppSemanticColors.of(context);
    return AppBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: semantics.warningContainer,
      textColor: semantics.onWarningContainer,
      borderColor: semantics.warning.withAlpha(50),
      size: size,
      onTap: onTap,
    );
  }

  /// Factory constructor for semantic danger (overdue, negative, missed)
  factory AppBadge.danger({
    Key? key,
    required String label,
    IconData? icon,
    AppBadgeSize size = AppBadgeSize.regular,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final semantics = AppSemanticColors.of(context);
    return AppBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: semantics.dangerContainer,
      textColor: semantics.onDangerContainer,
      borderColor: semantics.danger.withAlpha(50),
      size: size,
      onTap: onTap,
    );
  }

  /// Factory constructor for semantic info / metadata (domain tags, categories)
  factory AppBadge.info({
    Key? key,
    required String label,
    IconData? icon,
    AppBadgeSize size = AppBadgeSize.regular,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final semantics = AppSemanticColors.of(context);
    return AppBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: semantics.infoContainer,
      textColor: semantics.onInfoContainer,
      borderColor: semantics.info.withAlpha(50),
      size: size,
      onTap: onTap,
    );
  }

  /// Factory constructor for brand ember badge
  factory AppBadge.primary({
    Key? key,
    required String label,
    IconData? icon,
    AppBadgeSize size = AppBadgeSize.regular,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: colorScheme.primaryContainer,
      textColor: colorScheme.onPrimaryContainer,
      borderColor: colorScheme.primary.withAlpha(40),
      size: size,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bg = backgroundColor ??
        (color != null
            ? color!.withAlpha(35)
            : colorScheme.surfaceContainerHigh);

    final fg = textColor ?? (color ?? colorScheme.onSurface);

    final border = borderColor != null
        ? Border.all(color: borderColor!)
        : (isOutlined
            ? Border.all(
                color: color ?? colorScheme.outlineVariant.withAlpha(100))
            : Border.all(
                color: (color ?? colorScheme.outlineVariant).withAlpha(40)));

    final padding = size == AppBadgeSize.compact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs + 2, vertical: AppSpacing.xxs)
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs);

    final fontSize = size == AppBadgeSize.compact ? 10.0 : 11.5;
    final iconSize = size == AppBadgeSize.compact ? 11.0 : 13.0;

    Widget badgeContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          SizedBox(width: size == AppBadgeSize.compact ? 2.0 : 4.0),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: fg,
          ),
        ),
      ],
    );

    Widget container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillRadius,
        border: border,
      ),
      child: badgeContent,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: container,
      );
    }

    return container;
  }
}
