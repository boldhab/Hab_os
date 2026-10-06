import 'package:equatable/equatable.dart';

/// LeetCode profile statistics and problem difficulty breakdown (UC-60 to UC-64)
class LeetCodeStatsModel extends Equatable {
  final String username;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastSyncedAt;

  const LeetCodeStatsModel({
    required this.username,
    this.totalSolved = 0,
    this.easySolved = 0,
    this.mediumSolved = 0,
    this.hardSolved = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSyncedAt,
  });

  /// Computed total from difficulty breakdown if totalSolved was zero
  int get computedTotal =>
      totalSolved > 0 ? totalSolved : (easySolved + mediumSolved + hardSolved);

  double get easyRatio =>
      computedTotal > 0 ? (easySolved / computedTotal).clamp(0.0, 1.0) : 0.0;

  double get mediumRatio =>
      computedTotal > 0 ? (mediumSolved / computedTotal).clamp(0.0, 1.0) : 0.0;

  double get hardRatio =>
      computedTotal > 0 ? (hardSolved / computedTotal).clamp(0.0, 1.0) : 0.0;

  factory LeetCodeStatsModel.fromJson(Map<String, dynamic> json) {
    return LeetCodeStatsModel(
      username: json['username']?.toString() ?? '',
      totalSolved: (json['totalSolved'] as num?)?.toInt() ?? 0,
      easySolved: (json['easySolved'] as num?)?.toInt() ?? 0,
      mediumSolved: (json['mediumSolved'] as num?)?.toInt() ?? 0,
      hardSolved: (json['hardSolved'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'totalSolved': totalSolved,
        'easySolved': easySolved,
        'mediumSolved': mediumSolved,
        'hardSolved': hardSolved,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt!.toIso8601String(),
      };

  LeetCodeStatsModel copyWith({
    String? username,
    int? totalSolved,
    int? easySolved,
    int? mediumSolved,
    int? hardSolved,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastSyncedAt,
  }) {
    return LeetCodeStatsModel(
      username: username ?? this.username,
      totalSolved: totalSolved ?? this.totalSolved,
      easySolved: easySolved ?? this.easySolved,
      mediumSolved: mediumSolved ?? this.mediumSolved,
      hardSolved: hardSolved ?? this.hardSolved,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
        username,
        totalSolved,
        easySolved,
        mediumSolved,
        hardSolved,
        currentStreak,
        longestStreak,
        lastSyncedAt,
      ];
}

/// GitHub account integration metrics and commit streaks (UC-53 to UC-59)
class GitHubIntegrationStatsModel extends Equatable {
  final String username;
  final int publicReposCount;
  final int totalCommits;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastSyncedAt;

  const GitHubIntegrationStatsModel({
    required this.username,
    this.publicReposCount = 0,
    this.totalCommits = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSyncedAt,
  });

  factory GitHubIntegrationStatsModel.fromJson(Map<String, dynamic> json) {
    return GitHubIntegrationStatsModel(
      username: json['username']?.toString() ?? '',
      publicReposCount: (json['publicReposCount'] as num?)?.toInt() ?? 0,
      totalCommits: (json['totalCommits'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'publicReposCount': publicReposCount,
        'totalCommits': totalCommits,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        username,
        publicReposCount,
        totalCommits,
        currentStreak,
        longestStreak,
        lastSyncedAt,
      ];
}
