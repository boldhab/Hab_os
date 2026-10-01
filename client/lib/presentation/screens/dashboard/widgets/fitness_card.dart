import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/common/app_card.dart';

class FitnessCard extends StatelessWidget {
  final DashboardFitnessSection fitness;

  const FitnessCard({super.key, required this.fitness});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final target = fitness.targetWorkouts > 0 ? fitness.targetWorkouts : 1;
    final pct = fitness.targetWorkouts > 0
        ? (fitness.workoutsThisWeekCount / target).clamp(0.0, 1.0)
        : 0.0;
    final done = fitness.workoutsThisWeekCount >= fitness.targetWorkouts &&
        fitness.targetWorkouts > 0;
    final activeColor = done ? const Color(0xFF34A853) : colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: activeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: activeColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Fitness',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${fitness.workoutsThisWeekCount}/${fitness.targetWorkouts}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: done ? const Color(0xFF34A853) : colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'workouts this week',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(180),
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4.0,
              backgroundColor: activeColor.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                fitness.workedOutToday
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 12,
                color: fitness.workedOutToday
                    ? const Color(0xFF34A853)
                    : colorScheme.onSurfaceVariant.withAlpha(150),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fitness.workedOutToday ? 'Trained today ✓' : 'No workout yet',
                  style: textTheme.labelSmall?.copyWith(
                    color: fitness.workedOutToday
                        ? const Color(0xFF34A853)
                        : colorScheme.onSurfaceVariant.withAlpha(180),
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
