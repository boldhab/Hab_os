import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/focus_session_model.dart';
import '../../data/repositories/focus_repository.dart';
import 'dashboard_provider.dart';

enum PomodoroStatus { idle, running, paused, completed }

class FocusState {
  final PomodoroStatus status;
  final int targetMinutes;
  final int remainingSeconds;
  final String category;
  final String? activeSessionId;
  final DateTime? sessionStartTime;
  final List<FocusSessionModel> todaySessions;
  final FocusStatsModel? todayStats;
  final bool isLoading;
  final String? errorMessage;

  const FocusState({
    this.status = PomodoroStatus.idle,
    this.targetMinutes = 25,
    this.remainingSeconds = 25 * 60,
    this.category = 'CODING',
    this.activeSessionId,
    this.sessionStartTime,
    this.todaySessions = const [],
    this.todayStats,
    this.isLoading = false,
    this.errorMessage,
  });

  FocusState copyWith({
    PomodoroStatus? status,
    int? targetMinutes,
    int? remainingSeconds,
    String? category,
    String? activeSessionId,
    DateTime? sessionStartTime,
    List<FocusSessionModel>? todaySessions,
    FocusStatsModel? todayStats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FocusState(
      status: status ?? this.status,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      category: category ?? this.category,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      todaySessions: todaySessions ?? this.todaySessions,
      todayStats: todayStats ?? this.todayStats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  final FocusRepository _repository;
  final Ref _ref;
  Timer? _timer;

  FocusNotifier(this._repository, this._ref) : super(const FocusState()) {
    loadTodayData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadTodayData() async {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
      final sessions = await _repository.getFocusSessions(startDate: startOfToday);
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

  Future<void> startTimer() async {
    if (state.status == PomodoroStatus.running) return;

    if (state.status == PomodoroStatus.idle) {
      try {
        final session = await _repository.startSession(
          category: state.category,
        );
        state = state.copyWith(
          status: PomodoroStatus.running,
          activeSessionId: session.id,
          sessionStartTime: DateTime.now(),
        );
      } catch (e) {
        // Fallback local start if network fails
        state = state.copyWith(
          status: PomodoroStatus.running,
          sessionStartTime: DateTime.now(),
        );
      }
    } else {
      // Resume from paused
      state = state.copyWith(status: PomodoroStatus.running);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
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
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: state.targetMinutes * 60,
      activeSessionId: null,
      sessionStartTime: null,
    );
  }

  Future<void> finishAndSaveSession() async {
    _timer?.cancel();
    final elapsedSeconds = (state.targetMinutes * 60) - state.remainingSeconds;
    final elapsedMinutes = (elapsedSeconds / 60).ceil().clamp(1, 1440);

    if (state.activeSessionId != null) {
      try {
        await _repository.endSession(
          state.activeSessionId!,
          durationMinutes: elapsedMinutes,
        );
      } catch (_) {}
    } else if (state.sessionStartTime != null) {
      try {
        final endTime = DateTime.now();
        await _repository.logCompletedSession(
          startTime: state.sessionStartTime!.toIso8601String(),
          endTime: endTime.toIso8601String(),
          durationMinutes: elapsedMinutes,
          category: state.category,
        );
      } catch (_) {}
    }

    resetTimer();
    await loadTodayData();
    _ref.read(dashboardProvider.notifier).load(showLoading: false);
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
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  final repository = ref.watch(focusRepositoryProvider);
  return FocusNotifier(repository, ref);
});
