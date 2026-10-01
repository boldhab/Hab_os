import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../analytics_screen.dart';

class AnalyticsFocusChart extends StatefulWidget {
  final RetrospectiveModel retro;

  const AnalyticsFocusChart({super.key, required this.retro});

  @override
  State<AnalyticsFocusChart> createState() => _AnalyticsFocusChartState();
}

class _AnalyticsFocusChartState extends State<AnalyticsFocusChart> {
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final entries = widget.retro.dailyFocusHours.entries.toList();

    double maxVal = 0.0;
    double sumHours = 0.0;
    for (final e in entries) {
      sumHours += e.value;
      if (e.value > maxVal) maxVal = e.value;
    }

    final avgHours = entries.isNotEmpty ? sumHours / entries.length : 0.0;
    final chartCeiling = maxVal > 0 ? (maxVal * 1.25) : 8.0;

    return Semantics(
      label:
          '7-day daily focus hours chart. Total ${widget.retro.totalFocusHours} hours, daily average ${avgHours.toStringAsFixed(1)} hours.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAILY FOCUS BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Avg ${avgHours.toStringAsFixed(1)}h/day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryRed,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalGapLg,

            // Tooltip Display for Selected Bar
            if (_selectedBarIndex != null &&
                _selectedBarIndex! < entries.length) ...[
              Builder(
                builder: (context) {
                  final entry = entries[_selectedBarIndex!];
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryRed.withAlpha(50)),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value.toStringAsFixed(1)} focus hours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryRed,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            // Custom Painter Vertical Bar Chart
            RepaintBoundary(
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    const height = 180.0;

                    return GestureDetector(
                      onTapDown: (details) {
                        final barWidth = width / entries.length;
                        final clickedIndex =
                            (details.localPosition.dx / barWidth).floor();
                        if (clickedIndex >= 0 &&
                            clickedIndex < entries.length) {
                          AppHaptics.selection();
                          setState(() {
                            _selectedBarIndex = clickedIndex;
                          });
                        }
                      },
                      child: CustomPaint(
                        size: Size(width, height),
                        painter: _BarChartPainter(
                          entries: entries,
                          maxVal: chartCeiling,
                          avgVal: avgHours,
                          peakVal: maxVal,
                          primaryRed: primaryRed,
                          trackColor: colorScheme.outlineVariant.withAlpha(30),
                          textColor: colorScheme.onSurfaceVariant,
                          selectedIndex: _selectedBarIndex,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double maxVal;
  final double avgVal;
  final double peakVal;
  final Color primaryRed;
  final Color trackColor;
  final Color textColor;
  final int? selectedIndex;

  const _BarChartPainter({
    required this.entries,
    required this.maxVal,
    required this.avgVal,
    required this.peakVal,
    required this.primaryRed,
    required this.trackColor,
    required this.textColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const bottomLabelHeight = 24.0;
    final chartHeight = size.height - bottomLabelHeight;
    final n = entries.length;
    final totalWidth = size.width;
    final slotWidth = totalWidth / n;
    final barWidth = math.min(slotWidth * 0.5, 24.0);

    // 1. Average Reference Line (Dashed Line)
    if (avgVal > 0 && maxVal > 0) {
      final avgY = chartHeight - (chartHeight * (avgVal / maxVal));
      final dashPaint = Paint()
        ..color = primaryRed.withAlpha(100)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      double startX = 0.0;
      while (startX < totalWidth) {
        canvas.drawLine(
          Offset(startX, avgY),
          Offset(math.min(startX + 4, totalWidth), avgY),
          dashPaint,
        );
        startX += 8;
      }
    }

    // 2. Render Vertical Bars & Axis Labels
    for (int i = 0; i < n; i++) {
      final entry = entries[i];
      final val = entry.value;
      final isPeak = val == peakVal && peakVal > 0;
      final isSelected = selectedIndex == i;

      final cx = (i * slotWidth) + (slotWidth / 2);
      final left = cx - (barWidth / 2);

      // Bar Height (Zero hours shows a min 4px stub bar)
      final barH =
          maxVal > 0 ? math.max(4.0, chartHeight * (val / maxVal)) : 4.0;
      final top = chartHeight - barH;

      final barPaint = Paint()
        ..color = isSelected
            ? primaryRed
            : isPeak
                ? primaryRed.withAlpha(220)
                : trackColor.withAlpha(120)
        ..style = PaintingStyle.fill;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barH),
        const Radius.circular(6),
      );

      canvas.drawRRect(rrect, barPaint);

      // X-Axis Date / Weekday Label
      final dayLabel =
          entry.key.length >= 5 ? entry.key.substring(5) : entry.key;
      final textPainter = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                isPeak || isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isPeak || isSelected ? primaryRed : textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.entries != entries ||
      old.selectedIndex != selectedIndex ||
      old.maxVal != maxVal;
}
