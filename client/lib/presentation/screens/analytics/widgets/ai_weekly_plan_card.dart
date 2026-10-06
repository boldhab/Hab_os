import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/ai_insights_model.dart';
import '../../../widgets/common/app_card.dart';

/// Renders personalized multi-domain weekly rebalancing plan (UC-143)
class AiWeeklyPlanCard extends StatelessWidget {
  final PersonalizedPlan plan;

  const AiWeeklyPlanCard({super.key, required this.plan});

  Color _getDomainColor(String domain, ColorScheme colorScheme) {
    switch (domain.toUpperCase()) {
      case 'FITNESS':
        return Colors.redAccent.shade400;
      case 'STUDY':
        return Colors.deepPurpleAccent;
      case 'FINANCE':
        return const Color(0xFF10B981);
      case 'DEV':
        return Colors.teal;
      case 'HABITS':
        return Colors.blueAccent;
      case 'PRODUCTIVITY':
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colorScheme.primary;

    return AppCard(
      borderRadius: AppRadius.lg,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.indigo,
                  size: 18,
                ),
              ),
              AppSpacing.horizontalGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUTONOMOUS REBALANCING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.indigo,
                      ),
                    ),
                    AppSpacing.verticalGapXs,
                    Text(
                      'Personalized Weekly Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: Colors.indigo.withAlpha(50)),
                ),
                child: Text(
                  '${(plan.totalSuggestedFocusMins / 60).toStringAsFixed(1)}h Total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,
          // Weekly Goal Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withAlpha(isDark ? 24 : 12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: primary.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_rounded, size: 18, color: primary),
                AppSpacing.horizontalGapSm,
                Expanded(
                  child: Text(
                    plan.weeklyGoal,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalGapMd,
          // 7-Day Schedule Timeline
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.schedule.length,
            separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
            itemBuilder: (context, index) {
              final day = plan.schedule[index];
              final domainColor = _getDomainColor(day.focusDomain, colorScheme);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 60 : 30),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          day.dayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        AppSpacing.horizontalGapSm,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: domainColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            day.focusDomain,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: domainColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${day.targetMins}m Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (day.suggestedActions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final action in day.suggestedActions)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12)),
                              Expanded(
                                child: Text(
                                  action,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (plan.aiAdvice.isNotEmpty) ...[
            AppSpacing.verticalGapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withAlpha(16),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.amber.shade700.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_rounded,
                      size: 16, color: Colors.amber.shade700),
                  AppSpacing.horizontalGapSm,
                  Expanded(
                    child: Text(
                      plan.aiAdvice,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
