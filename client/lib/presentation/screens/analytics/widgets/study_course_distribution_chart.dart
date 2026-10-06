import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class StudyCourseDistributionChart extends StatelessWidget {
  final List<CourseStudyTime> courses;

  const StudyCourseDistributionChart({super.key, required this.courses});

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

    if (courses.isEmpty) {
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
              'ACADEMIC STUDY TIME BY COURSE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant.withAlpha(160),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No academic study sessions recorded in this cycle. Log course study sessions to view distribution.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    double maxVal = 0;
    for (final c in courses) {
      if (c.hours > maxVal) maxVal = c.hours;
    }
    final chartMaxY = maxVal > 0 ? (maxVal * 1.25) : 5.0;

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < courses.length; i++) {
      final crs = courses[i];
      final color = _parseHexColor(crs.color, colorScheme.tertiary);
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: crs.hours,
              color: color,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

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
                'ACADEMIC STUDY TIME BY COURSE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              Text(
                '${courses.length} courses',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapLg,

          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withAlpha(20),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}h',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < courses.length) {
                          final label = courses[idx].code ??
                              (courses[idx].courseName.length > 8
                                  ? courses[idx].courseName.substring(0, 8)
                                  : courses[idx].courseName);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
