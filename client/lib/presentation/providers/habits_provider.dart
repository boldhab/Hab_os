import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../infrastructure/services/notification_service.dart';
import 'dashboard_provider.dart';

enum HabitsStatus { initial, loading, loaded, error }

class HabitsState {
  final HabitsStatus status;
  final List<HabitModel> habits;
  final List<RoutineModel> routines;
  final List<HabitCorrelationModel> correlations;
  final List<HabitCategoryModel> categories;
  final bool filterActiveOnly;
  final String? errorMessage;
  final Map<String, List<HabitLogModel>> habitHistories;

  const HabitsState({
    this.status = HabitsStatus.initial,
    this.habits = const [],
    this.routines = const [],
    this.correlations = const [],
    this.categories = const [],
    this.filterActiveOnly = true,
    this.errorMessage,
    this.habitHistories = const {},
  });

  List<HabitModel> get filteredHabits {
    if (filterActiveOnly) {
      return habits.where((h) => h.isActive).toList();
    }
    return habits;
  }

  HabitsState copyWith({
    HabitsStatus? status,
    List<HabitModel>? habits,
    List<RoutineModel>? routines,
    List<HabitCorrelationModel>? correlations,
    List<HabitCategoryModel>? categories,
    bool? filterActiveOnly,
    String? errorMessage,
    Map<String, List<HabitLogModel>>? habitHistories,
  }) {
    return HabitsState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      routines: routines ?? this.routines,
      correlations: correlations ?? this.correlations,
      categories: categories ?? this.categories,
      filterActiveOnly: filterActiveOnly ?? this.filterActiveOnly,
      errorMessage: errorMessage ?? this.errorMessage,
      habitHistories: habitHistories ?? this.habitHistories,
    );
  }
}

class HabitsNotifier extends StateNotifier<HabitsState> {
  final HabitRepository _repository;
  final Ref _ref;

  final Map<String, Timer> _debounceTimers = {};
  final Map<String, List<HabitModel>> _rollbackSnapshots = {};

