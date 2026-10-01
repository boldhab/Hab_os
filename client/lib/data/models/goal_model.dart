import 'package:equatable/equatable.dart';

class MilestoneTaskSummary extends Equatable {
  final String id;
  final String title;
  final String priority;
  final String status;
  final bool isCompleted;
  final String? dueDate;
  final int? estimatedMinutes;

  const MilestoneTaskSummary({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.isCompleted,
    this.dueDate,
    this.estimatedMinutes,
  });

  factory MilestoneTaskSummary.fromJson(Map<String, dynamic> json) {
    return MilestoneTaskSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'TODO',
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'],
      estimatedMinutes: json['estimatedMinutes'],
    );
  }

  @override
  List<Object?> get props =>
      [id, title, priority, status, isCompleted, dueDate];
}

class MilestoneModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? targetDate;
  final String status;
  final bool isCompleted;
  final double order;
  final double weight;
  final List<MilestoneTaskSummary> tasks;

  const MilestoneModel({
    required this.id,
    required this.title,
    this.description,
    this.targetDate,
    required this.status,
    required this.isCompleted,
    this.order = 0.0,
    this.weight = 1.0,
    this.tasks = const [],
  });

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => tasks.length;
  double get taskProgressRatio => totalTasksCount == 0
      ? (isCompleted ? 1.0 : 0.0)
      : (completedTasksCount / totalTasksCount);
  int get progressPercent => (taskProgressRatio * 100).round();

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return MilestoneModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      targetDate: json['targetDate'],
      status: json['status'] ?? 'NOT_STARTED',
      isCompleted: json['isCompleted'] ?? false,
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      tasks: rawTasks
          .map((t) =>
              MilestoneTaskSummary.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        targetDate,
        status,
        isCompleted,
        order,
        weight,
        tasks
      ];
}

class GoalCheckInModel extends Equatable {
  final String id;
  final String date;
  final String confidence; // 'ON_TRACK', 'BEHIND', 'AT_RISK'
  final String? note;

  const GoalCheckInModel({
    required this.id,
    required this.date,
    required this.confidence,
    this.note,
  });

  factory GoalCheckInModel.fromJson(Map<String, dynamic> json) {
    return GoalCheckInModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      confidence: json['confidence'] ?? 'ON_TRACK',
      note: json['note'],
    );
  }

  @override
  List<Object?> get props => [id, date, confidence, note];
}

class GoalModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final double progress;
  final String? targetDate;
  final double? targetAmount;
  final double? currentAmount;
  final List<MilestoneModel> milestones;
  final List<MilestoneTaskSummary> tasks;
  final List<GoalCheckInModel> checkIns;
  final int milestoneCount;
  final int taskCount;

  const GoalModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.progress,
    this.targetDate,
    this.targetAmount,
    this.currentAmount,
    this.milestones = const [],
    this.tasks = const [],
    this.checkIns = const [],
    this.milestoneCount = 0,
    this.taskCount = 0,
  });

  bool get isFinancial => category.toUpperCase() == 'FINANCIAL';
  double get financialProgressRatio =>
      (targetAmount != null && targetAmount! > 0)
          ? ((currentAmount ?? 0) / targetAmount!).clamp(0.0, 1.0)
          : (progress / 100.0).clamp(0.0, 1.0);

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as List<dynamic>? ?? [];
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    final rawCheckIns = json['checkIns'] as List<dynamic>? ?? [];

    final counts = json['_count'] as Map<String, dynamic>?;

    return GoalModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'PERSONAL',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'IN_PROGRESS',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'],
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      milestones: rawMilestones
          .map((m) => MilestoneModel.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      tasks: rawTasks
          .map((t) =>
              MilestoneTaskSummary.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
      checkIns: rawCheckIns
          .map((c) => GoalCheckInModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      milestoneCount: counts?['milestones'] ?? rawMilestones.length,
      taskCount: counts?['tasks'] ?? rawTasks.length,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        priority,
        status,
        progress,
        targetDate,
        targetAmount,
        currentAmount,
        milestones,
        tasks,
        checkIns,
      ];
}

class GoalTreeBranchModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final double order;
  final double weight;
  final String? targetDate;
  final bool isCompleted;
  final String status;
  final int progress;
  final int totalTasks;
  final int completedTasks;
  final List<MilestoneTaskSummary> tasks;

  const GoalTreeBranchModel({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    required this.weight,
    this.targetDate,
    required this.isCompleted,
    required this.status,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.tasks,
  });

  factory GoalTreeBranchModel.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return GoalTreeBranchModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      targetDate: json['targetDate'],
      isCompleted: json['isCompleted'] ?? false,
      status: json['status'] ?? 'NOT_STARTED',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      tasks: rawTasks
          .map((t) =>
              MilestoneTaskSummary.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        order,
        weight,
        targetDate,
        isCompleted,
        status,
        progress,
        totalTasks,
        completedTasks,
        tasks,
      ];
}

