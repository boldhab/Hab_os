import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/dashboard_feed_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'auth_provider.dart';

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
  final SecureStorageService _storage;
  final AuthState _authState;

  DashboardNotifier(this._repository, this._storage, this._authState)
      : super(const DashboardState()) {
    if (_authState.status == AuthStatus.authenticated) {
      load();
    }
  }

  Future<void> load({bool showLoading = true}) async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      if (_authState.status == AuthStatus.authenticated) {
        // Small delay in case token write is in-flight on Web IndexedDB
        await Future.delayed(const Duration(milliseconds: 200));
        final retryToken = await _storage.getAccessToken();
        if (retryToken == null || retryToken.isEmpty) {
          state = state.copyWith(
            status: DashboardStatus.error,
            errorMessage:
                'Authentication token not found. Please log in again.',
          );
          return;
        }
      } else {
        // User is not authenticated yet
        state = const DashboardState(status: DashboardStatus.initial);
        return;
      }
    }

    if (showLoading) {
      state = state.copyWith(status: DashboardStatus.loading);
    }
    try {
      final feed = await _repository.getFeed();
      state = state.copyWith(status: DashboardStatus.loaded, feed: feed);
    } catch (e) {
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  final Set<String> _pendingItemIds = {};

  bool isItemPending(String id) => _pendingItemIds.contains(id);

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Optimistically toggle habit completion and refresh feed silently.
  Future<void> logHabit(String habitId) async {
    if (_pendingItemIds.contains(habitId)) return;
    _pendingItemIds.add(habitId);

    // 1. Optimistic UI update
    final current = state.feed;
    if (current == null) {
      _pendingItemIds.remove(habitId);
      return;
    }

    final habitIndex = current.habits.items.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) {
      _pendingItemIds.remove(habitId);
      return;
    }

    final targetHabit = current.habits.items[habitIndex];
    final newCompletedState = !targetHabit.isCompletedToday;

    final updatedItems = current.habits.items.map((h) {
      if (h.id == habitId) return h.copyWith(isCompletedToday: newCompletedState);
      return h;
    }).toList();

    final completedCount = updatedItems.where((h) => h.isCompletedToday).length;

    final updatedHabits = DashboardHabitsSection(
      total: current.habits.total,
      completedToday: completedCount,
      items: updatedItems,
    );

    state = state.copyWith(
      feed: current.copyWith(habits: updatedHabits),
    );

    // 2. Fire API call
    try {
      final value = targetHabit.targetType == 'CHECKBOX'
          ? (newCompletedState ? 1 : 0)
          : (newCompletedState ? targetHabit.targetValue : 0);
      await _repository.logHabit(
        habitId,
        isCompleted: newCompletedState,
        value: value,
      );
      await load(showLoading: false); // refresh streak count etc.
    } catch (e) {
      // Revert optimistic update on failure with visible error message
      state = state.copyWith(
        feed: current,
        errorMessage: 'Failed to update habit: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      _pendingItemIds.remove(habitId);
    }
  }

  /// Optimistically toggle task completion.
  Future<void> toggleTask(String taskId, bool currentValue) async {
    if (_pendingItemIds.contains(taskId)) return;
    _pendingItemIds.add(taskId);

    final current = state.feed;
    if (current == null) {
      _pendingItemIds.remove(taskId);
      return;
    }

    final newValue = !currentValue;
    final updatedTasks = current.tasksDueToday.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: newValue);
      }
      return t;
    }).toList();

    state = state.copyWith(
      feed: current.copyWith(tasksDueToday: updatedTasks),
    );

    try {
      await _repository.toggleTask(taskId, newValue);
      await load(showLoading: false);
    } catch (e) {
      state = state.copyWith(
        feed: current,
        errorMessage: 'Failed to update task: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      _pendingItemIds.remove(taskId);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  final authState = ref.watch(authProvider);
  return DashboardNotifier(repo, storage, authState);
});
