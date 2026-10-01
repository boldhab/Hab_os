import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import '../../providers/goals_provider.dart';
import '../../../data/models/goal_model.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_needs_attention_section.dart';
import 'widgets/goal_status_filter_sheet.dart';
import 'widgets/goal_form_dialog.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedStatusFilter = 'ACTIVE'; // 'ACTIVE', 'COMPLETED', 'ALL'
  String? _selectedGoalId;

  static const _categories = [
    {'id': 'ALL', 'label': 'All'},
    {'id': 'CAREER', 'label': 'Career'},
    {'id': 'HEALTH', 'label': 'Health'},
    {'id': 'EDUCATION', 'label': 'Education'},
    {'id': 'FINANCIAL', 'label': 'Financial'},
    {'id': 'PERSONAL', 'label': 'Personal'},
  ];

  void _openStatusFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalStatusFilterSheet(
        currentStatus: _selectedStatusFilter,
        onSelectStatus: (status) {
          setState(() => _selectedStatusFilter = status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsListProvider);
    final healthAsync = ref.watch(goalsHealthProvider);
    final selectedCategory = ref.watch(selectedGoalCategoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        final mainListContent = Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                healthAsync.when(
                  data: (health) => Text(
                    '${health.totalActive} active · ${health.atRiskCount + health.behindCount} need attention',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                  loading: () => Text(
                    'Loading goals...',
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
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _selectedStatusFilter != 'ACTIVE'
                      ? primaryRed
                      : colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Filter Status',
                onPressed: () => _openStatusFilterSheet(context),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: colorScheme.onSurfaceVariant),
                tooltip: 'Refresh',
                onPressed: () {
                  AppHaptics.light();
                  ref.invalidate(goalsListProvider);
                  ref.invalidate(goalsHealthProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Underline Segmented Category Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(40),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = selectedCategory == cat['id'];

                    return InkWell(
                      onTap: () {
                        AppHaptics.selection();
                        ref.read(selectedGoalCategoryProvider.notifier).state =
                            cat['id']!;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: selected ? primaryRed : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected
                                ? primaryRed
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main List Content Body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(goalsListProvider);
                    ref.invalidate(goalsHealthProvider);
                  },
                  color: primaryRed,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      healthAsync.when(
                        data: (health) => _buildGoalOverview(context, health),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // 1. Compact Needs Attention Section (Only shown if at-risk/behind goals exist)
                      healthAsync.when(
                        data: (health) => GoalNeedsAttentionSection(
                          healthSummary: health,
                          onGoalTap: (id) {
                            if (isWide) {
                              setState(() => _selectedGoalId = id);
                            } else {
                              context.go('/goals/$id');
                            }
                          },
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      AppSpacing.verticalGapLg,

                      // 2. All Goals Header
                      Text(
                        'ALL GOALS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant.withAlpha(160),
                        ),
                      ),
                      AppSpacing.verticalGapSm,

                      // 3. Goal Cards List
                      goalsAsync.when(
                        loading: () => Column(
                          children: List.generate(
                            3,
                            (_) => Container(
                              height: 110,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha(40),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        error: (err, _) => AppErrorState(
                          message: err.toString(),
                          onRetry: () {
                            ref.invalidate(goalsListProvider);
                            ref.invalidate(goalsHealthProvider);
                          },
                        ),
                        data: (goals) {
                          final healthMap = <String, String>{};
                          healthAsync.whenData((h) {
                            for (final a in h.atRisk) {
                              healthMap[a.id] = 'AT_RISK';
                            }
                            for (final b in h.behind) {
                              healthMap[b.id] = 'BEHIND';
                            }
                            for (final o in h.onTrack) {
                              healthMap[o.id] = 'ON_TRACK';
                            }
                          });

                          // Filter by status if requested
                          final filteredGoals = goals.where((g) {
                            final isDone =
                                g.status.toUpperCase() == 'COMPLETED' ||
                                    g.progress >= 100;
                            if (_selectedStatusFilter == 'ACTIVE') {
                              return !isDone;
                            }
                            if (_selectedStatusFilter == 'COMPLETED') {
                              return isDone;
                            }
                            return true;
                          }).toList();

                          if (filteredGoals.isEmpty) {
                            return AppEmptyState(
                              icon: Icons.flag_outlined,
                              title: 'No goals found',
                              description:
                                  'Set your first goal and break it down into actionable milestones.',
                              actionLabel: 'New Goal',
                              onAction: () => _openCreateGoal(context),
                            );
                          }

                          return Column(
                            children: filteredGoals.map((goal) {
                              return GoalCard(
                                goal: goal,
                                healthStatus: healthMap[goal.id],
                                onTap: () {
                                  if (isWide) {
                                    setState(() => _selectedGoalId = goal.id);
                                  } else {
                                    context.go('/goals/${goal.id}');
                                  }
                                },
                                onDelete: () {
                                  ref
                                      .read(goalsActionsProvider.notifier)
                                      .deleteGoal(goal.id);
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateGoal(context),
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Goal',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              SizedBox(width: 420, child: mainListContent),
              VerticalDivider(
                  width: 1, color: colorScheme.outlineVariant.withAlpha(40)),
              Expanded(
                child: _selectedGoalId == null
                    ? Scaffold(
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        body: const Center(
                          child: Text(
                            'Select a goal to view details',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : GoalDetailScreen(goalId: _selectedGoalId!),
              ),
            ],
          );
        }

        return mainListContent;
      },
    );
  }

  Widget _buildGoalOverview(
      BuildContext context, GoalsHealthSummary health) {
    final colorScheme = Theme.of(context).colorScheme;
    final attentionCount = health.atRiskCount + health.behindCount;
    final activeCount = health.totalActive;
    final onTrackRatio = activeCount == 0
        ? 0.0
        : (health.onTrackCount / activeCount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(20),
            colorScheme.primaryContainer.withAlpha(105),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Goal momentum',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.flag_rounded, size: 20, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            activeCount == 0
                ? 'Set a goal to give your next step a direction.'
                : '$activeCount active goals, ${health.onTrackCount} moving well',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: onTrackRatio,
              minHeight: 7,
              backgroundColor: colorScheme.outlineVariant.withAlpha(70),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _goalMetric(context,
                  value: '${health.onTrackCount}', label: 'on track'),
              _goalMetric(context,
                  value: '$attentionCount', label: 'need attention'),
              _goalMetric(context,
                  value: '${(onTrackRatio * 100).round()}', label: 'healthy pace'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalMetric(BuildContext context,
      {required String value, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface)),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  void _openCreateGoal(BuildContext context) {
    GoalFormDialog.show(
      context,
      onSubmit: (payload) async {
        await ref.read(goalsActionsProvider.notifier).createGoal(payload);
      },
    );
  }
}
