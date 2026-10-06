import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import '../../providers/focus_provider.dart';
import '../../../app/theme/app_theme.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_overview_card.dart';
import 'widgets/habit_correlation_banner.dart';
import 'widgets/routines_tab_view.dart';
import 'widgets/habit_form_dialog.dart';
import 'widgets/habit_history_sheet.dart';
import 'dialogs/edit_routine_dialog.dart';
import 'dialogs/log_progress_dialog.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/common/form_section_header.dart';

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

    // Show mutation error SnackBars when in loaded state (load errors shown via AppErrorState)
    ref.listen<HabitsState>(habitsProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage &&
          next.status == HabitsStatus.loaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppSemanticColors.of(context).danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    });

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
          RoutinesTabView(
            state: state,
            onCreateRoutine: () =>
                _openCreateRoutineDialog(context, ref, state.habits),
            onEditRoutine: (routine) =>
                _openEditRoutineDialog(context, ref, routine, state.habits),
          ),
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
              HabitOverviewCard(habits: habits),
              const SizedBox(height: 16),

              // Behavioral Correlation Insight Banner
              if (state.correlations.isNotEmpty) ...[
                HabitCorrelationBanner(correlations: state.correlations),
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
                ...habits.map((habit) => HabitCard(
                      habit: habit,
                      onToggleComplete: () => ref
                          .read(habitsProvider.notifier)
                          .toggleHabitCompletion(habit),
                      onIncrement: (delta) => ref
                          .read(habitsProvider.notifier)
                          .incrementHabitProgress(habit, delta),
                      onStartFocus: () {
                        ref
                            .read(focusProvider.notifier)
                            .startTimerForHabit(habit);
                        context.go('/focus');
                      },
                      onLogProgress: () =>
                          _openLogProgressDialog(context, ref, habit),
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

  // ── Dialog Handlers ────────────────────────────────────────────────────────

  Future<void> _openCreateHabitDialog(
      BuildContext context, WidgetRef ref) async {
    final categories = ref.read(habitsProvider).categories;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => HabitFormDialog(categories: categories),
    );
    if (result != null) {
      await ref.read(habitsProvider.notifier).createHabit(result);
    }
  }

  Future<void> _openEditHabitDialog(
      BuildContext context, WidgetRef ref, HabitModel habit) async {
    final categories = ref.read(habitsProvider).categories;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => HabitFormDialog(habit: habit, categories: categories),
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
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_awesome_motion_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Habit Routine',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                            ),
                            Text(
                              'Sequence and bundle your daily rituals',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const FormSectionHeader(
                    title: 'ROUTINE IDENTITY',
                    icon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name *',
                      hintText: 'e.g. Morning Launchpad',
                      prefixIcon: Icon(Icons.stars_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'e.g. My daily wake-up ritual',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FormSectionHeader(
                        title: 'BUNDLE HABITS',
                        icon: Icons.low_priority_rounded,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${selectedHabitIds.length} selected',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (availableHabits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No habits available to bundle.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(80)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableHabits.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final h = availableHabits[index];
                          final isChecked = selectedHabitIds.contains(h.id);
                          final orderIndex = selectedHabitIds.indexOf(h.id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            title: Text(
                              h.name,
                              style: TextStyle(
                                fontWeight: isChecked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: isChecked
                                ? Text(
                                    'Step ${orderIndex + 1} of ${selectedHabitIds.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
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
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Routine'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  Future<void> _openEditRoutineDialog(
    BuildContext context,
    WidgetRef ref,
    RoutineModel routine,
    List<HabitModel> availableHabits,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => EditRoutineDialog(
        routine: routine,
        availableHabits: availableHabits,
      ),
    );
  }

  Future<void> _openLogProgressDialog(
    BuildContext context,
    WidgetRef ref,
    HabitModel habit,
  ) async {
    final result = await LogProgressDialog.show(context, habit);
    if (result != null) {
      await ref.read(habitsProvider.notifier).logHabitProgress(habit, result);
    }
  }
}
