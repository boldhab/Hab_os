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

  /// Optimistically toggle habit completion and refresh feed silently.
  Future<void> logHabit(String habitId) async {
    // 1. Optimistic UI update
    final current = state.feed;
    if (current == null) return;

    final updatedItems = current.habits.items.map((h) {
      if (h.id == habitId) return h.copyWith(isCompletedToday: true);
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
  final storage = ref.watch(secureStorageProvider);
  final authState = ref.watch(authProvider);
  return DashboardNotifier(repo, storage, authState);
});
