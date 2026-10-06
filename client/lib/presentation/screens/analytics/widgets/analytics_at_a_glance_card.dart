import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class _ActivityGlanceItem {
  final String label;
  final int sharePercent;
  final double aisUnits;
  final Color color;
  final String countDisplay;

  const _ActivityGlanceItem({
    required this.label,
    required this.sharePercent,
    required this.aisUnits,
    required this.color,
    required this.countDisplay,
  });
}

class AnalyticsAtAGlanceCard extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsAtAGlanceCard({super.key, required this.retro});

  // Standardized Activity Impact Score (AIS) operational weights
  static const double _focusHourWeight = 60.0;
  static const double _taskWeight = 10.0;
  static const double _workoutWeight = 40.0;
  static const double _habitWeight = 5.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    // Initial validation pass: Check raw trace metrics without early integer rounding
    final hasTraceActivity = retro.totalFocusHours > 0 ||
        retro.completedTasksCount > 0 ||
        retro.workoutsCount > 0 ||
        retro.habitsCompletedCount > 0;

    if (!hasTraceActivity) return const SizedBox.shrink();

    // Standardized Activity Impact Score (AIS) normalization
    final focusAis = retro.totalFocusHours * _focusHourWeight;
    final tasksAis = retro.completedTasksCount * _taskWeight;
    final workoutsAis = retro.workoutsCount * _workoutWeight;
    final habitsAis = retro.habitsCompletedCount * _habitWeight;
    final totalAis = focusAis + tasksAis + workoutsAis + habitsAis;

    if (totalAis <= 0.0) return const SizedBox.shrink();

    final focusShare = ((focusAis / totalAis) * 100).round();
    final tasksShare = ((tasksAis / totalAis) * 100).round();
    final workoutsShare = ((workoutsAis / totalAis) * 100).round();
    final habitsShare = ((habitsAis / totalAis) * 100).round();

    final items = [
      _ActivityGlanceItem(
        label: 'Focus',
        sharePercent: focusShare,
        aisUnits: focusAis,
        color: primaryRed,
        countDisplay: '${retro.totalFocusHours.toStringAsFixed(1)}h',
      ),
      _ActivityGlanceItem(
        label: 'Tasks',
        sharePercent: tasksShare,
        aisUnits: tasksAis,
        color: semantics.success,
        countDisplay: '${retro.completedTasksCount}',
      ),
      _ActivityGlanceItem(
        label: 'Workouts',
        sharePercent: workoutsShare,
        aisUnits: workoutsAis,
        color: colorScheme.secondary,
        countDisplay: '${retro.workoutsCount}',
      ),
      _ActivityGlanceItem(
        label: 'Habits',
        sharePercent: habitsShare,
        aisUnits: habitsAis,
        color: colorScheme.tertiary,
        countDisplay: '${retro.habitsCompletedCount}',
      ),
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
            'THIS WEEK AT A GLANCE (IMPACT SCORE)',
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
                  if (item.aisUnits <= 0) return const SizedBox.shrink();
                  final flex = item.sharePercent > 0 ? item.sharePercent : 1;

                  return Expanded(
                    flex: flex,
                    child: Container(
                      color: item.color,
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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.countDisplay} (${item.sharePercent}%)',
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
