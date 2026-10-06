import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/habit_model.dart';
import '../behavioral_insights_screen.dart';

/// Highlight banner displaying top behavioral habit correlation insights with 1-tap navigation to detailed analytics.
class HabitCorrelationBanner extends StatelessWidget {
  final List<HabitCorrelationModel> correlations;

  const HabitCorrelationBanner({super.key, required this.correlations});

  @override
  Widget build(BuildContext context) {
    if (correlations.isEmpty) return const SizedBox.shrink();
    final correlation = correlations.first;
    final semantics = AppSemanticColors.of(context);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BehavioralInsightsScreen(),
        ),
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: semantics.warning.withAlpha(25),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: semantics.warning.withAlpha(80)),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: semantics.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Behavioral Habit Insight',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (correlations.length > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: semantics.warning.withAlpha(45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${correlations.length - 1} more',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: semantics.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    correlation.insightText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: semantics.warning),
          ],
        ),
      ),
    );
  }
}
