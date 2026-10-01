import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import '../../../app/theme/app_theme.dart';
import 'controllers/gym_controller.dart';
import 'models/gym_models.dart';

// Backward compatibility typedef for existing callers
typedef WorkoutModel = WorkoutDetailModel;

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

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
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Rest Timer'),
                  onPressed: () => _openRestTimerModal(context),
                ),
              ];

              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: AppSpacing.sm),
                    buttons[1],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: buttons[1]),
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

  void _openWorkoutLogger(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _WorkoutLoggerSheet(),
    );
  }

  void _openRestTimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _RestTimerWidget(),
    );
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

// ==========================================
// WORKOUT LOGGER MODAL
// ==========================================

class _WorkoutLoggerSheet extends ConsumerStatefulWidget {
  const _WorkoutLoggerSheet();

  @override
  ConsumerState<_WorkoutLoggerSheet> createState() =>
      _WorkoutLoggerSheetState();
}

class _WorkoutLoggerSheetState extends ConsumerState<_WorkoutLoggerSheet> {
  final _nameController = TextEditingController(text: 'Strength Workout');
  final _notesController = TextEditingController();
  final _durationController = TextEditingController(text: '60');

  final List<_ExerciseEntryState> _loggedExercises = [];

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(gymExercisesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Workout Session'),
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Title *',
                hintText: 'e.g. Upper Body Hypertrophy',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Duration (min)'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    decoration:
                        const InputDecoration(labelText: 'Notes (optional)'),
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
                TextButton.icon(
                  icon: const Icon(Icons.timer_outlined, size: 16),
                  label: const Text('Rest Timer'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => const _RestTimerWidget(),
                    );
                  },
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Text('Set ${sIdx + 1}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: TextFormField(
                                  initialValue: s.weightKg.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    isDense: true,
                                  ),
                                  onChanged: (v) =>
                                      s.weightKg = double.tryParse(v) ?? 0.0,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
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
                              const SizedBox(width: AppSpacing.sm),
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
                                  weightKg: lastWeight, repetitions: lastReps));
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
            exercisesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (catalog) {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercise from Catalog'),
                  onPressed: () => _pickExerciseDialog(catalog),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickExerciseDialog(List<ExerciseCatalogModel> catalog) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        title: const Text('Select Exercise'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: catalog.length,
            itemBuilder: (ctx, i) {
              final ex = catalog[i];
              return ListTile(
                title: Text(ex.name),
                subtitle: Text('${ex.muscleGroup} • ${ex.equipmentType}'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _loggedExercises.add(_ExerciseEntryState(
                      exerciseId: ex.id,
                      exerciseName: ex.name,
                      sets: [
                        _SetEntryDraft(
                            weightKg: 60.0, repetitions: 10, rpe: 8.0),
                        _SetEntryDraft(
                            weightKg: 60.0, repetitions: 10, rpe: 8.5),
                        _SetEntryDraft(
                            weightKg: 60.0, repetitions: 8, rpe: 9.0),
                      ],
                    ));
                  });
                },
              );
            },
          ),
        ),
      ),
    );
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
            if (s.rpe != null) 'rpe': s.rpe,
          };
        }).toList(),
      };
    }).toList();

    Navigator.pop(context);

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

class _ExerciseEntryState {
  final String exerciseId;
  final String exerciseName;
  final List<_SetEntryDraft> sets;