  HabitsNotifier(this._repository, this._ref) : super(const HabitsState()) {
    loadHabits();
    loadRoutines();
    loadCorrelations();
    loadCategories();
  }

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _rollbackSnapshots.clear();
    super.dispose();
  }

  Future<void> loadHabits({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(status: HabitsStatus.loading);
    }
    try {
      final habits = await _repository.getHabits(includeInactive: true);
      state = state.copyWith(status: HabitsStatus.loaded, habits: habits);
      _ref.read(notificationServiceProvider).syncHabitReminders(habits);
    } catch (e) {
      state = state.copyWith(
        status: HabitsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadRoutines() async {
    try {
      final routines = await _repository.getRoutines();
      state = state.copyWith(routines: routines);
    } catch (_) {}
  }

  Future<void> loadCorrelations() async {
    try {
      final correlations = await _repository.getHabitCorrelations();
      state = state.copyWith(correlations: correlations);
    } catch (_) {}
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(categories: categories);
    } catch (_) {}
  }

  void toggleFilterActive(bool activeOnly) {
    state = state.copyWith(filterActiveOnly: activeOnly);
  }

  void incrementHabitProgress(HabitModel habit, int delta) {
    // 1. Capture snapshot at the beginning of a rapid tapping sequence
    _rollbackSnapshots.putIfAbsent(habit.id, () => state.habits);

    final currentHabit =
        state.habits.where((h) => h.id == habit.id).firstOrNull ?? habit;
    final current = currentHabit.currentTodayValue;
    final newVal = (current + delta).clamp(0, 999999);
    final isDone = newVal >= habit.targetValue;

    // 2. Instant local optimistic update for 60fps responsiveness
    final updatedList = state.habits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(
          isCompletedToday: isDone,
          todayLog: HabitLogModel(
            id: h.todayLog?.id ?? 'temp',
            habitId: h.id,
            date: DateTime.now().toIso8601String(),
            isCompleted: isDone,
            value: newVal,
          ),
        );
      }
      return h;
    }).toList();

    state = state.copyWith(habits: updatedList);

    // 3. Debounce network execution to prevent race conditions & out-of-order writes
    _debounceTimers[habit.id]?.cancel();
    _debounceTimers[habit.id] = Timer(const Duration(milliseconds: 350), () async {
      try {
        await _repository.logHabit(
          habit.id,
          value: newVal,
          isCompleted: isDone,
        );
        _rollbackSnapshots.remove(habit.id);
        await loadHabits(showLoading: false);
        await loadRoutines();
        _ref.read(dashboardProvider.notifier).load(showLoading: false);
      } catch (e) {
        // Roll back to the original snapshot before rapid taps started
        final snapshot = _rollbackSnapshots.remove(habit.id);
        if (snapshot != null) {
          state = state.copyWith(
            habits: snapshot,
            errorMessage: 'Sync failed. Progress restored.',
          );
        }
      }
    });
  }

  Future<void> logHabitProgress(HabitModel habit, int value) async {
    _debounceTimers[habit.id]?.cancel();
    final snapshot = state.habits;
    final isDone = value >= habit.targetValue;

    // Optimistic state update
    final updatedList = state.habits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(
          isCompletedToday: isDone,
          todayLog: HabitLogModel(
            id: h.todayLog?.id ?? 'temp',
            habitId: h.id,
            date: DateTime.now().toIso8601String(),
            isCompleted: isDone,
            value: value,
          ),
        );
      }
      return h;
    }).toList();

    state = state.copyWith(habits: updatedList);

    try {
      await _repository.logHabit(
        habit.id,
        value: value,
        isCompleted: isDone,
      );
      _rollbackSnapshots.remove(habit.id);
      await loadHabits(showLoading: false);
      await loadRoutines();
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(
        habits: snapshot,
        errorMessage: 'Failed to update progress.',
      );
    }
  }

  Future<void> toggleHabitCompletion(HabitModel habit) async {
    _debounceTimers[habit.id]?.cancel();
    final snapshot = state.habits;
    final newCompletedState = !habit.isCompletedToday;

    // Optimistic state update
    final updatedList = state.habits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(isCompletedToday: newCompletedState);
      }
      return h;
    }).toList();

    state = state.copyWith(habits: updatedList);

    try {
      await _repository.logHabit(
        habit.id,
        isCompleted: newCompletedState,
      );
      await loadHabits(showLoading: false);
      await loadRoutines();
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(
        habits: snapshot,
        errorMessage: 'Failed to update habit status.',
      );
    }
  }

  Future<bool> createHabit(Map<String, dynamic> payload) async {
    try {
      final created = await _repository.createHabit(payload);
      await loadHabits(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      if (created.reminderTime != null && created.reminderTime!.isNotEmpty) {
        _ref.read(notificationServiceProvider).scheduleHabitReminder(created);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateHabit(String id, Map<String, dynamic> payload) async {
    try {
      final updated = await _repository.updateHabit(id, payload);
      await loadHabits(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      if (updated.isActive &&
          updated.reminderTime != null &&
          updated.reminderTime!.isNotEmpty) {
        _ref.read(notificationServiceProvider).scheduleHabitReminder(updated);
      } else {
        _ref.read(notificationServiceProvider).cancelHabitReminder(id);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> toggleArchive(HabitModel habit) async {
    await updateHabit(habit.id, {'isActive': !habit.isActive});
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _repository.deleteHabit(id);
      _ref.read(notificationServiceProvider).cancelHabitReminder(id);
      await loadHabits(showLoading: false);
      await loadRoutines();
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<List<HabitLogModel>> fetchHistory(String habitId) async {
    try {
      final logs = await _repository.getHabitHistory(habitId);
      final updatedHistories =
          Map<String, List<HabitLogModel>>.from(state.habitHistories);
      updatedHistories[habitId] = logs;
      state = state.copyWith(habitHistories: updatedHistories);
      return logs;
    } catch (e) {
      return [];
    }
  }

  Future<void> refillStreakFreeze(String habitId, {int count = 1}) async {
    try {
      await _repository.refillStreakFreeze(habitId, count: count);
      await loadHabits(showLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // --- Routines ---
  Future<bool> createRoutine(Map<String, dynamic> payload) async {
    try {
      await _repository.createRoutine(payload);
      await loadRoutines();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateRoutine(String id, Map<String, dynamic> payload) async {
    try {
      await _repository.updateRoutine(id, payload);
      await loadRoutines();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      await _repository.deleteRoutine(id);
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> completeRoutine(String id) async {
    try {
      await _repository.completeRoutine(id);
      await loadHabits(showLoading: false);
      await loadRoutines();
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitsNotifier(repository, ref);
});
