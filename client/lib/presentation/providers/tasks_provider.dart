import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import 'dashboard_provider.dart';

enum TasksStatus { initial, loading, loaded, error }

class TasksState {
  final TasksStatus status;
  final List<TaskModel> tasks;
  final String currentViewFilter; // 'all', 'today', 'upcoming', 'overdue', 'completed'
  final String? priorityFilter; // null, 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final String searchQuery;
  final String? errorMessage;

  const TasksState({
    this.status = TasksStatus.initial,
    this.tasks = const [],
    this.currentViewFilter = 'all',
    this.priorityFilter,
    this.searchQuery = '',
    this.errorMessage,
  });

  TasksState copyWith({
    TasksStatus? status,
    List<TaskModel>? tasks,
    String? currentViewFilter,
    String? priorityFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      currentViewFilter: currentViewFilter ?? this.currentViewFilter,
      priorityFilter: priorityFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
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
      state = state.copyWith(status: TasksStatus.loading);
    }
    try {
      final tasks = await _repository.getTasks(
        view: state.currentViewFilter,
        priority: state.priorityFilter,
        search: state.searchQuery,
      );
      state = state.copyWith(status: TasksStatus.loaded, tasks: tasks);
    } catch (e) {
      state = state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setViewFilter(String view) {
    state = TasksState(
      status: state.status,
      tasks: state.tasks,
      currentViewFilter: view,
      priorityFilter: state.priorityFilter,
      searchQuery: state.searchQuery,
    );
    loadTasks();
  }

  void setPriorityFilter(String? priority) {
    state = TasksState(
      status: state.status,
      tasks: state.tasks,
      currentViewFilter: state.currentViewFilter,
      priorityFilter: priority,
      searchQuery: state.searchQuery,
    );
    loadTasks();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTasks(showLoading: false);
  }

  Future<void> toggleTaskComplete(TaskModel task) async {
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
    } catch (_) {
      loadTasks(showLoading: false);
    }
  }

  Future<bool> createTask(Map<String, dynamic> payload) async {
    try {
      await _repository.createTask(payload);
      await loadTasks(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
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
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository, ref);
});
