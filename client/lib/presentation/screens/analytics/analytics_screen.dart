import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/models/retrospective_model.dart';
import '../../../domain/usecases/analytics/export_analytics_usecase.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'widgets/analytics_hero_card.dart';
import 'widgets/analytics_stat_tiles.dart';
import 'widgets/analytics_focus_chart.dart';
import 'widgets/analytics_at_a_glance_card.dart';
import 'widgets/analytics_period_comparison_card.dart';
import 'widgets/analytics_multi_domain_card.dart';
import 'widgets/analytics_completed_tasks_card.dart';
import 'widgets/gym_strength_curve_chart.dart';
import 'widgets/finance_spending_pie_chart.dart';
import 'widgets/study_course_distribution_chart.dart';
import 'widgets/productivity_diurnal_chart.dart';
import '../../providers/ai_insights_provider.dart';
import '../../../domain/models/ai_insights_model.dart';
import 'widgets/ai_neglected_areas_card.dart';
import 'widgets/ai_recommended_tasks_card.dart';
import 'widgets/ai_weekly_plan_card.dart';
import '../../widgets/app_bar_ai_button.dart';

export '../../../domain/models/retrospective_model.dart';
export '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _getDateRangeString(Map<String, double> dailyFocusHours) {
    final formatter = DateFormat('MMM d');

    if (dailyFocusHours.isEmpty) {
      final now = DateTime.now();
      final ago = now.subtract(const Duration(days: 6));
      return '${formatter.format(ago)} - ${formatter.format(now)}';
    }

    final keys = dailyFocusHours.keys.toList();
    final firstDate = DateTime.tryParse(keys.first);
    final lastDate = DateTime.tryParse(keys.last);

    if (firstDate != null && lastDate != null) {
      return '${formatter.format(firstDate)} - ${formatter.format(lastDate)}';
    }

    return '${keys.first} - ${keys.last}';
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref, {
    required bool isPdf,
    required String period,
  }) async {
    final dio = ref.read(dioProvider);
    final useCase = ExportAnalyticsUseCase(dio);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compiling ${isPdf ? "PDF" : "CSV"} binary report...'),
          duration: const Duration(seconds: 1),
        ),
      );

      final bytes = await useCase.exportReport(isPdf: isPdf, period: period);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(
              '${isPdf ? "PDF" : "CSV"} compiled successfully (${bytes.length} bytes ready).',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Export failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(selectedPeriodProvider);
    final retroAsync = ref.watch(retrospectiveProvider);
    final aiData = ref.watch(aiInsightsProvider).valueOrNull ?? const AiInsightsData();
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
                    currentPeriod.label,
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
          const AppBarAiButton(),
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Time Tracker',
            onPressed: () => context.push('/more/analytics/time-tracker'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
              title: 'No activity recorded for this period',
              description:
                  'Start a focus session, complete a task, or log a habit to generate personal insights.',
              actionLabel: 'Start Focus Session',
              onAction: () => context.go('/focus'),
            );
          }

          final md = retro.multiDomain;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(retrospectiveProvider),
            color: primaryRed,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;

                final periodToggle = Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(50),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            ref.read(selectedPeriodProvider.notifier).state =
                                TimePeriod.weekly;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: currentPeriod == TimePeriod.weekly
                                  ? colorScheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: currentPeriod == TimePeriod.weekly
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Weekly (7D)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: currentPeriod == TimePeriod.weekly
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: currentPeriod == TimePeriod.weekly
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            ref.read(selectedPeriodProvider.notifier).state =
                                TimePeriod.monthly;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: currentPeriod == TimePeriod.monthly
                                  ? colorScheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: currentPeriod == TimePeriod.monthly
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Monthly (30D)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: currentPeriod == TimePeriod.monthly
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: currentPeriod == TimePeriod.monthly
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                final exportDeck = Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleExport(
                            context,
                            ref,
                            isPdf: false,
                            period: currentPeriod.apiValue,
                          ),
                          icon: const Icon(Icons.table_chart_outlined, size: 18),
                          label: const Text('Export CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _handleExport(
                            context,
                            ref,
                            isPdf: true,
                            period: currentPeriod.apiValue,
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          label: const Text('Export PDF'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryRed,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        periodToggle,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  AnalyticsHeroCard(retro: retro),
                                  AppSpacing.verticalGapLg,
                                  AnalyticsFocusChart(retro: retro),
                                  AppSpacing.verticalGapLg,
                                  ProductivityDiurnalChart(distribution: md?.productivity),
                                  AppSpacing.verticalGapLg,
                                  GymStrengthCurveChart(points: md?.strengthProgression ?? const []),
                                  AppSpacing.verticalGapLg,
                                  AnalyticsMultiDomainCard(retro: retro),
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
                                  AppSpacing.verticalGapLg,
                                  AnalyticsPeriodComparisonCard(retro: retro),
                                  AppSpacing.verticalGapLg,
                                  AiNeglectedAreasCard(areas: aiData.neglectedAreas),
                                  AppSpacing.verticalGapLg,
                                  if (aiData.recommendedTasks.isNotEmpty) ...[
                                    AiRecommendedTasksCard(tasks: aiData.recommendedTasks),
                                    AppSpacing.verticalGapLg,
                                  ],
                                  if (aiData.plan != null) ...[
                                    AiWeeklyPlanCard(plan: aiData.plan!),
                                    AppSpacing.verticalGapLg,
                                  ],
                                  FinanceSpendingPieChart(categories: md?.spendingByCategory ?? const []),
                                  AppSpacing.verticalGapLg,
                                  StudyCourseDistributionChart(courses: md?.studyByCourse ?? const []),
                                  if (retro.completedTasks.isNotEmpty) ...[
                                    AppSpacing.verticalGapLg,
                                    AnalyticsCompletedTasksCard(retro: retro),
                                  ],
                                  AppSpacing.verticalGapLg,
                                  exportDeck,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // Period Toggle Segmented Control
                    periodToggle,

                    // 1. Hero Summary Card
                    AnalyticsHeroCard(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 2. Daily Focus Vertical Bar Chart
                    AnalyticsFocusChart(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 3. Diurnal Productivity Heatmap (UC-147)
                    ProductivityDiurnalChart(distribution: md?.productivity),
                    AppSpacing.verticalGapLg,

                    // 4. Calm Stat Tiles
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

                    // 5. Activity Impact Score Distribution
                    AnalyticsAtAGlanceCard(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 6. Period Comparison & Variances (UC-146)
                    AnalyticsPeriodComparisonCard(retro: retro),
                    AppSpacing.verticalGapLg,

                    // AI Insights Engine: Neglected Areas Radar (UC-142)
                    AiNeglectedAreasCard(areas: aiData.neglectedAreas),
                    AppSpacing.verticalGapLg,

                    // AI Insights Engine: Recommended High-Impact Tasks (UC-141)
                    if (aiData.recommendedTasks.isNotEmpty) ...[
                      AiRecommendedTasksCard(tasks: aiData.recommendedTasks),
                      AppSpacing.verticalGapLg,
                    ],

                    // AI Insights Engine: Autonomous Weekly Plan (UC-143)
                    if (aiData.plan != null) ...[
                      AiWeeklyPlanCard(plan: aiData.plan!),
                      AppSpacing.verticalGapLg,
                    ],

                    // 7. Deep Multi-Domain Matrix (UC-144)
                    AnalyticsMultiDomainCard(retro: retro),
                    AppSpacing.verticalGapLg,

                    // 8. Gym 1RM Strength Progression Curve (UC-150)
                    GymStrengthCurveChart(points: md?.strengthProgression ?? const []),
                    AppSpacing.verticalGapLg,

                    // 9. Financial Spending Category Breakdown (UC-151)
                    FinanceSpendingPieChart(categories: md?.spendingByCategory ?? const []),
                    AppSpacing.verticalGapLg,

                    // 10. Academic Study Time by Course (UC-149)
                    StudyCourseDistributionChart(courses: md?.studyByCourse ?? const []),
                    AppSpacing.verticalGapLg,

                    // 11. Completed Tasks Recap
                    if (retro.completedTasks.isNotEmpty) ...[
                      AnalyticsCompletedTasksCard(retro: retro),
                      AppSpacing.verticalGapLg,
                    ],

                    // 12. Export Trigger Deck (UC-153 / UC-154)
                    exportDeck,
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
