import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/focus_session_model.dart';

class FocusRepository {
  final Dio _dio;

  FocusRepository(this._dio);

  Future<FocusSessionModel> startSession({
    String category = 'CODING',
    String? taskId,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.focusStart,
      data: {
        'category': category,
        if (taskId != null) 'taskId': taskId,
        if (notes != null) 'notes': notes,
      },
    );
    final data = response.data['data'] ?? response.data;
    return FocusSessionModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FocusSessionModel> endSession(
    String id, {
    required int durationMinutes,
    String? notes,
    String? taskId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.focusEnd(id),
      data: {
        'durationMinutes': durationMinutes,
        if (notes != null) 'notes': notes,
        if (taskId != null) 'taskId': taskId,
      },
    );
    final data = response.data['data'] ?? response.data;
    return FocusSessionModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FocusSessionModel> logCompletedSession({
    required String startTime,
    required String endTime,
    required int durationMinutes,
    String category = 'CODING',
    String? taskId,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.focusLog,
      data: {
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'category': category,
        if (taskId != null) 'taskId': taskId,
        if (notes != null) 'notes': notes,
      },
    );
    final data = response.data['data'] ?? response.data;
    return FocusSessionModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<FocusSessionModel>> getFocusSessions({
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final response = await _dio.get(ApiEndpoints.focus, queryParameters: query);
    final data = response.data['data'];
    List items = [];
    if (data is Map && data.containsKey('data')) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items.map((i) => FocusSessionModel.fromJson(Map<String, dynamic>.from(i))).toList();
  }

  Future<FocusStatsModel> getFocusStats() async {
    final response = await _dio.get(ApiEndpoints.focusStats);
    final data = response.data['data'] ?? response.data;
    return FocusStatsModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteSession(String id) async {
    await _dio.delete(ApiEndpoints.focusById(id));
  }
}

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FocusRepository(dio);
});
