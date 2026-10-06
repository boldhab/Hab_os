import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/repositories/project_repository.dart';
import '../models/project_models.dart';

export '../models/project_models.dart' show CommitsResult, PaginatedList;

// ==========================================
// DATA PROVIDERS (Driven via ProjectRepository)
// ==========================================

final projectsListProvider =
    FutureProvider.autoDispose<List<ProjectOverviewModel>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjects();
});

final techStackInsightsProvider =
    FutureProvider.autoDispose<List<TechStackInsightModel>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getTechStackInsights();
});

final projectDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectById(id);
});

final projectBoardProvider = FutureProvider.autoDispose
    .family<KanbanBoardModel, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getBoard(id);
});

final projectFeaturesProvider = FutureProvider.autoDispose
    .family<List<FeatureItemModel>, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  final paginated = await repo.getFeatures(id, page: 1, limit: 100);
  return paginated.items;
});

final projectBugsProvider = FutureProvider.autoDispose
    .family<List<BugItemModel>, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  final paginated = await repo.getBugs(id, page: 1, limit: 100);
  return paginated.items;
});

final projectAnalyticsProvider = FutureProvider.autoDispose
    .family<ProjectAnalyticsModel, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getAnalytics(id);
});

final projectCommitsProvider = FutureProvider.autoDispose
    .family<CommitsResult, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getCommits(id);
});

final projectTasksProvider = FutureProvider.autoDispose
    .family<List<TaskModel>, String>((ref, projectId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    ApiEndpoints.tasks,
    queryParameters: {'projectId': projectId},
  );
  final data = response.data['data'];
  List items = [];
  if (data is List) {
    items = data;
  } else if (data is Map && data.containsKey('data')) {
    items = data['data'] as List;
  }
  return items
      .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
      .toList();
});

final projectTasksGroupedProvider = Provider.autoDispose
    .family<Map<String, List<TaskModel>>, String>((ref, projectId) {
  final tasksAsync = ref.watch(projectTasksProvider(projectId));
  final tasks = tasksAsync.asData?.value ?? const <TaskModel>[];
  return {
    'TODO': tasks.where((t) => !t.isCompleted && t.status == 'TODO').toList(),
    'IN_PROGRESS': tasks.where((t) => !t.isCompleted && t.status == 'IN_PROGRESS').toList(),
    'BLOCKED': tasks.where((t) => !t.isCompleted && t.status == 'BLOCKED').toList(),
    'COMPLETED': tasks.where((t) => t.isCompleted).toList(),
  };
});

// ==========================================
// CONTROLLER (MUTATIONS & FACADE)
// ==========================================

class ProjectsController {
  final Ref ref;
  ProjectsController(this.ref);

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  Future<void> createProject({
    required String title,
    String? description,
    String status = 'IN_PROGRESS',
    String? repoUrl,
    List<String> technologies = const [],
    String color = '#10B981',
  }) async {
    await _repo.createProject({
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'status': status,
      if (repoUrl != null && repoUrl.isNotEmpty) 'repoUrl': repoUrl,
      'technologies': technologies,
      'color': color,
    });
    ref.invalidate(projectsListProvider);
    ref.invalidate(techStackInsightsProvider);
  }

  Future<void> updateProject({
    required String projectId,
    required String title,
    String? description,
    String? status,
    String? repoUrl,
    List<String>? technologies,
    String? color,
  }) async {
    await _repo.updateProject(projectId, {
      'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (repoUrl != null) 'repoUrl': repoUrl,
      if (technologies != null) 'technologies': technologies,
      if (color != null) 'color': color,
    });
    ref.invalidate(projectsListProvider);
    ref.invalidate(techStackInsightsProvider);
    invalidateProjectViews(projectId);
  }

  Future<void> deleteProject(String projectId) async {
    await _repo.deleteProject(projectId);
    ref.invalidate(projectsListProvider);
    ref.invalidate(techStackInsightsProvider);
  }

