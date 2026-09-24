import 'package:flutter/material.dart';
import '../../../../data/models/dashboard_feed_model.dart';

class FitnessCard extends StatelessWidget {
  final DashboardFitnessSection fitness;

  const FitnessCard({super.key, required this.fitness});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (fitness.workoutsThisWeekCount / fitness.targetWorkouts)
        .clamp(0.0, 1.0);
    final done = fitness.workoutsThisWeekCount >= fitness.targetWorkouts;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done
                      ? Icons.fitness_center_rounded
                      : Icons.fitness_center_outlined,
                  color:
                      done ? colorScheme.tertiary : colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Fitness',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              '${fitness.workoutsThisWeekCount}/${fitness.targetWorkouts}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: done
                        ? colorScheme.tertiary
                        : colorScheme.onSurface,
                  ),
            ),
            Text(
              'workouts this week',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: colorScheme.primary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  done ? colorScheme.tertiary : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  fitness.workedOutToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: fitness.workedOutToday
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  fitness.workedOutToday
                      ? 'Trained today ✓'
                      : 'No workout yet',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fitness.workedOutToday
                            ? colorScheme.tertiary
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
