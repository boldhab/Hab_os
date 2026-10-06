import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import 'dashboard_provider.dart';

enum TasksStatus { initial, loading, loaded, error }

/// Sentinel used by [TasksState.copyWith] to distinguish "not provided"
/// from an explicit `null` on nullable fields.
const _sentinel = Object();

class TasksState {
  final TasksStatus status;
  final List<TaskModel> tasks;
  final String
      currentViewFilter; // 'all', 'today', 'upcoming', 'overdue', 'completed'
  final String? priorityFilter; // null, 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final String searchQuery;
  final String? errorMessage;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  const TasksState({
    this.status = TasksStatus.initial,
    this.tasks = const [],
    this.currentViewFilter = 'all',
    this.priorityFilter,
    this.searchQuery = '',
    this.errorMessage,
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// Nullable fields ([priorityFilter], [errorMessage], [nextCursor]) use a
  /// sentinel so callers can explicitly pass `null` to clear them, while
  /// omitting the argument preserves the current value.
  TasksState copyWith({
    TasksStatus? status,
    List<TaskModel>? tasks,
    String? currentViewFilter,
    Object? priorityFilter = _sentinel,
    String? searchQuery,
    Object? errorMessage = _sentinel,
    Object? nextCursor = _sentinel,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      currentViewFilter: currentViewFilter ?? this.currentViewFilter,
      priorityFilter: identical(priorityFilter, _sentinel)
          ? this.priorityFilter
          : priorityFilter as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      nextCursor: identical(nextCursor, _sentinel)
          ? this.nextCursor
          : nextCursor as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final TaskRepository _repository;
  final Ref _ref;

  TasksNotifier(this._repository, this._ref) : super(const TasksState()) {
    loadTasks();
  }

  Future<void> loadTasks({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(
        status: TasksStatus.loading,
        nextCursor: null,
        hasMore: false,
      );
    }
    try {
      final res = await _repository.getTasksCursor(
        view: state.currentViewFilter,
        priority: state.priorityFilter,
        search: state.searchQuery,
      );
      state = state.copyWith(
        status: TasksStatus.loaded,
        tasks: res.tasks,
        nextCursor: res.nextCursor,
        hasMore: res.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
        isLoadingMore: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _repository.getTasksCursor(
        view: state.currentViewFilter,
        priority: state.priorityFilter,
        search: state.searchQuery,
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        tasks: [...state.tasks, ...res.tasks],
        nextCursor: res.nextCursor,
        hasMore: res.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setViewFilter(String view) {
    state = state.copyWith(
      currentViewFilter: view,
      nextCursor: null,
      hasMore: false,
    );
    loadTasks();
  }

  void setPriorityFilter(String? priority) {
    state = state.copyWith(
      priorityFilter: priority,
      nextCursor: null,
      hasMore: false,
    );
    loadTasks();
  }

  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      loadTasks(showLoading: false);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<String?> toggleTaskComplete(TaskModel task) async {
    final newCompletedState = !task.isCompleted;

    // Optimistic UI update
    final updatedTasks = state.tasks.map((t) {
      if (t.id == task.id) {
        return t.copyWith(
          isCompleted: newCompletedState,
          status: newCompletedState ? 'COMPLETED' : 'TODO',
        );
      }
      return t;
    }).toList();

    state = state.copyWith(tasks: updatedTasks);

    try {
      await _repository.toggleComplete(task.id);
      await loadTasks(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      _ref.invalidate(tasksWorkloadProvider);
      _ref.invalidate(tasksMatrixProvider);
      return null;
    } catch (e) {
      await loadTasks(showLoading: false);
      final errorMsg = e is DioException && e.response?.data != null
          ? (e.response!.data['message']?.toString() ??
              e.message ??
              'Failed to update status')
          : e.toString();
      state = state.copyWith(errorMessage: errorMsg);
      return errorMsg;
    }
  }

  Future<bool> createTask(Map<String, dynamic> payload) async {
    try {
      await _repository.createTask(payload);
      await loadTasks(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      _ref.invalidate(tasksWorkloadProvider);
      _ref.invalidate(tasksMatrixProvider);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTask(String id, Map<String, dynamic> payload) async {
    try {
      await _repository.updateTask(id, payload);
      await loadTasks(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      _ref.invalidate(tasksWorkloadProvider);
      _ref.invalidate(tasksMatrixProvider);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      await loadTasks(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      _ref.invalidate(tasksWorkloadProvider);
      _ref.invalidate(tasksMatrixProvider);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Optimistically reorders a task and syncs the fractional order with backend.
  Future<void> reorderTask(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= state.tasks.length ||
        newIndex < 0 ||
        newIndex > state.tasks.length ||
        oldIndex == newIndex) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final currentTasks = List<TaskModel>.from(state.tasks);
    final movedTask = currentTasks.removeAt(oldIndex);
    currentTasks.insert(newIndex, movedTask);

    double? prevOrder;
    double? nextOrder;

    if (newIndex > 0) {
      prevOrder = currentTasks[newIndex - 1].order;
    }
    if (newIndex < currentTasks.length - 1) {
      nextOrder = currentTasks[newIndex + 1].order;
    }

    double updatedOrder;
    if (prevOrder != null && nextOrder != null) {
      updatedOrder = (prevOrder + nextOrder) / 2.0;
    } else if (prevOrder != null) {
      updatedOrder = prevOrder + 1.0;
    } else if (nextOrder != null) {
      updatedOrder = nextOrder / 2.0;
    } else {
      updatedOrder = 1.0;
    }

    final updatedMovedTask = movedTask.copyWith(order: updatedOrder);
    currentTasks[newIndex] = updatedMovedTask;

    // Optimistic UI state update
    state = state.copyWith(tasks: currentTasks);

    try {
      await _repository.reorderTask(
        taskId: movedTask.id,
        prevOrder: prevOrder,
        nextOrder: nextOrder,
      );
    } catch (e) {
      await loadTasks(showLoading: false);
      state = state.copyWith(
        errorMessage: 'Failed to reorder task: ${e.toString()}',
      );
    }
  }

  /// Triggers full two-way synchronization with Google Calendar
  Future<bool> syncCalendar() async {
    try {
      await _repository.syncAllCalendar();
      await loadTasks(showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to sync calendar: ${e.toString()}');
      return false;
    }
  }

  /// Synchronizes a specific task to Google Calendar
  Future<bool> syncTaskToCalendar(String taskId) async {
    try {
      await _repository.syncTaskToCalendar(taskId);
      await loadTasks(showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to sync task to calendar: ${e.toString()}');
      return false;
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository, ref);
});

final tasksWorkloadProvider =
    FutureProvider.autoDispose<TaskWorkloadData>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getWorkload();
});

/// Grouped tasks by status — replaces inline grouping in TasksTab build().
/// Returns a Map<String, List<TaskModel>> with keys: 'TODO', 'IN_PROGRESS', 'BLOCKED', 'COMPLETED'
final groupedTasksByStatusProvider = Provider.autoDispose<Map<String, List<TaskModel>>>((ref) {
  final state = ref.watch(tasksProvider);
  final tasks = state.tasks;
  return {
    'TODO': tasks.where((t) => !t.isCompleted && t.status == 'TODO').toList(),
    'IN_PROGRESS': tasks.where((t) => !t.isCompleted && t.status == 'IN_PROGRESS').toList(),
    'BLOCKED': tasks.where((t) => !t.isCompleted && t.status == 'BLOCKED').toList(),
    'COMPLETED': tasks.where((t) => t.isCompleted).toList(),
  };
});

/// Filtered active (non-completed) tasks for Eisenhower matrix.
final activeTasksProvider = Provider.autoDispose<List<TaskModel>>((ref) {
  final state = ref.watch(tasksProvider);
  return state.tasks.where((t) => !t.isCompleted).toList();
});

class EisenhowerQuadrants {
  final List<TaskModel> q1;
  final List<TaskModel> q2;
  final List<TaskModel> q3;
  final List<TaskModel> q4;

  const EisenhowerQuadrants({
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
  });
}

/// Dynamic quadrant computation for Eisenhower Matrix view
final eisenhowerMatrixProvider =
    Provider.autoDispose<EisenhowerQuadrants>((ref) {
  final state = ref.watch(tasksProvider);
  final now = DateTime.now();
  final urgentCutoff = now.add(const Duration(hours: 48));

  bool isUrgent(TaskModel t) {
    if (t.dueDate == null) return false;
    final d = DateTime.tryParse(t.dueDate!);
    return d != null && d.isBefore(urgentCutoff);
  }

  bool isImportant(TaskModel t) {
    final p = t.priority.toUpperCase();
    return p == 'HIGH' || p == 'CRITICAL';
  }

  final activeTasks = state.tasks.where((t) => !t.isCompleted).toList();
  return EisenhowerQuadrants(
    q1: activeTasks.where((t) => isImportant(t) && isUrgent(t)).toList(),
    q2: activeTasks.where((t) => isImportant(t) && !isUrgent(t)).toList(),
    q3: activeTasks.where((t) => !isImportant(t) && isUrgent(t)).toList(),
    q4: activeTasks.where((t) => !isImportant(t) && !isUrgent(t)).toList(),
  );
});

/// Server-side Eisenhower Matrix data provider covering full user dataset
final tasksMatrixProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getEisenhowerMatrix();
});



