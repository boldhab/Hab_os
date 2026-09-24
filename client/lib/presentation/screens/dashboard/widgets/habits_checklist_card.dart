import 'package:flutter/material.dart';
import '../../../../data/models/dashboard_feed_model.dart';

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
    final completedPct =
        habits.total > 0 ? habits.completedToday / habits.total : 0.0;
    final allDone = habits.completedToday == habits.total && habits.total > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  allDone
                      ? Icons.check_circle_rounded
                      : Icons.repeat_rounded,
                  color: allDone
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Habits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${habits.completedToday}/${habits.total}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: allDone
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completedPct,
                minHeight: 5,
                backgroundColor:
                    colorScheme.primary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  allDone ? colorScheme.tertiary : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Habit list
            if (habits.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No active habits yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...habits.items.map((h) => _HabitRow(
                    habit: h,
                    onTap: onHabitTap,
                    colorScheme: colorScheme,
                  )),
          ],
        ),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final DashboardHabitItem habit;
  final void Function(String) onTap;
  final ColorScheme colorScheme;

  const _HabitRow({
    required this.habit,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: habit.isCompletedToday ? null : () => onTap(habit.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Checkbox visual
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.isCompletedToday
                    ? colorScheme.tertiary
                    : Colors.transparent,
                border: Border.all(
                  color: habit.isCompletedToday
                      ? colorScheme.tertiary
                      : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: habit.isCompletedToday
                  ? Icon(Icons.check_rounded,
                      size: 14, color: colorScheme.onTertiary)
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + streak
            Expanded(
              child: Text(
                habit.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: habit.isCompletedToday
                          ? TextDecoration.lineThrough
                          : null,
                      color: habit.isCompletedToday
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
              ),
            ),

            // Streak badge
            if (habit.currentStreak > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}d',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
