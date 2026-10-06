import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/ai_insights_model.dart';
import '../../../widgets/common/app_card.dart';

/// Renders automated AI detection of overlooked and lagging life domains (UC-142)
class AiNeglectedAreasCard extends StatelessWidget {
  final List<NeglectedArea> areas;

  const AiNeglectedAreasCard({super.key, required this.areas});

  IconData _getDomainIcon(String domain) {
    switch (domain.toUpperCase()) {
      case 'FITNESS':
        return Icons.fitness_center_rounded;
      case 'STUDY':
        return Icons.school_rounded;
      case 'FINANCE':
        return Icons.account_balance_wallet_rounded;
      case 'HABITS':
        return Icons.repeat_rounded;
      case 'DEV':
        return Icons.code_rounded;
      case 'PRODUCTIVITY':
      default:
        return Icons.timer_rounded;
    }
  }

  Color _getSeverityColor(String severity, ColorScheme colorScheme) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return colorScheme.error;
      case 'MEDIUM':
        return Colors.amber.shade700;
      case 'LOW':
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: Colors.amber.shade700.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.radar_rounded,
                  color: Colors.amber.shade700,
                  size: 18,
                ),
              ),
              AppSpacing.horizontalGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOMAIN VULNERABILITY RADAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    AppSpacing.verticalGapXs,
                    Text(
                      'Lagging & Neglected Areas',
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
              if (areas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: colorScheme.error.withAlpha(60)),
                  ),
                  child: Text(
                    '${areas.length} Flagged',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.verticalGapMd,
          if (areas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(isDark ? 30 : 16),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.green, size: 24),
                  AppSpacing.horizontalGapMd,
                  Expanded(
                    child: Text(
                      'All life domains are currently balanced. Keep maintaining your daily routines and focus cadence.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: areas.length,
              separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
              itemBuilder: (context, index) {
                final area = areas[index];
                final sevColor = _getSeverityColor(area.severity, colorScheme);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 50),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: sevColor.withAlpha(60),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getDomainIcon(area.domain),
                            size: 16,
                            color: sevColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            area.domain,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: sevColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withAlpha(24),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              area.severity,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: sevColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalGapXs,
                      Text(
                        area.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        area.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      AppSpacing.verticalGapSm,
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                            ),
                            child: Text(
                              '${area.metricLabel}: ${area.metricValue}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (area.daysInactive != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${area.daysInactive}d inactive',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (area.recommendedAction.isNotEmpty) ...[
                        AppSpacing.verticalGapSm,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withAlpha(180),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  size: 14, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  area.recommendedAction,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
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
        ],
      ),
    );
  }
}
