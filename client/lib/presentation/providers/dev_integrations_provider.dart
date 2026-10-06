import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/dev_integrations_model.dart';

// ==========================================
// LEETCODE NOTIFIER & PROVIDER (UC-60 to UC-64)
// ==========================================

class LeetCodeStateNotifier extends StateNotifier<AsyncValue<LeetCodeStatsModel?>> {
  final Ref _ref;

  LeetCodeStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.integrationsLeetCodeStats);
      final rawData = response.data['data'] ?? response.data;

      if (rawData == null || (rawData is Map && rawData.isEmpty)) {
        state = const AsyncValue.data(null);
      } else {
        final stats = LeetCodeStatsModel.fromJson(Map<String, dynamic>.from(rawData));
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncStats({
    required String username,
    int? easySolved,
    int? mediumSolved,
    int? hardSolved,
    int? currentStreak,
    int? longestStreak,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.integrationsLeetCodeSync,
        data: {
          'username': username,
          if (easySolved != null) 'easySolved': easySolved,
          if (mediumSolved != null) 'mediumSolved': mediumSolved,
          if (hardSolved != null) 'hardSolved': hardSolved,
          if (currentStreak != null) 'currentStreak': currentStreak,
          if (longestStreak != null) 'longestStreak': longestStreak,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      final stats = LeetCodeStatsModel.fromJson(Map<String, dynamic>.from(rawData));
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final leetCodeStatsProvider =
    StateNotifierProvider.autoDispose<LeetCodeStateNotifier, AsyncValue<LeetCodeStatsModel?>>((ref) {
  return LeetCodeStateNotifier(ref);
});

// ==========================================
// GITHUB STATS NOTIFIER & PROVIDER (UC-53 to UC-59)
// ==========================================

class GitHubStatsStateNotifier
    extends StateNotifier<AsyncValue<GitHubIntegrationStatsModel?>> {
  final Ref _ref;

  GitHubStatsStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.integrationsGitHubStats);
      final rawData = response.data['data'] ?? response.data;

      if (rawData == null || (rawData is Map && rawData.isEmpty)) {
        state = const AsyncValue.data(null);
      } else {
        final stats =
            GitHubIntegrationStatsModel.fromJson(Map<String, dynamic>.from(rawData));
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncStats({
    required String username,
    String? accessToken,
    int? publicReposCount,
    int? totalCommits,
    int? currentStreak,
    int? longestStreak,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.integrationsGitHubSync,
        data: {
          'username': username,
          if (accessToken != null && accessToken.isNotEmpty)
            'accessToken': accessToken,
          if (publicReposCount != null) 'publicReposCount': publicReposCount,
          if (totalCommits != null) 'totalCommits': totalCommits,
          if (currentStreak != null) 'currentStreak': currentStreak,
          if (longestStreak != null) 'longestStreak': longestStreak,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      final stats =
          GitHubIntegrationStatsModel.fromJson(Map<String, dynamic>.from(rawData));
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final gitHubStatsProvider = StateNotifierProvider.autoDispose<
    GitHubStatsStateNotifier, AsyncValue<GitHubIntegrationStatsModel?>>((ref) {
  return GitHubStatsStateNotifier(ref);
});
