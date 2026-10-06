import 'package:equatable/equatable.dart';

// ==========================================
// Life Score
// ==========================================

class LifeScoreComponentModel extends Equatable {
  final String name;
  final double score;
  final double weight;

  const LifeScoreComponentModel({
    required this.name,
    required this.score,
    required this.weight,
  });

  factory LifeScoreComponentModel.fromJson(Map<String, dynamic> json) {
    return LifeScoreComponentModel(
      name: json['name'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [name, score, weight];
}

class LifeScoreModel extends Equatable {
  final double overallScore;
  final String level;
  final List<LifeScoreComponentModel> components;

  const LifeScoreModel({
    required this.overallScore,
    required this.level,
    required this.components,
  });

  factory LifeScoreModel.fromJson(Map<String, dynamic> json) {
    List<LifeScoreComponentModel> comps = [];
    final rawComps = json['components'];
    if (rawComps is List) {
      comps = rawComps
          .map((c) =>
              LifeScoreComponentModel.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    } else if (rawComps is Map) {
      comps = rawComps.entries.map((e) {
        final val = e.value is Map
            ? Map<String, dynamic>.from(e.value)
            : <String, dynamic>{};
        return LifeScoreComponentModel(
          name: val['label']?.toString() ??
              val['name']?.toString() ??
              e.key.toString().toUpperCase(),
          score: (val['score'] as num?)?.toDouble() ?? 0.0,
          weight: (val['weight'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }

    return LifeScoreModel(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      level: json['level']?.toString() ?? 'Beginner',
      components: comps,
    );
  }

  @override
  List<Object?> get props => [overallScore, level, components];
}

// ==========================================
// Habits
// ==========================================

class DashboardHabitItem extends Equatable {
  final String id;
  final String name;
  final String frequency;
  final String targetType;
  final int targetValue;
  final int currentValue;
  final int currentStreak;
  final bool isCompletedToday;

  const DashboardHabitItem({
    required this.id,
    required this.name,
    required this.frequency,
    this.targetType = 'CHECKBOX',
    this.targetValue = 1,
    this.currentValue = 0,
    required this.currentStreak,
    required this.isCompletedToday,
  });

  factory DashboardHabitItem.fromJson(Map<String, dynamic> json) {
    return DashboardHabitItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      frequency: json['frequency'] ?? 'DAILY',
      targetType: json['targetType'] ?? 'CHECKBOX',
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      isCompletedToday: json['isCompletedToday'] ?? false,
    );
  }

  DashboardHabitItem copyWith({bool? isCompletedToday}) {
    return DashboardHabitItem(
      id: id,
      name: name,
      frequency: frequency,
      targetType: targetType,
      targetValue: targetValue,
      currentValue: currentValue,
      currentStreak: currentStreak,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, frequency, targetType, targetValue, currentValue,
        currentStreak, isCompletedToday];
}

class DashboardHabitsSection extends Equatable {
  final int total;
  final int completedToday;
  final List<DashboardHabitItem> items;

  const DashboardHabitsSection({
    required this.total,
    required this.completedToday,
    required this.items,
  });

  factory DashboardHabitsSection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = (rawItems is List ? rawItems : [])
        .map((i) => DashboardHabitItem.fromJson(
            Map<String, dynamic>.from(i is Map ? i : {})))
        .toList();
    return DashboardHabitsSection(
      total: (json['total'] as num?)?.toInt() ?? items.length,
      completedToday: (json['completedToday'] as num?)?.toInt() ??
          items.where((h) => h.isCompletedToday).length,
      items: items,
    );
  }

  @override
  List<Object?> get props => [total, completedToday, items];
}

// ==========================================
// Tasks
// ==========================================

class DashboardTaskItem extends Equatable {
  final String id;
  final String title;
  final String priority;
  final String status;
  final bool isCompleted;
  final String? dueDate;
  final String? projectTitle;

  const DashboardTaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.isCompleted,
    this.dueDate,
    this.projectTitle,
  });

  factory DashboardTaskItem.fromJson(Map<String, dynamic> json) {
    final project = json['project'] as Map<String, dynamic>?;
    return DashboardTaskItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'TODO',
      isCompleted: json['isCompleted'] == true,
      dueDate: json['dueDate']?.toString(),
      projectTitle: project?['title']?.toString(),
    );
  }

  DashboardTaskItem copyWith({
    String? id,
    String? title,
    String? priority,
    String? status,
    bool? isCompleted,
    String? dueDate,
    String? projectTitle,
  }) {
    return DashboardTaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      projectTitle: projectTitle ?? this.projectTitle,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, priority, status, isCompleted, dueDate, projectTitle];
}

// ==========================================
// Projects
// ==========================================

class DashboardProjectItem extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String status;
  final double progress;
  final int taskCount;
  final int featureCount;
  final int bugCount;

  const DashboardProjectItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.progress = 0.0,
    this.taskCount = 0,
    this.featureCount = 0,
    this.bugCount = 0,
  });

  factory DashboardProjectItem.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] is Map
        ? Map<String, dynamic>.from(json['_count'])
        : <String, dynamic>{};
    return DashboardProjectItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'IN_PROGRESS',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      taskCount: (counts['tasks'] as num?)?.toInt() ?? 0,
      featureCount: (counts['features'] as num?)?.toInt() ?? 0,
      bugCount: (counts['bugs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        progress,
        taskCount,
        featureCount,
        bugCount
      ];
}

// ==========================================
// Fitness
// ==========================================

class DashboardFitnessSection extends Equatable {
  final int workoutsThisWeekCount;
  final int targetWorkouts;
  final bool workedOutToday;
  final String? latestWorkoutName;

  const DashboardFitnessSection({
    required this.workoutsThisWeekCount,
    required this.targetWorkouts,
    required this.workedOutToday,
    this.latestWorkoutName,
  });

  factory DashboardFitnessSection.fromJson(Map<String, dynamic> json) {
    final latest = json['latestWorkout'] is Map
        ? Map<String, dynamic>.from(json['latestWorkout'])
        : null;
    return DashboardFitnessSection(
      workoutsThisWeekCount:
          (json['workoutsThisWeekCount'] as num?)?.toInt() ?? 0,
      targetWorkouts: (json['targetWorkouts'] as num?)?.toInt() ?? 4,
      workedOutToday: json['workedOutToday'] == true,
      latestWorkoutName: latest?['name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        workoutsThisWeekCount,
        targetWorkouts,
        workedOutToday,
        latestWorkoutName
      ];
}

// ==========================================
// Finance
// ==========================================

class DashboardFinanceSection extends Equatable {
  final double spentThisMonth;
  final double totalBudgetCap;
  final double budgetRemaining;
  final bool isWarning;

  const DashboardFinanceSection({
    required this.spentThisMonth,
    required this.totalBudgetCap,
    required this.budgetRemaining,
    required this.isWarning,
  });

  factory DashboardFinanceSection.fromJson(Map<String, dynamic> json) {
    return DashboardFinanceSection(
      spentThisMonth: (json['spentThisMonth'] as num?)?.toDouble() ?? 0.0,
      totalBudgetCap: (json['totalBudgetCap'] as num?)?.toDouble() ?? 0.0,
      budgetRemaining: (json['budgetRemaining'] as num?)?.toDouble() ?? 0.0,
      isWarning: json['isWarning'] ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [spentThisMonth, totalBudgetCap, budgetRemaining, isWarning];
}

// ==========================================
// Global Activity Item
// ==========================================

class GlobalActivityItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'TRANSACTION', 'FOCUS', 'TASK', 'HABIT', 'WORKOUT', 'STUDY'
  final DateTime timestamp;
  final double? amount;
  final String? color;

  const GlobalActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timestamp,
    this.amount,
    this.color,
  });

  factory GlobalActivityItem.fromJson(Map<String, dynamic> json) {
    return GlobalActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      category: json['type']?.toString() ?? json['category']?.toString() ?? 'TASK',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble(),
      color: json['color']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, subtitle, category, timestamp, amount, color];
}

class DashboardScheduleEvent extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String color;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;

  const DashboardScheduleEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.color = '#6366F1',
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
  });