  Future<PaginatedList<FeatureItemModel>> getFeaturesPage(
    String projectId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
  }) {
    return _repo.getFeatures(
      projectId,
      page: page,
      limit: limit,
      status: status,
      priority: priority,
    );
  }

  Future<void> createFeature({
    required String projectId,
    required String name,
    String? description,
    String priority = 'MEDIUM',
    String status = 'TODO',
  }) async {
    await _repo.createFeature(projectId, {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
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
    await _repo.updateFeature(projectId, featureId, data);
    invalidateProjectViews(projectId);
  }

  Future<void> deleteFeature(String projectId, String featureId) async {
    await _repo.deleteFeature(projectId, featureId);
    invalidateProjectViews(projectId);
  }

  Future<PaginatedList<BugItemModel>> getBugsPage(
    String projectId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    String? severity,
  }) {
    return _repo.getBugs(
      projectId,
      page: page,
      limit: limit,
      status: status,
      priority: priority,
      severity: severity,
    );
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
    await _repo.createBug(projectId, {
      'title': title,
      'description': description,
      if (stepsToReproduce != null && stepsToReproduce.isNotEmpty)
        'stepsToReproduce': stepsToReproduce,
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
    await _repo.updateBug(projectId, bugId, data);
    invalidateProjectViews(projectId);
  }

  Future<void> deleteBug(String projectId, String bugId) async {
    await _repo.deleteBug(projectId, bugId);
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
    await _repo.moveBoardItem(projectId, {
      'entityType': entityType,
      'entityId': entityId,
      'targetStatus': targetStatus,
      if (prevOrder != null) 'prevOrder': prevOrder,
      if (nextOrder != null) 'nextOrder': nextOrder,
    });
    invalidateProjectViews(projectId);
  }

  Future<Map<String, dynamic>> registerGithubWebhook({
    required String owner,
    required String repo,
    required String projectId,
  }) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      ApiEndpoints.registerGithubWebhook(owner, repo),
      data: {'projectId': projectId},
    );
    invalidateProjectViews(projectId);
    return Map<String, dynamic>.from(response.data['data']);
  }

  // --- GITHUB WEBHOOKS & LINKS (PHASE 2) ---

  Future<Map<String, dynamic>> getWebhookConfig(String projectId) {
    return _repo.getWebhookConfig(projectId);
  }

  Future<Map<String, dynamic>> generateWebhookSecret(String projectId) async {
    final result = await _repo.generateWebhookSecret(projectId);
    ref.invalidate(projectDetailProvider(projectId));
    return result;
  }

  Future<List<Map<String, dynamic>>> getGithubLinks(String projectId) {
    return _repo.getGithubLinks(projectId);
  }

  Future<void> linkGithubEntity({
    required String projectId,
    required String entityType,
    required String entityId,
    required int issueOrPrNumber,
    required String repoFullName,
  }) async {
    await _repo.linkGithubEntity(
      projectId,
      entityType: entityType,
      entityId: entityId,
      issueOrPrNumber: issueOrPrNumber,
      repoFullName: repoFullName,
    );
    invalidateProjectViews(projectId);
  }

  Future<void> unlinkGithubEntity({
    required String projectId,
    required String linkId,
  }) async {
    await _repo.unlinkGithubEntity(projectId, linkId);
    invalidateProjectViews(projectId);
  }

  void invalidateProjectViews(String projectId) {
    ref.invalidate(projectBoardProvider(projectId));
    ref.invalidate(projectFeaturesProvider(projectId));
    ref.invalidate(projectBugsProvider(projectId));
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectAnalyticsProvider(projectId));
    ref.invalidate(projectTasksProvider(projectId));
    ref.invalidate(projectsListProvider);
    ref.invalidate(techStackInsightsProvider);
  }
}

final projectsControllerProvider = Provider((ref) => ProjectsController(ref));
