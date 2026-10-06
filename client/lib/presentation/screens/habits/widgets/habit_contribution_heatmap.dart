import 'package:flutter/material.dart';
import '../../../../data/models/habit_model.dart';
import '../../../../app/theme/app_theme.dart';

class HabitContributionHeatmap extends StatelessWidget {
  final List<HabitLogModel> logs;
  final Color primaryColor;
  final int weeksToShow;

  const HabitContributionHeatmap({
    super.key,
    required this.logs,
    this.primaryColor = Colors.green,
    this.weeksToShow = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    // Build a map of YYYY-MM-DD -> HabitLogModel
    final logMap = <String, HabitLogModel>{};
    for (final log in logs) {
      final parsed = DateTime.tryParse(log.date)?.toLocal();
      final dateKey = parsed != null
          ? '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}'
          : log.date.split('T')[0];
      logMap[dateKey] = log;
    }

    final today = DateTime.now();
    // End date is upcoming Sunday or today
    final totalDays = weeksToShow * 7;
    final startDate = today.subtract(Duration(days: totalDays - 1));

    // Align startDate to Monday
    final daysFromMonday = (startDate.weekday - 1) % 7;
    final alignedStart = startDate.subtract(Duration(days: daysFromMonday));

    final weeks = <List<DateTime>>[];
    var currentDay = alignedStart;

    while (currentDay.isBefore(today.add(const Duration(days: 1)))) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity Heatmap (${weeks.length} weeks)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                _buildLegendItem(
                    colorScheme, colorScheme.surfaceContainerHighest, 'Missed'),
                const SizedBox(width: 8),
                _buildLegendItem(colorScheme, semantics.info, 'Frozen ❄️'),
                const SizedBox(width: 8),
                _buildLegendItem(colorScheme, primaryColor, 'Done'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // Show most recent weeks on the right
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks.map((week) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: week.map((date) {
                    final dateKey =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final isFuture = date.isAfter(today);
                    final log = logMap[dateKey];

                    Color cellColor;
                    Widget? innerIcon;

                    if (isFuture) {
                      cellColor = Colors.transparent;
                    } else if (log != null && log.wasFrozen) {
                      cellColor = semantics.info.withAlpha(80);
                      innerIcon = Icon(Icons.ac_unit_rounded,
                          size: 9, color: semantics.info);
                    } else if (log != null && log.isCompleted) {
                      cellColor = primaryColor;
                    } else {
                      cellColor = colorScheme.surfaceContainerHighest;
                    }

                    return Tooltip(
                      message: isFuture
                          ? ''
                          : '$dateKey: ${log == null ? 'Missed' : (log.wasFrozen ? 'Streak Frozen ❄️' : 'Completed')}',
                      child: Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(3),
                          border: isFuture
                              ? null
                              : Border.all(
                                  color:
                                      colorScheme.outlineVariant.withAlpha(40),
                                  width: 0.5,
                                ),
                        ),
                        child: Center(child: innerIcon),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(ColorScheme colorScheme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
