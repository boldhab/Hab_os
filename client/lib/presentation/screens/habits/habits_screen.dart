import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_animated_check.dart';
import 'widgets/habit_form_dialog.dart';
import 'widgets/habit_history_sheet.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits & Routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              notifier.loadHabits();
              notifier.loadRoutines();
              notifier.loadCorrelations();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.repeat_rounded),
              text: 'Habits (${state.filteredHabits.length})',
            ),
            Tab(
              icon: const Icon(Icons.auto_awesome_rounded),
              text: 'Routines (${state.routines.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHabitsTab(context, ref, state),
          _buildRoutinesTab(context, ref, state),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _openCreateHabitDialog(context, ref);
          } else {
            _openCreateRoutineDialog(context, ref, state.habits);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'New Habit' : 'New Routine'),
      ),
    );
  }

  // ── 1. HABITS TAB ──────────────────────────────────────────────────────────

  Widget _buildHabitsTab(
      BuildContext context, WidgetRef ref, HabitsState state) {
    final notifier = ref.read(habitsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    switch (state.status) {
      case HabitsStatus.initial:
      case HabitsStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HabitsStatus.error:
        return AppErrorState(
          message: state.errorMessage,
          onRetry: () => notifier.loadHabits(),
        );

      case HabitsStatus.loaded:
        final habits = state.filteredHabits;

        return RefreshIndicator(
          onRefresh: () => notifier.loadHabits(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              _buildHabitOverview(context, habits),
              const SizedBox(height: 16),

              // Behavioral Correlation Insight Banner
              if (state.correlations.isNotEmpty) ...[
                _buildCorrelationBanner(context, state.correlations.first),
                const SizedBox(height: 12),
              ],

              // Filter toggle row
              Row(
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Active'),
                        icon: Icon(Icons.check_circle_outline_rounded),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('All'),
                        icon: Icon(Icons.list_alt_rounded),
                      ),
                    ],
                    selected: {state.filterActiveOnly},
                    onSelectionChanged: (selection) {
                      notifier.toggleFilterActive(selection.first);
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${habits.length} habits',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (habits.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: AppEmptyState(
                    icon: Icons.repeat_rounded,
                    title: state.filterActiveOnly
                        ? 'No active habits'
                        : 'No habits created yet',
                    description:
                        'Tap "+ New Habit" below to build consistency.',
                    actionLabel: 'New Habit',
                    onAction: () => _openCreateHabitDialog(context, ref),
                  ),
                )
              else
                ...habits.map((habit) => _HabitCard(
                      habit: habit,
                      onToggleComplete: () => ref
                          .read(habitsProvider.notifier)
                          .toggleHabitCompletion(habit),
                      onEdit: () => _openEditHabitDialog(context, ref, habit),
                      onHistory: () => _openHistorySheet(context, habit),
                      onToggleArchive: () => ref
                          .read(habitsProvider.notifier)
                          .toggleArchive(habit),
                      onDelete: () => _confirmDeleteHabit(context, ref, habit),
                    )),
            ],
          ),
        );
    }
  }

  Widget _buildHabitOverview(
      BuildContext context, List<HabitModel> habits) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeHabits = habits.where((habit) => habit.isActive).toList();
    final completedCount =
        activeHabits.where((habit) => habit.isCompletedToday).length;
    final completionRatio = activeHabits.isEmpty
        ? 0.0
        : completedCount / activeHabits.length;
    final bestStreak = activeHabits.isEmpty
        ? 0
        : activeHabits
            .map((habit) => habit.currentStreak)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(22),
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
                  'Daily rhythm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome_rounded,
                  color: colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            activeHabits.isEmpty
                ? 'Create a habit to start building momentum.'
                : '$completedCount of ${activeHabits.length} habits completed today',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completionRatio,
              minHeight: 7,
              backgroundColor: colorScheme.outlineVariant.withAlpha(70),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _overviewMetric(
                context,
                value: '${(completionRatio * 100).round()}%',
                label: 'complete',
              ),
              _overviewMetric(
                context,
                value: '$bestStreak days',
                label: 'best active streak',
              ),
              _overviewMetric(
                context,
                value: '${activeHabits.length}',
                label: 'active habits',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric(BuildContext context,
      {required String value, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrelationBanner(
      BuildContext context, HabitCorrelationModel correlation) {
    final semantics = AppSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: semantics.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantics.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: semantics.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Behavioral Habit Insight',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  correlation.insightText,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. ROUTINES TAB ────────────────────────────────────────────────────────

  Widget _buildRoutinesTab(
      BuildContext context, WidgetRef ref, HabitsState state) {
    final routines = state.routines;
    final colorScheme = Theme.of(context).colorScheme;

    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 48, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.sm + 4),
              const Text(
                'No habit routines yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Chain habits into sequential rituals (e.g. Morning Launchpad: Hydrate → Meditate → Journal).',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Routine'),
                onPressed: () =>
                    _openCreateRoutineDialog(context, ref, state.habits),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(habitsProvider.notifier).loadRoutines(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, 80),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final r = routines[index];
          return _RoutineCard(
            routine: r,
            onComplete: () async {
              await ref.read(habitsProvider.notifier).completeRoutine(r.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '🎉 Completed "${r.name}" ritual! All streak counts updated.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            onDelete: () async {
              final semantics = AppSemanticColors.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Routine'),
                  content:
                      Text('Delete "${r.name}"? (Habits will remain intact)'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: semantics.danger,
                        foregroundColor: semantics.onDanger,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(habitsProvider.notifier).deleteRoutine(r.id);
              }
            },
          );
        },
      ),
    );
  }

  // ── Dialog Handlers ────────────────────────────────────────────────────────

  Future<void> _openCreateHabitDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const HabitFormDialog(),
    );
    if (result != null) {
      await ref.read(habitsProvider.notifier).createHabit(result);
    }
  }

  Future<void> _openEditHabitDialog(
      BuildContext context, WidgetRef ref, HabitModel habit) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => HabitFormDialog(habit: habit),
    );
    if (result != null) {
      await ref.read(habitsProvider.notifier).updateHabit(habit.id, result);
    }
  }

  void _openHistorySheet(BuildContext context, HabitModel habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.sheetRadius,
      ),
      builder: (_) => HabitHistorySheet(habit: habit),
    );
  }

  Future<void> _confirmDeleteHabit(
      BuildContext context, WidgetRef ref, HabitModel habit) async {
    final semantics = AppSemanticColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: semantics.danger,
              foregroundColor: semantics.onDanger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
    }
  }

  Future<void> _openCreateRoutineDialog(
    BuildContext context,
    WidgetRef ref,
    List<HabitModel> availableHabits,
  ) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final selectedHabitIds = <String>[];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('New Habit Routine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine Name *',
                    hintText: 'e.g. Morning Launchpad',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. My daily wake-up ritual',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Habits in Ritual Order:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (availableHabits.isEmpty)
                  const Text('No habits available to bundle.',
                      style: TextStyle(color: Colors.grey))
                else
                  ...availableHabits.map((h) {
                    final isChecked = selectedHabitIds.contains(h.id);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(h.name),
                      value: isChecked,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedHabitIds.add(h.id);
                          } else {
                            selectedHabitIds.remove(h.id);
                          }
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create Routine'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref.read(habitsProvider.notifier).createRoutine({
        'name': nameController.text.trim(),
        'description': descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        'habitIds': selectedHabitIds,
      });
    }
  }
}

