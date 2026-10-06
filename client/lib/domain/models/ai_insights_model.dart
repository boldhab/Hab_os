import 'package:equatable/equatable.dart';

/// Represents a life domain identified as lagging or neglected (UC-142)
class NeglectedArea extends Equatable {
  final String domain;
  final String title;
  final String description;
  final String severity; // 'HIGH', 'MEDIUM', 'LOW'
  final int? daysInactive;
  final String metricLabel;
  final String metricValue;
  final String recommendedAction;

  const NeglectedArea({
    required this.domain,
    required this.title,
    required this.description,
    required this.severity,
    this.daysInactive,
    required this.metricLabel,
    required this.metricValue,
    required this.recommendedAction,
  });

  factory NeglectedArea.fromJson(Map<String, dynamic> json) {
    return NeglectedArea(
      domain: json['domain']?.toString() ?? 'PRODUCTIVITY',
      title: json['title']?.toString() ?? 'Neglected Area Alert',
      description: json['description']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'MEDIUM',
      daysInactive: json['daysInactive'] is num
          ? (json['daysInactive'] as num).toInt()
          : null,
      metricLabel: json['metricLabel']?.toString() ?? 'Status',
      metricValue: json['metricValue']?.toString() ?? '',
      recommendedAction: json['recommendedAction']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'title': title,
        'description': description,
        'severity': severity,
        'daysInactive': daysInactive,
        'metricLabel': metricLabel,
        'metricValue': metricValue,
        'recommendedAction': recommendedAction,
      };

  @override
  List<Object?> get props => [
        domain,
        title,
        description,
        severity,
        daysInactive,
        metricLabel,
        metricValue,
        recommendedAction,
      ];
}

/// Represents an intelligently ranked next task recommendation (UC-141)
class RecommendedTask extends Equatable {
  final String id;
  final String title;
  final String priority;
  final String domain;
  final int score;
  final DateTime? dueDate;
  final int? estimatedMinutes;
  final String? projectName;
  final String? courseName;
  final String reason;

  const RecommendedTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.domain,
    required this.score,
    this.dueDate,
    this.estimatedMinutes,
    this.projectName,
    this.courseName,
    required this.reason,
  });

  factory RecommendedTask.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDue;
    if (json['dueDate'] != null) {
      parsedDue = DateTime.tryParse(json['dueDate'].toString());
    }

    return RecommendedTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Task',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      domain: json['domain']?.toString() ?? 'PRODUCTIVITY',
      score: (json['score'] is num) ? (json['score'] as num).toInt() : 0,
      dueDate: parsedDue,
      estimatedMinutes: json['estimatedMinutes'] is num
          ? (json['estimatedMinutes'] as num).toInt()
          : null,
      projectName: json['projectName']?.toString(),
      courseName: json['courseName']?.toString(),
      reason: json['reason']?.toString() ?? 'Recommended for immediate focus',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority,
        'domain': domain,
        'score': score,
        'dueDate': dueDate?.toIso8601String(),
        'estimatedMinutes': estimatedMinutes,
        'projectName': projectName,
        'courseName': courseName,
        'reason': reason,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        priority,
        domain,
        score,
        dueDate,
        estimatedMinutes,
        projectName,
        courseName,
        reason,
      ];
}

/// Represents a day schedule within a personalized weekly rebalancing plan (UC-143)
class PersonalizedPlanDay extends Equatable {
  final String dayName;
  final String focusDomain;
  final int targetMins;
  final List<String> suggestedActions;

  const PersonalizedPlanDay({
    required this.dayName,
    required this.focusDomain,
    required this.targetMins,
    required this.suggestedActions,
  });

  factory PersonalizedPlanDay.fromJson(Map<String, dynamic> json) {
    final actionsRaw = json['suggestedActions'];
    final List<String> actions = [];
    if (actionsRaw is List) {
      for (final a in actionsRaw) {
        if (a != null) actions.add(a.toString());
      }
    }

    return PersonalizedPlanDay(
      dayName: json['dayName']?.toString() ?? 'Day',
      focusDomain: json['focusDomain']?.toString() ?? 'PRODUCTIVITY',
      targetMins: (json['targetMins'] is num)
          ? (json['targetMins'] as num).toInt()
          : 60,
      suggestedActions: actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayName': dayName,
        'focusDomain': focusDomain,
        'targetMins': targetMins,
        'suggestedActions': suggestedActions,
      };

  @override
  List<Object?> get props => [dayName, focusDomain, targetMins, suggestedActions];
}

/// Represents the overall weekly AI rebalancing plan (UC-143)
class PersonalizedPlan extends Equatable {
  final String weeklyGoal;
  final int totalSuggestedFocusMins;
  final List<String> priorityDomains;
  final List<PersonalizedPlanDay> schedule;
  final String aiAdvice;

  const PersonalizedPlan({
    required this.weeklyGoal,
    required this.totalSuggestedFocusMins,
    required this.priorityDomains,
    required this.schedule,
    required this.aiAdvice,
  });

  factory PersonalizedPlan.fromJson(Map<String, dynamic> json) {
    final domainsRaw = json['priorityDomains'];
    final List<String> domains = [];
    if (domainsRaw is List) {
      for (final d in domainsRaw) {
        if (d != null) domains.add(d.toString());
      }
    }

    final scheduleRaw = json['schedule'];
    final List<PersonalizedPlanDay> sched = [];
    if (scheduleRaw is List) {
      for (final s in scheduleRaw) {
        if (s is Map<String, dynamic>) {
          sched.add(PersonalizedPlanDay.fromJson(s));
        }
      }
    }

    return PersonalizedPlan(
      weeklyGoal: json['weeklyGoal']?.toString() ?? 'Weekly Focus Plan',
      totalSuggestedFocusMins: (json['totalSuggestedFocusMins'] is num)
          ? (json['totalSuggestedFocusMins'] as num).toInt()
          : 0,
      priorityDomains: domains,
      schedule: sched,
      aiAdvice: json['aiAdvice']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'weeklyGoal': weeklyGoal,
        'totalSuggestedFocusMins': totalSuggestedFocusMins,
        'priorityDomains': priorityDomains,
        'schedule': schedule.map((s) => s.toJson()).toList(),
        'aiAdvice': aiAdvice,
      };

  @override
  List<Object?> get props => [
        weeklyGoal,
        totalSuggestedFocusMins,
        priorityDomains,
        schedule,
        aiAdvice,
      ];
}

/// Combined container for AI Insights view state
class AiInsightsData extends Equatable {
  final List<NeglectedArea> neglectedAreas;
  final List<RecommendedTask> recommendedTasks;
  final PersonalizedPlan? plan;

  const AiInsightsData({
    this.neglectedAreas = const [],
    this.recommendedTasks = const [],
    this.plan,
  });

  @override
  List<Object?> get props => [neglectedAreas, recommendedTasks, plan];
}
