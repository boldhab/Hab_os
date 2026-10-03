import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/app_error_state.dart';
import '../controllers/projects_controller.dart';

class MetricsTab extends ConsumerWidget {
  final String projectId;
  const MetricsTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(projectAnalyticsProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () =>
            ref.invalidate(projectAnalyticsProvider(projectId)),
      ),
      data: (analytics) {
        // Non-zero weekly data for bar chart
        final weeks = analytics.weeklyVelocity;
        final maxY = weeks.isEmpty
            ? 10.0
            : weeks
                .map((w) =>
                    w.tasksCompleted +
                    w.featuresCompleted +
                    w.bugsResolved)
                .fold<int>(0, (a, b) => a > b ? a : b)
                .toDouble()
                .clamp(5, double.infinity);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stat row
            Row(
              children: [
                _statTile('${analytics.totalFocusHours}h', 'FOCUS HOURS',
                    primaryRed, colorScheme),
                const SizedBox(width: 8),
                _statTile('${analytics.progress.toInt()}%', 'PROGRESS',
                    semantics.success, colorScheme),
                const SizedBox(width: 8),
                _statTile(analytics.velocityTrend, 'VELOCITY',
                    analytics.velocityTrend == 'UP'
                        ? semantics.success
                        : analytics.velocityTrend == 'DOWN'
                            ? semantics.danger
                            : colorScheme.onSurfaceVariant,
                    colorScheme),
              ],
            ),
            const SizedBox(height: 16),

            // Health card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Health Signals',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 10),
                  _healthRow(
                      analytics.isStale ? '⚠ Stale' : '✓ Active',
                      analytics.isStale ? semantics.danger : semantics.success,
                      colorScheme),
                  const SizedBox(height: 4),
                  _healthRow(
                      analytics.isFirefighting
                          ? '⚠ Firefighting mode'
                          : '✓ Balanced',
                      analytics.isFirefighting
                          ? semantics.danger
                          : semantics.success,
                      colorScheme),
                  const SizedBox(height: 4),
                  _healthRow(
                      'Status: ${analytics.healthStatus.replaceAll('_', ' ')}',
                      analytics.healthStatus == 'HEALTHY'
                          ? semantics.success
                          : analytics.healthStatus == 'NEEDS_ATTENTION'
                              ? semantics.warning
                              : semantics.danger,
                      colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Technologies
            if (analytics.technologies.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tech Stack',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: analytics.technologies.map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryRed.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: primaryRed.withAlpha(40)),
                          ),
                          child: Text(tech,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryRed)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Real Velocity Chart
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Engineering Velocity',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: primaryRed)),
                        Text('(8 weeks)',
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant
                                    .withAlpha(140))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Legend
                    Row(
                      children: [
                        _legendDot(primaryRed, 'Tasks'),
                        const SizedBox(width: 12),
                        _legendDot(semantics.success, 'Features'),
                        const SizedBox(width: 12),
                        _legendDot(semantics.danger, 'Bugs Fixed'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (weeks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No velocity data yet.\nComplete tasks and features to see trends.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant
                                    .withAlpha(140)),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY + 2,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: colorScheme.outlineVariant
                                    .withAlpha(30),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (v, meta) => Text(
                                    v.toInt().toString(),
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: colorScheme.onSurfaceVariant
                                            .withAlpha(140)),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= weeks.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final dateStr =
                                        weeks[idx].weekStart.length >= 10
                                            ? weeks[idx].weekStart.substring(5, 10)
                                            : weeks[idx].weekStart;
                                    return Transform.rotate(
                                      angle: -0.3,
                                      child: Text(
                                        dateStr,
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: colorScheme
                                                .onSurfaceVariant
                                                .withAlpha(140)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: weeks.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final w = entry.value;
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: w.tasksCompleted.toDouble(),
                                    color: primaryRed,
                                    width: 6,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                  BarChartRodData(
                                    toY: w.featuresCompleted.toDouble(),
                                    color: semantics.success,
                                    width: 6,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                  BarChartRodData(
                                    toY: w.bugsResolved.toDouble(),
                                    color: semantics.danger,
                                    width: 6,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ],
                                barsSpace: 3,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Formula explanation
            if (analytics.formula.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Progress Formula',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(analytics.formula,
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _statTile(
      String value, String label, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant.withAlpha(140))),
          ],
        ),
      ),
    );
  }

  Widget _healthRow(String text, Color color, ColorScheme cs) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }
}
