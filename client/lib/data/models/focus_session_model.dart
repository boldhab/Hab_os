import 'package:equatable/equatable.dart';

class FocusSessionModel extends Equatable {
  final String id;
  final String category;
  final String startTime;
  final String? endTime;
  final int? durationMinutes;
  final String? taskId;
  final String? notes;
  final String? createdAt;

  const FocusSessionModel({
    required this.id,
    required this.category,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.taskId,
    this.notes,
    this.createdAt,
  });

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) {
    return FocusSessionModel(
      id: json['id'] ?? '',
      category: json['category'] ?? 'CODING',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      durationMinutes: json['durationMinutes'],
      taskId: json['taskId'],
      notes: json['notes'],
      createdAt: json['createdAt'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        startTime,
        endTime,
        durationMinutes,
        taskId,
        notes,
        createdAt,
      ];
}

class FocusStatsModel extends Equatable {
  final int totalMinutesToday;
  final int totalSessionsToday;
  final Map<String, int> categoryBreakdown;

  const FocusStatsModel({
    required this.totalMinutesToday,
    required this.totalSessionsToday,
    required this.categoryBreakdown,
  });

  factory FocusStatsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> breakdown = {};
    if (json['categoryBreakdown'] is Map) {
      (json['categoryBreakdown'] as Map).forEach((key, val) {
        if (val is num) breakdown[key.toString()] = val.toInt();
      });
    }
    return FocusStatsModel(
      totalMinutesToday: (json['totalMinutesToday'] as num?)?.toInt() ?? 0,
      totalSessionsToday: (json['totalSessionsToday'] as num?)?.toInt() ?? 0,
      categoryBreakdown: breakdown,
    );
  }

  @override
  List<Object?> get props => [
        totalMinutesToday,
        totalSessionsToday,
        categoryBreakdown,
      ];
}
