import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/dashboard_feed_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
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
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: _buildBody(dashState, colorScheme),
      ),
    );
  }

  Widget _buildBody(DashboardState state, ColorScheme colorScheme) {
    switch (state.status) {
      case DashboardStatus.initial:
      case DashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());

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
    return CustomScrollView(
      slivers: [
        _buildAppBar(feed, colorScheme),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Life Score ───────────────────────────────────────────────
              LifeScoreCard(lifeScore: feed.lifeScore),
              const SizedBox(height: 16),

              // ── AI Tip ───────────────────────────────────────────────────
              if (feed.aiRecommendation != null &&
                  feed.aiRecommendation!.isNotEmpty) ...[
                AiTipCard(tip: feed.aiRecommendation!),
                const SizedBox(height: 16),
              ],

              // ── Habits Checklist ─────────────────────────────────────────
              HabitsChecklistCard(
                habits: feed.habits,
                onHabitTap: (habitId) =>
                    ref.read(dashboardProvider.notifier).logHabit(habitId),
              ),
              const SizedBox(height: 16),

              // ── Tasks Due Today ──────────────────────────────────────────
              TasksTodayCard(
                tasks: feed.tasksDueToday,
                onToggle: (id, current) =>
                    ref.read(dashboardProvider.notifier).toggleTask(id, current),
              ),
              const SizedBox(height: 16),

              // ── Active Projects ──────────────────────────────────────────
              ActiveProjectsCard(projects: feed.activeProjects),
              const SizedBox(height: 16),

              // ── Fitness + Finance ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: FitnessCard(fitness: feed.fitness)),
                  const SizedBox(width: 12),
                  Expanded(child: FinanceCard(finance: feed.finance)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Recent Activity ───────────────────────────────────────────
              RecentActivityCard(activities: feed.recentActivities),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(DashboardFeedModel feed, ColorScheme colorScheme) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      snap: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              feed.userName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Sign out',
          onPressed: _signOut,
        ),
      ],
    );
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
  }
}