  _ExerciseEntryState({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

class _SetEntryDraft {
  double weightKg;
  int repetitions;
  double? rpe;

  _SetEntryDraft({required this.weightKg, required this.repetitions, this.rpe});
}

// ==========================================
// REST TIMER WIDGET (IN-WORKOUT UX)
// ==========================================

class _RestTimerWidget extends StatefulWidget {
  const _RestTimerWidget();

  @override
  State<_RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<_RestTimerWidget> {
  int _totalSeconds = 90;
  int _remainingSeconds = 90;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final progress =
        _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'In-Workout Rest Timer',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: colorScheme.primaryContainer.withAlpha(80),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingSeconds == 0
                        ? semantics.success
                        : colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$mins:${secs.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _remainingSeconds == 0
                        ? 'Rest Complete!'
                        : (_isRunning ? 'Resting...' : 'Ready'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _remainingSeconds == 0
                          ? semantics.success
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _presetChip(60, '60s'),
              const SizedBox(width: AppSpacing.sm),
              _presetChip(90, '90s'),
              const SizedBox(width: AppSpacing.sm),
              _presetChip(120, '2m'),
              const SizedBox(width: AppSpacing.sm),
              _presetChip(180, '3m'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int secs, String label) {
    return ActionChip(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      label: Text(label),
      onPressed: () => _startTimer(secs),
    );
  }
}

// ==========================================
// TAB 2: PROGRESSIVE OVERLOAD & PRs
// ==========================================

class _ProgressiveOverloadTab extends ConsumerWidget {
  const _ProgressiveOverloadTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text(
            'Exercise Progression Explorer',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),

          exercisesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (exercises) {
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
                    itemCount: exercises.take(6).length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final ex = exercises[i];
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
                  final isWarning = ins.severity == 'WARNING';
                  final bg = isWarning
                      ? semantics.warningContainer
                      : semantics.infoContainer;
                  final fg = isWarning
                      ? semantics.onWarningContainer
                      : semantics.onInfoContainer;
                  final borderCol =
                      isWarning ? semantics.warning : semantics.info;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    color: bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                      side: BorderSide(color: borderCol.withAlpha(60)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isWarning
                                    ? Icons.warning_amber_rounded
                                    : Icons.psychology_outlined,
                                color: fg,
                              ),
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
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(ins.message,
                              style: TextStyle(fontSize: 12, color: fg)),
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
                      child: Row(
                        children: [
                          Icon(Icons.scale_rounded,
                              color: colorScheme.primary, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Tonnage Lifted',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                '$tonnage Tons',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
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

class _BodyMetricsTemplatesTab extends ConsumerWidget {
  const _BodyMetricsTemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(gymBodyMetricsProvider);
    final templatesAsync = ref.watch(gymTemplatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body Weight & 7-Day Average
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Body Weight & 7-Day Trend',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Weight'),
                onPressed: () => _openLogBodyMetricDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          metricsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (metrics) {
              if (metrics.isEmpty) {
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
                      'No body metrics logged. Log daily weight to unlock 7-day smoothing.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              final latest = metrics.first;
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
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.md,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Latest Weight',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                          Text('${latest.weightKg} kg',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '7-Day Rolling Avg',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            '${latest.sevenDayAverageKg} kg',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (latest.bodyFatPercent != null)
                        Column(
                          children: [
                            Text(
                              'Body Fat',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            Text('${latest.bodyFatPercent}%',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Workout Routines & Templates
          Text(
            'Workout Templates & Routines',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),

          templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (templates) {
              if (templates.isEmpty) {
                return Text(
                  'No templates found.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: templates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final t = templates[i];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
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
                                      color: colorScheme.onPrimaryContainer),
                                ),
                              ),
                            ],
                          ),
                          if (t.description != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(t.description!,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            children: t.exercises.map((e) {
                              return Chip(
                                label: Text(
                                    '${e.exerciseName} (${e.targetSets}×${e.targetReps})'),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.pillRadius),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
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

  void _openLogBodyMetricDialog(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController();
    final bfCtrl = TextEditingController();
    final waistCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        title: const Text('Log Body Metric'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Body Weight (kg) *'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: bfCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Body Fat % (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: waistCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Waist Circumference (cm)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final w = double.tryParse(weightCtrl.text.trim());
              if (w == null) return;
              Navigator.pop(ctx);
              await ref.read(gymControllerProvider).logBodyMetric(
                    weightKg: w,
                    bodyFatPercent: double.tryParse(bfCtrl.text.trim()),
                    waistCm: double.tryParse(waistCtrl.text.trim()),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
