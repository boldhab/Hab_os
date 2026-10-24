import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Reusable Section Header for Form Dialogs and Modals in HABos.
/// Provides consistent typography, spacing, and optional icon styling for form groupings.
class FormSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const FormSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 6.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: AppTypography.micro(
              context,
              color: colorScheme.onSurfaceVariant.withAlpha(200),
            ).copyWith(letterSpacing: 0.8),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
