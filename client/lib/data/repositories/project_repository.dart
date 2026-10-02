import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../presentation/screens/projects/models/project_models.dart';

class ProjectRepository {
  final Dio _dio;

  ProjectRepository(this._dio);

  Future<List<ProjectOverviewModel>> getProjects({
    String? status,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };
    final response = await _dio.get(
      ApiEndpoints.projects,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data['data'];
    List items = [];
    if (data is Map && data.containsKey('data')) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items
        .map((i) => ProjectOverviewModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  Future<List<TechStackInsightModel>> getTechStackInsights() async {
    final response = await _dio.get(ApiEndpoints.projectTechInsights);
    final data = response.data['data'];
    if (data is Map && data.containsKey('technologies')) {
      final list = data['technologies'] as List;
      return list
          .map((i) =>
              TechStackInsightModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getProjectById(String id) async {
    final response = await _dio.get(ApiEndpoints.projectById(id));
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> createProject(
      Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiEndpoints.projects, data: payload);
    return Map<String, dynamic>.from(response.data['data'] ?? response.data);
  }

  Future<Map<String, dynamic>> updateProject(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _dio.put(ApiEndpoints.projectById(id), data: payload);
    return Map<String, dynamic>.from(response.data['data'] ?? response.data);
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete(ApiEndpoints.projectById(id));
  }

  // --- FEATURES ---

  Future<PaginatedList<FeatureItemModel>> getFeatures(
    String projectId, {
    int page = 1,
    int limit = 50,
    String? status,
    String? priority,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
    };
    final response = await _dio.get(
      ApiEndpoints.projectFeatures(projectId),
      queryParameters: query,
    );
    final rawData = response.data['data'];

    List items = [];
    int total = 0;
    int totalPages = 1;

    if (rawData is Map && rawData.containsKey('data')) {
      items = (rawData['data'] as List?) ?? [];
      final meta = rawData['meta'] as Map<String, dynamic>? ?? {};
      total = meta['total'] as int? ?? items.length;
      totalPages = meta['totalPages'] as int? ?? 1;
    } else if (rawData is List) {
      items = rawData;
      total = items.length;
      totalPages = 1;
    }

    final parsedItems = items
        .map((i) => FeatureItemModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();

    return PaginatedList<FeatureItemModel>(
      items: parsedItems,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }

  Future<FeatureItemModel> createFeature(
      String projectId, Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiEndpoints.projectFeatures(projectId),
      data: payload,
    );
    final data = response.data['data'] ?? response.data;
    return FeatureItemModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FeatureItemModel> updateFeature(
    String projectId,
    String featureId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.projectFeatureById(projectId, featureId),
      data: payload,
    );
    final data = response.data['data'] ?? response.data;
    return FeatureItemModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteFeature(String projectId, String featureId) async {
    await _dio.delete(ApiEndpoints.projectFeatureById(projectId, featureId));
  }

  // --- BUGS ---

  Future<PaginatedList<BugItemModel>> getBugs(
    String projectId, {
    int page = 1,
    int limit = 50,
    String? status,
    String? priority,
    String? severity,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
    };
    final response = await _dio.get(
      ApiEndpoints.projectBugs(projectId),
      queryParameters: query,
    );
    final rawData = response.data['data'];

    List items = [];
    int total = 0;
    int totalPages = 1;

    if (rawData is Map && rawData.containsKey('data')) {
      items = (rawData['data'] as List?) ?? [];
      final meta = rawData['meta'] as Map<String, dynamic>? ?? {};
      total = meta['total'] as int? ?? items.length;
      totalPages = meta['totalPages'] as int? ?? 1;
    } else if (rawData is List) {
      items = rawData;
      total = items.length;
      totalPages = 1;
    }

    final parsedItems = items
        .map((i) => BugItemModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();

    return PaginatedList<BugItemModel>(
      items: parsedItems,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }

  Future<BugItemModel> createBug(
      String projectId, Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiEndpoints.projectBugs(projectId),
      data: payload,
    );
    final data = response.data['data'] ?? response.data;
    return BugItemModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<BugItemModel> updateBug(
    String projectId,
    String bugId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.projectBugById(projectId, bugId),
      data: payload,
    );
    final data = response.data['data'] ?? response.data;
    return BugItemModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteBug(String projectId, String bugId) async {
    await _dio.delete(ApiEndpoints.projectBugById(projectId, bugId));
  }

  // --- KANBAN BOARD ---

  Future<KanbanBoardModel> getBoard(String projectId) async {
    final response = await _dio.get(ApiEndpoints.projectBoard(projectId));
    return KanbanBoardModel.fromJson(
        Map<String, dynamic>.from(response.data['data']));
  }

  Future<Map<String, dynamic>> moveBoardItem(
    String projectId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.projectBoardMove(projectId),
      data: payload,
    );
    return Map<String, dynamic>.from(response.data['data'] ?? response.data);
  }

  // --- ANALYTICS & COMMITS ---

  Future<ProjectAnalyticsModel> getAnalytics(String projectId) async {
    final response = await _dio.get(ApiEndpoints.projectAnalytics(projectId));
    return ProjectAnalyticsModel.fromJson(
        Map<String, dynamic>.from(response.data['data']));
  }

  Future<CommitsResult> getCommits(String projectId) async {
    final response = await _dio.get(ApiEndpoints.projectCommits(projectId));
    final data = response.data['data'];
    if (data is Map) {
      final commits = (data['commits'] as List? ?? [])
          .map((i) => CommitItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
      return CommitsResult(
        commits: commits,
        errorCode: data['errorCode'] as String?,
        message: data['message'] as String?,
      );
    }
    return const CommitsResult(commits: []);
  }

  // --- GITHUB WEBHOOKS & LINKS (PHASE 2) ---

  Future<Map<String, dynamic>> getWebhookConfig(String projectId) async {
    final response =
        await _dio.get(ApiEndpoints.projectWebhookConfig(projectId));
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> generateWebhookSecret(String projectId) async {
    final response =
        await _dio.post(ApiEndpoints.projectWebhookSecret(projectId));
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getGithubLinks(String projectId) async {
    final response =
        await _dio.get(ApiEndpoints.projectGithubLinks(projectId));
    final list = response.data['data'] as List? ?? [];
    return list.map((i) => Map<String, dynamic>.from(i)).toList();
  }

  Future<Map<String, dynamic>> linkGithubEntity(
    String projectId, {
    required String entityType,
    required String entityId,
    required int issueOrPrNumber,
    required String repoFullName,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.projectGithubLinks(projectId),
      data: {
        'entityType': entityType,
        'entityId': entityId,
        'issueOrPrNumber': issueOrPrNumber,
        'repoFullName': repoFullName,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<void> unlinkGithubEntity(String projectId, String linkId) async {
    await _dio.delete(ApiEndpoints.projectGithubLinkById(projectId, linkId));
  }

  // --- REAL-TIME SSE COLLABORATION ---

  Stream<Map<String, dynamic>> subscribeToProjectEvents(String projectId) async* {
    try {
      final response = await _dio.get<ResponseBody>(
        ApiEndpoints.projectEvents(projectId),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      String buffer = '';
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              try {
                final map = jsonDecode(jsonStr);
                if (map is Map<String, dynamic>) {
                  yield map;
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {
      // Handled silently; StreamProvider will auto-recover
    }
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProjectRepository(dio);
});

final projectEventsStreamProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.subscribeToProjectEvents(projectId);
});
