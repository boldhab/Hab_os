import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rest_timer_provider.dart';
import '../main_scaffold.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import '../../../app/theme/app_theme.dart';
import 'controllers/gym_controller.dart';
import 'dialogs/custom_exercise_dialog.dart';
import 'dialogs/custom_template_dialog.dart';
import 'dialogs/exercise_picker_dialog.dart';
import 'dialogs/plate_calculator_dialog.dart';
import 'models/gym_models.dart';
import 'tabs/gym_progress_tab.dart';

// Backward compatibility typedef for existing callers
typedef WorkoutModel = WorkoutDetailModel;

class GymScreen extends ConsumerStatefulWidget {
  final String? initialWorkoutId;
  const GymScreen({super.key, this.initialWorkoutId});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym & Fitness Hub'),
        actions: [
          IconButton(
            tooltip: 'Plate Calculator',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => PlateCalculatorDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(gymControllerProvider).invalidateGymData();
              ref.invalidate(gymExercisesProvider);
              ref.invalidate(gymTemplatesProvider);
              ref.invalidate(gymBodyMetricsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
                icon: Icon(Icons.fitness_center_rounded),
                text: 'Workouts & Logger'),
            Tab(
                icon: Icon(Icons.emoji_events_outlined),
                text: 'Progressive Overload'),
            Tab(
                icon: Icon(Icons.pie_chart_outline_rounded),
                text: 'Volume & Insights'),
            Tab(
                icon: Icon(Icons.monitor_weight_outlined),
                text: 'Body & Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WorkoutsTab(),
          _ProgressiveOverloadTab(),
          _VolumeAnalyticsTab(),
          _BodyMetricsTemplatesTab(),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: WORKOUTS & LIVE LOGGER
// ==========================================

class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(gymWorkoutsProvider);
    final statsAsync = ref.watch(gymStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(gymControllerProvider).invalidateGymData();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxxl),
        children: [
          // Weekly Target Progress Card
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              final pct =
                  (stats.workoutsThisWeek / stats.weeklyTarget).clamp(0.0, 1.0);
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
                              stats.workedOutToday
                                  ? 'Training day complete'
                                  : 'Ready for your next session',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            stats.workedOutToday
                                ? Icons.check_circle_rounded
                                : Icons.fitness_center_rounded,
                            color: stats.workedOutToday
                                ? semantics.success
                                : colorScheme.primary,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.workoutsThisWeek} of ${stats.weeklyTarget} sessions this week',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor:
                              colorScheme.outlineVariant.withAlpha(70),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stats.workoutsThisWeek >= stats.weeklyTarget
                                ? semantics.success
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${(pct * 100).toInt()}% of weekly target',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            stats.workedOutToday ? 'DONE FOR TODAY' : 'KEEP GOING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: stats.workedOutToday
                                  ? semantics.success
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Action buttons: Quick Log or Start from Template
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log Workout'),
                  onPressed: () => _openWorkoutLogger(context, ref),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('From Template'),
                  onPressed: () => _openTemplatePicker(context, ref),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Rest Timer'),
                  onPressed: () => _openRestTimerModal(context),
                ),
              ];

              if (constraints.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(child: buttons[1]),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(child: buttons[2]),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: buttons[1]),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: buttons[2]),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Workout History',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Workouts List
          workoutsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () => ref.refresh(gymWorkoutsProvider),
            ),
            data: (workouts) {
              if (workouts.isEmpty) {
                return AppEmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'No workouts logged yet',
                  description:
                      'Tap "+ Log Workout" to start tracking progressive overload.',
                  actionLabel: 'Log Workout',
                  onAction: () => _openWorkoutLogger(context, ref),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workouts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final w = workouts[i];
                  final dateStr = w.date.split('T')[0];
                  final tonnageStr = w.totalVolume >= 1000
                      ? '${(w.totalVolume / 1000).toStringAsFixed(1)} tons'
                      : '${w.totalVolume.toStringAsFixed(0)} kg';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(40)),
                    ),
                    color: colorScheme.surfaceContainer,
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center_rounded,
                            color: colorScheme.onPrimaryContainer, size: 20),
                      ),
                      title: Text(
                        w.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        '$dateStr • ${w.durationMinutes}m • $tonnageStr',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (w.prCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs),
                              margin:
                                  const EdgeInsets.only(right: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: semantics.warningContainer,
                                borderRadius: AppRadius.badgeRadius,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events_rounded,
                                      size: 12,
                                      color: semantics.onWarningContainer),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    '${w.prCount} PR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: semantics.onWarningContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _openWorkoutLogger(
                              context,
                              ref,
                              existingWorkout: w,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            onPressed: () =>
                                _confirmDeleteWorkout(context, ref, w.id),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        if (w.exercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Text(
                                'No individual exercises tracked for this session.'),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: w.exercises.map((we) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        we.exerciseName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xs,
                                        children: we.sets.map((s) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.xs,
                                                vertical: AppSpacing.xxs),
                                            decoration: BoxDecoration(
                                              color: s.isPR
                                                  ? semantics.warningContainer
                                                  : colorScheme
                                                      .surfaceContainerHighest,
                                              borderRadius:
                                                  AppRadius.badgeRadius,
                                              border: Border.all(
                                                color: s.isPR
                                                    ? semantics.warning
                                                        .withAlpha(120)
                                                    : colorScheme.outlineVariant
                                                        .withAlpha(40),
                                              ),
                                            ),
                                            child: Text(
                                              '${s.weightKg}kg × ${s.repetitions}${s.rpe != null ? " @RPE${s.rpe}" : ""}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: s.isPR
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: s.isPR
                                                    ? semantics
                                                        .onWarningContainer
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _openTemplatePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final templatesAsync = ref.watch(gymTemplatesProvider);
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Start from Template'),
            ),
            body: templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (templates) {
                if (templates.isEmpty) {
                  return const Center(child: Text('No workout templates available.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = templates[i];
                    return Card(
                      color: colorScheme.surfaceContainer,
                      child: ListTile(
                        title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${t.category} • ${t.exercises.length} exercises'),
                        trailing: FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openWorkoutLogger(
                              context,
                              ref,
                              template: t,
                              templateSelection: TemplateSelectionModel.fromTemplate(t),
                            );
                          },
                          child: const Text('Use Template'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openRestTimerModal(BuildContext context) {
    RestTimerModalSheet.show(context);
  }

  Future<void> _confirmDeleteWorkout(
      BuildContext context, WidgetRef ref, String workoutId) async {
    final semantics = AppSemanticColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        title: const Text('Delete Workout?'),
        content: const Text(
            'This will delete all logged sets and volume data for this session.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: semantics.danger,
              foregroundColor: semantics.onDanger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(gymControllerProvider).deleteWorkout(workoutId);
    }
  }
}

void _openWorkoutLogger(
  BuildContext context,
  WidgetRef ref, {
  WorkoutTemplateModel? template,
  TemplateSelectionModel? templateSelection,
  WorkoutDetailModel? existingWorkout,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _WorkoutLoggerSheet(
      template: template,
      templateSelection: templateSelection,
      existingWorkout: existingWorkout,
    ),
  );
}

// ==========================================
// WORKOUT LOGGER MODAL
// ==========================================

class _WorkoutLoggerSheet extends ConsumerStatefulWidget {
  final WorkoutTemplateModel? template;
  final TemplateSelectionModel? templateSelection;
  final WorkoutDetailModel? existingWorkout;

  const _WorkoutLoggerSheet({
    this.template,
    this.templateSelection,
    this.existingWorkout,
  });

  @override
  ConsumerState<_WorkoutLoggerSheet> createState() =>
      _WorkoutLoggerSheetState();
}

class _WorkoutLoggerSheetState extends ConsumerState<_WorkoutLoggerSheet> {
  final _nameController = TextEditingController(text: 'Strength Workout');
  final _notesController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  bool _saveAsTemplate = false;

  final List<_ExerciseEntryState> _loggedExercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingWorkout != null) {
      final w = widget.existingWorkout!;
      _nameController.text = w.name;
      _notesController.text = w.notes ?? '';
      _durationController.text = w.durationMinutes.toString();
      for (final we in w.exercises) {
        _loggedExercises.add(_ExerciseEntryState(
          exerciseId: we.exerciseId,
          exerciseName: we.exerciseName,
          category: we.category,
          sets: we.sets
              .map((s) => _SetEntryDraft(
                    weightKg: s.weightKg,
                    repetitions: s.repetitions,
                    rpe: s.rpe,
                    tag: s.tag,
                    durationSeconds: s.durationSeconds,
                    distanceMeters: s.distanceMeters,
                    caloriesBurned: s.caloriesBurned,
                  ))
              .toList(),
        ));
      }
    } else {
      final selectedTemplate = widget.templateSelection ??
          (widget.template != null ? TemplateSelectionModel.fromTemplate(widget.template!) : null);
      if (selectedTemplate != null) {
        final t = selectedTemplate;
        _nameController.text = t.name;
        _notesController.text = t.description ?? '';
        for (final te in t.exercises) {
          final List<_SetEntryDraft> setsDraft = [];
          if (te.lastPerformance.isNotEmpty) {
            for (final lp in te.lastPerformance) {
              setsDraft.add(_SetEntryDraft(
                weightKg: lp.weightKg,
                repetitions: lp.repetitions,
                rpe: lp.rpe,
                tag: lp.tag,
                durationSeconds: lp.durationSeconds,
                distanceMeters: lp.distanceMeters,
                caloriesBurned: lp.caloriesBurned,
              ));
            }
          } else {
            final targetSets = te.targetSets > 0 ? te.targetSets : 3;
            final targetReps = te.targetReps > 0 ? te.targetReps : 10;
            final targetRpe = te.targetRpe ?? 8.0;
            final exName = te.exerciseName.toLowerCase();
            final double initialWeight;
            if (exName.contains('push-up') || exName.contains('pull-up') || exName.contains('dip')) {
              initialWeight = 0.0;
            } else if (exName.contains('curl') || exName.contains('raise') || exName.contains('fly') || exName.contains('pushdown') || exName.contains('extension')) {
              initialWeight = 10.0;
            } else if (exName.contains('squat') || exName.contains('deadlift') || exName.contains('press') || exName.contains('row')) {
              initialWeight = 20.0;
            } else {
              initialWeight = 15.0;
            }
            for (int s = 0; s < targetSets; s++) {
              setsDraft.add(_SetEntryDraft(
                weightKg: initialWeight,
                repetitions: targetReps,
                rpe: targetRpe,
                tag: 'N',
              ));
            }
          }
          _loggedExercises.add(_ExerciseEntryState(
            exerciseId: te.exerciseId,
            exerciseName: te.exerciseName,
            category: te.category,
            sets: setsDraft,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(gymExercisesProvider);
    final timerState = ref.watch(restTimerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existingWorkout != null
              ? 'Edit Workout Session'
              : 'Log Workout Session'),
          actions: [
            TextButton(
              onPressed: _saveWorkout,
              child: const Text('SAVE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Live background rest timer status banner if running
            if (timerState.isRunning || (timerState.remainingSeconds < timerState.totalSeconds && timerState.remainingSeconds > 0)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppRadius.cardRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Rest Timer: ${timerState.remainingSeconds ~/ 60}:${(timerState.remainingSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => RestTimerModalSheet.show(context),
                      child: const Text('Manage Timer', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Title *',
                hintText: 'e.g. Upper Body Hypertrophy',
                prefixIcon: Icon(Icons.fitness_center_rounded, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      prefixIcon: Icon(Icons.timer_outlined, size: 20),
                      suffixText: 'min',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Energy level, pump, or form cues',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises & Sets',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: const Text('Plate Calc'),
                      onPressed: () => PlateCalculatorDialog.show(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton.icon(
                      icon: const Icon(Icons.timer_outlined, size: 16),
                      label: const Text('Rest Timer'),
                      onPressed: () => RestTimerModalSheet.show(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // List of exercises added to this workout
            ..._loggedExercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final exState = entry.value;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius,
                  side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exState.exerciseName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _loggedExercises.removeAt(idx)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Sets Table
                      ...exState.sets.asMap().entries.map((sEntry) {
                        final sIdx = sEntry.key;
                        final s = sEntry.value;
                        final isCardio = exState.category.toUpperCase() == 'CARDIO';

                        // Tag styling
                        Color tagBg;
                        Color tagFg;
                        String tagLabel;
                        switch (s.tag) {
                          case 'W':
                            tagBg = Colors.amber.shade100;
                            tagFg = Colors.amber.shade900;
                            tagLabel = 'W (Warmup)';
                            break;
                          case 'D':
                            tagBg = Colors.purple.shade100;
                            tagFg = Colors.purple.shade900;
                            tagLabel = 'D (Drop)';
                            break;
                          case 'F':
                            tagBg = Colors.red.shade100;
                            tagFg = Colors.red.shade900;
                            tagLabel = 'F (Failure)';
                            break;
                          case 'N':
                          default:
                            tagBg = colorScheme.primaryContainer;
                            tagFg = colorScheme.onPrimaryContainer;
                            tagLabel = 'N (Normal)';
                            break;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Interactive Tag Cycle Chip
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      setState(() {
                                        const tags = ['N', 'W', 'D', 'F'];
                                        final currIdx = tags.indexOf(s.tag);
                                        s.tag = tags[(currIdx + 1) % tags.length];
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: tagBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${sIdx + 1} $tagLabel',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: tagFg,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  if (!isCardio) ...[
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey('weight_${idx}_${sIdx}_${s.weightKg}'),
                                        initialValue: s.weightKg.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Weight (kg)',
                                          isDense: true,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.calculate_outlined, size: 16),
                                            tooltip: 'Calculate Plates',
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () async {
                                              final calculated = await PlateCalculatorDialog.show(
                                                context,
                                                initialWeight: s.weightKg,
                                              );
                                              if (calculated != null && mounted) {
                                                setState(() {
                                                  s.weightKg = calculated;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        onChanged: (v) =>
                                            s.weightKg = double.tryParse(v) ?? 0.0,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: s.repetitions.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            s.repetitions = int.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: s.rpe?.toString() ?? '',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'RPE',
                                          isDense: true,
                                        ),
                                        onChanged: (v) => s.rpe = double.tryParse(v),
                                      ),
                                    ),
                                  ] else ...[
                                    // Cardio Dynamic Inputs: Duration, Distance, Calories
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: s.durationSeconds != null
                                            ? (s.durationSeconds! ~/ 60).toString()
                                            : '20',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Dur (min)',
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            s.durationSeconds = (int.tryParse(v) ?? 0) * 60,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: s.distanceMeters != null
                                            ? (s.distanceMeters! / 1000).toStringAsFixed(1)
                                            : '3.0',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Dist (km)',
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            s.distanceMeters = (double.tryParse(v) ?? 0.0) * 1000,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: s.caloriesBurned?.toString() ?? '150',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Calories',
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            s.caloriesBurned = int.tryParse(v),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Set',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              final lastWeight = exState.sets.isNotEmpty
                                  ? exState.sets.last.weightKg
                                  : 60.0;
                              final lastReps = exState.sets.isNotEmpty
                                  ? exState.sets.last.repetitions
                                  : 8;
                              exState.sets.add(_SetEntryDraft(
                                weightKg: lastWeight,
                                repetitions: lastReps,
                                tag: 'N',
                                durationSeconds: exState.sets.isNotEmpty
                                    ? exState.sets.last.durationSeconds
                                    : 1200,
                                distanceMeters: exState.sets.isNotEmpty
                                    ? exState.sets.last.distanceMeters
                                    : 3000,
                                caloriesBurned: exState.sets.isNotEmpty
                                    ? exState.sets.last.caloriesBurned
                                    : 180,
                              ));
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Button to Add Exercise from Catalog
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Exercise from Catalog'),
              onPressed: _pickExerciseDialog,
            ),
            const SizedBox(height: AppSpacing.md),

            // Save Workout as Template Checkbox / Switch
            SwitchListTile.adaptive(
              value: _saveAsTemplate,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Save as Reusable Template',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Creates a template schema from these exercises for future workouts',
                style: TextStyle(fontSize: 11),
              ),
              onChanged: (val) => setState(() => _saveAsTemplate = val),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExerciseDialog() async {
    final selected = await ExercisePickerDialog.show(context);
    if (selected != null && mounted) {
      setState(() {
        _loggedExercises.add(_ExerciseEntryState(
          exerciseId: selected.id,
          exerciseName: selected.name,
          category: selected.category,
          sets: selected.category.toUpperCase() == 'CARDIO'
              ? [
                  _SetEntryDraft(
                    weightKg: 0.0,
                    repetitions: 0,
                    tag: 'N',
                    durationSeconds: 1200,
                    distanceMeters: 3000,
                    caloriesBurned: 180,
                  ),
                ]
              : [
                  _SetEntryDraft(weightKg: 60.0, repetitions: 10, rpe: 8.0, tag: 'N'),
                  _SetEntryDraft(weightKg: 60.0, repetitions: 10, rpe: 8.5, tag: 'N'),
                  _SetEntryDraft(weightKg: 60.0, repetitions: 8, rpe: 9.0, tag: 'N'),
                ],
        ));
      });
    }
  }

  Future<void> _saveWorkout() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) return;

    final dur = int.tryParse(_durationController.text.trim()) ?? 60;
    final exercisesPayload = _loggedExercises.asMap().entries.map((entry) {
      final idx = entry.key;
      final ex = entry.value;
      return {
        'exerciseId': ex.exerciseId,
        'order': idx + 1,
        'sets': ex.sets.asMap().entries.map((sEntry) {
          final sIdx = sEntry.key;
          final s = sEntry.value;
          return {
            'setNumber': sIdx + 1,
            'weightKg': s.weightKg,
            'repetitions': s.repetitions,
            'tag': s.tag,
            if (s.rpe != null) 'rpe': s.rpe,
            if (s.durationSeconds != null) 'durationSeconds': s.durationSeconds,
            if (s.distanceMeters != null) 'distanceMeters': s.distanceMeters,
            if (s.caloriesBurned != null) 'caloriesBurned': s.caloriesBurned,
          };
        }).toList(),
      };
    }).toList();

    Navigator.pop(context);

    if (_saveAsTemplate && _loggedExercises.isNotEmpty) {
      final templateExercises = _loggedExercises.asMap().entries.map((entry) {
        final idx = entry.key;
        final ex = entry.value;
        return {
          'exerciseId': ex.exerciseId,
          'order': idx + 1,
          'targetSets': ex.sets.length > 0 ? ex.sets.length : 3,
          'targetReps': ex.sets.isNotEmpty ? ex.sets.first.repetitions : 10,
          if (ex.sets.isNotEmpty && ex.sets.first.rpe != null)
            'targetRpe': ex.sets.first.rpe,
        };
      }).toList();

      ref.read(gymControllerProvider).createTemplate(
            name: '$title Template',
            description: _notesController.text.trim().isEmpty
                ? 'Generated from workout session: $title'
                : _notesController.text.trim(),
            category: 'PPL',
            exercises: templateExercises,
          );
    }

    if (widget.existingWorkout != null) {
      await ref.read(gymControllerProvider).updateWorkout(
            workoutId: widget.existingWorkout!.id,
            name: title,
            notes: _notesController.text.trim(),
            durationMinutes: dur,
            exercises: exercisesPayload,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout updated successfully')),
        );
      }
    } else {
      final res = await ref.read(gymControllerProvider).logWorkout(
            name: title,
            notes: _notesController.text.trim(),
            durationMinutes: dur,
            exercises: exercisesPayload,
          );

      final prs = res['detectedPRs'] as List? ?? [];
      if (prs.isNotEmpty && mounted) {
        final semantics = AppSemanticColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: semantics.warningContainer,
            content: Text(
              '🔥 Awesome! You hit ${prs.length} new Personal Record(s)!',
              style: TextStyle(
                  color: semantics.onWarningContainer,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }
}

class _ExerciseEntryState {
  final String exerciseId;
  final String exerciseName;
  final String category;
  final List<_SetEntryDraft> sets;

  _ExerciseEntryState({
    required this.exerciseId,
    required this.exerciseName,
    this.category = 'CHEST',
    required this.sets,
  });
}

class _SetEntryDraft {
  double weightKg;
  int repetitions;
  double? rpe;
  String tag; // W, N, D, F
  int? durationSeconds;
  double? distanceMeters;
  int? caloriesBurned;

  _SetEntryDraft({
    required this.weightKg,
    required this.repetitions,
    this.rpe,
    this.tag = 'N',
    this.durationSeconds,
    this.distanceMeters,
    this.caloriesBurned,
  });
}

// ==========================================
// TAB 2: PROGRESSIVE OVERLOAD & PRs
// ==========================================

class _ProgressiveOverloadTab extends ConsumerStatefulWidget {
  const _ProgressiveOverloadTab();

  @override
  ConsumerState<_ProgressiveOverloadTab> createState() =>
      _ProgressiveOverloadTabState();
}

class _ProgressiveOverloadTabState
    extends ConsumerState<_ProgressiveOverloadTab> {
  String _search = '';
  String _selectedCategory = 'ALL';

  static const _categories = [
    'ALL',
    'CHEST',
    'BACK',
    'LEGS',
    'SHOULDERS',
    'ARMS',
    'CORE',
  ];

  @override
  Widget build(BuildContext context) {
    final prsAsync = ref.watch(gymPRsProvider);
    final exercisesAsync = ref.watch(gymExercisesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PR Trophy Header
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: semantics.warning, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Personal Records Wall',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          prsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading PRs: $err'),
            data: (prs) {
              if (prs.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No PRs logged yet. Heavy sets with reps automatically generate PRs!',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: prs.length,
                itemBuilder: (context, i) {
                  final pr = prs[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(color: semantics.warning.withAlpha(50)),
                    ),
                    color: colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            '${pr.weightKg}kg × ${pr.repetitions}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Est. 1RM: ${pr.calculatedOneRepMax}kg',
                            style: TextStyle(
                              fontSize: 11,
                              color: semantics.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Exercise 1RM History Explorer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Progression Explorer',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Exercise'),
                onPressed: () => _openCreateExerciseDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Search & Filter controls
          TextField(
            decoration: InputDecoration(
              hintText: 'Search movements...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.xs),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading exercises: $err'),
            data: (exercises) {
              final filtered = exercises.where((ex) {
                final matchesCategory = _selectedCategory == 'ALL' ||
                    ex.category.toUpperCase() == _selectedCategory ||
                    ex.muscleGroup.toUpperCase() == _selectedCategory;
                final matchesSearch = _search.isEmpty ||
                    ex.name.toLowerCase().contains(_search);
                return matchesCategory && matchesSearch;
              }).toList();

              if (filtered.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(40)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: Text('No matching exercises found.'),
                    ),
                  ),
                );
              }

              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius,
                  side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(40)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final ex = filtered[i];
                      return ListTile(
                        title: Text(ex.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle:
                            Text('${ex.muscleGroup} • ${ex.equipmentType}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _openExerciseHistoryModal(context, ex.id),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openExerciseHistoryModal(BuildContext context, String exerciseId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ExerciseHistorySheet(exerciseId: exerciseId),
    );
  }

  void _openCreateExerciseDialog(BuildContext context, WidgetRef ref) {
    CustomExerciseDialog.show(context);
  }
}

class _ExerciseHistorySheet extends ConsumerWidget {
  final String exerciseId;
  const _ExerciseHistorySheet({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(gymExerciseHistoryProvider(exerciseId));
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Progression Curve')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(gymExerciseHistoryProvider(exerciseId)),
        ),
        data: (data) {
          final chronologicalHistory = data.history.reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                data.exercise.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${data.exercise.muscleGroup} • Total Sessions: ${data.totalSessions}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.currentPR != null)
                Card(
                  elevation: 0,
                  color: semantics.warningContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(color: semantics.warning.withAlpha(50)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: semantics.onWarningContainer, size: 28),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All-Time Estimated 1RM',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: semantics.onWarningContainer),
                            ),
                            Text(
                              '${data.currentPR!.calculatedOneRepMax} kg',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: semantics.onWarningContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // 1RM Progressive Overload Curve (fl_chart)
              if (chronologicalHistory.length >= 2) ...[
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '1RM Progressive Overload Curve',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Est. 1RM (kg)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trajectory of calculated strength capacity across sessions',
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 20,
                                getDrawingHorizontalLine: (val) => FlLine(
                                  color:
                                      colorScheme.outlineVariant.withAlpha(30),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (idx, _) {
                                      final i = idx.toInt();
                                      if (i < 0 ||
                                          i >= chronologicalHistory.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final s = chronologicalHistory[i];
                                      final parts = s.date.split('T')[0].split('-');
                                      final label = parts.length >= 3
                                          ? '${parts[1]}/${parts[2]}'
                                          : 'S$i';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(label,
                                            style:
                                                const TextStyle(fontSize: 9)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 34,
                                    getTitlesWidget: (val, _) {
                                      return Text('${val.toInt()}',
                                          style:
                                              const TextStyle(fontSize: 9));
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chronologicalHistory
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(
                                          e.key.toDouble(), e.value.maxEst1RM))
                                      .toList(),
                                  isCurved: true,
                                  color: semantics.warning,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: semantics.warning.withAlpha(30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Text(
                'Historical Sessions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.history.isEmpty)
                Text(
                  'No sessions logged for this exercise yet.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              else
                ...data.history.map((s) {
                  return Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainer,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(40)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(
                            '${s.date.split("T")[0]} • ${s.workoutName}'),
                        subtitle: Text(
                          'Max Weight: ${s.maxWeight}kg • 1RM: ${s.maxEst1RM}kg • Vol: ${s.totalVolume}kg',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// TAB 3: VOLUME ANALYTICS & INSIGHTS
// ==========================================

class _VolumeAnalyticsTab extends ConsumerWidget {
  const _VolumeAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gymStatsProvider);
    final insightsAsync = ref.watch(gymInsightsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cross-Module Training Insights
          insightsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (insights) {
              if (insights.isEmpty) return const SizedBox.shrink();
              return Column(
                children: insights.map((ins) {
                  final isCritical = ins.severity == 'CRITICAL';
                  final isWarning = ins.severity == 'WARNING';
                  final isPositive = ins.severity == 'POSITIVE';

                  final Color bg;
                  final Color fg;
                  final Color borderCol;
                  final IconData icon;

                  if (isCritical) {
                    bg = semantics.dangerContainer;
                    fg = semantics.onDangerContainer;
                    borderCol = semantics.danger;
                    icon = Icons.warning_rounded;
                  } else if (isWarning) {
                    bg = semantics.warningContainer;
                    fg = semantics.onWarningContainer;
                    borderCol = semantics.warning;
                    icon = Icons.warning_amber_rounded;
                  } else if (isPositive) {
                    bg = semantics.successContainer;
                    fg = semantics.onSuccessContainer;
                    borderCol = semantics.success;
                    icon = Icons.check_circle_outline_rounded;
                  } else {
                    bg = semantics.infoContainer;
                    fg = semantics.onInfoContainer;
                    borderCol = semantics.info;
                    icon = Icons.insights_rounded;
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    color: bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(color: borderCol.withAlpha(80)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: fg, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  ins.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: fg),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: borderCol.withAlpha(40),
                                  borderRadius: AppRadius.badgeRadius,
                                ),
                                child: Text(
                                  ins.severity,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: fg),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            ins.message,
                            style: TextStyle(
                                fontSize: 12,
                                color: fg.withAlpha(230),
                                height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Total Lifetime Volume
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (stats) {
              final tonnage =
                  (stats.totalLifetimeTonnage / 1000.0).toStringAsFixed(1);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.cardRadius,
                            side: BorderSide(
                                color: colorScheme.outlineVariant.withAlpha(40)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(Icons.scale_rounded,
                                    color: colorScheme.primary, size: 28),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Tonnage',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '$tonnage T',
                                        style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.cardRadius,
                            side: BorderSide(
                                color: colorScheme.outlineVariant.withAlpha(40)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(Icons.accessibility_new_rounded,
                                    color: colorScheme.tertiary, size: 28),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Calisthenics Reps',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${stats.calisthenicsTotalReps} reps',
                                        style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 8-Week Rolling Workload Trend
                  if (stats.weeklyVolumeTrend.isNotEmpty) ...[
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.cardRadius,
                        side: BorderSide(
                            color: colorScheme.outlineVariant.withAlpha(40)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.bar_chart_rounded,
                                        color: colorScheme.primary, size: 20),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '8-Week Workload Volume Trend',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Weekly Tonnage (kg)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 150,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (stats.weeklyVolumeTrend
                                              .map((b) => b.volumeKg)
                                              .fold(
                                                  0.0,
                                                  (m, v) =>
                                                      v > m ? v : m) *
                                          1.25)
                                      .clamp(100.0, double.infinity),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (val) => FlLine(
                                      color: colorScheme.outlineVariant
                                          .withAlpha(25),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 38,
                                        getTitlesWidget: (val, _) {
                                          if (val == 0) {
                                            return const SizedBox.shrink();
                                          }
                                          final label = val >= 1000
                                              ? '${(val / 1000).toStringAsFixed(0)}k'
                                              : '${val.toInt()}';
                                          return Text(label,
                                              style: const TextStyle(
                                                  fontSize: 9));
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (idx, _) {
                                          final i = idx.toInt();
                                          if (i < 0 ||
                                              i >=
                                                  stats
                                                      .weeklyVolumeTrend
                                                      .length) {
                                            return const SizedBox.shrink();
                                          }
                                          final bucket =
                                              stats.weeklyVolumeTrend[i];
                                          final parts =
                                              bucket.weekStart.split('-');
                                          final label = parts.length >= 3
                                              ? '${parts[1]}/${parts[2]}'
                                              : 'W$i';
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4),
                                            child: Text(label,
                                                style: const TextStyle(
                                                    fontSize: 9)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: stats.weeklyVolumeTrend
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final i = entry.key;
                                    final b = entry.value;
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: b.volumeKg,
                                          color: i ==
                                                  stats.weeklyVolumeTrend
                                                          .length -
                                                      1
                                              ? colorScheme.primary
                                              : colorScheme.primary
                                                  .withAlpha(150),
                                          width: 14,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Hypertrophic Stimulus vs Structural Volume Telemetry Card
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(40)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded,
                                      color: Colors.deepOrange, size: 22),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Hypertrophy Stimulus Telemetry',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: AppRadius.badgeRadius,
                                ),
                                child: Text(
                                  'RPE ≥ 7 • RIR ≤ 3',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimaryContainer),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Filters non-stimulating warm-ups to isolate hyper-stimulating mechanical tension.',
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Stimulative Load',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stats.stimulativeWorkingVolumeKg.toStringAsFixed(0)} kg',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.deepOrange),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Warmup Load',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stats.warmupVolumeKg.toStringAsFixed(0)} kg',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Effective Sets',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stats.stimulativeSetsCount}/${stats.totalSetsCount}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Efficiency',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stats.hypertrophicEfficiencyPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: AppRadius.badgeRadius,
                            child: SizedBox(
                              height: 8,
                              child: LinearProgressIndicator(
                                value: (stats.hypertrophicEfficiencyPercentage /
                                        100.0)
                                    .clamp(0.0, 1.0),
                                backgroundColor:
                                    colorScheme.outlineVariant.withAlpha(60),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.deepOrange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Muscle Group Volume Distribution
                  Text(
                    'Volume by Muscle Group',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  ...stats.muscleDistribution.map((m) {
                    final pct = (m.percentage / 100.0).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m.muscleGroup,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${m.volumeKg.toStringAsFixed(0)} kg (${m.percentage.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                    fontSize: 12, color: colorScheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          ClipRRect(
                            borderRadius: AppRadius.badgeRadius,
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor:
                                  colorScheme.primaryContainer.withAlpha(80),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: BODY METRICS & TEMPLATES
// ==========================================

class _BodyMetricsTemplatesTab extends ConsumerStatefulWidget {
  const _BodyMetricsTemplatesTab();

  @override
  ConsumerState<_BodyMetricsTemplatesTab> createState() =>
      _BodyMetricsTemplatesTabState();
}

class _BodyMetricsTemplatesTabState
    extends ConsumerState<_BodyMetricsTemplatesTab> {
  int _selectedSegment = 0; // 0: Body Composition & Trends, 1: Workout Templates

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.show_chart_rounded, size: 18),
                  label: Text('Body Composition & Trends'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.copy_rounded, size: 18),
                  label: Text('Workout Templates'),
                ),
              ],
              selected: {_selectedSegment},
              onSelectionChanged: (set) {
                setState(() => _selectedSegment = set.first);
              },
            ),
          ),
        ),
        Expanded(
          child: _selectedSegment == 0
              ? const GymProgressTab()
              : _buildTemplatesList(context, ref),
        ),
      ],
    );
  }

  Widget _buildTemplatesList(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(gymTemplatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(gymTemplatesProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxxl),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workout Templates & Routines',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New Template'),
                    onPressed: () => CustomTemplateDialog.show(context),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    icon: const Icon(Icons.fitness_center_rounded, size: 16),
                    label: const Text('Log Workout'),
                    onPressed: () => _openWorkoutLogger(context, ref),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          templatesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () => ref.refresh(gymTemplatesProvider),
            ),
            data: (templates) {
              if (templates.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No templates found. Pre-configured routines will appear here.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: templates.map((t) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    color: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(40)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: AppRadius.badgeRadius,
                                ),
                                child: Text(
                                  t.category,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimaryContainer),
                                ),
                              ),
                            ],
                          ),
                          if (t.description != null &&
                              t.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(t.description!,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: t.exercises.map((e) {
                              return Chip(
                                label: Text(
                                  '${e.exerciseName} (${e.targetSets}×${e.targetReps})',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.pillRadius),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 18),
                              label: const Text('Use Template'),
                              onPressed: () {
                                _openWorkoutLogger(
                                  context,
                                  ref,
                                  template: t,
                                  templateSelection:
                                      TemplateSelectionModel.fromTemplate(t),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
