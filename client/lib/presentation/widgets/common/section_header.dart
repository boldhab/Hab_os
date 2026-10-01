import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Reusable Section Header Component for HABos Dashboard & Feature Cards.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;
  final Color? iconColor;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.iconColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: effectiveIconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: 18,
          ),
        ),
        AppSpacing.horizontalGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(180),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
