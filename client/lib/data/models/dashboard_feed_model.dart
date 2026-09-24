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
    final comps = (json['components'] as List<dynamic>? ?? [])
        .map((c) => LifeScoreComponentModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    return LifeScoreModel(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] ?? 'Beginner',
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
  final int currentStreak;
  final bool isCompletedToday;

  const DashboardHabitItem({
    required this.id,
    required this.name,
    required this.frequency,
    required this.currentStreak,
    required this.isCompletedToday,
  });

  factory DashboardHabitItem.fromJson(Map<String, dynamic> json) {
    return DashboardHabitItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      frequency: json['frequency'] ?? 'DAILY',
      currentStreak: json['currentStreak'] ?? 0,
      isCompletedToday: json['isCompletedToday'] ?? false,
    );
  }

  DashboardHabitItem copyWith({bool? isCompletedToday}) {
    return DashboardHabitItem(
      id: id,
      name: name,
      frequency: frequency,
      currentStreak: currentStreak,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }

  @override
  List<Object?> get props => [id, name, frequency, currentStreak, isCompletedToday];
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
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((i) => DashboardHabitItem.fromJson(Map<String, dynamic>.from(i)))
        .toList();
    return DashboardHabitsSection(
      total: json['total'] ?? 0,
      completedToday: json['completedToday'] ?? 0,
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'TODO',
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'],
      projectTitle: project?['title'],
    );
  }

  @override
  List<Object?> get props => [id, title, priority, status, isCompleted, dueDate, projectTitle];
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
    final counts = json['_count'] as Map<String, dynamic>? ?? {};
    return DashboardProjectItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'IN_PROGRESS',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      taskCount: (counts['tasks'] as num?)?.toInt() ?? 0,
      featureCount: (counts['features'] as num?)?.toInt() ?? 0,
      bugCount: (counts['bugs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status, progress, taskCount, featureCount, bugCount];
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
    final latest = json['latestWorkout'] as Map<String, dynamic>?;
    return DashboardFitnessSection(
      workoutsThisWeekCount: json['workoutsThisWeekCount'] ?? 0,
      targetWorkouts: json['targetWorkouts'] ?? 4,
      workedOutToday: json['workedOutToday'] ?? false,
      latestWorkoutName: latest?['name'],
    );
  }

  @override
  List<Object?> get props => [workoutsThisWeekCount, targetWorkouts, workedOutToday, latestWorkoutName];
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
  List<Object?> get props => [spentThisMonth, totalBudgetCap, budgetRemaining, isWarning];
}

// ==========================================
// Global Activity Item
// ==========================================

class GlobalActivityItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'TASK', 'HABIT', 'FITNESS', 'FINANCE', 'FOCUS'
  final DateTime timestamp;

  const GlobalActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, title, subtitle, category, timestamp];
}

// ==========================================
// Full Dashboard Feed
// ==========================================

class DashboardFeedModel extends Equatable {
  final String userName;
  final String? userAvatarUrl;
  final LifeScoreModel lifeScore;
  final DashboardHabitsSection habits;
  final List<DashboardTaskItem> tasksDueToday;
  final List<DashboardProjectItem> activeProjects;
  final DashboardFitnessSection fitness;
  final DashboardFinanceSection finance;
  final String? aiRecommendation;
  final DateTime? generatedAt;

  const DashboardFeedModel({
    required this.userName,
    this.userAvatarUrl,
    required this.lifeScore,
    required this.habits,
    required this.tasksDueToday,
    this.activeProjects = const [],
    required this.fitness,
    required this.finance,
    this.aiRecommendation,
    this.generatedAt,
  });

  List<GlobalActivityItem> get recentActivities {
    final list = <GlobalActivityItem>[];
    final now = generatedAt ?? DateTime.now();

    // Completed tasks today
    for (final task in tasksDueToday.where((t) => t.isCompleted)) {
      list.add(GlobalActivityItem(
        id: 'task-${task.id}',
        title: 'Completed task: ${task.title}',
        subtitle: task.projectTitle != null ? 'Project: ${task.projectTitle}' : 'Task completed',
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
        title: 'Completed workout${fitness.latestWorkoutName != null ? ': ${fitness.latestWorkoutName}' : ''}',
        subtitle: '${fitness.workoutsThisWeekCount}/${fitness.targetWorkouts} workouts this week',
        category: 'FITNESS',
        timestamp: now,
      ));
    }

    return list;
  }

  factory DashboardFeedModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final timeline = json['timeline'] as Map<String, dynamic>? ?? {};
    final tasksList = (timeline['tasksDueToday'] as List<dynamic>? ?? [])
        .map((t) => DashboardTaskItem.fromJson(Map<String, dynamic>.from(t)))
        .toList();
    final projectsList = (json['projects'] as List<dynamic>? ?? [])
        .map((p) => DashboardProjectItem.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    return DashboardFeedModel(
      userName: user['name'] ?? 'User',
      userAvatarUrl: user['avatarUrl'],
      lifeScore: LifeScoreModel.fromJson(
        Map<String, dynamic>.from(json['lifeScore'] ?? {}),
      ),
      habits: DashboardHabitsSection.fromJson(
        Map<String, dynamic>.from(json['habits'] ?? {}),
      ),
      tasksDueToday: tasksList,
      activeProjects: projectsList,
      fitness: DashboardFitnessSection.fromJson(
        Map<String, dynamic>.from(json['fitness'] ?? {}),
      ),
      finance: DashboardFinanceSection.fromJson(
        Map<String, dynamic>.from(json['finance'] ?? {}),
      ),
      aiRecommendation: json['aiRecommendation'] is String
          ? json['aiRecommendation']
          : null,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        userAvatarUrl,
        lifeScore,
        habits,
        tasksDueToday,
        activeProjects,
        fitness,
        finance,
        aiRecommendation,
      ];
}
