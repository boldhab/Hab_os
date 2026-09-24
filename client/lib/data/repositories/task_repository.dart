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
    return items.map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i))).toList();
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
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TaskRepository(dio);
});
