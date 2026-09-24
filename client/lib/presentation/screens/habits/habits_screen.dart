import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import 'widgets/habit_form_dialog.dart';
import 'widgets/habit_history_sheet.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadHabits(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
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
                  '${state.filteredHabits.length} habits',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main list
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Habit'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, HabitsState state) {
    switch (state.status) {
      case HabitsStatus.initial:
      case HabitsStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HabitsStatus.error:
        return AppErrorState(
          message: state.errorMessage,
          onRetry: () => ref.read(habitsProvider.notifier).loadHabits(),
        );

      case HabitsStatus.loaded:
        final habits = state.filteredHabits;
        if (habits.isEmpty) {
          return AppEmptyState(
            icon: Icons.repeat_rounded,
            title: state.filterActiveOnly ? 'No active habits' : 'No habits created yet',
            description: 'Tap "+ New Habit" below to build consistency.',
            actionLabel: 'New Habit',
            onAction: () => _openCreateDialog(context, ref),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(habitsProvider.notifier).loadHabits(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return _HabitCard(
                habit: habit,
                onToggleComplete: () =>
                    ref.read(habitsProvider.notifier).toggleHabitCompletion(habit),
                onEdit: () => _openEditDialog(context, ref, habit),
                onHistory: () => _openHistorySheet(context, habit),
                onToggleArchive: () =>
                    ref.read(habitsProvider.notifier).toggleArchive(habit),
                onDelete: () => _confirmDelete(context, ref, habit),
              );
            },
          ),
        );
    }
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const HabitFormDialog(),
    );
    if (result != null) {
      await ref.read(habitsProvider.notifier).createHabit(result);
    }
  }

  Future<void> _openEditDialog(
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

  Future<void> _confirmDelete(
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
}

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
                  Row(
                    children: [
                      _Chip(
                        label: habit.frequency,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 6),
                      if (habit.targetType != 'CHECKBOX') ...[
                        _Chip(
                          label: '${habit.targetValue} ${habit.targetType.toLowerCase()}',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (habit.reminderTime != null) ...[
                        Icon(Icons.access_time_rounded,
                            size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          habit.reminderTime!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 6),
                      ],
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
                        '${habit.currentStreak}d',
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
                  'Best ${habit.longestStreak}d',
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
                      Text('History & Stats'),
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
