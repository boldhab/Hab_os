import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class AnalyticsPeriodComparisonCard extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsPeriodComparisonCard({super.key, required this.retro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final comparison = retro.comparison;

    if (comparison.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERIOD-OVER-PERIOD VARIANCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  retro.period == 'MONTHLY' ? 'vs Prior 30 Days' : 'vs Prior 7 Days',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comparison.length,
            separatorBuilder: (_, __) => Divider(
              height: 14,
              thickness: 0.6,
              color: colorScheme.outlineVariant.withAlpha(25),
            ),
            itemBuilder: (context, index) {
              final item = comparison[index];
              final isPositive = item.deltaPercentage > 0;
              final isZero = item.deltaPercentage == 0;
              final chipBg = isZero
                  ? colorScheme.outlineVariant.withAlpha(30)
                  : isPositive
                      ? semantics.success.withAlpha(22)
                      : semantics.danger.withAlpha(22);
              final chipFg = isZero
                  ? colorScheme.onSurfaceVariant
                  : isPositive
                      ? semantics.success
                      : semantics.danger;

              final sign = isPositive ? '+' : '';

              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.metric,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item.current} ${item.unit}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: chipFg.withAlpha(50), width: 0.8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isZero
                              ? Icons.remove_rounded
                              : isPositive
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                          size: 11,
                          color: chipFg,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$sign${item.deltaPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: chipFg,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
