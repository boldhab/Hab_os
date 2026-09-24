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
  final int value;
  final String? notes;

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    required this.value,
    this.notes,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['id'] ?? '',
      habitId: json['habitId'] ?? '',
      date: json['date'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      value: json['value'] ?? 1,
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props => [id, habitId, date, isCompleted, value, notes];
}

class HabitModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String frequency;
  final String targetType;
  final int targetValue;
  final String? reminderTime;
  final int currentStreak;
  final int longestStreak;
  final bool isActive;
  final bool isCompletedToday;
  final HabitCategoryModel? category;
  final HabitLogModel? todayLog;

  const HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.frequency,
    required this.targetType,
    required this.targetValue,
    this.reminderTime,
    required this.currentStreak,
    required this.longestStreak,
    required this.isActive,
    required this.isCompletedToday,
    this.category,
    this.todayLog,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      frequency: json['frequency'] ?? 'DAILY',
      targetType: json['targetType'] ?? 'CHECKBOX',
      targetValue: json['targetValue'] ?? 1,
      reminderTime: json['reminderTime'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      isActive: json['isActive'] ?? true,
      isCompletedToday: json['isCompletedToday'] ?? false,
      category: json['category'] != null
          ? HabitCategoryModel.fromJson(Map<String, dynamic>.from(json['category']))
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
    String? targetType,
    int? targetValue,
    String? reminderTime,
    int? currentStreak,
    int? longestStreak,
    bool? isActive,
    bool? isCompletedToday,
    HabitCategoryModel? category,
    HabitLogModel? todayLog,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      reminderTime: reminderTime ?? this.reminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isActive: isActive ?? this.isActive,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
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
        targetType,
        targetValue,
        reminderTime,
        currentStreak,
        longestStreak,
        isActive,
        isCompletedToday,
        category,
        todayLog,
      ];
}
