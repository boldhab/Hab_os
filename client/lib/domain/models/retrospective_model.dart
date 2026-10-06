import 'package:equatable/equatable.dart';

class RetrospectiveTask extends Equatable {
  final String id;
  final String title;
  final String priority;

  const RetrospectiveTask({
    required this.id,
    required this.title,
    required this.priority,
  });

  factory RetrospectiveTask.fromJson(Map<String, dynamic> json) {
    return RetrospectiveTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Task',
      priority: json['priority']?.toString() ?? 'MEDIUM',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'priority': priority,
  };

  @override
  List<Object?> get props => [id, title, priority];
}

class MetricComparison extends Equatable {
  final String metric;
  final double current;
  final double previous;
  final String unit;
  final double deltaPercentage;

  const MetricComparison({
    required this.metric,
    required this.current,
    required this.previous,
    required this.unit,
    required this.deltaPercentage,
  });

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    return MetricComparison(
      metric: json['metric']?.toString() ?? '',
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      previous: (json['previous'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? '',
      deltaPercentage: (json['deltaPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'metric': metric,
    'current': current,
    'previous': previous,
    'unit': unit,
    'deltaPercentage': deltaPercentage,
  };

  @override
  List<Object?> get props => [metric, current, previous, unit, deltaPercentage];
}

class CategorySpending extends Equatable {
  final String name;
  final String color;
  final double amount;
  final double percentage;

  const CategorySpending({
    required this.name,
    required this.color,
    required this.amount,
    required this.percentage,
  });

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      name: json['name']?.toString() ?? 'General',
      color: json['color']?.toString() ?? '#EF4444',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [name, color, amount, percentage];
}

class CourseStudyTime extends Equatable {
  final String courseName;
  final String? code;
  final String color;
  final double hours;
  final int sessionsCount;

  const CourseStudyTime({
    required this.courseName,
    this.code,
    required this.color,
    required this.hours,
    required this.sessionsCount,
  });

  factory CourseStudyTime.fromJson(Map<String, dynamic> json) {
    return CourseStudyTime(
      courseName: json['courseName']?.toString() ?? 'General Study',
      code: json['code']?.toString(),
      color: json['color']?.toString() ?? '#8B5CF6',
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [courseName, code, color, hours, sessionsCount];
}

class StrengthProgressionPoint extends Equatable {
  final String exerciseName;
  final double weightKg;
  final int repetitions;
  final double oneRepMax;
  final String date;

  const StrengthProgressionPoint({
    required this.exerciseName,
    required this.weightKg,
    required this.repetitions,
    required this.oneRepMax,
    required this.date,
  });

  factory StrengthProgressionPoint.fromJson(Map<String, dynamic> json) {
    return StrengthProgressionPoint(
      exerciseName: json['exerciseName']?.toString() ?? 'Exercise',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 1,
      oneRepMax: (json['oneRepMax'] as num?)?.toDouble() ?? 0.0,
      date: json['date']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [exerciseName, weightKg, repetitions, oneRepMax, date];
}

class ProductivityTimeDistribution extends Equatable {
  final double morningHours;
  final double afternoonHours;
  final double eveningHours;
  final double nightHours;
  final String peakWindow;

  const ProductivityTimeDistribution({
    required this.morningHours,
    required this.afternoonHours,
    required this.eveningHours,
    required this.nightHours,
    required this.peakWindow,
  });

  factory ProductivityTimeDistribution.fromJson(Map<String, dynamic> json) {
    return ProductivityTimeDistribution(
      morningHours: (json['morningHours'] as num?)?.toDouble() ?? 0.0,
      afternoonHours: (json['afternoonHours'] as num?)?.toDouble() ?? 0.0,
      eveningHours: (json['eveningHours'] as num?)?.toDouble() ?? 0.0,
      nightHours: (json['nightHours'] as num?)?.toDouble() ?? 0.0,
      peakWindow: json['peakWindow']?.toString() ?? 'Morning',
    );
  }

  @override
  List<Object?> get props => [morningHours, afternoonHours, eveningHours, nightHours, peakWindow];
}

class MultiDomainMetrics extends Equatable {
  final double studyHours;
  final int studySessionsCount;
  final List<CourseStudyTime> studyByCourse;
  final int totalCommits;
  final int codingStreak;
  final int leetcodeTotal;
  final int leetcodeEasy;
  final int leetcodeMedium;
  final int leetcodeHard;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final int transactionCount;
  final List<CategorySpending> spendingByCategory;
  final int gymWorkoutsCount;
  final List<StrengthProgressionPoint> strengthProgression;
  final ProductivityTimeDistribution? productivity;

  const MultiDomainMetrics({
    required this.studyHours,
    required this.studySessionsCount,
    this.studyByCourse = const [],
    required this.totalCommits,
    required this.codingStreak,
    required this.leetcodeTotal,
    required this.leetcodeEasy,
    required this.leetcodeMedium,
    required this.leetcodeHard,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.transactionCount,
    this.spendingByCategory = const [],
    this.gymWorkoutsCount = 0,
    this.strengthProgression = const [],
    this.productivity,
  });

  factory MultiDomainMetrics.fromJson(Map<String, dynamic> json) {
    final study = json['study'] as Map<String, dynamic>? ?? {};
    final coding = json['coding'] as Map<String, dynamic>? ?? {};
    final finance = json['finance'] as Map<String, dynamic>? ?? {};
    final gym = json['gym'] as Map<String, dynamic>? ?? {};
    final prod = json['productivity'] as Map<String, dynamic>?;

    final byCourse = <CourseStudyTime>[];
    if (study['byCourse'] is List) {
      for (final item in study['byCourse'] as List) {
        if (item is Map) {
          byCourse.add(CourseStudyTime.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final spending = <CategorySpending>[];
    if (finance['spendingByCategory'] is List) {
      for (final item in finance['spendingByCategory'] as List) {
        if (item is Map) {
          spending.add(CategorySpending.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final strength = <StrengthProgressionPoint>[];
    if (gym['strengthProgression'] is List) {
      for (final item in gym['strengthProgression'] as List) {
        if (item is Map) {
          strength.add(StrengthProgressionPoint.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return MultiDomainMetrics(
      studyHours: (study['totalHours'] as num?)?.toDouble() ?? 0.0,
      studySessionsCount: (study['sessionCount'] as num?)?.toInt() ?? 0,
      studyByCourse: byCourse,
      totalCommits: (coding['totalCommits'] as num?)?.toInt() ?? 0,
      codingStreak: (coding['currentStreak'] as num?)?.toInt() ?? 0,
      leetcodeTotal: (coding['leetcodeTotal'] as num?)?.toInt() ?? 0,
      leetcodeEasy: (coding['leetcodeEasy'] as num?)?.toInt() ?? 0,
      leetcodeMedium: (coding['leetcodeMedium'] as num?)?.toInt() ?? 0,
      leetcodeHard: (coding['leetcodeHard'] as num?)?.toInt() ?? 0,
      totalIncome: (finance['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (finance['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netSavings: (finance['netSavings'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (finance['transactionCount'] as num?)?.toInt() ?? 0,
      spendingByCategory: spending,
      gymWorkoutsCount: (gym['workoutsCount'] as num?)?.toInt() ?? 0,
      strengthProgression: strength,
      productivity: prod != null ? ProductivityTimeDistribution.fromJson(prod) : null,
    );
  }

  @override
  List<Object?> get props => [
    studyHours,
    studySessionsCount,
    studyByCourse,
    totalCommits,
    codingStreak,
    leetcodeTotal,
    leetcodeEasy,
    leetcodeMedium,
    leetcodeHard,
    totalIncome,
    totalExpense,
    netSavings,
    transactionCount,
    spendingByCategory,
    gymWorkoutsCount,
    strengthProgression,
    productivity,
  ];
}

class RetrospectiveModel extends Equatable {
  final String period;
  final double totalFocusHours;
  final double totalTrackedHours;
  final int completedTasksCount;
  final int workoutsCount;
  final int habitsCompletedCount;
  final Map<String, double> dailyFocusHours;
  final List<RetrospectiveTask> completedTasks;
  final List<MetricComparison> comparison;
  final MultiDomainMetrics? multiDomain;

  const RetrospectiveModel({
    this.period = 'WEEKLY',
    required this.totalFocusHours,
    required this.totalTrackedHours,
    required this.completedTasksCount,
    required this.workoutsCount,
    required this.habitsCompletedCount,
    required this.dailyFocusHours,
    required this.completedTasks,
    this.comparison = const [],
    this.multiDomain,
  });

  factory RetrospectiveModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final daily = <String, double>{};
    if (json['dailyFocusHours'] is Map) {
      (json['dailyFocusHours'] as Map).forEach((k, v) {
        if (v is num) daily[k.toString()] = v.toDouble();
      });
    }

    final tasksList = <RetrospectiveTask>[];
    if (json['completedTasks'] is List) {
      for (final item in json['completedTasks'] as List) {
        if (item is Map) {
          tasksList.add(RetrospectiveTask.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final comparisonList = <MetricComparison>[];
    if (json['comparison'] is List) {
      for (final item in json['comparison'] as List) {
        if (item is Map) {
          comparisonList.add(MetricComparison.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    MultiDomainMetrics? multiDomain;
    if (json['multiDomain'] is Map) {
      multiDomain = MultiDomainMetrics.fromJson(
        Map<String, dynamic>.from(json['multiDomain'] as Map),
      );
    }

    return RetrospectiveModel(
      period: json['period']?.toString() ?? 'WEEKLY',
      totalFocusHours: (summary['totalFocusHours'] as num?)?.toDouble() ?? 0.0,
      totalTrackedHours:
          (summary['totalTrackedHours'] as num?)?.toDouble() ?? 0.0,
      completedTasksCount:
          (summary['completedTasksCount'] as num?)?.toInt() ?? tasksList.length,
      workoutsCount: (summary['workoutsCount'] as num?)?.toInt() ?? 0,
      habitsCompletedCount:
          (summary['habitsCompletedCount'] as num?)?.toInt() ?? 0,
      dailyFocusHours: daily,
      completedTasks: tasksList,
      comparison: comparisonList,
      multiDomain: multiDomain,
    );
  }

  @override
  List<Object?> get props => [
    period,
    totalFocusHours,
    totalTrackedHours,
    completedTasksCount,
    workoutsCount,
    habitsCompletedCount,
    dailyFocusHours,
    completedTasks,
    comparison,
    multiDomain,
  ];
}

class TimeEntryModel extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;
  final String? taskId;
  final String? taskTitle;
  final String? taskPriority;

  const TimeEntryModel({
    required this.id,
    required this.startTime,
    this.endTime,
    this.duration,
    this.taskId,
    this.taskTitle,
    this.taskPriority,
  });

  bool get isActive => endTime == null;

  factory TimeEntryModel.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>?;

    return TimeEntryModel(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      duration: (json['duration'] as num?)?.toInt(),
      taskId: json['taskId']?.toString(),
      taskTitle: task?['title']?.toString(),
      taskPriority: task?['priority']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, startTime, endTime, duration, taskId, taskTitle, taskPriority];
}
