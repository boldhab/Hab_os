import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/gym_models.dart';

// ==========================================
// DATA PROVIDERS
// ==========================================

final gymWorkoutsProvider = FutureProvider.autoDispose<List<WorkoutDetailModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymWorkouts);
  final data = response.data['data'];
  List items = [];
  if (data is List) {
    items = data;
  } else if (data is Map && data.containsKey('data')) {
    items = data['data'] as List;
  }
  return items.map((i) => WorkoutDetailModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final gymExercisesProvider = FutureProvider.autoDispose<List<ExerciseCatalogModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymExercises);
  final list = response.data['data'] as List? ?? [];
  return list.map((i) => ExerciseCatalogModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final gymExerciseHistoryProvider =
    FutureProvider.autoDispose.family<ExerciseHistoryModel, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymExerciseHistory(id));
  return ExerciseHistoryModel.fromJson(Map<String, dynamic>.from(response.data['data']));
});

final gymPRsProvider = FutureProvider.autoDispose<List<PersonalRecordModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymPRs);
  final data = response.data['data'];
  if (data is Map && data.containsKey('personalRecords')) {
    final list = data['personalRecords'] as List;
    return list.map((i) => PersonalRecordModel.fromJson(Map<String, dynamic>.from(i))).toList();
  }
  return [];
});

final gymStatsProvider = FutureProvider.autoDispose<GymStatsModel>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymStats);
  return GymStatsModel.fromJson(Map<String, dynamic>.from(response.data['data']));
});

final gymTemplatesProvider = FutureProvider.autoDispose<List<WorkoutTemplateModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymTemplates);
  final list = response.data['data'] as List? ?? [];
  return list.map((i) => WorkoutTemplateModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final gymBodyMetricsProvider = FutureProvider.autoDispose<List<BodyMetricModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymBodyMetrics);
  final list = response.data['data'] as List? ?? [];
  return list.map((i) => BodyMetricModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final gymInsightsProvider = FutureProvider.autoDispose<List<GymInsightModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.gymInsights);
  final data = response.data['data'];
  if (data is Map && data.containsKey('insights')) {
    final list = data['insights'] as List;
    return list.map((i) => GymInsightModel.fromJson(Map<String, dynamic>.from(i))).toList();
  }
  return [];
});

// ==========================================
// CONTROLLER (MUTATIONS)
// ==========================================

class GymController {
  final Ref ref;
  GymController(this.ref);

  Future<Map<String, dynamic>> logWorkout({
    required String name,
    String? notes,
    int durationMinutes = 60,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final dio = ref.read(dioProvider);
    final res = await dio.post(ApiEndpoints.gymWorkouts, data: {
      'name': name,
      'date': DateTime.now().toIso8601String(),
      'durationMinutes': durationMinutes,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'exercises': exercises,
    });
    invalidateGymData();
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<void> deleteWorkout(String workoutId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.gymWorkoutById(workoutId));
    invalidateGymData();
  }

  Future<void> createExercise({
    required String name,
    String category = 'CHEST',
    String muscleGroup = 'CHEST',
    String equipmentType = 'BARBELL',
    String? notes,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.gymExercises, data: {
      'name': name,
      'category': category,
      'muscleGroup': muscleGroup,
      'equipmentType': equipmentType,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    ref.invalidate(gymExercisesProvider);
  }

  Future<void> createTemplate({
    required String name,
    String? description,
    String category = 'PPL',
    required List<Map<String, dynamic>> exercises,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.gymTemplates, data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'category': category,
      'exercises': exercises,
    });
    ref.invalidate(gymTemplatesProvider);
  }

  Future<void> deleteTemplate(String templateId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.gymTemplateById(templateId));
    ref.invalidate(gymTemplatesProvider);
  }

  Future<void> logBodyMetric({
    required double weightKg,
    double? bodyFatPercent,
    double? chestCm,
    double? waistCm,
    double? armsCm,
    double? legsCm,
    String? notes,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.gymBodyMetrics, data: {
      'date': DateTime.now().toIso8601String(),
      'weightKg': weightKg,
      if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
      if (chestCm != null) 'chestCm': chestCm,
      if (waistCm != null) 'waistCm': waistCm,
      if (armsCm != null) 'armsCm': armsCm,
      if (legsCm != null) 'legsCm': legsCm,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    ref.invalidate(gymBodyMetricsProvider);
  }

  Future<void> deleteBodyMetric(String metricId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.gymBodyMetricById(metricId));
    ref.invalidate(gymBodyMetricsProvider);
  }

  void invalidateGymData() {
    ref.invalidate(gymWorkoutsProvider);
    ref.invalidate(gymPRsProvider);
    ref.invalidate(gymStatsProvider);
    ref.invalidate(gymInsightsProvider);
  }
}

final gymControllerProvider = Provider((ref) => GymController(ref));
