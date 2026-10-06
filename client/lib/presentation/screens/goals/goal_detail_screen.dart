import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/goals_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/focus_provider.dart';
import '../../widgets/app_error_state.dart';
import '../../../app/theme/app_theme.dart';
import '../habits/widgets/habit_card.dart';
import '../habits/dialogs/habit_form_dialog.dart';
import '../habits/widgets/habit_history_sheet.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(goalDetailsProvider(widget.goalId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(goalDetailsProvider(widget.goalId)),
        ),
      ),
      data: (goal) {
        final isCompleted =
            goal.status.toUpperCase() == 'COMPLETED' || goal.progress >= 100;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        goal.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Priority: ${goal.priority}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? semantics.success.withAlpha(20)
                      : primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${goal.progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? semantics.success : primaryRed,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: primaryRed,
              labelColor: primaryRed,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Milestones'),
                Tab(text: 'Tasks'),
                Tab(text: 'Habits'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _MilestonesTab(goal: goal),
              _TasksTab(goal: goal),
              _HabitsTab(goal: goal),
              _HistoryTab(goal: goal),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (_tabController.index == 2) {
                            _openCreateHabitForGoal(context, goal);
                          } else {
                            _openAddMilestoneSheet(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(_tabController.index == 2
                            ? Icons.add_task_rounded
                            : Icons.add_rounded),
                        label: Text(
                          _tabController.index == 2
                              ? 'Add Supporting Habit'
                              : 'Add Milestone',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAddMilestoneSheet(BuildContext context) async {
    final titleController = TextEditingController();
    final weightController = TextEditingController(text: '1.0');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Milestone',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                AppSpacing.verticalGapMd,
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Milestone Title *',
                    hintText: 'e.g. Complete v1 MVP design',
                  ),
                ),
                AppSpacing.verticalGapMd,
                TextField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Relative Weight',
                    hintText: '1.0',
                    helperText:
                        'Progress is auto-normalized based on relative milestone weights.',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Quick weight: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    ...['1.0', '2.0', '3.0', '5.0'].map((w) {
                      final selected = weightController.text == w;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${w}x'),
                          selected: selected,
                          labelStyle: const TextStyle(fontSize: 11),
                          onSelected: (_) {
                            setSheetState(() => weightController.text = w);
                          },
                        ),
                      );
                    }),
                  ],
                ),
                AppSpacing.verticalGapLg,
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final weight =
                          double.tryParse(weightController.text.trim()) ?? 1.0;
                      await ref
                          .read(goalsActionsProvider.notifier)
                          .createMilestone(
                        widget.goalId,
                        {
                          'title': titleController.text.trim(),
                          'weight': weight,
                        },
                      );
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Milestone added & progress recalculated!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add Milestone'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCreateHabitForGoal(BuildContext context, GoalModel goal) async {
    final habitsState = ref.read(habitsProvider);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => HabitFormDialog(categories: habitsState.categories),
    );
    if (result != null) {
      await ref.read(habitsProvider.notifier).createHabit(result);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. MILESTONES TAB (VERTICAL TIMELINE WITH CONNECTED NODES)
// ─────────────────────────────────────────────────────────────────────────────
class _MilestonesTab extends ConsumerWidget {
  final GoalModel goal;
  const _MilestonesTab({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final milestones = goal.milestones;

    if (milestones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined,
                  size: 40, color: colorScheme.onSurfaceVariant.withAlpha(120)),
              AppSpacing.verticalGapSm,
              Text(
                'No milestones created yet',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Break down your goal into small actionable milestones.',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final m = milestones[index];
        final isLast = index == milestones.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connected Node Column
              Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final willBeCompleted = !m.isCompleted;
                      if (willBeCompleted) {
                        AppHaptics.heavy();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Milestone "${m.title}" reached! 🎯'),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        AppHaptics.selection();
                      }
                      await ref.read(goalsActionsProvider.notifier).updateMilestone(
                        goal.id,
                        m.id,
                        {'isCompleted': willBeCompleted},
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: m.isCompleted
                            ? primaryRed
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: m.isCompleted
                              ? primaryRed
                              : colorScheme.outlineVariant.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: m.isCompleted
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: colorScheme.outlineVariant.withAlpha(40),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: m.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: m.isCompleted
                                      ? colorScheme.onSurfaceVariant
                                          .withAlpha(140)
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Weight ${m.weight.toStringAsFixed(1)}x',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (m.description != null &&
                            m.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            m.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TASKS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _TasksTab extends ConsumerWidget {
  final GoalModel goal;
  const _TasksTab({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tasks = goal.tasks;

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt_rounded,
                  size: 40, color: colorScheme.onSurfaceVariant.withAlpha(120)),
              AppSpacing.verticalGapSm,
              Text(
                'No tasks linked yet',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Link tasks from the Tasks module to power auto-progress.',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: task.isCompleted
                    ? colorScheme.secondary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. HISTORY TAB (CHECK-INS)
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  final GoalModel goal;
  const _HistoryTab({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final checkIns = goal.checkIns;

    if (checkIns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded,
                  size: 40, color: colorScheme.onSurfaceVariant.withAlpha(120)),
              AppSpacing.verticalGapSm,
              Text(
                'No check-in history yet',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: checkIns.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Current Progress',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('${goal.progress.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(height: 32, width: 1, color: colorScheme.outlineVariant.withAlpha(50)),
                Column(
                  children: [
                    Text('Milestones',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      '${goal.milestones.where((m) => m.isCompleted).length}/${goal.milestones.length}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Container(height: 32, width: 1, color: colorScheme.outlineVariant.withAlpha(50)),
                Column(
                  children: [
                    Text('Check-ins',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('${checkIns.length}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          );
        }

        final c = checkIns[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.confidence,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (c.note != null && c.note!.isNotEmpty)
                      Text(
                        c.note!,
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withAlpha(150)),
                      ),
                  ],
                ),
              ),
              Text(
                c.date.split('T')[0],
                style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withAlpha(140)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. HABITS TAB (CROSS-MODULE SYNERGY MATRIX)
// ─────────────────────────────────────────────────────────────────────────────
class _HabitsTab extends ConsumerStatefulWidget {
  final GoalModel goal;
  const _HabitsTab({required this.goal});

  @override
  ConsumerState<_HabitsTab> createState() => _HabitsTabState();
}

class _HabitsTabState extends ConsumerState<_HabitsTab> {
  bool _showAllHabits = false;

  bool _isHabitRelevantToGoal(HabitModel habit, GoalModel goal) {
    final goalCat = goal.category.toUpperCase();
    final habitCat = habit.category?.name.toUpperCase() ?? '';
    final habitName = habit.name.toUpperCase();
    final goalTitle = goal.title.toUpperCase();

    if (goalCat.contains('HEALTH') || goalCat.contains('FITNESS')) {
      if (habitCat.contains('HEALTH') ||
          habitCat.contains('FITNESS') ||
          habitCat.contains('GYM') ||
          habitName.contains('WATER') ||
          habitName.contains('SLEEP') ||
          habitName.contains('RUN') ||
          habitName.contains('WALK')) {
        return true;
      }
    }
    if (goalCat.contains('CAREER') ||
        goalCat.contains('WORK') ||
        goalCat.contains('BUSINESS')) {
      if (habitCat.contains('PRODUCTIV') ||
          habitCat.contains('WORK') ||
          habitCat.contains('CAREER') ||
          habitName.contains('CODE') ||
          habitName.contains('PLAN') ||
          habitName.contains('DEEP WORK')) {
        return true;
      }
    }
    if (goalCat.contains('EDUCATION') ||
        goalCat.contains('LEARN') ||
        goalCat.contains('STUDY') ||
        goalCat.contains('ACADEMIC')) {
      if (habitCat.contains('LEARN') ||
          habitCat.contains('GROWTH') ||
          habitCat.contains('STUDY') ||
          habitName.contains('READ') ||
          habitName.contains('BOOK') ||
          habitName.contains('STUDY')) {
        return true;
      }
    }
    if (goalCat.contains('FINANC') || goalCat.contains('MONEY')) {
      if (habitCat.contains('FINANC') ||
          habitName.contains('SAVE') ||
          habitName.contains('BUDGET') ||
          habitName.contains('EXPENSE')) {
        return true;
      }
    }
    if (goalCat.contains('MINDFUL') ||
        goalCat.contains('MENTAL') ||
        goalCat.contains('SPIRIT')) {
      if (habitCat.contains('MINDFUL') ||
          habitCat.contains('MENTAL') ||
          habitName.contains('MEDITAT') ||
          habitName.contains('JOURNAL')) {
        return true;
      }
    }

    // Keyword match between habit title and goal title
    final goalWords = goalTitle.split(RegExp(r'\s+')).where((w) => w.length > 3);
    for (final word in goalWords) {
      if (habitName.contains(word)) return true;
    }

    return false;
  }

  void _openLogProgressDialog(BuildContext context, HabitModel habit) async {
    int value = habit.currentTodayValue;
    final unit = habit.targetType == 'DURATION' ? 'mins' : 'reps';
    final controller = TextEditingController(text: value.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDone = value >= habit.targetValue;
          return AlertDialog(
            title: Text('Log ${habit.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target: ${habit.targetValue} $unit',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove),
                      onPressed: value > 0
                          ? () {
                              setModalState(() {
                                value = (value -
                                        (habit.targetType == 'DURATION' ? 5 : 1))
                                    .clamp(0, 99999);
                                controller.text = value.toString();
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        onChanged: (text) {
                          final parsed = int.tryParse(text);
                          if (parsed != null) {
                            setModalState(() => value = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setModalState(() {
                          value = (value +
                                  (habit.targetType == 'DURATION' ? 5 : 1))
                              .clamp(0, 99999);
                          controller.text = value.toString();
                        });
                      },
                    ),
                  ],
                ),
                if (isDone) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Target reached! 🎉',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, value),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await ref.read(habitsProvider.notifier).logHabitProgress(habit, result);
    }
  }

  void _openEditHabitDialog(BuildContext context, HabitModel habit) async {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => HabitHistorySheet(habit: habit),
    );
  }

  void _confirmDeleteHabit(BuildContext context, HabitModel habit) async {
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

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final activeHabits = habitsState.habits.where((h) => h.isActive).toList();

    final domainHabits = activeHabits
        .where((h) => _isHabitRelevantToGoal(h, widget.goal))
        .toList();

    final displayedHabits = _showAllHabits
        ? activeHabits
        : (domainHabits.isNotEmpty ? domainHabits : activeHabits);

    final isFiltered = !_showAllHabits && domainHabits.isNotEmpty;

    if (activeHabits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.loop_rounded,
                  size: 44, color: colorScheme.primary.withAlpha(140)),
              AppSpacing.verticalGapSm,
              Text(
                'No supporting habits yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Atomic daily habits power long-term goals. Build a habit routine for "${widget.goal.title}".',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160)),
              ),
              AppSpacing.verticalGapMd,
              FilledButton.icon(
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) =>
                        HabitFormDialog(categories: habitsState.categories),
                  );
                  if (result != null) {
                    await ref.read(habitsProvider.notifier).createHabit(result);
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Habit'),
              ),
            ],
          ),
        ),
      );
    }

    final completedTodayCount =
        displayedHabits.where((h) => h.isCompletedToday).length;
    final maxStreak = displayedHabits.isEmpty
        ? 0
        : displayedHabits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
      children: [
        // Synergy Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_graph_rounded,
                      size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFiltered
                          ? '${widget.goal.category} Habit System'
                          : 'Supporting Habit System',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (domainHabits.isNotEmpty)
                    InkWell(
                      onTap: () =>
                          setState(() => _showAllHabits = !_showAllHabits),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Text(
                          _showAllHabits
                              ? 'Filter to Goal'
                              : 'Show All (${activeHabits.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$completedTodayCount of ${displayedHabits.length} completed today',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '🔥 Max Streak: $maxStreak days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Habit Cards
        ...displayedHabits.map((habit) => HabitCard(
              habit: habit,
              onToggleComplete: () => ref
                  .read(habitsProvider.notifier)
                  .toggleHabitCompletion(habit),
              onIncrement: (delta) => ref
                  .read(habitsProvider.notifier)
                  .incrementHabitProgress(habit, delta),
              onStartFocus: () {
                ref.read(focusProvider.notifier).startTimerForHabit(habit);
                context.go('/focus');
              },
              onLogProgress: () => _openLogProgressDialog(context, habit),
              onEdit: () => _openEditHabitDialog(context, habit),
              onHistory: () => _openHistorySheet(context, habit),
              onToggleArchive: () =>
                  ref.read(habitsProvider.notifier).toggleArchive(habit),
              onDelete: () => _confirmDeleteHabit(context, habit),
            )),
      ],
    );
  }
}
