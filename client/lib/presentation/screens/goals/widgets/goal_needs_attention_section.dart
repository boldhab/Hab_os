import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/goal_model.dart';

class GoalNeedsAttentionSection extends StatelessWidget {
  final GoalsHealthSummary healthSummary;
  final Function(String goalId) onGoalTap;

  const GoalNeedsAttentionSection({
    super.key,
    required this.healthSummary,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    // Combine at-risk and behind alerts
    final alerts = [...healthSummary.atRisk, ...healthSummary.behind];

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 16, color: semantics.warning),
            const SizedBox(width: 6),
            Text(
              'NEEDS ATTENTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: semantics.warning,
              ),
            ),
          ],
        ),
        AppSpacing.verticalGapSm,
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final isAtRisk = alert.healthStatus.toUpperCase() == 'AT_RISK';
              final dotColor = isAtRisk ? semantics.danger : semantics.warning;
              final healthLabel = isAtRisk ? 'At risk' : 'Behind';

              return InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onGoalTap(alert.id);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dotColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: dotColor.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                healthLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: dotColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${alert.progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        alert.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        alert.daysUntilTarget != null
                            ? '${alert.daysUntilTarget} days left'
                            : 'No target date',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