  factory DashboardScheduleEvent.fromJson(Map<String, dynamic> json) {
    return DashboardScheduleEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Event',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      color: json['color']?.toString() ?? '#6366F1',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
      isRecurring: json['isRecurring'] == true,
    );
  }

  @override
  List<Object?> get props => [id, title, description, location, color, startTime, endTime, isRecurring];
}

class DashboardAcademicDeliverable extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final bool isExam;
  final String courseName;
  final String? courseCode;
  final String courseColor;
  final double? weight;

  const DashboardAcademicDeliverable({
    required this.id,
    required this.title,
    required this.date,
    required this.isExam,
    required this.courseName,
    this.courseCode,
    required this.courseColor,
    this.weight,
  });

  factory DashboardAcademicDeliverable.fromAssignment(Map<String, dynamic> json) {
    final course = json['course'] is Map ? Map<String, dynamic>.from(json['course']) : <String, dynamic>{};
    return DashboardAcademicDeliverable(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Assignment',
      date: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      isExam: false,
      courseName: course['name']?.toString() ?? 'Course',
      courseCode: course['code']?.toString(),
      courseColor: course['color']?.toString() ?? '#8B5CF6',
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  factory DashboardAcademicDeliverable.fromExam(Map<String, dynamic> json) {
    final course = json['course'] is Map ? Map<String, dynamic>.from(json['course']) : <String, dynamic>{};
    return DashboardAcademicDeliverable(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Exam',
      date: DateTime.tryParse(json['examDate']?.toString() ?? '') ?? DateTime.now(),
      isExam: true,
      courseName: course['name']?.toString() ?? 'Course',
      courseCode: course['code']?.toString(),
      courseColor: course['color']?.toString() ?? '#8B5CF6',
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, title, date, isExam, courseName, courseCode, courseColor, weight];
}

// ==========================================
// Full Dashboard Feed
// ==========================================

class DashboardFeedModel extends Equatable {
  final String userName;
  final String? userAvatarUrl;
  final List<String> dashboardModules;
  final LifeScoreModel lifeScore;
  final DashboardHabitsSection habits;
  final List<DashboardTaskItem> tasksDueToday;
  final List<DashboardScheduleEvent> scheduleEvents;
  final List<DashboardProjectItem> activeProjects;
  final List<DashboardAcademicDeliverable> academicDeliverables;
  final DashboardFitnessSection fitness;
  final DashboardFinanceSection finance;
  final List<GlobalActivityItem> recentActivitiesList;
  final String? aiRecommendation;
  final DateTime? generatedAt;

  const DashboardFeedModel({
    required this.userName,
    this.userAvatarUrl,
    this.dashboardModules = const [],
    required this.lifeScore,
    required this.habits,
    required this.tasksDueToday,
    this.scheduleEvents = const [],
    this.activeProjects = const [],
    this.academicDeliverables = const [],
    required this.fitness,
    required this.finance,
    this.recentActivitiesList = const [],
    this.aiRecommendation,
    this.generatedAt,
  });

  bool isModuleEnabled(String moduleName) {
    if (dashboardModules.isEmpty) return true;
    final upper = moduleName.toUpperCase();
    return dashboardModules.map((m) => m.toUpperCase()).contains(upper);
  }

  List<GlobalActivityItem> get recentActivities {
    if (recentActivitiesList.isNotEmpty) {
      return recentActivitiesList;
    }

    final list = <GlobalActivityItem>[];
    final now = generatedAt ?? DateTime.now();

    // Completed tasks today
    for (final task in tasksDueToday.where((t) => t.isCompleted)) {
      list.add(GlobalActivityItem(
        id: 'task-${task.id}',
        title: 'Completed task: ${task.title}',
        subtitle: task.projectTitle != null
            ? 'Project: ${task.projectTitle}'
            : 'Task completed',
        category: 'TASK',
        timestamp: now,
      ));
    }

    // Completed habits today
    for (final habit in habits.items.where((h) => h.isCompletedToday)) {
      list.add(GlobalActivityItem(
        id: 'habit-${habit.id}',
        title: 'Maintained habit: ${habit.name}',
        subtitle: '${habit.currentStreak} day streak',
        category: 'HABIT',
        timestamp: now,
      ));
    }

    // Fitness activity
    if (fitness.workedOutToday) {
      list.add(GlobalActivityItem(
        id: 'fitness-today',
        title:
            'Completed workout${fitness.latestWorkoutName != null ? ': ${fitness.latestWorkoutName}' : ''}',
        subtitle:
            '${fitness.workoutsThisWeekCount}/${fitness.targetWorkouts} workouts this week',
        category: 'FITNESS',
        timestamp: now,
      ));
    }

    return list;
  }

  DashboardFeedModel copyWith({
    String? userName,
    String? userAvatarUrl,
    List<String>? dashboardModules,
    LifeScoreModel? lifeScore,
    DashboardHabitsSection? habits,
    List<DashboardTaskItem>? tasksDueToday,
    List<DashboardScheduleEvent>? scheduleEvents,
    List<DashboardProjectItem>? activeProjects,
    List<DashboardAcademicDeliverable>? academicDeliverables,
    DashboardFitnessSection? fitness,
    DashboardFinanceSection? finance,
    List<GlobalActivityItem>? recentActivitiesList,
    String? aiRecommendation,
    DateTime? generatedAt,
  }) {
    return DashboardFeedModel(
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      dashboardModules: dashboardModules ?? this.dashboardModules,
      lifeScore: lifeScore ?? this.lifeScore,
      habits: habits ?? this.habits,
      tasksDueToday: tasksDueToday ?? this.tasksDueToday,
      scheduleEvents: scheduleEvents ?? this.scheduleEvents,
      activeProjects: activeProjects ?? this.activeProjects,
      academicDeliverables: academicDeliverables ?? this.academicDeliverables,
      fitness: fitness ?? this.fitness,
      finance: finance ?? this.finance,
      recentActivitiesList: recentActivitiesList ?? this.recentActivitiesList,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  factory DashboardFeedModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};
    final timeline = json['timeline'] is Map
        ? Map<String, dynamic>.from(json['timeline'])
        : <String, dynamic>{};

    final rawTasks = timeline['tasksDueToday'] ?? json['tasksDueToday'];
    final tasksList = (rawTasks is List ? rawTasks : [])
        .map((t) => DashboardTaskItem.fromJson(Map<String, dynamic>.from(t)))
        .toList();

    final rawSchedules = timeline['scheduleEvents'] ?? json['scheduleEvents'];
    final scheduleList = (rawSchedules is List ? rawSchedules : [])
        .map((s) => DashboardScheduleEvent.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    final rawProjects = json['projects'] ?? json['activeProjects'];
    final projectsList = (rawProjects is List ? rawProjects : [])
        .map((p) => DashboardProjectItem.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    // Academics: upcoming assignments & exams
    final rawAcademics = json['academics'] is Map
        ? Map<String, dynamic>.from(json['academics'])
        : <String, dynamic>{};
    final rawAssignments = rawAcademics['upcomingAssignments'] ?? json['upcomingAssignments'];
    final rawExams = rawAcademics['upcomingExams'] ?? json['upcomingExams'];
    final deliverables = <DashboardAcademicDeliverable>[];
    if (rawAssignments is List) {
      for (final a in rawAssignments) {
        if (a is Map) deliverables.add(DashboardAcademicDeliverable.fromAssignment(Map<String, dynamic>.from(a)));
      }
    }
    if (rawExams is List) {
      for (final e in rawExams) {
        if (e is Map) deliverables.add(DashboardAcademicDeliverable.fromExam(Map<String, dynamic>.from(e)));
      }
    }
    deliverables.sort((a, b) => a.date.compareTo(b.date));

    // Recent activity stream
    final rawActivities = json['recentActivities'];
    final activityList = (rawActivities is List ? rawActivities : [])
        .map((a) => GlobalActivityItem.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    // Module visibility preferences
    final rawModules = json['dashboardModules'] ?? user['dashboardModules'];
    final moduleList = (rawModules is List ? rawModules : [])
        .map((m) => m.toString())
        .toList();

    String? recommendationText;
    final rawRec = json['aiRecommendation'];
    if (rawRec is String) {
      recommendationText = rawRec;
    } else if (rawRec is Map) {
      final title = rawRec['title']?.toString() ?? '';
      final reasoning = rawRec['reasoning']?.toString() ?? '';
      if (title.isNotEmpty && reasoning.isNotEmpty) {
        recommendationText = '$title — $reasoning';
      } else if (title.isNotEmpty) {
        recommendationText = title;
      } else if (reasoning.isNotEmpty) {
        recommendationText = reasoning;
      }
    }

    return DashboardFeedModel(
      userName: user['name']?.toString() ?? 'User',
      userAvatarUrl: user['avatarUrl']?.toString(),
      dashboardModules: moduleList,
      lifeScore: LifeScoreModel.fromJson(
        json['lifeScore'] is Map
            ? Map<String, dynamic>.from(json['lifeScore'])
            : {},
      ),
      habits: DashboardHabitsSection.fromJson(
        json['habits'] is Map ? Map<String, dynamic>.from(json['habits']) : {},
      ),
      tasksDueToday: tasksList,
      scheduleEvents: scheduleList,
      activeProjects: projectsList,
      academicDeliverables: deliverables,
      fitness: DashboardFitnessSection.fromJson(
        json['fitness'] is Map
            ? Map<String, dynamic>.from(json['fitness'])
            : {},
      ),
      finance: DashboardFinanceSection.fromJson(
        json['finance'] is Map
            ? Map<String, dynamic>.from(json['finance'])
            : {},
      ),
      recentActivitiesList: activityList,
      aiRecommendation: recommendationText,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        userAvatarUrl,
        dashboardModules,
        lifeScore,
        habits,
        tasksDueToday,
        scheduleEvents,
        activeProjects,
        academicDeliverables,
        fitness,
        finance,
        recentActivitiesList,
        aiRecommendation,
      ];
}
