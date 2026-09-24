import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/project_models.dart';

// ==========================================
// DATA PROVIDERS
// ==========================================

final projectsListProvider = FutureProvider.autoDispose<List<ProjectOverviewModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projects);
  final data = response.data['data'];
  List items = [];
  if (data is List) {
    items = data;
  } else if (data is Map && data.containsKey('data')) {
    items = data['data'] as List;
  }
  return items.map((i) => ProjectOverviewModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final techStackInsightsProvider = FutureProvider.autoDispose<List<TechStackInsightModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectTechInsights);
  final data = response.data['data'];
  if (data is Map && data.containsKey('technologies')) {
    final list = data['technologies'] as List;
    return list.map((i) => TechStackInsightModel.fromJson(Map<String, dynamic>.from(i))).toList();
  }
  return [];
});

final projectDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectById(id));
  return Map<String, dynamic>.from(response.data['data']);
});

final projectBoardProvider = FutureProvider.autoDispose.family<KanbanBoardModel, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectBoard(id));
  return KanbanBoardModel.fromJson(Map<String, dynamic>.from(response.data['data']));
});

final projectFeaturesProvider = FutureProvider.autoDispose.family<List<FeatureItemModel>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectFeatures(id));
  final list = response.data['data'] as List? ?? [];
  return list.map((i) => FeatureItemModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final projectBugsProvider = FutureProvider.autoDispose.family<List<BugItemModel>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectBugs(id));
  final list = response.data['data'] as List? ?? [];
  return list.map((i) => BugItemModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final projectAnalyticsProvider = FutureProvider.autoDispose.family<ProjectAnalyticsModel, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectAnalytics(id));
  return ProjectAnalyticsModel.fromJson(Map<String, dynamic>.from(response.data['data']));
});

final projectCommitsProvider = FutureProvider.autoDispose.family<List<CommitItemModel>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.projectCommits(id));
  final data = response.data['data'];
  if (data is Map && data.containsKey('commits')) {
    final list = data['commits'] as List? ?? [];
    return list.map((i) => CommitItemModel.fromJson(Map<String, dynamic>.from(i))).toList();
  }
  return [];
});

// ==========================================
// CONTROLLER (MUTATIONS)
// ==========================================

class ProjectsController {
  final Ref ref;
  ProjectsController(this.ref);

  Future<void> createProject({
    required String title,
    String? description,
    String status = 'IN_PROGRESS',
    String? repoUrl,
    List<String> technologies = const [],
    String color = '#10B981',
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.projects, data: {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'status': status,
      if (repoUrl != null && repoUrl.isNotEmpty) 'repoUrl': repoUrl,
      'technologies': technologies,
      'color': color,
    });
    ref.invalidate(projectsListProvider);
    ref.invalidate(techStackInsightsProvider);
  }

  Future<void> deleteProject(String projectId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.projectById(projectId));
    ref.invalidate(projectsListProvider);
    ref.invalidate(techStackInsightsProvider);
  }

  Future<void> createFeature({
    required String projectId,
    required String name,
    String? description,
    String priority = 'MEDIUM',
    String status = 'TODO',
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.projectFeatures(projectId), data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'priority': priority,
      'status': status,
    });
    invalidateProjectViews(projectId);
  }

  Future<void> updateFeature({
    required String projectId,
    required String featureId,
    required Map<String, dynamic> data,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.patch(ApiEndpoints.projectFeatureById(projectId, featureId), data: data);
    invalidateProjectViews(projectId);
  }

  Future<void> deleteFeature(String projectId, String featureId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.projectFeatureById(projectId, featureId));
    invalidateProjectViews(projectId);
  }

  Future<void> createBug({
    required String projectId,
    required String title,
    required String description,
    String? stepsToReproduce,
    String severity = 'MAJOR',
    String priority = 'MEDIUM',
    String status = 'OPEN',
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.projectBugs(projectId), data: {
      'title': title,
      'description': description,
      if (stepsToReproduce != null && stepsToReproduce.isNotEmpty) 'stepsToReproduce': stepsToReproduce,
      'severity': severity,
      'priority': priority,
      'status': status,
    });
    invalidateProjectViews(projectId);
  }

  Future<void> updateBug({
    required String projectId,
    required String bugId,
    required Map<String, dynamic> data,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.patch(ApiEndpoints.projectBugById(projectId, bugId), data: data);
    invalidateProjectViews(projectId);
  }

  Future<void> deleteBug(String projectId, String bugId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.projectBugById(projectId, bugId));
    invalidateProjectViews(projectId);
  }

  Future<void> moveBoardItem({
    required String projectId,
    required String entityType,
    required String entityId,
    required String targetStatus,
    double? prevOrder,
    double? nextOrder,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.projectBoardMove(projectId), data: {
      'entityType': entityType,
      'entityId': entityId,
      'targetStatus': targetStatus,
      if (prevOrder != null) 'prevOrder': prevOrder,
      if (nextOrder != null) 'nextOrder': nextOrder,
    });
    invalidateProjectViews(projectId);
  }

  void invalidateProjectViews(String projectId) {
    ref.invalidate(projectBoardProvider(projectId));
    ref.invalidate(projectFeaturesProvider(projectId));
    ref.invalidate(projectBugsProvider(projectId));
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectAnalyticsProvider(projectId));
    ref.invalidate(projectsListProvider);
  }
}

final projectsControllerProvider = Provider((ref) => ProjectsController(ref));
