import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class FinanceSpendingPieChart extends StatelessWidget {
  final List<CategorySpending> categories;

  const FinanceSpendingPieChart({super.key, required this.categories});

  Color _parseHexColor(String hexStr, Color fallback) {
    try {
      final clean = hexStr.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPENDING BREAKDOWN BY CATEGORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant.withAlpha(160),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No expense transactions captured for this timeframe.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final totalAmount = categories.fold<double>(0, (sum, c) => sum + c.amount);

    final sections = categories.map((cat) {
      final color = _parseHexColor(cat.color, colorScheme.primary);
      return PieChartSectionData(
        value: cat.amount,
        color: color,
        radius: 28,
        showTitle: false,
      );
    }).toList();

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
                'SPENDING BREAKDOWN BY CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(0)} total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapLg,

          Row(
            children: [
              // Donut Chart
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Category Legend
              Expanded(
                child: Column(
                  children: categories.take(4).map((cat) {
                    final color = _parseHexColor(cat.color, colorScheme.primary);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${cat.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
