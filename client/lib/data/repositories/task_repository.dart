import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  Future<List<TaskModel>> getTasks({
    String view = 'all',
    String? status,
    String? priority,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'view': view,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await _dio.get(ApiEndpoints.tasks, queryParameters: query);
    final data = response.data['data'];
    List items = [];
    if (data is Map && data.containsKey('data')) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items
        .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  Future<TaskModel> getTaskById(String id) async {
    final response = await _dio.get(ApiEndpoints.taskById(id));
    final data = response.data['data'] ?? response.data;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TaskModel> createTask(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiEndpoints.tasks, data: payload);
    final data = response.data['data'] ?? response.data;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> payload) async {
    final response = await _dio.put(ApiEndpoints.taskById(id), data: payload);
    final data = response.data['data'] ?? response.data;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TaskModel> toggleComplete(String id) async {
    final response = await _dio.patch(ApiEndpoints.taskComplete(id));
    final data = response.data['data'] ?? response.data;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete(ApiEndpoints.taskById(id));
  }

  Future<TaskModel> createSubtask(String parentTaskId, String title) async {
    final response = await _dio.post(
      ApiEndpoints.taskSubtasks(parentTaskId),
      data: {'title': title},
    );
    final data = response.data['data'] ?? response.data;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> addDependency(
      String blockedTaskId, String blockingTaskId) async {
    await _dio.post(
      ApiEndpoints.taskDependencies(blockedTaskId),
      data: {'blockingTaskId': blockingTaskId},
    );
  }

  Future<void> removeDependency(
      String blockedTaskId, String blockingTaskId) async {
    await _dio
        .delete(ApiEndpoints.taskDependency(blockedTaskId, blockingTaskId));
  }

  Future<TaskWorkloadData> getWorkload() async {
    final response = await _dio.get(ApiEndpoints.taskWorkload);
    final data = response.data['data'] ?? response.data;
    return TaskWorkloadData.fromJson(Map<String, dynamic>.from(data));
  }

  /// Fetches 4-quadrant Eisenhower matrix categorization from backend.
  Future<Map<String, dynamic>> getEisenhowerMatrix() async {
    final response = await _dio.get(ApiEndpoints.taskMatrix);
    final data = response.data['data'] ?? response.data;
    return Map<String, dynamic>.from(data);
  }

  /// Reorders a task using fractional ordering.
  Future<void> reorderTask({
    required String taskId,
    double? prevOrder,
    double? nextOrder,
  }) async {
    await _dio.post(
      ApiEndpoints.taskReorder,
      data: {
        'targetTaskId': taskId,
        if (prevOrder != null) 'prevOrder': prevOrder,
        if (nextOrder != null) 'nextOrder': nextOrder,
      },
    );
  }

  /// Fetches tasks using cursor-based pagination.
  Future<PaginatedTasksResponse> getTasksCursor({
    String view = 'all',
    String? status,
    String? priority,
    String? search,
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'view': view,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await _dio.get(ApiEndpoints.tasks, queryParameters: query);
    final data = response.data['data'];

    List items = [];
    String? nextCursor;
    bool hasMore = false;
    int total = 0;

    if (data is Map) {
      if (data['tasks'] is List) {
        items = data['tasks'] as List;
      } else if (data['data'] is List) {
        items = data['data'] as List;
      }

      final pagination = data['pagination'];
      if (pagination is Map) {
        nextCursor = pagination['nextCursor']?.toString();
        hasMore = pagination['hasMore'] == true;
        total = (pagination['total'] as num?)?.toInt() ?? 0;
      }
    } else if (data is List) {
      items = data;
    }

    final tasks = items
        .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();

    return PaginatedTasksResponse(
      tasks: tasks,
      nextCursor: nextCursor,
      hasMore: hasMore,
      total: total,
    );
  }

  /// Synchronizes a specific task to Google Calendar
  Future<void> syncTaskToCalendar(String taskId) async {
    await _dio.post(ApiEndpoints.taskSyncCalendarSingle(taskId));
  }

  /// Triggers two-way sync for all tasks with Google Calendar
  Future<Map<String, dynamic>> syncAllCalendar() async {
    final response = await _dio.post(ApiEndpoints.taskSyncCalendar);
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }
}

class PaginatedTasksResponse {
  final List<TaskModel> tasks;
  final String? nextCursor;
  final bool hasMore;
  final int total;

  const PaginatedTasksResponse({
    required this.tasks,
    this.nextCursor,
    this.hasMore = false,
    this.total = 0,
  });
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TaskRepository(dio);
});
