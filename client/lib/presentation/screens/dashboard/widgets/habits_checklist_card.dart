import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/app_animated_check.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/section_header.dart';

/// Interactive habit checklist with streak badges and completion checkmarks.
class HabitsChecklistCard extends StatelessWidget {
  final DashboardHabitsSection habits;
  final void Function(String habitId) onHabitTap;

  const HabitsChecklistCard({
    super.key,
    required this.habits,
    required this.onHabitTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryRed = colorScheme.primary;

    final completedPct = habits.total > 0
        ? (habits.completedToday / habits.total).clamp(0.0, 1.0)
        : 0.0;
    final allDone = habits.completedToday == habits.total && habits.total > 0;
    final accentColor = allDone ? const Color(0xFF34A853) : primaryRed;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SectionHeader(
            icon: allDone ? Icons.check_circle_rounded : Icons.repeat_rounded,
            title: 'Today\'s Habits',
            iconColor: accentColor,
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${habits.completedToday}/${habits.total}',
                style: textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          AppSpacing.verticalGapSm,

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedPct,
              minHeight: 4.5,
              backgroundColor: accentColor.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          AppSpacing.verticalGapSm,

          // Habit list
          if (habits.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No active habits yet.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...habits.items.map((h) => _HabitRow(
                  habit: h,
                  onTap: onHabitTap,
                  colorScheme: colorScheme,
                  activeColor: const Color(0xFF34A853),
                )),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final DashboardHabitItem habit;
  final void Function(String) onTap;
  final ColorScheme colorScheme;
  final Color activeColor;

  const _HabitRow({
    required this.habit,
    required this.onTap,
    required this.colorScheme,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: InkWell(
        onTap: () => onTap(habit.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Checkbox visual
              AppAnimatedCheck(
                value: habit.isCompletedToday,
                isCircle: true,
                size: 22,
                activeColor: activeColor,
                onChanged: (_) => onTap(habit.id),
              ),
              AppSpacing.horizontalGapMd,

              // Name
              Expanded(
                child: Text(
                  habit.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: habit.isCompletedToday
                        ? FontWeight.w400
                        : FontWeight.w600,
                    fontSize: 14,
                    decoration: habit.isCompletedToday
                        ? TextDecoration.lineThrough
                        : null,
                    color: habit.isCompletedToday
                        ? colorScheme.onSurfaceVariant.withAlpha(150)
                        : colorScheme.onSurface,
                  ),
                ),
              ),

              // Streak badge (Icon instead of emoji)
              if (habit.currentStreak > 0) ...[
                AppSpacing.horizontalGapSm,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${habit.currentStreak}d',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
