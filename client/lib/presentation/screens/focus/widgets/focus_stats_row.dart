import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/focus_provider.dart';

class FocusStatsRow extends StatelessWidget {
  final FocusState state;

  const FocusStatsRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final stats = state.todayStats;
    final totalMins = stats?.totalMinutesToday ?? 0;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final count = stats?.totalSessionsToday ?? state.todaySessions.length;

    // Daily 2-hour goal progress (120 minutes)
    const goalMinutes = 120;
    final goalProgress = (totalMins / goalMinutes).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FOCUS TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 28,
              width: 1,
              color: colorScheme.outlineVariant.withAlpha(40),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SESSIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.verticalGapMd,

        // Daily Goal Progress Bar (2h Goal)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Goal (2h)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                  Text(
                    '${(goalProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryRed,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: goalProgress,
                  minHeight: 5,
                  backgroundColor: colorScheme.outlineVariant.withAlpha(40),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
