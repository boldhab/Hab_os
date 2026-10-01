import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/dashboard_feed_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardFeedModel> getFeed() async {
    final response = await _dio.get(ApiEndpoints.dashboardFeed);
    dynamic raw = response.data;
    if (raw is String) {
      raw = jsonDecode(raw);
    }
    final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
    if (data is! Map) {
      throw Exception('Invalid response format received from dashboard API');
    }
    return DashboardFeedModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> logHabit(String habitId) async {
    await _dio.post(ApiEndpoints.habitLog(habitId));
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    await _dio.patch(
      ApiEndpoints.taskById(taskId),
      data: {'isCompleted': isCompleted},
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio);
});