// ── Components ─────────────────────────────────────────────────────────────

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onToggleArchive;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onHistory,
    required this.onToggleArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      color: habit.isActive
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerHigh.withAlpha(120),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            // Checkbox completion toggle
            AppAnimatedCheck(
              value: habit.isCompletedToday,
              isCircle: true,
              size: 28,
              activeColor: semantics.success,
              checkColor: semantics.onSuccess,
              onChanged: (_) => onToggleComplete(),
            ),
            const SizedBox(width: AppSpacing.sm + 6),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: habit.isCompletedToday
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: habit.isActive
                                        ? (habit.isCompletedToday
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                      if (!habit.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Archived',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  if (habit.description != null &&
                      habit.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      habit.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Chip(
                        label: habit.frequency,
                        colorScheme: colorScheme,
                      ),
                      if (habit.isWeeklyCount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Week: ${habit.weeklyCompletionsCount}/${habit.targetFrequencyCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      _Chip(
                        label: habit.difficulty,
                        colorScheme: colorScheme,
                      ),
                      if (habit.targetType != 'CHECKBOX')
                        _Chip(
                          label:
                              '${habit.targetValue} ${habit.targetType.toLowerCase()}',
                          colorScheme: colorScheme,
                        ),
                      if (habit.streakFreezes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: semantics.info.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '❄️ ${habit.streakFreezes}',
                            style:
                                TextStyle(fontSize: 10, color: semantics.info),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Streak Badge
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        habit.isWeeklyCount
                            ? '${habit.currentStreak}w'
                            : '${habit.currentStreak}d',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best ${habit.longestStreak}${habit.isWeeklyCount ? "w" : "d"}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
              ],
            ),

            // Action Menu
            PopupMenuButton<String>(
              onSelected: (val) {
                switch (val) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'history':
                    onHistory();
                    break;
                  case 'archive':
                    onToggleArchive();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('History & Heatmap'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        habit.isActive
                            ? Icons.archive_outlined
                            : Icons.unarchive_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(habit.isActive ? 'Archive' : 'Unarchive'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: semantics.danger),
                      const SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: semantics.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withAlpha(40),
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (routine.description != null &&
                          routine.description!.isNotEmpty)
                        Text(
                          routine.description!,
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18, color: semantics.danger),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),

            // Step items
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm + 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: routine.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: item.isCompletedToday
                              ? semantics.success
                              : colorScheme.primary.withAlpha(50),
                          child: item.isCompletedToday
                              ? Icon(Icons.check,
                                  size: 12, color: semantics.onSuccess)
                              : Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.habitName,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: item.isCompletedToday
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isCompletedToday
                                  ? colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        Text('🔥 ${item.currentStreak}d',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 4),

            // Actions row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 12,
              children: [
                Text(
                  '${routine.completedCount}/${routine.totalHabits} completed today',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                FilledButton.icon(
                  icon: Icon(
                    routine.isCompletedToday
                        ? Icons.check_circle_rounded
                        : Icons.play_arrow_rounded,
                    size: 16,
                  ),
                  label: Text(routine.isCompletedToday
                      ? 'Ritual Done'
                      : 'Complete Ritual'),
                  onPressed: routine.isCompletedToday ? null : onComplete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _Chip({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
      ),
    );
  }
}
