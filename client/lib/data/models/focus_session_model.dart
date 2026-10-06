import 'package:equatable/equatable.dart';

class FocusSessionModel extends Equatable {
  final String id;
  final String category;
  final String status;
  final String startTime;
  final String? endTime;
  final int? durationMinutes;
  final String? taskId;
  final String? courseId;
  final String? timeEntryId;
  final String? notes;
  final String? cancelledAt;
  final String? createdAt;

  const FocusSessionModel({
    required this.id,
    required this.category,
    this.status = 'COMPLETED',
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.taskId,
    this.courseId,
    this.timeEntryId,
    this.notes,
    this.cancelledAt,
    this.createdAt,
  });

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) {
    return FocusSessionModel(
      id: json['id'] ?? '',
      category: json['category'] ?? 'CODING',
      status: json['status'] ?? 'COMPLETED',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      durationMinutes: json['durationMinutes'],
      taskId: json['taskId'],
      courseId: json['courseId'],
      timeEntryId: json['timeEntryId'],
      notes: json['notes'],
      cancelledAt: json['cancelledAt'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'status': status,
      'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (taskId != null) 'taskId': taskId,
      if (courseId != null) 'courseId': courseId,
      if (timeEntryId != null) 'timeEntryId': timeEntryId,
      if (notes != null) 'notes': notes,
      if (cancelledAt != null) 'cancelledAt': cancelledAt,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        category,
        status,
        startTime,
        endTime,
        durationMinutes,
        taskId,
        courseId,
        timeEntryId,
        notes,
        cancelledAt,
        createdAt,
      ];
}

class FocusPeriodStats extends Equatable {
  final int minutes;
  final double hours;
  final int sessionsCount;

  const FocusPeriodStats({
    this.minutes = 0,
    this.hours = 0.0,
    this.sessionsCount = 0,
  });

  factory FocusPeriodStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FocusPeriodStats();
    return FocusPeriodStats(
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [minutes, hours, sessionsCount];
}

class FocusStatsModel extends Equatable {
  final int totalMinutesToday;
  final int totalSessionsToday;
  final FocusPeriodStats today;
  final FocusPeriodStats thisWeek;
  final FocusPeriodStats thisMonth;
  final Map<String, int> categoryBreakdown;

  const FocusStatsModel({
    required this.totalMinutesToday,
    required this.totalSessionsToday,
    this.today = const FocusPeriodStats(),
    this.thisWeek = const FocusPeriodStats(),
    this.thisMonth = const FocusPeriodStats(),
    required this.categoryBreakdown,
  });

  factory FocusStatsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> breakdown = {};
    if (json['categoryBreakdown'] is Map) {
      (json['categoryBreakdown'] as Map).forEach((key, val) {
        if (val is num) breakdown[key.toString()] = val.toInt();
      });
    }

    final todayStats = FocusPeriodStats.fromJson(
      json['today'] is Map ? Map<String, dynamic>.from(json['today'] as Map) : null,
    );
    final weekStats = FocusPeriodStats.fromJson(
      json['thisWeek'] is Map ? Map<String, dynamic>.from(json['thisWeek'] as Map) : null,
    );
    final monthStats = FocusPeriodStats.fromJson(
      json['thisMonth'] is Map ? Map<String, dynamic>.from(json['thisMonth'] as Map) : null,
    );

    final totalMins = (json['totalMinutesToday'] as num?)?.toInt() ?? todayStats.minutes;
    final totalSessions = (json['totalSessionsToday'] as num?)?.toInt() ?? todayStats.sessionsCount;

    return FocusStatsModel(
      totalMinutesToday: totalMins,
      totalSessionsToday: totalSessions,
      today: todayStats,
      thisWeek: weekStats,
      thisMonth: monthStats,
      categoryBreakdown: breakdown,
    );
  }

  @override
  List<Object?> get props => [
        totalMinutesToday,
        totalSessionsToday,
        today,
        thisWeek,
        thisMonth,
        categoryBreakdown,
      ];
}
