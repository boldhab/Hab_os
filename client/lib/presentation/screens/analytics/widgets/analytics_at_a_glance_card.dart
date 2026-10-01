import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../analytics_screen.dart';

class AnalyticsAtAGlanceCard extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsAtAGlanceCard({super.key, required this.retro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    final focusUnits = retro.totalFocusHours.round();
    final tasksUnits = retro.completedTasksCount;
    final workoutsUnits = retro.workoutsCount;
    final habitsUnits = retro.habitsCompletedCount;
    final totalSum = focusUnits + tasksUnits + workoutsUnits + habitsUnits;

    if (totalSum == 0) return const SizedBox.shrink();

    final focusShare = (focusUnits / totalSum * 100).round();
    final tasksShare = (tasksUnits / totalSum * 100).round();
    final workoutsShare = (workoutsUnits / totalSum * 100).round();
    final habitsShare = (habitsUnits / totalSum * 100).round();

    final items = [
      {
        'label': 'Focus',
        'share': focusShare,
        'color': primaryRed,
        'count': '${retro.totalFocusHours.toStringAsFixed(1)}h'
      },
      {
        'label': 'Tasks',
        'share': tasksShare,
        'color': semantics.success,
        'count': '${retro.completedTasksCount}'
      },
      {
        'label': 'Workouts',
        'share': workoutsShare,
        'color': colorScheme.secondary,
        'count': '${retro.workoutsCount}'
      },
      {
        'label': 'Habits',
        'share': habitsShare,
        'color': colorScheme.tertiary,
        'count': '${retro.habitsCompletedCount}'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK AT A GLANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
          AppSpacing.verticalGapSm,

          // Stacked Horizontal Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: items.map((item) {
                  final share = item['share'] as int;
                  final color = item['color'] as Color;
                  if (share <= 0) return const SizedBox.shrink();

                  return Expanded(
                    flex: share,
                    child: Container(
                      color: color,
                      margin: const EdgeInsets.only(right: 1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          AppSpacing.verticalGapSm,

          // Legend Items
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: items.map((item) {
              final label = item['label'] as String;
              final share = item['share'] as int;
              final color = item['color'] as Color;
              final count = item['count'] as String;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count ($share%)',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withAlpha(140),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
