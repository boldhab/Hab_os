import 'package:flutter/material.dart';
import '../../../../data/models/habit_model.dart';

/// The Daily Rhythm progress card summarizing completions, best streaks, and active habit ratios.
class HabitOverviewCard extends StatelessWidget {
  final List<HabitModel> habits;

  const HabitOverviewCard({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeHabits = habits.where((habit) => habit.isActive).toList();
    final completedCount =
        activeHabits.where((habit) => habit.isCompletedToday).length;
    final completionRatio = activeHabits.isEmpty
        ? 0.0
        : completedCount / activeHabits.length;
    final bestStreak = activeHabits.isEmpty
        ? 0
        : activeHabits
            .map((habit) => habit.currentStreak)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(22),
            colorScheme.primaryContainer.withAlpha(105),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily rhythm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome_rounded,
                  color: colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            activeHabits.isEmpty
                ? 'Create a habit to start building momentum.'
                : '$completedCount of ${activeHabits.length} habits completed today',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completionRatio,
              minHeight: 7,
              backgroundColor: colorScheme.outlineVariant.withAlpha(70),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _overviewMetric(
                context,
                value: '${(completionRatio * 100).round()}%',
                label: 'complete',
              ),
              _overviewMetric(
                context,
                value: '$bestStreak days',
                label: 'best active streak',
              ),
              _overviewMetric(
                context,
                value: '${activeHabits.length}',
                label: 'active habits',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric(BuildContext context,
      {required String value, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
