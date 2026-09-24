class ProjectOverviewModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final double progress;
  final bool manualProgress;
  final List<String> technologies;
  final String color;
  final String? repoUrl;
  final double totalFocusHours;
  final String healthStatus;
  final bool isStale;
  final bool isFirefighting;
  final int tasksCount;
  final int completedTasksCount;
  final int featuresCount;
  final int completedFeaturesCount;
  final int bugsCount;
  final int openBugsCount;
  final int openCriticalBugsCount;

  ProjectOverviewModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.progress,
    required this.manualProgress,
    required this.technologies,
    required this.color,
    this.repoUrl,
    required this.totalFocusHours,
    required this.healthStatus,
    required this.isStale,
    required this.isFirefighting,
    required this.tasksCount,
    required this.completedTasksCount,
    required this.featuresCount,
    required this.completedFeaturesCount,
    required this.bugsCount,
    required this.openBugsCount,
    required this.openCriticalBugsCount,
  });

  factory ProjectOverviewModel.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    final techs = (json['technologies'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return ProjectOverviewModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'IN_PROGRESS',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      manualProgress: json['manualProgress'] == true,
      technologies: techs,
      color: json['color'] ?? '#10B981',
      repoUrl: json['repoUrl'],
      totalFocusHours: (json['totalFocusHours'] as num?)?.toDouble() ?? 0.0,
      healthStatus: json['healthStatus'] ?? 'HEALTHY',
      isStale: json['isStale'] == true,
      isFirefighting: json['isFirefighting'] == true,
      tasksCount: counts['tasks'] ?? 0,
      completedTasksCount: counts['completedTasks'] ?? 0,
      featuresCount: counts['features'] ?? 0,
      completedFeaturesCount: counts['completedFeatures'] ?? 0,
      bugsCount: counts['bugs'] ?? 0,
      openBugsCount: counts['openBugs'] ?? 0,
      openCriticalBugsCount: counts['openCriticalBugs'] ?? 0,
    );
  }
}

class FeatureItemModel {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String priority;
  final double order;
  final int? githubIssueNumber;
  final String? githubUrl;
  final String? assignedTaskId;

  FeatureItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.priority,
    required this.order,
    this.githubIssueNumber,
    this.githubUrl,
    this.assignedTaskId,
  });

  factory FeatureItemModel.fromJson(Map<String, dynamic> json) {
    return FeatureItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'TODO',
      priority: json['priority'] ?? 'MEDIUM',
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      githubIssueNumber: json['githubIssueNumber'] as int?,
      githubUrl: json['githubUrl'],
      assignedTaskId: json['assignedTaskId'],
    );
  }
}

class BugItemModel {
  final String id;
  final String title;
  final String description;
  final String? stepsToReproduce;
  final String severity;
  final String priority;
  final String status;
  final double order;
  final int? githubIssueNumber;
  final String? githubUrl;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  BugItemModel({
    required this.id,
    required this.title,
    required this.description,
    this.stepsToReproduce,
    required this.severity,
    required this.priority,
    required this.status,
    required this.order,
    this.githubIssueNumber,
    this.githubUrl,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory BugItemModel.fromJson(Map<String, dynamic> json) {
    return BugItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      stepsToReproduce: json['stepsToReproduce'],
      severity: json['severity'] ?? 'MAJOR',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'OPEN',
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      githubIssueNumber: json['githubIssueNumber'] as int?,
      githubUrl: json['githubUrl'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt']) : null,
      resolutionNotes: json['resolutionNotes'],
    );
  }
}

class KanbanCardModel {
  final String id;
  final String type; // 'TASK', 'FEATURE', 'BUG'
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? severity;
  final double order;
  final int? githubIssueNumber;
  final bool isCompleted;

  KanbanCardModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.severity,
    required this.order,
    this.githubIssueNumber,
    this.isCompleted = false,
  });

  factory KanbanCardModel.fromJson(Map<String, dynamic> json) {
    return KanbanCardModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'TASK',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'TODO',
      priority: json['priority'] ?? 'MEDIUM',
      severity: json['severity'],
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      githubIssueNumber: json['githubIssueNumber'] as int?,
      isCompleted: json['isCompleted'] == true,
    );
  }
}

class KanbanBoardModel {
  final String projectId;
  final List<KanbanCardModel> todo;
  final List<KanbanCardModel> inProgress;
  final List<KanbanCardModel> blocked;
  final List<KanbanCardModel> completed;
  final int totalItems;

