import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final Dio _dio;

  GoalRepository(this._dio);

  Future<List<GoalModel>> getGoals({String? category}) async {
    final query = <String, dynamic>{
      if (category != null && category.isNotEmpty && category != 'ALL')
        'category': category,
    };
    final response = await _dio.get(ApiEndpoints.goals, queryParameters: query);
    final data = response.data['data'];
    List items = [];
    if (data is Map && data.containsKey('data')) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items.map((i) => GoalModel.fromJson(Map<String, dynamic>.from(i))).toList();
  }

  Future<GoalModel> getGoalById(String id) async {
    final response = await _dio.get(ApiEndpoints.goalById(id));
    final data = response.data['data'] ?? response.data;
    return GoalModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<GoalTreeModel> getGoalTree(String id) async {
    final response = await _dio.get(ApiEndpoints.goalTree(id));
    final data = response.data['data'] ?? response.data;
    return GoalTreeModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<GoalsHealthSummary> getGoalsHealth() async {
    final response = await _dio.get(ApiEndpoints.goalsHealth);
    final data = response.data['data'] ?? response.data;
    return GoalsHealthSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<GoalModel> createGoal(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiEndpoints.goals, data: payload);
    final data = response.data['data'] ?? response.data;
    return GoalModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<GoalModel> updateGoal(String id, Map<String, dynamic> payload) async {
    final response = await _dio.put(ApiEndpoints.goalById(id), data: payload);
    final data = response.data['data'] ?? response.data;
    return GoalModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteGoal(String id) async {
    await _dio.delete(ApiEndpoints.goalById(id));
  }

  Future<MilestoneModel> createMilestone(String goalId, Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiEndpoints.goalMilestones(goalId), data: payload);
    final data = response.data['data'] ?? response.data;
    return MilestoneModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<MilestoneModel> updateMilestone(
    String goalId,
    String milestoneId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.goalMilestoneById(goalId, milestoneId),
      data: payload,
    );
    final data = response.data['data'] ?? response.data;
    return MilestoneModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteMilestone(String goalId, String milestoneId) async {
    await _dio.delete(ApiEndpoints.goalMilestoneById(goalId, milestoneId));
  }

  Future<GoalCheckInModel> recordCheckIn(
    String goalId,
    String confidence,
    String? note,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.goalCheckIns(goalId),
      data: {
        'confidence': confidence,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final data = response.data['data'] ?? response.data;
    return GoalCheckInModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<GoalModel> contributeFinancial(String goalId, double amount) async {
    final response = await _dio.post(
      ApiEndpoints.goalContribute(goalId),
      data: {'amount': amount},
    );
    final data = response.data['data'] ?? response.data;
    return GoalModel.fromJson(Map<String, dynamic>.from(data));
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GoalRepository(dio);
});
