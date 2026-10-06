import 'package:equatable/equatable.dart';

class HabitCategoryModel extends Equatable {
  final String id;
  final String name;
  final String? color;
  final String? icon;

  const HabitCategoryModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory HabitCategoryModel.fromJson(Map<String, dynamic> json) {
    return HabitCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
    };
  }

  @override
  List<Object?> get props => [id, name, color, icon];
}

class HabitLogModel extends Equatable {
  final String id;
  final String habitId;
  final String date;
  final bool isCompleted;
  final bool wasFrozen;
  final int value;
  final String? notes;

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    this.wasFrozen = false,
    required this.value,
    this.notes,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['id'] ?? '',
      habitId: json['habitId'] ?? '',
      date: json['date'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      wasFrozen: json['wasFrozen'] ?? false,
      value: json['value'] ?? 1,
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props =>
      [id, habitId, date, isCompleted, wasFrozen, value, notes];
}

class HabitModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String frequency;
  final int? targetFrequencyCount;
  final String? targetFrequencyPeriod;
  final String targetType;
  final int targetValue;
  final String? reminderTime;
  final int currentStreak;
  final int longestStreak;
  final int streakFreezes;
  final String difficulty;
  final double weight;
  final bool isActive;
  final bool isCompletedToday;
  final int weeklyCompletionsCount;
  final HabitCategoryModel? category;
  final HabitLogModel? todayLog;

  const HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.frequency,
    this.targetFrequencyCount,
    this.targetFrequencyPeriod,
    required this.targetType,
    required this.targetValue,
    this.reminderTime,
    required this.currentStreak,
    required this.longestStreak,
    this.streakFreezes = 2,
    this.difficulty = 'MEDIUM',
    this.weight = 1.0,
    required this.isActive,
    required this.isCompletedToday,
    this.weeklyCompletionsCount = 0,
    this.category,
    this.todayLog,
  });

  bool get isWeeklyCount =>
      frequency == 'CUSTOM' ||
      targetFrequencyPeriod == 'WEEK' ||
      (targetFrequencyCount != null && targetFrequencyCount! > 1);

  bool get isNumericProgress =>
      targetType == 'COUNT' || targetType == 'DURATION';

  int get currentTodayValue =>
      todayLog?.value ?? (isCompletedToday ? targetValue : 0);

  double get progressRatio {
    if (targetValue <= 0) return isCompletedToday ? 1.0 : 0.0;
    return (currentTodayValue / targetValue).clamp(0.0, 1.0);
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      frequency: json['frequency'] ?? 'DAILY',
      targetFrequencyCount: json['targetFrequencyCount'],
      targetFrequencyPeriod: json['targetFrequencyPeriod'],
      targetType: json['targetType'] ?? 'CHECKBOX',
      targetValue: json['targetValue'] ?? 1,
      reminderTime: json['reminderTime'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      streakFreezes: json['streakFreezes'] ?? 2,
      difficulty: json['difficulty'] ?? 'MEDIUM',
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      isActive: json['isActive'] ?? true,
      isCompletedToday: json['isCompletedToday'] ?? false,
      weeklyCompletionsCount: json['weeklyCompletionsCount'] ?? 0,
      category: json['category'] != null
          ? HabitCategoryModel.fromJson(
              Map<String, dynamic>.from(json['category']))
          : null,
      todayLog: json['todayLog'] != null
          ? HabitLogModel.fromJson(Map<String, dynamic>.from(json['todayLog']))
          : null,
    );
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? frequency,
    int? targetFrequencyCount,
    String? targetFrequencyPeriod,
    String? targetType,
    int? targetValue,
    String? reminderTime,
    int? currentStreak,
    int? longestStreak,
    int? streakFreezes,
    String? difficulty,
    double? weight,
    bool? isActive,
    bool? isCompletedToday,
    int? weeklyCompletionsCount,
    HabitCategoryModel? category,
    HabitLogModel? todayLog,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      targetFrequencyCount: targetFrequencyCount ?? this.targetFrequencyCount,
      targetFrequencyPeriod:
          targetFrequencyPeriod ?? this.targetFrequencyPeriod,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      reminderTime: reminderTime ?? this.reminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      difficulty: difficulty ?? this.difficulty,
      weight: weight ?? this.weight,
      isActive: isActive ?? this.isActive,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      weeklyCompletionsCount:
          weeklyCompletionsCount ?? this.weeklyCompletionsCount,
      category: category ?? this.category,
      todayLog: todayLog ?? this.todayLog,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        frequency,
        targetFrequencyCount,
        targetFrequencyPeriod,
        targetType,
        targetValue,
        reminderTime,
        currentStreak,
        longestStreak,
        streakFreezes,
        difficulty,
        weight,
        isActive,
        isCompletedToday,
        weeklyCompletionsCount,
        category,
        todayLog,
      ];
}

