import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import 'dashboard_provider.dart';

enum HabitsStatus { initial, loading, loaded, error }

class HabitsState {
  final HabitsStatus status;
  final List<HabitModel> habits;
  final bool filterActiveOnly;
  final String? errorMessage;
  final Map<String, List<HabitLogModel>> habitHistories;

  const HabitsState({
    this.status = HabitsStatus.initial,
    this.habits = const [],
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
    bool? filterActiveOnly,
    String? errorMessage,
    Map<String, List<HabitLogModel>>? habitHistories,
  }) {
    return HabitsState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      filterActiveOnly: filterActiveOnly ?? this.filterActiveOnly,
      errorMessage: errorMessage ?? this.errorMessage,
      habitHistories: habitHistories ?? this.habitHistories,
    );
  }
}

class HabitsNotifier extends StateNotifier<HabitsState> {
  final HabitRepository _repository;
  final Ref _ref;

  HabitsNotifier(this._repository, this._ref) : super(const HabitsState()) {
    loadHabits();
  }

  Future<void> loadHabits({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(status: HabitsStatus.loading);
    }
    try {
      final habits = await _repository.getHabits(includeInactive: true);
      state = state.copyWith(status: HabitsStatus.loaded, habits: habits);
    } catch (e) {
      state = state.copyWith(
        status: HabitsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleFilterActive(bool activeOnly) {
    state = state.copyWith(filterActiveOnly: activeOnly);
  }

  Future<void> toggleHabitCompletion(HabitModel habit) async {
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
      // Reload in background to refresh streak numbers from server calculation
      await loadHabits(showLoading: false);
      // Also silently reload dashboard feed
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      // Rollback on error
      loadHabits(showLoading: false);
    }
  }

  Future<bool> createHabit(Map<String, dynamic> payload) async {
    try {
      await _repository.createHabit(payload);
      await loadHabits(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateHabit(String id, Map<String, dynamic> payload) async {
    try {
      await _repository.updateHabit(id, payload);
      await loadHabits(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
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
      await loadHabits(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<List<HabitLogModel>> fetchHistory(String habitId) async {
    try {
      final logs = await _repository.getHabitHistory(habitId);
      final updatedHistories = Map<String, List<HabitLogModel>>.from(state.habitHistories);
      updatedHistories[habitId] = logs;
      state = state.copyWith(habitHistories: updatedHistories);
      return logs;
    } catch (e) {
      return [];
    }
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitsNotifier(repository, ref);
});
