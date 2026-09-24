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
    return items.map((i) => HabitModel.fromJson(Map<String, dynamic>.from(i))).toList();
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

  Future<HabitModel> updateHabit(String id, Map<String, dynamic> payload) async {
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
    if (data is List) {
      return data.map((i) => HabitLogModel.fromJson(Map<String, dynamic>.from(i))).toList();
    }
    return [];
  }
}

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HabitRepository(dio);
});