class RoutineItemModel extends Equatable {
  final String id;
  final int order;
  final String habitId;
  final String habitName;
  final String targetType;
  final int targetValue;
  final int currentStreak;
  final bool isCompletedToday;

  const RoutineItemModel({
    required this.id,
    required this.order,
    required this.habitId,
    required this.habitName,
    required this.targetType,
    required this.targetValue,
    required this.currentStreak,
    required this.isCompletedToday,
  });

  factory RoutineItemModel.fromJson(Map<String, dynamic> json) {
    return RoutineItemModel(
      id: json['id'] ?? '',
      order: json['order'] ?? 0,
      habitId: json['habitId'] ?? '',
      habitName: json['habitName'] ?? '',
      targetType: json['targetType'] ?? 'CHECKBOX',
      targetValue: json['targetValue'] ?? 1,
      currentStreak: json['currentStreak'] ?? 0,
      isCompletedToday: json['isCompletedToday'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        order,
        habitId,
        habitName,
        targetType,
        targetValue,
        currentStreak,
        isCompletedToday,
      ];
}

class RoutineModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final String? targetTime;
  final int totalHabits;
  final int completedCount;
  final bool isCompletedToday;
  final List<RoutineItemModel> items;

  const RoutineModel({
    required this.id,
    required this.name,
    this.description,
    this.icon = 'routine',
    this.color = '#3B82F6',
    this.targetTime,
    required this.totalHabits,
    required this.completedCount,
    required this.isCompletedToday,
    this.items = const [],
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? 'routine',
      color: json['color'] ?? '#3B82F6',
      targetTime: json['targetTime'],
      totalHabits: json['totalHabits'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
      isCompletedToday: json['isCompletedToday'] ?? false,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) =>
                  RoutineItemModel.fromJson(Map<String, dynamic>.from(i)))
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        color,
        targetTime,
        totalHabits,
        completedCount,
        isCompletedToday,
        items,
      ];
}

class HabitCorrelationModel extends Equatable {
  final String habitAId;
  final String habitAName;
  final String habitBId;
  final String habitBName;
  final double probBGivenA;
  final double probBGivenNotA;
  final int liftPercent;
  final String insightText;

  const HabitCorrelationModel({
    required this.habitAId,
    required this.habitAName,
    required this.habitBId,
    required this.habitBName,
    required this.probBGivenA,
    required this.probBGivenNotA,
    required this.liftPercent,
    required this.insightText,
  });

  factory HabitCorrelationModel.fromJson(Map<String, dynamic> json) {
    return HabitCorrelationModel(
      habitAId: json['habitAId'] ?? '',
      habitAName: json['habitAName'] ?? '',
      habitBId: json['habitBId'] ?? '',
      habitBName: json['habitBName'] ?? '',
      probBGivenA: (json['probBGivenA'] as num?)?.toDouble() ?? 0.0,
      probBGivenNotA: (json['probBGivenNotA'] as num?)?.toDouble() ?? 0.0,
      liftPercent: json['liftPercent'] ?? 0,
      insightText: json['insightText'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        habitAId,
        habitAName,
        habitBId,
        habitBName,
        probBGivenA,
        probBGivenNotA,
        liftPercent,
        insightText,
      ];
}
