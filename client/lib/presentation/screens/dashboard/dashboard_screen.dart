import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../data/models/dashboard_feed_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_error_state.dart';
import 'widgets/life_score_card.dart';
import 'widgets/habits_checklist_card.dart';
import 'widgets/tasks_today_card.dart';
import 'widgets/active_projects_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/fitness_card.dart';
import 'widgets/finance_card.dart';
import 'widgets/ai_tip_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: _buildBody(dashState, colorScheme),
      ),
    );
  }

  Widget _buildBody(DashboardState state, ColorScheme colorScheme) {
    switch (state.status) {
      case DashboardStatus.initial:
      case DashboardStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        );

      case DashboardStatus.error:
        return AppErrorState(
          message: state.errorMessage,
          onRetry: () => ref.read(dashboardProvider.notifier).load(),
        );

      case DashboardStatus.loaded:
        final feed = state.feed!;
        return _buildFeed(feed, colorScheme);
    }
  }

  Widget _buildFeed(DashboardFeedModel feed, ColorScheme colorScheme) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 768;
            final horizontalPadding = isWide ? AppSpacing.xl : AppSpacing.md;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(feed, colorScheme),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          horizontalPadding, 18, horizontalPadding, 100),
                      sliver: SliverToBoxAdapter(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, opacity, child) {
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, (1.0 - opacity) * 12),
                                child: child,
                              ),
                            );
                          },
                          child: isWide
                              ? _buildWideGrid(feed)
                              : _buildMobileColumn(feed),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileColumn(DashboardFeedModel feed) {
    return Column(
      children: [
        LifeScoreCard(lifeScore: feed.lifeScore),
        AppSpacing.verticalGapMd,
        if (feed.aiRecommendation != null &&
            feed.aiRecommendation!.isNotEmpty) ...[
          AiTipCard(tip: feed.aiRecommendation!),
          AppSpacing.verticalGapMd,
        ],
        HabitsChecklistCard(
          habits: feed.habits,
          onHabitTap: (habitId) =>
              ref.read(dashboardProvider.notifier).logHabit(habitId),
        ),
        AppSpacing.verticalGapMd,
        TasksTodayCard(
          tasks: feed.tasksDueToday,
          onToggle: (id, current) =>
              ref.read(dashboardProvider.notifier).toggleTask(id, current),
        ),
        AppSpacing.verticalGapMd,
        ActiveProjectsCard(projects: feed.activeProjects),
        AppSpacing.verticalGapMd,
        Row(
          children: [
            Expanded(child: FitnessCard(fitness: feed.fitness)),
            AppSpacing.horizontalGapMd,
            Expanded(child: FinanceCard(finance: feed.finance)),
          ],
        ),
        AppSpacing.verticalGapMd,
        RecentActivityCard(activities: feed.recentActivities),
      ],
    );
  }

  Widget _buildWideGrid(DashboardFeedModel feed) {
    return Column(
      children: [
        LifeScoreCard(lifeScore: feed.lifeScore),
        AppSpacing.verticalGapMd,
        if (feed.aiRecommendation != null &&
            feed.aiRecommendation!.isNotEmpty) ...[
          AiTipCard(tip: feed.aiRecommendation!),
          AppSpacing.verticalGapMd,
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              child: Column(
                children: [
                  HabitsChecklistCard(
                    habits: feed.habits,
                    onHabitTap: (habitId) =>
                        ref.read(dashboardProvider.notifier).logHabit(habitId),
                  ),
                  AppSpacing.verticalGapMd,
                  ActiveProjectsCard(projects: feed.activeProjects),
                  AppSpacing.verticalGapMd,
                  FitnessCard(fitness: feed.fitness),
                ],
              ),
            ),
            AppSpacing.horizontalGapMd,
            // Right Column
            Expanded(
              child: Column(
                children: [
                  TasksTodayCard(
                    tasks: feed.tasksDueToday,
                    onToggle: (id, current) => ref
                        .read(dashboardProvider.notifier)
                        .toggleTask(id, current),
                  ),
                  AppSpacing.verticalGapMd,
                  FinanceCard(finance: feed.finance),
                  AppSpacing.verticalGapMd,
                  RecentActivityCard(activities: feed.recentActivities),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(DashboardFeedModel feed, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userInitials = feed.userName.isNotEmpty
        ? feed.userName
            .trim()
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return SliverAppBar(
      expandedHeight: 150,
      floating: true,
      snap: true,
      backgroundColor: colorScheme.surface.withAlpha(230),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          'HabOS',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: PopupMenuButton<String>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
            elevation: 8,
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'theme') {
                ref.read(themeProvider.notifier).toggleTheme(context);
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDark ? 'Light Theme' : 'Dark Theme',
                      style:
                          TextStyle(fontSize: 14, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEA4335),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 14, color: Color(0xFFEA4335)),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    Color.lerp(colorScheme.primary, Colors.black, 0.18) ??
                        colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withAlpha(isDark ? 18 : 35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(38),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
  }
}
