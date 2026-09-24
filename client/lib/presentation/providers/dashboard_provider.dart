import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_feed_model.dart';
import '../../data/repositories/dashboard_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardStatus status;
  final DashboardFeedModel? feed;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.feed,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardFeedModel? feed,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const DashboardState()) {
    load();
  }

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(status: DashboardStatus.loading);
    }
    try {
      final feed = await _repository.getFeed();
      state = state.copyWith(status: DashboardStatus.loaded, feed: feed);
    } catch (e) {
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Optimistically toggle habit completion and refresh feed silently.
  Future<void> logHabit(String habitId) async {
    // 1. Optimistic UI update
    final current = state.feed;
    if (current == null) return;

    final updatedItems = current.habits.items.map((h) {
      if (h.id == habitId) return h.copyWith(isCompletedToday: true);
      return h;
    }).toList();

    final completedCount =
        updatedItems.where((h) => h.isCompletedToday).length;

    final updatedHabits = DashboardHabitsSection(
      total: current.habits.total,
      completedToday: completedCount,
      items: updatedItems,
    );

    state = state.copyWith(
      feed: DashboardFeedModel(
        userName: current.userName,
        userAvatarUrl: current.userAvatarUrl,
        lifeScore: current.lifeScore,
        habits: updatedHabits,
        tasksDueToday: current.tasksDueToday,
        fitness: current.fitness,
        finance: current.finance,
        aiRecommendation: current.aiRecommendation,
        generatedAt: current.generatedAt,
      ),
    );

    // 2. Fire API call (no await — fire & forget; silent refresh on success)
    try {
      await _repository.logHabit(habitId);
      await load(showLoading: false); // refresh streak count etc.
    } catch (_) {
      // Revert optimistic update on failure
      state = state.copyWith(feed: current);
    }
  }

  /// Optimistically toggle task completion.
  Future<void> toggleTask(String taskId, bool currentValue) async {
    final current = state.feed;
    if (current == null) return;

    final newValue = !currentValue;
    final updatedTasks = current.tasksDueToday.map((t) {
      if (t.id == taskId) {
        return DashboardTaskItem(
          id: t.id,
          title: t.title,
          priority: t.priority,
          status: t.status,
          isCompleted: newValue,
          dueDate: t.dueDate,
        );
      }
      return t;
    }).toList();

    state = state.copyWith(
      feed: DashboardFeedModel(
        userName: current.userName,
        userAvatarUrl: current.userAvatarUrl,
        lifeScore: current.lifeScore,
        habits: current.habits,
        tasksDueToday: updatedTasks,
        fitness: current.fitness,
        finance: current.finance,
        aiRecommendation: current.aiRecommendation,
        generatedAt: current.generatedAt,
      ),
    );

    try {
      await _repository.toggleTask(taskId, newValue);
      await load(showLoading: false);
    } catch (_) {
      state = state.copyWith(feed: current);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repo);
});
