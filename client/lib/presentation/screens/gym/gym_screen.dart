import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'controllers/gym_controller.dart';
import 'models/gym_models.dart';

// Backward compatibility typedef for existing callers
typedef WorkoutModel = WorkoutDetailModel;

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> with SingleTickerProviderStateMixin {
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
            Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Workouts & Logger'),
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Progressive Overload'),
            Tab(icon: Icon(Icons.pie_chart_outline_rounded), text: 'Volume & Insights'),
            Tab(icon: Icon(Icons.monitor_weight_outlined), text: 'Body & Templates'),
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(gymControllerProvider).invalidateGymData();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Weekly Target Progress Card
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              final pct = (stats.workoutsThisWeek / stats.weeklyTarget).clamp(0.0, 1.0);
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                stats.workedOutToday
                                    ? Icons.check_circle_rounded
                                    : Icons.fitness_center_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Weekly Target: ${stats.workoutsThisWeek}/${stats.weeklyTarget} Sessions',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            stats.workedOutToday ? 'Trained Today ✓' : 'Ready to Lift',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stats.workedOutToday ? Colors.green : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: colorScheme.primary.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stats.workoutsThisWeek >= stats.weeklyTarget
                                ? Colors.green
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Action buttons: Quick Log or Start from Template
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log Workout'),
                  onPressed: () => _openWorkoutLogger(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Rest Timer'),
                onPressed: () => _openRestTimerModal(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Workout History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

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
                  description: 'Tap "+ Log Workout" to start tracking progressive overload.',
                  actionLabel: 'Log Workout',
                  onAction: () => _openWorkoutLogger(context, ref),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workouts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final w = workouts[i];
                  final dateStr = w.date.split('T')[0];
                  final tonnageStr = w.totalVolume >= 1000
                      ? '${(w.totalVolume / 1000).toStringAsFixed(1)} tons'
                      : '${w.totalVolume.toStringAsFixed(0)} kg';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                    color: colorScheme.surfaceContainerHighest,
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center_rounded, color: colorScheme.primary, size: 20),
                      ),
                      title: Text(
                        w.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emoji_events_rounded, size: 12, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${w.prCount} PR',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            onPressed: () => _confirmDeleteWorkout(context, ref, w.id),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        if (w.exercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No individual exercises tracked for this session.'),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: w.exercises.map((we) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        we.exerciseName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: we.sets.map((s) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: s.isPR
                                                  ? Colors.amber.withAlpha(40)
                                                  : colorScheme.surface,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: s.isPR
                                                    ? Colors.amber
                                                    : colorScheme.outlineVariant.withAlpha(60),
                                              ),
                                            ),
                                            child: Text(
                                              '${s.weightKg}kg × ${s.repetitions}${s.rpe != null ? " @RPE${s.rpe}" : ""}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: s.isPR ? FontWeight.bold : FontWeight.normal,
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

  Future<void> _confirmDeleteWorkout(BuildContext context, WidgetRef ref, String workoutId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('This will delete all logged sets and volume data for this session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
  ConsumerState<_WorkoutLoggerSheet> createState() => _WorkoutLoggerSheetState();
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Workout Session'),
          actions: [
            TextButton(
              onPressed: _saveWorkout,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Title *',
                hintText: 'e.g. Upper Body Hypertrophy',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (min)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises & Sets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 8),

            // List of exercises added to this workout
            ..._loggedExercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final exState = entry.value;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exState.exerciseName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _loggedExercises.removeAt(idx)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Sets Table
                      ...exState.sets.asMap().entries.map((sEntry) {
                        final sIdx = sEntry.key;
                        final s = sEntry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text('Set ${sIdx + 1}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: TextFormField(
                                  initialValue: s.weightKg.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    isDense: true,
                                  ),
                                  onChanged: (v) => s.weightKg = double.tryParse(v) ?? 0.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: s.repetitions.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    isDense: true,
                                  ),
                                  onChanged: (v) => s.repetitions = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          label: const Text('Add Set', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              final lastWeight = exState.sets.isNotEmpty ? exState.sets.last.weightKg : 60.0;
                              final lastReps = exState.sets.isNotEmpty ? exState.sets.last.repetitions : 8;
                              exState.sets.add(_SetEntryDraft(weightKg: lastWeight, repetitions: lastReps));
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
                        _SetEntryDraft(weightKg: 60.0, repetitions: 10, rpe: 8.0),
                        _SetEntryDraft(weightKg: 60.0, repetitions: 10, rpe: 8.5),
                        _SetEntryDraft(weightKg: 60.0, repetitions: 8, rpe: 9.0),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amber[800],
          content: Text('🔥 Awesome! You hit ${prs.length} new Personal Record(s)!'),
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
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'In-Workout Rest Timer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: colorScheme.primary.withAlpha(40),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingSeconds == 0 ? Colors.green : colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$mins:${secs.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _remainingSeconds == 0
                        ? 'Rest Complete!'
                        : (_isRunning ? 'Resting...' : 'Ready'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _remainingSeconds == 0 ? Colors.green : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _presetChip(60, '60s'),
              const SizedBox(width: 8),
              _presetChip(90, '90s'),
              const SizedBox(width: 8),
              _presetChip(120, '2m'),
              const SizedBox(width: 8),
              _presetChip(180, '3m'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int secs, String label) {
    return ActionChip(
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PR Trophy Header
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Personal Records Wall',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          prsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading PRs: $err'),
            data: (prs) {
              if (prs.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No PRs logged yet. Heavy sets with reps automatically generate PRs!'),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: prs.length,
                itemBuilder: (context, i) {
                  final pr = prs[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.amber.withAlpha(60)),
                    ),
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            '${pr.weightKg}kg × ${pr.repetitions}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Est. 1RM: ${pr.calculatedOneRepMax}kg',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.amber,
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
          const SizedBox(height: 24),

          // Exercise 1RM History Explorer
          Text(
            'Exercise Progression Explorer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          exercisesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (exercises) {
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.take(6).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final ex = exercises[i];
                    return ListTile(
                      title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${ex.muscleGroup} • ${ex.equipmentType}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openExerciseHistoryModal(context, ex.id),
                    );
                  },
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
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data.exercise.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('${data.exercise.muscleGroup} • Total Sessions: ${data.totalSessions}'),
              const SizedBox(height: 16),
              if (data.currentPR != null)
                Card(
                  elevation: 0,
                  color: Colors.amber.withAlpha(25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('All-Time Estimated 1RM', style: TextStyle(fontSize: 12)),
                            Text(
                              '${data.currentPR!.calculatedOneRepMax} kg',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Historical Sessions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (data.history.isEmpty)
                const Text('No sessions logged for this exercise yet.')
              else
                ...data.history.map((s) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                    child: ListTile(
                      title: Text('${s.date.split("T")[0]} • ${s.workoutName}'),
                      subtitle: Text('Max Weight: ${s.maxWeight}kg • 1RM: ${s.maxEst1RM}kg • Vol: ${s.totalVolume}kg'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isWarning ? Colors.orange.withAlpha(25) : Colors.blue.withAlpha(25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isWarning ? Colors.orange : Colors.blueAccent),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isWarning ? Icons.warning_amber_rounded : Icons.psychology_outlined,
                                color: isWarning ? Colors.orange : Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ins.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(ins.message, style: const TextStyle(fontSize: 12)),
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
              final tonnage = (stats.totalLifetimeTonnage / 1000.0).toStringAsFixed(1);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.scale_rounded, color: colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Tonnage Lifted', style: TextStyle(fontSize: 12)),
                              Text(
                                '$tonnage Tons',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Muscle Group Volume Distribution
                  Text(
                    'Volume by Muscle Group',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...stats.muscleDistribution.map((m) {
                    final pct = (m.percentage / 100.0).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m.muscleGroup, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${m.volumeKg.toStringAsFixed(0)} kg (${m.percentage.toStringAsFixed(0)}%)',
                                style: TextStyle(fontSize: 12, color: colorScheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: colorScheme.primary.withAlpha(30),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body Weight & 7-Day Average
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Body Weight & 7-Day Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Weight'),
                onPressed: () => _openLogBodyMetricDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 10),

          metricsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (metrics) {
              if (metrics.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No body metrics logged. Log daily weight to unlock 7-day smoothing.'),
                  ),
                );
              }

              final latest = metrics.first;
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Latest Weight', style: TextStyle(fontSize: 12)),
                          Text('${latest.weightKg} kg',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('7-Day Rolling Avg', style: TextStyle(fontSize: 12)),
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
                            const Text('Body Fat', style: TextStyle(fontSize: 12)),
                            Text('${latest.bodyFatPercent}%',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Workout Routines & Templates
          Text(
            'Workout Templates & Routines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (templates) {
              if (templates.isEmpty) {
                return const Text('No templates found.');
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.category,
                                  style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer),
                                ),
                              ),
                            ],
                          ),
                          if (t.description != null) ...[
                            const SizedBox(height: 4),
                            Text(t.description!, style: Theme.of(context).textTheme.bodySmall),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: t.exercises.map((e) {
                              return Chip(
                                label: Text('${e.exerciseName} (${e.targetSets}×${e.targetReps})'),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
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
        title: const Text('Log Body Metric'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Body Weight (kg) *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bfCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Body Fat % (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waistCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Waist Circumference (cm)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