class GoalTreeModel extends Equatable {
  final String id;
  final String title;
  final String category;
  final String priority;
  final String? targetDate;
  final double overallProgress;
  final String status;
  final double? targetAmount;
  final double? currentAmount;
  final int milestoneCount;
  final int directTasksCount;
  final List<GoalTreeBranchModel> branches;
  final List<MilestoneTaskSummary> unassignedTasks;

  const GoalTreeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    this.targetDate,
    required this.overallProgress,
    required this.status,
    this.targetAmount,
    this.currentAmount,
    required this.milestoneCount,
    required this.directTasksCount,
    required this.branches,
    required this.unassignedTasks,
  });

  factory GoalTreeModel.fromJson(Map<String, dynamic> json) {
    final rawBranches = json['branches'] as List<dynamic>? ?? [];
    final rawDirect = json['unassignedTasks'] as List<dynamic>? ?? [];

    return GoalTreeModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'PERSONAL',
      priority: json['priority'] ?? 'MEDIUM',
      targetDate: json['targetDate'],
      overallProgress: (json['overallProgress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'IN_PROGRESS',
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble(),
      milestoneCount: (json['milestoneCount'] as num?)?.toInt() ?? 0,
      directTasksCount: (json['directTasksCount'] as num?)?.toInt() ?? 0,
      branches: rawBranches
          .map(
              (b) => GoalTreeBranchModel.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
      unassignedTasks: rawDirect
          .map((t) =>
              MilestoneTaskSummary.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        priority,
        targetDate,
        overallProgress,
        status,
        branches,
        unassignedTasks,
      ];
}

class GoalHealthAlert extends Equatable {
  final String id;
  final String title;
  final String category;
  final String priority;
  final String? targetDate;
  final double progress;
  final int? daysUntilTarget;
  final int daysSinceActivity;
  final String? latestConfidence;
  final String healthStatus; // 'ON_TRACK', 'BEHIND', 'AT_RISK'
  final String? riskReason;

  const GoalHealthAlert({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    this.targetDate,
    required this.progress,
    this.daysUntilTarget,
    required this.daysSinceActivity,
    this.latestConfidence,
    required this.healthStatus,
    this.riskReason,
  });

  factory GoalHealthAlert.fromJson(Map<String, dynamic> json) {
    return GoalHealthAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'PERSONAL',
      priority: json['priority'] ?? 'MEDIUM',
      targetDate: json['targetDate'],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      daysUntilTarget: (json['daysUntilTarget'] as num?)?.toInt(),
      daysSinceActivity: (json['daysSinceActivity'] as num?)?.toInt() ?? 0,
      latestConfidence: json['latestConfidence'],
      healthStatus: json['healthStatus'] ?? 'ON_TRACK',
      riskReason: json['riskReason'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        priority,
        targetDate,
        progress,
        daysUntilTarget,
        daysSinceActivity,
        healthStatus,
      ];
}

class GoalsHealthSummary extends Equatable {
  final int totalActive;
  final int atRiskCount;
  final int behindCount;
  final int onTrackCount;
  final List<GoalHealthAlert> atRisk;
  final List<GoalHealthAlert> behind;
  final List<GoalHealthAlert> onTrack;

  const GoalsHealthSummary({
    required this.totalActive,
    required this.atRiskCount,
    required this.behindCount,
    required this.onTrackCount,
    required this.atRisk,
    required this.behind,
    required this.onTrack,
  });

  factory GoalsHealthSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final rawAtRisk = json['atRisk'] as List<dynamic>? ?? [];
    final rawBehind = json['behind'] as List<dynamic>? ?? [];
    final rawOnTrack = json['onTrack'] as List<dynamic>? ?? [];

    return GoalsHealthSummary(
      totalActive: (summary['totalActive'] as num?)?.toInt() ?? 0,
      atRiskCount: (summary['atRiskCount'] as num?)?.toInt() ?? 0,
      behindCount: (summary['behindCount'] as num?)?.toInt() ?? 0,
      onTrackCount: (summary['onTrackCount'] as num?)?.toInt() ?? 0,
      atRisk: rawAtRisk
          .map((g) => GoalHealthAlert.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
      behind: rawBehind
          .map((g) => GoalHealthAlert.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
      onTrack: rawOnTrack
          .map((g) => GoalHealthAlert.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalActive,
        atRiskCount,
        behindCount,
        onTrackCount,
        atRisk,
        behind,
        onTrack
      ];
}
