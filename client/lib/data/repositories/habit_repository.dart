import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/habit_model.dart';

class HabitRepository {
  final Dio _dio;

  HabitRepository(this._dio);

  Future<List<HabitModel>> getHabits({bool includeInactive = true}) async {
    final response = await _dio.get(
      ApiEndpoints.habits,
      queryParameters: {
        'includeInactive': includeInactive,
      },
    );
    final data = response.data['data'];
    List items = [];
    if (data is Map && data.containsKey('data')) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items
        .map((i) => HabitModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  Future<HabitModel> getHabitById(String id) async {
    final response = await _dio.get(ApiEndpoints.habitById(id));
    final data = response.data['data'] ?? response.data;
    return HabitModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<HabitModel> createHabit(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiEndpoints.habits, data: payload);
    final data = response.data['data'] ?? response.data;
    return HabitModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<HabitModel> updateHabit(
      String id, Map<String, dynamic> payload) async {
    final response = await _dio.put(ApiEndpoints.habitById(id), data: payload);
    final data = response.data['data'] ?? response.data;
    return HabitModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteHabit(String id) async {
    await _dio.delete(ApiEndpoints.habitById(id));
  }

  Future<void> logHabit(
    String id, {
    String? date,
    bool isCompleted = true,
    int value = 1,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      if (date != null) 'date': date,
      'isCompleted': isCompleted,
      'value': value,
      if (notes != null) 'notes': notes,
    };
    await _dio.post(ApiEndpoints.habitLog(id), data: payload);
  }

  Future<List<HabitLogModel>> getHabitHistory(String id) async {
    final response = await _dio.get(ApiEndpoints.habitHistory(id));
    final data = response.data['data'] ?? response.data;
    if (data is Map && data.containsKey('logs')) {
      final logsList = data['logs'] as List;
      return logsList
          .map((i) => HabitLogModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else if (data is List) {
      return data
          .map((i) => HabitLogModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return [];
  }

  Future<void> refillStreakFreeze(String id, {int count = 1}) async {
    await _dio.post(ApiEndpoints.habitFreeze(id), data: {'count': count});
  }

  // --- Categories ---
  Future<List<HabitCategoryModel>> getCategories() async {
    final response = await _dio.get('${ApiEndpoints.habits}/categories');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((i) => HabitCategoryModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return [];
  }

  // --- Routines ---
  Future<List<RoutineModel>> getRoutines() async {
    final response = await _dio.get(ApiEndpoints.habitRoutines);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((i) => RoutineModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return [];
  }

  Future<RoutineModel> createRoutine(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiEndpoints.habitRoutines, data: payload);
    final data = response.data['data'] ?? response.data;
    return RoutineModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<RoutineModel> updateRoutine(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _dio.put(ApiEndpoints.habitRoutineById(id), data: payload);
    final data = response.data['data'] ?? response.data;
    return RoutineModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteRoutine(String id) async {
    await _dio.delete(ApiEndpoints.habitRoutineById(id));
  }

  Future<void> completeRoutine(String id, {String? date}) async {
    await _dio.post(ApiEndpoints.habitRoutineComplete(id), data: {
      if (date != null) 'date': date,
    });
  }

  // --- Behavioral Correlations ---
  Future<List<HabitCorrelationModel>> getHabitCorrelations() async {
    final response = await _dio.get(ApiEndpoints.habitCorrelations);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((i) =>
              HabitCorrelationModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return [];
  }
}

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HabitRepository(dio);
});
