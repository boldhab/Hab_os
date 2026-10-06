import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/gym_controller.dart';
import '../models/gym_models.dart';

/// Advanced data visualization tab displaying daily bodyweight scatter points
/// overlaid with a smoothed 7-day moving average trend line using fl_chart,
/// accompanied by a virtualized historical log list with deletion controls.
class GymProgressTab extends ConsumerWidget {
  const GymProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(gymBodyMetricsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(gymBodyMetricsProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxxl),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bodyweight & Composition',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Log Weight'),
                onPressed: () => _openLogBodyMetricDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          metricsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error loading progress data: $err'),
              ),
            ),
            data: (metrics) {
              if (metrics.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.monitor_weight_outlined,
                            size: 48, color: colorScheme.primary),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'No weigh-in data yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Log daily weight to reveal your 7-day smoothed trend line and body composition progression.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => _openLogBodyMetricDialog(context, ref),
                          child: const Text('Log First Weigh-In'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Metrics are sorted desc by date from API. Reverse for chronological chart plotting
              final sortedMetrics = metrics.reversed.toList();
              final latest = metrics.first;
              final oldest = metrics.last;
              final weightDelta = latest.weightKg - oldest.weightKg;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stat Cards Matrix
                  _buildStatsMatrix(context, latest, weightDelta, colorScheme, semantics),
                  const SizedBox(height: AppSpacing.lg),

                  // 7-Day Moving Average & Scatter Chart
                  _buildChartCard(context, sortedMetrics, colorScheme, semantics),
                  const SizedBox(height: AppSpacing.xl),

                  // Virtualized Historical Log Catalog
                  _buildHistoryCatalog(context, ref, metrics, colorScheme, semantics),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsMatrix(
    BuildContext context,
    BodyMetricModel latest,
    double deltaKg,
    ColorScheme colorScheme,
    AppSemanticColors semantics,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Latest Weight', '${latest.weightKg} kg', colorScheme.onSurface),
            _statItem('7-Day Rolling Avg', '${latest.sevenDayAverageKg} kg', colorScheme.primary),
            _statItem(
              'Net Delta',
              '${deltaKg >= 0 ? "+" : ""}${deltaKg.toStringAsFixed(1)} kg',
              deltaKg < 0 ? semantics.success : (deltaKg > 0 ? semantics.warning : colorScheme.onSurface),
            ),
            if (latest.bodyFatPercent != null)
              _statItem('Body Fat', '${latest.bodyFatPercent}%', semantics.info),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    List<BodyMetricModel> sortedMetrics,
    ColorScheme colorScheme,
    AppSemanticColors semantics,
  ) {
    final List<FlSpot> rawWeightSpots = [];
    final List<FlSpot> smoothedAvgSpots = [];

    double minWeight = double.infinity;
    double maxWeight = double.negativeInfinity;

    for (int i = 0; i < sortedMetrics.length; i++) {
      final m = sortedMetrics[i];
      final raw = m.weightKg;
      final avg = m.sevenDayAverageKg;

      rawWeightSpots.add(FlSpot(i.toDouble(), raw));
      smoothedAvgSpots.add(FlSpot(i.toDouble(), avg));

      if (raw < minWeight) minWeight = raw;
      if (raw > maxWeight) maxWeight = raw;
      if (avg < minWeight) minWeight = avg;
      if (avg > maxWeight) maxWeight = avg;
    }

    final double minY = (minWeight - 2.0).floorToDouble();
    final double maxY = (maxWeight + 2.0).ceilToDouble();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '7-Day Trend vs Daily Weigh-Ins',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scatter dots: raw entries • Solid line: 7-day rolling average',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary)),
                    const SizedBox(width: 4),
                    const Text('7d Avg', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: semantics.info)),
                    const SizedBox(width: 4),
                    const Text('Daily', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: colorScheme.outlineVariant.withAlpha(30),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 2,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}kg',
                          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (sortedMetrics.length / 5).clamp(1.0, 10.0),
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < sortedMetrics.length) {
                            final dateParts = sortedMetrics[idx].date.split('T')[0].split('-');
                            if (dateParts.length >= 3) {
                              return Text(
                                '${dateParts[1]}/${dateParts[2]}',
                                style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final item = sortedMetrics[idx];
                          final isRaw = spot.barIndex == 0;
                          return LineTooltipItem(
                            isRaw
                                ? 'Weigh-in: ${spot.y.toStringAsFixed(1)} kg\nDate: ${item.date.split("T")[0]}'
                                : '7-Day Avg: ${spot.y.toStringAsFixed(1)} kg',
                            TextStyle(
                              color: isRaw ? semantics.info : colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Daily Raw Scatter Spots (Rendered as distinct dot marks)
                    LineChartBarData(
                      spots: rawWeightSpots,
                      isCurved: false,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: semantics.info,
                            strokeWidth: 1.5,
                            strokeColor: colorScheme.surface,
                          );
                        },
                      ),
                    ),
                    // Smoothed 7-Day Moving Average Line Curve
                    LineChartBarData(
                      spots: smoothedAvgSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withAlpha(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCatalog(
    BuildContext context,
    WidgetRef ref,
    List<BodyMetricModel> metrics,
    ColorScheme colorScheme,
    AppSemanticColors semantics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historical Weigh-In Catalog (${metrics.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Swipe to review logs',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, i) {
            final m = metrics[i];
            final dateStr = m.date.split('T')[0];

            return Card(
              elevation: 0,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.cardRadius,
                side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
              ),
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${m.weightKg.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  '$dateStr • ${m.weightKg} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  '7-Day Rolling: ${m.sevenDayAverageKg}kg${m.bodyFatPercent != null ? " • BF: ${m.bodyFatPercent}%" : ""}${m.waistCm != null ? " • Waist: ${m.waistCm}cm" : ""}${m.notes != null ? " • ${m.notes}" : ""}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: 'Delete Entry',
                  onPressed: () => _confirmDeleteMetric(context, ref, m.id),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openLogBodyMetricDialog(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController();
    final bfCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        title: const Text('Log Body Metric Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Body Weight (kg) *',
                  hintText: 'e.g. 78.5',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: bfCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Body Fat % (optional)',
                  hintText: 'e.g. 14.5',
                  prefixIcon: Icon(Icons.pie_chart_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: waistCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Waist Circumference (cm)',
                  hintText: 'e.g. 82.0',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. Fasted morning weigh-in',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final w = double.tryParse(weightCtrl.text.trim());
              if (w == null) return;
              Navigator.pop(ctx);
              await ref.read(gymControllerProvider).logBodyMetric(
                    weightKg: w,
                    bodyFatPercent: double.tryParse(bfCtrl.text.trim()),
                    waistCm: double.tryParse(waistCtrl.text.trim()),
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
            },
            child: const Text('Save Weigh-In'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteMetric(
      BuildContext context, WidgetRef ref, String metricId) async {
    final semantics = AppSemanticColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        title: const Text('Delete Weigh-in Entry?'),
        content: const Text(
            'This record will be permanently deleted and rolling averages will be recalibrated.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: semantics.danger,
              foregroundColor: semantics.onDanger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(gymControllerProvider).deleteBodyMetric(metricId);
    }
  }
}
