import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class AnalyticsHeroCard extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsHeroCard({super.key, required this.retro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    // Calculate Best Day and Daily Average from dailyFocusHours map
    double maxHours = 0.0;
    String bestDayLabel = 'N/A';
    double totalHoursSum = 0.0;
    final entries = retro.dailyFocusHours.entries.toList();

    for (final e in entries) {
      totalHoursSum += e.value;
      if (e.value > maxHours) {
        maxHours = e.value;
        bestDayLabel = e.key.length >= 5 ? e.key.substring(5) : e.key;
      }
    }

    final dailyAverage =
        entries.isNotEmpty ? totalHoursSum / entries.length : 0.0;
    final insightText = maxHours > 0
        ? 'Best day: $bestDayLabel (${maxHours.toStringAsFixed(1)}h) • Avg: ${dailyAverage.toStringAsFixed(1)}h/day'
        : 'Daily average: ${dailyAverage.toStringAsFixed(1)}h/day';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryRed.withAlpha(28),
            primaryRed.withAlpha(8),
            colorScheme.surfaceContainerHighest.withAlpha(40),
          ],
        ),
        border: Border.all(
          color: primaryRed.withAlpha(45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL FOCUS TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        retro.totalFocusHours.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          color: colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'hrs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Mini 7-Bar Sparkline in Header
              if (entries.isNotEmpty)
                SizedBox(
                  width: 70,
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: entries.map((e) {
                      final h = maxHours > 0 ? (e.value / maxHours) : 0.0;
                      final isPeak = e.value == maxHours && maxHours > 0;

                      return Container(
                        width: 6,
                        height: math.max(4.0, 34.0 * h),
                        decoration: BoxDecoration(
                          color: isPeak ? primaryRed : primaryRed.withAlpha(60),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          AppSpacing.verticalGapMd,

          // One-Line Insight Caption
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryRed.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryRed.withAlpha(30)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: primaryRed),
                Text(
                  insightText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