  KanbanBoardModel({
    required this.projectId,
    required this.todo,
    required this.inProgress,
    required this.blocked,
    required this.completed,
    required this.totalItems,
  });

  factory KanbanBoardModel.fromJson(Map<String, dynamic> json) {
    final cols = json['columns'] as Map<String, dynamic>? ?? {};
    return KanbanBoardModel(
      projectId: json['projectId'] ?? '',
      todo: (cols['TODO'] as List?)?.map((i) => KanbanCardModel.fromJson(i)).toList() ?? [],
      inProgress: (cols['IN_PROGRESS'] as List?)?.map((i) => KanbanCardModel.fromJson(i)).toList() ?? [],
      blocked: (cols['BLOCKED'] as List?)?.map((i) => KanbanCardModel.fromJson(i)).toList() ?? [],
      completed: (cols['COMPLETED'] as List?)?.map((i) => KanbanCardModel.fromJson(i)).toList() ?? [],
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class VelocityWeekModel {
  final String weekStart;
  final int focusMinutes;
  final int tasksCompleted;
  final int featuresCompleted;
  final int bugsResolved;

  VelocityWeekModel({
    required this.weekStart,
    required this.focusMinutes,
    required this.tasksCompleted,
    required this.featuresCompleted,
    required this.bugsResolved,
  });

  factory VelocityWeekModel.fromJson(Map<String, dynamic> json) {
    return VelocityWeekModel(
      weekStart: json['weekStart'] ?? '',
      focusMinutes: json['focusMinutes'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      featuresCompleted: json['featuresCompleted'] ?? 0,
      bugsResolved: json['bugsResolved'] ?? 0,
    );
  }
}

class ProjectAnalyticsModel {
  final String projectId;
  final int totalFocusMinutes;
  final double totalFocusHours;
  final List<VelocityWeekModel> weeklyVelocity;
  final String healthStatus;
  final bool isStale;
  final bool isFirefighting;
  final String velocityTrend;
  final double progress;
  final String formula;
  final List<String> technologies;

  ProjectAnalyticsModel({
    required this.projectId,
    required this.totalFocusMinutes,
    required this.totalFocusHours,
    required this.weeklyVelocity,
    required this.healthStatus,
    required this.isStale,
    required this.isFirefighting,
    required this.velocityTrend,
    required this.progress,
    required this.formula,
    required this.technologies,
  });

  factory ProjectAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final health = json['health'] as Map<String, dynamic>? ?? {};
    final progressDetails = json['progress'] as Map<String, dynamic>? ?? {};
    final velList = (json['weeklyVelocity'] as List?)
            ?.map((e) => VelocityWeekModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final techs = (json['technologies'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return ProjectAnalyticsModel(
      projectId: json['projectId'] ?? '',
      totalFocusMinutes: json['totalFocusMinutes'] ?? 0,
      totalFocusHours: (json['totalFocusHours'] as num?)?.toDouble() ?? 0.0,
      weeklyVelocity: velList,
      healthStatus: health['healthStatus'] ?? 'HEALTHY',
      isStale: health['isStale'] == true,
      isFirefighting: health['isFirefighting'] == true,
      velocityTrend: health['velocityTrend'] ?? 'STABLE',
      progress: (progressDetails['progress'] as num?)?.toDouble() ?? 0.0,
      formula: progressDetails['formula'] ?? '',
      technologies: techs,
    );
  }
}

class TechStackInsightModel {
  final String technology;
  final int totalMinutes;
  final double totalHours;
  final double percentage;
  final int projectsCount;

  TechStackInsightModel({
    required this.technology,
    required this.totalMinutes,
    required this.totalHours,
    required this.percentage,
    required this.projectsCount,
  });

  factory TechStackInsightModel.fromJson(Map<String, dynamic> json) {
    return TechStackInsightModel(
      technology: json['technology'] ?? '',
      totalMinutes: json['totalMinutes'] ?? 0,
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      projectsCount: json['projectsCount'] ?? 0,
    );
  }
}

class CommitItemModel {
  final String sha;
  final String message;
  final String author;
  final String? date;
  final String? url;

  CommitItemModel({
    required this.sha,
    required this.message,
    required this.author,
    this.date,
    this.url,
  });

  factory CommitItemModel.fromJson(Map<String, dynamic> json) {
    return CommitItemModel(
      sha: json['sha'] ?? '',
      message: json['message'] ?? '',
      author: json['author'] ?? 'Unknown',
      date: json['date'],
      url: json['url'],
    );
  }
}
