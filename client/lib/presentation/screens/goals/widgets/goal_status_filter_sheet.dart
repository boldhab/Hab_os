import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class GoalStatusFilterSheet extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onSelectStatus;

  const GoalStatusFilterSheet({
    super.key,
    required this.currentStatus,
    required this.onSelectStatus,
  });

  static const _options = [
    {'id': 'ACTIVE', 'label': 'Active Goals'},
    {'id': 'COMPLETED', 'label': 'Completed Goals'},
    {'id': 'ALL', 'label': 'All Goals'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.verticalGapLg,
          Text(
            'Goal Status Filter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          AppSpacing.verticalGapMd,
          ..._options.map((opt) {
            final optId = opt['id']!;
            final selected = currentStatus == optId;

            return InkWell(
              onTap: () {
                AppHaptics.selection();
                onSelectStatus(optId);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? primaryRed.withAlpha(20)
                      : colorScheme.surfaceContainerHighest.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? primaryRed
                        : colorScheme.outlineVariant.withAlpha(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? primaryRed : colorScheme.onSurface,
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded,
                          size: 20, color: primaryRed),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.verticalGapSm,
        ],
      ),
    );
  }
}
