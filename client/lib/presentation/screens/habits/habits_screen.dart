import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
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

  Widget _buildHabitsTab(BuildContext context, WidgetRef ref, HabitsState state) {
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
                    description: 'Tap "+ New Habit" below to build consistency.',
                    actionLabel: 'New Habit',
                    onAction: () => _openCreateHabitDialog(context, ref),
                  ),
                )
              else
                ...habits.map((habit) => _HabitCard(
                      habit: habit,
                      onToggleComplete: () =>
                          ref.read(habitsProvider.notifier).toggleHabitCompletion(habit),
                      onEdit: () => _openEditHabitDialog(context, ref, habit),
                      onHistory: () => _openHistorySheet(context, habit),
                      onToggleArchive: () =>
                          ref.read(habitsProvider.notifier).toggleArchive(habit),
                      onDelete: () => _confirmDeleteHabit(context, ref, habit),
                    )),
            ],
          ),
        );
    }
  }

  Widget _buildCorrelationBanner(BuildContext context, HabitCorrelationModel correlation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 22),
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

  Widget _buildRoutinesTab(BuildContext context, WidgetRef ref, HabitsState state) {
    final routines = state.routines;

    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 12),
              const Text(
                'No habit routines yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chain habits into sequential rituals (e.g. Morning Launchpad: Hydrate → Meditate → Journal).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Routine'),
                onPressed: () => _openCreateRoutineDialog(context, ref, state.habits),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(habitsProvider.notifier).loadRoutines(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
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
                    content: Text('🎉 Completed "${r.name}" ritual! All streak counts updated.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Routine'),
                  content: Text('Delete "${r.name}"? (Habits will remain intact)'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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

  Future<void> _openCreateHabitDialog(BuildContext context, WidgetRef ref) async {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HabitHistorySheet(habit: habit),
    );
  }

  Future<void> _confirmDeleteHabit(
      BuildContext context, WidgetRef ref, HabitModel habit) async {
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
              backgroundColor: Theme.of(context).colorScheme.error,
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
                  const Text('No habits available to bundle.', style: TextStyle(color: Colors.grey))
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
        'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: habit.isActive
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerHigh.withAlpha(120),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox completion toggle
            InkWell(
              onTap: onToggleComplete,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: habit.isCompletedToday
                      ? colorScheme.tertiary
                      : Colors.transparent,
                  border: Border.all(
                    color: habit.isCompletedToday
                        ? colorScheme.tertiary
                        : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: habit.isCompletedToday
                    ? Icon(Icons.check_rounded,
                        size: 18, color: colorScheme.onTertiary)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          label: '${habit.targetValue} ${habit.targetType.toLowerCase()}',
                          colorScheme: colorScheme,
                        ),
                      if (habit.streakFreezes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '❄️ ${habit.streakFreezes}',
                            style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Streak Badge
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withAlpha(40),
                  child: Icon(Icons.auto_awesome_rounded, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (routine.description != null && routine.description!.isNotEmpty)
                        Text(
                          routine.description!,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Step items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
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
                              ? Colors.green
                              : colorScheme.primary.withAlpha(50),
                          child: item.isCompletedToday
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
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
                              decoration: item.isCompletedToday ? TextDecoration.lineThrough : null,
                              color: item.isCompletedToday ? colorScheme.onSurfaceVariant : null,
                            ),
                          ),
                        ),
                        Text('🔥 ${item.currentStreak}d', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${routine.completedCount}/${routine.totalHabits} completed today',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                FilledButton.icon(
                  icon: Icon(
                    routine.isCompletedToday ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                    size: 16,
                  ),
                  label: Text(routine.isCompletedToday ? 'Ritual Done' : 'Complete Ritual'),
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
