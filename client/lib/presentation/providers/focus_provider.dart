import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/focus_session_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/focus_repository.dart';
import 'dashboard_provider.dart';
import 'habits_provider.dart';

enum PomodoroStatus { idle, running, paused, completed }

class FocusState {
  final PomodoroStatus status;
  final int targetMinutes;
  final int remainingSeconds;
  final String category;
  final String? activeSessionId;
  final String? activeTaskId;
  final TaskModel? activeTask;
  final String? activeHabitId;
  final HabitModel? activeHabit;
  final DateTime? sessionStartTime;
  final DateTime? targetEndTime;
  final List<FocusSessionModel> todaySessions;
  final FocusStatsModel? todayStats;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const FocusState({
    this.status = PomodoroStatus.idle,
    this.targetMinutes = 25,
    this.remainingSeconds = 25 * 60,
    this.category = 'CODING',
    this.activeSessionId,
    this.activeTaskId,
    this.activeTask,
    this.activeHabitId,
    this.activeHabit,
    this.sessionStartTime,
    this.targetEndTime,
    this.todaySessions = const [],
    this.todayStats,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  FocusState copyWith({
    PomodoroStatus? status,
    int? targetMinutes,
    int? remainingSeconds,
    String? category,
    String? activeSessionId,
    String? activeTaskId,
    TaskModel? activeTask,
    String? activeHabitId,
    HabitModel? activeHabit,
    DateTime? sessionStartTime,
    DateTime? targetEndTime,
    List<FocusSessionModel>? todaySessions,
    FocusStatsModel? todayStats,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearActiveSession = false,
    bool clearActiveTask = false,
    bool clearActiveHabit = false,
    bool clearTargetEndTime = false,
  }) {
    return FocusState(
      status: status ?? this.status,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      category: category ?? this.category,
      activeSessionId: clearActiveSession
          ? null
          : (activeSessionId ?? this.activeSessionId),
      activeTaskId:
          clearActiveTask ? null : (activeTaskId ?? this.activeTaskId),
      activeTask: clearActiveTask ? null : (activeTask ?? this.activeTask),
      activeHabitId:
          clearActiveHabit ? null : (activeHabitId ?? this.activeHabitId),
      activeHabit:
          clearActiveHabit ? null : (activeHabit ?? this.activeHabit),
      sessionStartTime: clearActiveSession
          ? null
          : (sessionStartTime ?? this.sessionStartTime),
      targetEndTime: clearTargetEndTime
          ? null
          : (targetEndTime ?? this.targetEndTime),
      todaySessions: todaySessions ?? this.todaySessions,
      todayStats: todayStats ?? this.todayStats,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  final FocusRepository _repository;
  final SecureStorageService _storage;
  final Ref _ref;
  Timer? _timer;
  final Set<String> _creditedSessionKeys = {};

  FocusNotifier(this._repository, this._storage, this._ref)
      : super(const FocusState()) {
    _init();
  }

  Future<void> _init() async {
    await loadTodayData();
    await _restoreTimerFromStorage();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadTodayData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final now = DateTime.now();
      final startOfToday =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final sessions =
          await _repository.getFocusSessions(startDate: startOfToday);
      final stats = await _repository.getFocusStats();
      state = state.copyWith(
        isLoading: false,
        todaySessions: sessions,
        todayStats: stats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setDuration(int minutes) {
    if (state.status != PomodoroStatus.idle) return;
    state = state.copyWith(
      targetMinutes: minutes,
      remainingSeconds: minutes * 60,
    );
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  Future<void> startTimer({
    String? taskId,
    String? notes,
    String? category,
  }) async {
    if (state.status == PomodoroStatus.running) return;

    final targetCategory = category ?? state.category;
    final targetTaskId = taskId ?? state.activeTaskId;

    if (state.status == PomodoroStatus.idle) {
      final now = DateTime.now();
      final targetEndTime = now.add(Duration(seconds: state.remainingSeconds));

      try {
        final session = await _repository.startSession(
          category: targetCategory,
          taskId: targetTaskId,
          notes: notes,
        );
        state = state.copyWith(
          status: PomodoroStatus.running,
          category: targetCategory,
          activeTaskId: targetTaskId,
          activeSessionId: session.id,
          sessionStartTime: now,
          targetEndTime: targetEndTime,
          errorMessage: null,
        );
      } catch (e) {
        // Fallback local start if network fails
        state = state.copyWith(
          status: PomodoroStatus.running,
          category: targetCategory,
          activeTaskId: targetTaskId,
          sessionStartTime: now,
          targetEndTime: targetEndTime,
          errorMessage: null,
        );
      }
    } else {
      // Resume from paused
      final targetEndTime =
          DateTime.now().add(Duration(seconds: state.remainingSeconds));
      state = state.copyWith(
        status: PomodoroStatus.running,
        targetEndTime: targetEndTime,
        errorMessage: null,
      );
    }

    _saveTimerState();
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.targetEndTime == null) return;
      final remaining =
          state.targetEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        state = state.copyWith(remainingSeconds: remaining);
      } else {
        _timer?.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          status: PomodoroStatus.completed,
        );
        finishAndSaveSession();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    final remaining = state.targetEndTime != null
        ? state.targetEndTime!.difference(DateTime.now()).inSeconds
        : state.remainingSeconds;
    final clampedRemaining = remaining.clamp(0, state.targetMinutes * 60);

    state = state.copyWith(
      status: PomodoroStatus.paused,
      remainingSeconds: clampedRemaining,
      clearTargetEndTime: true,
    );
    _saveTimerState();
  }

  void resetTimer({bool skipServerCancel = false}) {
    _timer?.cancel();
    final currentSessionId = state.activeSessionId;

    if (!skipServerCancel && currentSessionId != null) {
      unawaited(
        _repository.cancelSession(currentSessionId).then<void>(
              (_) {},
              onError: (_) {},
            ),
      );
    }

    _clearSavedTimer();
    state = state.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: state.targetMinutes * 60,
      clearActiveSession: true,
      clearActiveTask: true,
      clearActiveHabit: true,
      clearTargetEndTime: true,
      errorMessage: null,
    );
  }

  void startTimerForHabit(HabitModel habit, {int? customMinutes}) {
    final minutes =
        customMinutes ?? (habit.targetValue > 0 ? habit.targetValue : 25);
    final mappedCategory = _mapHabitToFocusCategory(habit);

    setDuration(minutes);
    setCategory(mappedCategory);
    state = state.copyWith(
      activeHabitId: habit.id,
      activeHabit: habit,
      clearActiveTask: true,
    );
    startTimer(notes: 'Habit: ${habit.name}');
  }

  void startTimerForTask(TaskModel task, {int? customMinutes}) {
    final minutes = customMinutes ??
        (task.estimatedMinutes != null && task.estimatedMinutes! > 0
            ? task.estimatedMinutes!
            : 25);
    final mappedCategory = _mapTaskToFocusCategory(task);

    setDuration(minutes);
    setCategory(mappedCategory);
    state = state.copyWith(
      activeTaskId: task.id,
      activeTask: task,
      clearActiveHabit: true,
    );
    startTimer(
      taskId: task.id,
      category: mappedCategory,
      notes: 'Task: ${task.title}',
    );
  }

  String _mapHabitToFocusCategory(HabitModel habit) {
    final catName = habit.category?.name.toUpperCase() ?? '';
    if (catName.contains('HEALTH') || catName.contains('FITNESS')) {
      return 'WELLNESS';
    }
    if (catName.contains('STUDY') || catName.contains('LEARN')) {
      return 'STUDY';
    }
    if (catName.contains('MINDFUL')) return 'WELLNESS';
    if (catName.contains('DEV') || catName.contains('CODE')) return 'CODING';
    if (catName.contains('WORK') || catName.contains('PROJECT')) {
      return 'PROJECT';
    }
    return 'OTHER';
  }

  String _mapTaskToFocusCategory(TaskModel task) {
    final searchableText = [
      task.title,
      ...task.tags,
    ].join(' ').toUpperCase();
    final title = task.title.toUpperCase();
    if (searchableText.contains('HEALTH') ||
        searchableText.contains('FITNESS')) {
      return 'WELLNESS';
    }
    if (searchableText.contains('STUDY') ||
        searchableText.contains('LEARN')) {
      return 'STUDY';
    }
    if (searchableText.contains('MINDFUL')) return 'WELLNESS';
    if (searchableText.contains('DEV') ||
        searchableText.contains('CODE') ||
        title.contains('BUG') ||
        title.contains('FEATURE')) {
      return 'CODING';
    }
    if (searchableText.contains('WORK') ||
        searchableText.contains('PROJECT') ||
        task.projectId != null) {
      return 'PROJECT';
    }
    return 'OTHER';
  }

  Future<void> finishAndSaveSession({String? notes}) async {
    _timer?.cancel();
    final elapsedSeconds =
        (state.targetMinutes * 60) - state.remainingSeconds;
    final elapsedMinutes = (elapsedSeconds / 60).ceil().clamp(1, 1440);
    final linkedHabit = state.activeHabit;
    final sessionId = state.activeSessionId;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      if (sessionId != null) {
        await _repository.endSession(
          sessionId,
          durationMinutes: elapsedMinutes,
          taskId: state.activeTaskId,
          notes: notes,
        );
      } else if (state.sessionStartTime != null) {
        final endTime = DateTime.now();
        await _repository.logCompletedSession(
          startTime: state.sessionStartTime!.toIso8601String(),
          endTime: endTime.toIso8601String(),
          durationMinutes: elapsedMinutes,
          category: state.category,
          taskId: state.activeTaskId,
          notes: notes,
        );
      }

      // Idempotent habit progress crediting using session key
      if (linkedHabit != null) {
        final creditKey =
            '${linkedHabit.id}_${sessionId ?? state.sessionStartTime?.toIso8601String()}';
        if (!_creditedSessionKeys.contains(creditKey)) {
          _creditedSessionKeys.add(creditKey);
          _ref
              .read(habitsProvider.notifier)
              .incrementHabitProgress(linkedHabit, elapsedMinutes);
        }
      }

      await _clearSavedTimer();
      state = state.copyWith(isSaving: false, errorMessage: null);

      resetTimer(skipServerCancel: true);
      await loadTodayData();
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to save focus session: ${e.toString()}',
      );
      // Retain completed state so the user can retry saving
    }
  }

  Future<void> retrySaveSession({String? notes}) async {
    if (state.isSaving) return;
    await finishAndSaveSession(notes: notes);
  }

  Future<void> deleteSession(String id) async {
    try {
      await _repository.deleteSession(id);
      await loadTodayData();
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> _saveTimerState() async {
    try {
      final map = {
        'status': state.status.name,
        'targetMinutes': state.targetMinutes,
        'remainingSeconds': state.remainingSeconds,
        'category': state.category,
        'activeSessionId': state.activeSessionId,
        'activeTaskId': state.activeTaskId,
        'activeHabitId': state.activeHabitId,
        'sessionStartTime': state.sessionStartTime?.toIso8601String(),
        'targetEndTime': state.targetEndTime?.toIso8601String(),
      };
      await _storage.saveActiveTimer(jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _clearSavedTimer() async {
    try {
      await _storage.clearActiveTimer();
    } catch (_) {}
  }

  Future<void> _restoreTimerFromStorage() async {
    try {
      final raw = await _storage.getActiveTimer();
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final statusStr = data['status'] as String?;
      final targetMinutes = (data['targetMinutes'] as num?)?.toInt() ?? 25;
      final category = (data['category'] as String?) ?? 'CODING';
      final activeSessionId = data['activeSessionId'] as String?;
      final activeTaskId = data['activeTaskId'] as String?;
      final activeHabitId = data['activeHabitId'] as String?;
      final startTime = data['sessionStartTime'] != null
          ? DateTime.tryParse(data['sessionStartTime'] as String)
          : null;
      final targetEndTime = data['targetEndTime'] != null
          ? DateTime.tryParse(data['targetEndTime'] as String)
          : null;

      if (statusStr == PomodoroStatus.running.name && targetEndTime != null) {
        final remaining =
            targetEndTime.difference(DateTime.now()).inSeconds;
        if (remaining <= 0) {
          state = state.copyWith(
            status: PomodoroStatus.completed,
            targetMinutes: targetMinutes,
            remainingSeconds: 0,
            category: category,
            activeSessionId: activeSessionId,
            activeTaskId: activeTaskId,
            activeHabitId: activeHabitId,
            sessionStartTime: startTime,
            targetEndTime: targetEndTime,
          );
          finishAndSaveSession();
        } else {
          state = state.copyWith(
            status: PomodoroStatus.running,
            targetMinutes: targetMinutes,
            remainingSeconds: remaining,
            category: category,
            activeSessionId: activeSessionId,
            activeTaskId: activeTaskId,
            activeHabitId: activeHabitId,
            sessionStartTime: startTime,
            targetEndTime: targetEndTime,
          );
          _startTicker();
        }
      } else if (statusStr == PomodoroStatus.paused.name) {
        final remaining = (data['remainingSeconds'] as num?)?.toInt() ??
            (targetMinutes * 60);
        state = state.copyWith(
          status: PomodoroStatus.paused,
          targetMinutes: targetMinutes,
          remainingSeconds: remaining,
          category: category,
          activeSessionId: activeSessionId,
          activeTaskId: activeTaskId,
          activeHabitId: activeHabitId,
          sessionStartTime: startTime,
        );
      }
    } catch (_) {}
  }
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  final repository = ref.watch(focusRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return FocusNotifier(repository, storage, ref);
});
