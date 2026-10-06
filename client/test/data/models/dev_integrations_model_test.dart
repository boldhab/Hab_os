import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/domain/models/dev_integrations_model.dart';

void main() {
  group('Developer Hub Integrations Models (UC-53 to UC-64)', () {
    test('hydrates LeetCodeStatsModel from JSON with difficulty ratios', () {
      final json = {
        'username': 'code_ninja',
        'totalSolved': 350,
        'easySolved': 150,
        'mediumSolved': 150,
        'hardSolved': 50,
        'currentStreak': 14,
        'longestStreak': 42,
        'lastSyncedAt': '2026-10-04T12:00:00.000Z',
      };

      final stats = LeetCodeStatsModel.fromJson(json);

      expect(stats.username, 'code_ninja');
      expect(stats.totalSolved, 350);
      expect(stats.easySolved, 150);
      expect(stats.mediumSolved, 150);
      expect(stats.hardSolved, 50);
      expect(stats.currentStreak, 14);
      expect(stats.longestStreak, 42);
      expect(stats.computedTotal, 350);
      expect(stats.easyRatio, closeTo(150 / 350, 0.001));
      expect(stats.mediumRatio, closeTo(150 / 350, 0.001));
      expect(stats.hardRatio, closeTo(50 / 350, 0.001));
    });

    test('computes totalSolved fallback when totalSolved is 0', () {
      final stats = const LeetCodeStatsModel(
        username: 'dev_user',
        easySolved: 20,
        mediumSolved: 30,
        hardSolved: 10,
      );

      expect(stats.computedTotal, 60);
      expect(stats.easyRatio, closeTo(20 / 60, 0.001));
    });

    test('serializes and deserializes LeetCodeStatsModel correctly', () {
      final date = DateTime.parse('2026-10-04T10:00:00.000Z');
      final original = LeetCodeStatsModel(
        username: 'algo_master',
        totalSolved: 100,
        easySolved: 50,
        mediumSolved: 40,
        hardSolved: 10,
        currentStreak: 7,
        longestStreak: 21,
        lastSyncedAt: date,
      );

      final json = original.toJson();
      final copy = LeetCodeStatsModel.fromJson(json);

      expect(copy, equals(original));
    });

    test('hydrates GitHubIntegrationStatsModel from JSON', () {
      final json = {
        'username': 'octocat',
        'publicReposCount': 24,
        'totalCommits': 542,
        'currentStreak': 9,
        'longestStreak': 30,
        'lastSyncedAt': '2026-10-04T08:00:00.000Z',
      };

      final ghStats = GitHubIntegrationStatsModel.fromJson(json);

      expect(ghStats.username, 'octocat');
      expect(ghStats.publicReposCount, 24);
      expect(ghStats.totalCommits, 542);
      expect(ghStats.currentStreak, 9);
      expect(ghStats.longestStreak, 30);
    });
  });
}
