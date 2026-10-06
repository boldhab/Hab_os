import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class ProductivityDiurnalChart extends StatelessWidget {
  final ProductivityTimeDistribution? distribution;

  const ProductivityDiurnalChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    if (distribution == null) return const SizedBox.shrink();

    final dist = distribution!;
    final total = dist.morningHours + dist.afternoonHours + dist.eveningHours + dist.nightHours;

    final windows = [
      {'label': 'Morning', 'hours': dist.morningHours, 'icon': Icons.wb_sunny_outlined, 'range': '6AM-12PM'},
      {'label': 'Afternoon', 'hours': dist.afternoonHours, 'icon': Icons.wb_cloudy_outlined, 'range': '12PM-6PM'},
      {'label': 'Evening', 'hours': dist.eveningHours, 'icon': Icons.nights_stay_outlined, 'range': '6PM-12AM'},
      {'label': 'Night', 'hours': dist.nightHours, 'icon': Icons.bedtime_outlined, 'range': '12AM-6AM'},
    ];

    final maxVal = windows.fold<double>(0, (prev, w) => (w['hours'] as double) > prev ? (w['hours'] as double) : prev);

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
                'DIURNAL PRODUCTIVITY HEATMAP',
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
                  color: primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: primaryRed.withAlpha(40)),
                ),
                child: Text(
                  'Peak: ${dist.peakWindow}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primaryRed,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,

          Row(
            children: windows.map((w) {
              final label = w['label'] as String;
              final hours = w['hours'] as double;
              final icon = w['icon'] as IconData;
              final range = w['range'] as String;
              final isPeak = hours == maxVal && maxVal > 0;
              final sharePercent = total > 0 ? ((hours / total) * 100).round() : 0;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isPeak ? primaryRed.withAlpha(18) : colorScheme.surfaceContainerHighest.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPeak ? primaryRed.withAlpha(60) : colorScheme.outlineVariant.withAlpha(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isPeak ? primaryRed : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${hours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isPeak ? primaryRed : colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        range,
                        style: TextStyle(
                          fontSize: 8,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                      if (sharePercent > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$sharePercent%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isPeak ? primaryRed : colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
