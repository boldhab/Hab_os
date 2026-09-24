import 'package:equatable/equatable.dart';

class TaskProjectSummary extends Equatable {
  final String id;
  final String title;
  final String? color;

  const TaskProjectSummary({
    required this.id,
    required this.title,
    this.color,
  });

  factory TaskProjectSummary.fromJson(Map<String, dynamic> json) {
    return TaskProjectSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      color: json['color'],
    );
  }

  @override
  List<Object?> get props => [id, title, color];
}

class TaskGoalSummary extends Equatable {
  final String id;
  final String title;

  const TaskGoalSummary({
    required this.id,
    required this.title,
  });

  factory TaskGoalSummary.fromJson(Map<String, dynamic> json) {
    return TaskGoalSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title];
}

class TaskFocusSessionSummary extends Equatable {
  final String id;
  final String category;
  final int durationMinutes;
  final String startTime;

  const TaskFocusSessionSummary({
    required this.id,
    required this.category,
    required this.durationMinutes,
    required this.startTime,
  });

  factory TaskFocusSessionSummary.fromJson(Map<String, dynamic> json) {
    return TaskFocusSessionSummary(
      id: json['id'] ?? '',
      category: json['category'] ?? 'CODING',
      durationMinutes: json['durationMinutes'] ?? 0,
      startTime: json['startTime'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, category, durationMinutes, startTime];
}

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final bool isCompleted;
  final String? dueDate;
  final int? estimatedMinutes;
  final int? actualMinutes;
  final List<String> tags;
  final String? recurrence;
  final String? completedAt;
  final String? projectId;
  final String? goalId;
  final String? categoryId;
  final TaskProjectSummary? project;
  final TaskGoalSummary? goal;
  final List<TaskFocusSessionSummary> focusSessions;
  final String? createdAt;
  final String? updatedAt;

  final String? parentTaskId;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool isBlocked;
  final String? subtaskFraction;
  final int subtaskPercent;
  final List<dynamic> blockedByPrerequisites;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.isCompleted,
    this.dueDate,
    this.estimatedMinutes,
    this.actualMinutes,
    this.tags = const [],
    this.recurrence,
    this.completedAt,
    this.projectId,
    this.goalId,
    this.categoryId,
    this.project,
    this.goal,
    this.focusSessions = const [],
    this.parentTaskId,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isBlocked = false,
    this.subtaskFraction,
    this.subtaskPercent = 0,
    this.blockedByPrerequisites = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final focusList = (json['focusSessions'] as List<dynamic>? ?? [])
        .map((f) => TaskFocusSessionSummary.fromJson(Map<String, dynamic>.from(f)))
        .toList();
    final tagList = (json['tags'] as List<dynamic>? ?? [])
        .map((t) => t.toString())
        .toList();

    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'TODO',
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'],
      estimatedMinutes: json['estimatedMinutes'],
      actualMinutes: json['actualMinutes'],
      tags: tagList,
      recurrence: json['recurrence'],
      completedAt: json['completedAt'],
      projectId: json['projectId'],
      goalId: json['goalId'],
      categoryId: json['categoryId'],
      project: json['project'] != null
          ? TaskProjectSummary.fromJson(Map<String, dynamic>.from(json['project']))
          : null,
      goal: json['goal'] != null
          ? TaskGoalSummary.fromJson(Map<String, dynamic>.from(json['goal']))
          : null,
      focusSessions: focusList,
      parentTaskId: json['parentTaskId'],
      isRecurring: json['isRecurring'] ?? false,
      recurrenceRule: json['recurrenceRule'] ?? json['recurrence'],
      isBlocked: json['isBlocked'] ?? false,
      subtaskFraction: json['subtaskProgress'] != null ? json['subtaskProgress']['fraction'] : null,
      subtaskPercent: json['subtaskProgress'] != null ? (json['subtaskProgress']['percent'] ?? 0) : 0,
      blockedByPrerequisites: json['blockedByPrerequisites'] ?? const [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    bool? isCompleted,
    String? dueDate,
    int? estimatedMinutes,
    int? actualMinutes,
    List<String>? tags,
    String? recurrence,
    String? completedAt,
    String? projectId,
    String? goalId,
    String? categoryId,
    TaskProjectSummary? project,
    TaskGoalSummary? goal,
    List<TaskFocusSessionSummary>? focusSessions,
    String? createdAt,
    String? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      tags: tags ?? this.tags,
      recurrence: recurrence ?? this.recurrence,
      completedAt: completedAt ?? this.completedAt,
      projectId: projectId ?? this.projectId,
      goalId: goalId ?? this.goalId,
      categoryId: categoryId ?? this.categoryId,
      project: project ?? this.project,
      goal: goal ?? this.goal,
      focusSessions: focusSessions ?? this.focusSessions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priority,
        status,
        isCompleted,
        dueDate,
        estimatedMinutes,
        actualMinutes,
        tags,
        recurrence,
        completedAt,
        projectId,
        goalId,
        categoryId,
        project,
        goal,
        focusSessions,
        createdAt,
        updatedAt,
      ];
}
