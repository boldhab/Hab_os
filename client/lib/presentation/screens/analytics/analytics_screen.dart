import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'widgets/analytics_hero_card.dart';
import 'widgets/analytics_stat_tiles.dart';
import 'widgets/analytics_focus_chart.dart';
import 'widgets/analytics_at_a_glance_card.dart';

class RetrospectiveModel {
  final double totalFocusHours;
  final double totalTrackedHours;
  final int completedTasksCount;
  final int workoutsCount;
  final int habitsCompletedCount;
  final Map<String, double> dailyFocusHours;

  RetrospectiveModel({
    required this.totalFocusHours,
    required this.totalTrackedHours,
    required this.completedTasksCount,
    required this.workoutsCount,
    required this.habitsCompletedCount,
    required this.dailyFocusHours,
  });

  factory RetrospectiveModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final daily = <String, double>{};
    if (json['dailyFocusHours'] is Map) {
      (json['dailyFocusHours'] as Map).forEach((k, v) {
        if (v is num) daily[k.toString()] = v.toDouble();
      });
    }
    return RetrospectiveModel(
      totalFocusHours: (summary['totalFocusHours'] as num?)?.toDouble() ?? 0.0,
      totalTrackedHours:
          (summary['totalTrackedHours'] as num?)?.toDouble() ?? 0.0,
      completedTasksCount:
          (summary['completedTasksCount'] as num?)?.toInt() ?? 0,
      workoutsCount: (summary['workoutsCount'] as num?)?.toInt() ?? 0,
      habitsCompletedCount:
          (summary['habitsCompletedCount'] as num?)?.toInt() ?? 0,
      dailyFocusHours: daily,
    );
  }
}

final retrospectiveProvider =
    FutureProvider.autoDispose<RetrospectiveModel>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.analyticsRetrospective);
  final data = response.data['data'] ?? response.data;
  return RetrospectiveModel.fromJson(Map<String, dynamic>.from(data));
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _getDateRangeString(Map<String, double> dailyFocusHours) {
    if (dailyFocusHours.isEmpty) {
      final now = DateTime.now();
      final ago = now.subtract(const Duration(days: 6));
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[ago.month - 1]} ${ago.day} - ${months[now.month - 1]} ${now.day}';
    }

    final keys = dailyFocusHours.keys.toList();
    final first = keys.first;
    final last = keys.last;
    return '$first to $last';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroAsync = ref.watch(retrospectiveProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: primaryRed.withAlpha(40)),
                  ),
                  child: Text(
                    'Past 7 days',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryRed,
                    ),
                  ),
                ),
              ],
            ),
            retroAsync.when(
              data: (retro) => Text(
                _getDateRangeString(retro.dailyFocusHours),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                ),
              ),
              loading: () => Text(
                'Calculating retrospective...',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: colorScheme.onSurfaceVariant),
            tooltip: 'Refresh',
            onPressed: () {
              AppHaptics.light();
              ref.invalidate(retrospectiveProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: retroAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(retrospectiveProvider),
        ),
        data: (retro) {
          final isZeroActivity = retro.totalFocusHours == 0 &&
              retro.completedTasksCount == 0 &&
              retro.workoutsCount == 0 &&
              retro.habitsCompletedCount == 0;

          if (isZeroActivity) {
            return AppEmptyState(
              icon: Icons.analytics_outlined,
              title: 'No activity recorded this week',
              description:
                  'Start a focus session, complete a task, or log a habit to generate personal insights.',
              actionLabel: 'Start Focus Session',
              onAction: () => context.go('/focus'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(retrospectiveProvider),
            color: primaryRed,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;

                if (isWide) {
                  // Tablet & Wide Desktop 2-Column Layout
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              AnalyticsHeroCard(retro: retro),
                              AppSpacing.verticalGapLg,
                              AnalyticsFocusChart(retro: retro),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              AnalyticsStatTiles(retro: retro),
                              AppSpacing.verticalGapLg,
                              AnalyticsAtAGlanceCard(retro: retro),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Phone Standard Single-Column Layout
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // 1. Hero Summary Card (GPA / Total Focus + Sparkline)
                    AnalyticsHeroCard(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 2. Daily Focus Vertical Bar Chart
                    AnalyticsFocusChart(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 3. Calm Stat Tiles (2x2 Grid)
                    Text(
                      'PERFORMANCE METRICS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                    ),
                    AppSpacing.verticalGapSm,
                    AnalyticsStatTiles(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 4. This Week At A Glance Stacked Share Card
                    AnalyticsAtAGlanceCard(retro: retro),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
