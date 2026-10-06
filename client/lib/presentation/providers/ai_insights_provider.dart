import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/ai_insights_model.dart';

/// Fetches identified neglected areas across all life domains (UC-142)
final neglectedAreasProvider =
    FutureProvider.autoDispose<List<NeglectedArea>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(ApiEndpoints.aiNeglectedAreas);
    final payload = response.data['data'] ?? response.data;
    final listRaw = payload['neglectedAreas'] ?? payload;

    if (listRaw is List) {
      return listRaw
          .map((item) =>
              NeglectedArea.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Fetches top recommended high-impact tasks (UC-141)
final recommendedTasksProvider =
    FutureProvider.autoDispose<List<RecommendedTask>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(
      ApiEndpoints.aiRecommendTasks,
      queryParameters: {'limit': 5},
    );
    final listRaw = response.data['data'] ?? response.data;

    if (listRaw is List) {
      return listRaw
          .map((item) =>
              RecommendedTask.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Fetches personalized weekly plan (UC-143)
final personalizedPlanProvider =
    FutureProvider.autoDispose<PersonalizedPlan?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(ApiEndpoints.aiPlan);
    final data = response.data['data'] ?? response.data;
    if (data is Map) {
      return PersonalizedPlan.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Master AI Insights provider uniting neglected areas, tasks, and rebalancing plan
final aiInsightsProvider =
    FutureProvider.autoDispose<AiInsightsData>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final results = await Future.wait([
      dio.get(ApiEndpoints.aiNeglectedAreas),
      dio.get(ApiEndpoints.aiRecommendTasks, queryParameters: {'limit': 5}),
      dio.get(ApiEndpoints.aiPlan),
    ]);

    // Parse Neglected Areas
    final negData = results[0].data['data'] ?? results[0].data;
    final negListRaw = negData['neglectedAreas'] ?? negData;
    final List<NeglectedArea> neglectedAreas = [];
    if (negListRaw is List) {
      for (final item in negListRaw) {
        if (item is Map) {
          neglectedAreas
              .add(NeglectedArea.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Parse Recommended Tasks
    final tasksRaw = results[1].data['data'] ?? results[1].data;
    final List<RecommendedTask> recommendedTasks = [];
    if (tasksRaw is List) {
      for (final item in tasksRaw) {
        if (item is Map) {
          recommendedTasks
              .add(RecommendedTask.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Parse Personalized Plan
    final planData = results[2].data['data'] ?? results[2].data;
    PersonalizedPlan? plan;
    if (planData is Map) {
      plan = PersonalizedPlan.fromJson(Map<String, dynamic>.from(planData));
    }

    return AiInsightsData(
      neglectedAreas: neglectedAreas,
      recommendedTasks: recommendedTasks,
      plan: plan,
    );
  } catch (e) {
    // If backend endpoint is unavailable or returns an error, return empty gracefully
    return const AiInsightsData();
  }
});
