import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class AnalyticsStatTiles extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsStatTiles({super.key, required this.retro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final tiles = [
      {
        'label': 'TASKS COMPLETED',
        'value': '${retro.completedTasksCount}',
        'icon': Icons.task_alt_rounded,
        'accent': primaryRed,
      },
      {
        'label': 'WORKOUTS DONE',
        'value': '${retro.workoutsCount}',
        'icon': Icons.fitness_center_rounded,
        'accent': colorScheme.onSurfaceVariant,
      },
      {
        'label': 'HABITS STREAKS',
        'value': '${retro.habitsCompletedCount}',
        'icon': Icons.loop_rounded,
        'accent': colorScheme.onSurfaceVariant,
      },
      {
        'label': 'TOTAL TRACKED',
        'value': '${retro.totalTrackedHours.toStringAsFixed(1)}h',
        'icon': Icons.punch_clock_rounded,
        'accent': colorScheme.onSurfaceVariant,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.28,
      children: tiles.map((t) {
        final label = t['label'] as String;
        final val = t['value'] as String;
        final icon = t['icon'] as IconData;
        final accent = t['accent'] as Color;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                val,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: colorScheme.onSurfaceVariant.withAlpha(150),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
