class SetEntryModel {
  final String id;
  final int setNumber;
  final double weightKg;
  final int repetitions;
  final double? rpe;
  final int? rir;
  final double? estimatedOneRepMax;
  final bool isPR;
  final String? notes;

  SetEntryModel({
    required this.id,
    required this.setNumber,
    required this.weightKg,
    required this.repetitions,
    this.rpe,
    this.rir,
    this.estimatedOneRepMax,
    required this.isPR,
    this.notes,
  });

  factory SetEntryModel.fromJson(Map<String, dynamic> json) {
    return SetEntryModel(
      id: json['id'] ?? '',
      setNumber: json['setNumber'] ?? 1,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      repetitions: json['repetitions'] ?? 0,
      rpe: (json['rpe'] as num?)?.toDouble(),
      rir: json['rir'] as int?,
      estimatedOneRepMax: (json['estimatedOneRepMax'] as num?)?.toDouble(),
      isPR: json['isPR'] == true,
      notes: json['notes'],
    );
  }
}

class WorkoutExerciseModel {
  final String id;
  final int order;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String equipmentType;
  final List<SetEntryModel> sets;

  WorkoutExerciseModel({
    required this.id,
    required this.order,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.equipmentType,
    required this.sets,
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    final ex = json['exercise'] as Map<String, dynamic>? ?? {};
    final setsList = (json['sets'] as List?)
            ?.map((s) => SetEntryModel.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];

    return WorkoutExerciseModel(
      id: json['id'] ?? '',
      order: json['order'] ?? 1,
      exerciseId: json['exerciseId'] ?? ex['id'] ?? '',
      exerciseName: ex['name'] ?? 'Exercise',
      muscleGroup: ex['muscleGroup'] ?? ex['category'] ?? 'CHEST',
      equipmentType: ex['equipmentType'] ?? 'BARBELL',
      sets: setsList,
    );
  }
}

class WorkoutDetailModel {
  final String id;
  final String name;
  final String date;
  final int durationMinutes;
  final String? notes;
  final int totalSets;
  final double totalVolume;
  final int prCount;
  final List<WorkoutExerciseModel> exercises;

  WorkoutDetailModel({
    required this.id,
    required this.name,
    required this.date,
    required this.durationMinutes,
    this.notes,
    required this.totalSets,
    required this.totalVolume,
    required this.prCount,
    required this.exercises,
  });

  factory WorkoutDetailModel.fromJson(Map<String, dynamic> json) {
    final exList = (json['exercises'] as List?)
            ?.map((e) => WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return WorkoutDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Workout',
      date: json['date'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 60,
      notes: json['notes'],
      totalSets: json['totalSets'] ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      prCount: json['prCount'] ?? 0,
      exercises: exList,
    );
  }
}

class ExerciseCatalogModel {
  final String id;
  final String name;
  final String category;
  final String muscleGroup;
  final String equipmentType;
  final bool isCustom;
  final String? notes;

  ExerciseCatalogModel({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipmentType,
    required this.isCustom,
    this.notes,
  });

  factory ExerciseCatalogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseCatalogModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'CHEST',
      muscleGroup: json['muscleGroup'] ?? json['category'] ?? 'CHEST',
      equipmentType: json['equipmentType'] ?? 'BARBELL',
      isCustom: json['isCustom'] == true,
      notes: json['notes'],
    );
  }
}

class ExerciseSessionHistoryModel {
  final String workoutId;
  final String workoutName;
  final String date;
  final double maxWeight;
  final double maxEst1RM;
  final double totalVolume;
  final List<SetEntryModel> sets;

  ExerciseSessionHistoryModel({
    required this.workoutId,
    required this.workoutName,
    required this.date,
    required this.maxWeight,
    required this.maxEst1RM,
    required this.totalVolume,
    required this.sets,
  });

  factory ExerciseSessionHistoryModel.fromJson(Map<String, dynamic> json) {
    final setsList = (json['sets'] as List?)
            ?.map((s) => SetEntryModel.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];

    return ExerciseSessionHistoryModel(
      workoutId: json['workoutId'] ?? '',
      workoutName: json['workoutName'] ?? '',
      date: json['date'] ?? '',
      maxWeight: (json['maxWeight'] as num?)?.toDouble() ?? 0.0,
      maxEst1RM: (json['maxEst1RM'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      sets: setsList,
    );
  }
}

class ExerciseHistoryModel {
  final ExerciseCatalogModel exercise;
  final PersonalRecordModel? currentPR;
  final ExerciseSessionHistoryModel? lastPerformance;
  final int totalSessions;
  final List<ExerciseSessionHistoryModel> history;

  ExerciseHistoryModel({
    required this.exercise,
    this.currentPR,
    this.lastPerformance,
    required this.totalSessions,
    required this.history,
  });

  factory ExerciseHistoryModel.fromJson(Map<String, dynamic> json) {
    final ex = ExerciseCatalogModel.fromJson(Map<String, dynamic>.from(json['exercise']));
    final pr = json['currentPR'] != null
        ? PersonalRecordModel.fromJson(Map<String, dynamic>.from(json['currentPR']))
        : null;
    final lastPerf = json['lastPerformance'] != null
        ? ExerciseSessionHistoryModel.fromJson(Map<String, dynamic>.from(json['lastPerformance']))
        : null;
    final hist = (json['history'] as List?)
            ?.map((h) => ExerciseSessionHistoryModel.fromJson(Map<String, dynamic>.from(h)))
            .toList() ??
        [];

    return ExerciseHistoryModel(
      exercise: ex,
      currentPR: pr,
      lastPerformance: lastPerf,
      totalSessions: json['totalSessions'] ?? 0,
      history: hist,
    );
  }
}

class PersonalRecordModel {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final double weightKg;
  final int repetitions;
  final double calculatedOneRepMax;
  final String achievedDate;

  PersonalRecordModel({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.weightKg,
    required this.repetitions,
    required this.calculatedOneRepMax,
    required this.achievedDate,
  });

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    final ex = json['exercise'] as Map<String, dynamic>? ?? {};
    return PersonalRecordModel(
      id: json['id'] ?? '',
      exerciseId: json['exerciseId'] ?? ex['id'] ?? '',
      exerciseName: ex['name'] ?? 'Exercise',
      muscleGroup: ex['muscleGroup'] ?? ex['category'] ?? 'CHEST',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      repetitions: json['repetitions'] ?? 1,
      calculatedOneRepMax: (json['calculatedOneRepMax'] as num?)?.toDouble() ?? 0.0,
      achievedDate: json['achievedDate'] ?? '',
    );
  }
}

class MuscleVolumeModel {
  final String muscleGroup;
  final double volumeKg;
  final double percentage;

  MuscleVolumeModel({
    required this.muscleGroup,
    required this.volumeKg,
    required this.percentage,
  });

  factory MuscleVolumeModel.fromJson(Map<String, dynamic> json) {
    return MuscleVolumeModel(
      muscleGroup: json['muscleGroup'] ?? 'CHEST',
      volumeKg: (json['volumeKg'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GymStatsModel {
  final int workoutsThisWeek;
  final int weeklyTarget;
  final bool workedOutToday;
  final double totalLifetimeTonnage;
  final List<MuscleVolumeModel> muscleDistribution;

  GymStatsModel({
    required this.workoutsThisWeek,
    required this.weeklyTarget,
    required this.workedOutToday,
    required this.totalLifetimeTonnage,
    required this.muscleDistribution,
  });

  factory GymStatsModel.fromJson(Map<String, dynamic> json) {
    final dist = (json['muscleDistribution'] as List?)
            ?.map((m) => MuscleVolumeModel.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        [];

    return GymStatsModel(
      workoutsThisWeek: json['workoutsThisWeek'] ?? 0,
      weeklyTarget: json['weeklyTarget'] ?? 4,
      workedOutToday: json['workedOutToday'] == true,
      totalLifetimeTonnage: (json['totalLifetimeTonnage'] as num?)?.toDouble() ?? 0.0,
      muscleDistribution: dist,
    );
  }
}

class WorkoutTemplateExerciseModel {
  final String id;
  final int order;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int targetSets;
  final int targetReps;
  final double? targetRpe;
  final List<SetEntryModel> lastPerformance;

  WorkoutTemplateExerciseModel({
    required this.id,
    required this.order,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.targetSets,
    required this.targetReps,
    this.targetRpe,
    required this.lastPerformance,
  });

  factory WorkoutTemplateExerciseModel.fromJson(Map<String, dynamic> json) {
    final ex = json['exercise'] as Map<String, dynamic>? ?? {};
    final lastPerf = (json['lastPerformance'] as List?)
            ?.map((s) => SetEntryModel.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];

    return WorkoutTemplateExerciseModel(
      id: json['id'] ?? '',
      order: json['order'] ?? 1,
      exerciseId: json['exerciseId'] ?? ex['id'] ?? '',
      exerciseName: ex['name'] ?? 'Exercise',
      muscleGroup: ex['muscleGroup'] ?? ex['category'] ?? 'CHEST',
      targetSets: json['targetSets'] ?? 3,
      targetReps: json['targetReps'] ?? 10,
      targetRpe: (json['targetRpe'] as num?)?.toDouble(),
      lastPerformance: lastPerf,
    );
  }
}

class WorkoutTemplateModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final List<WorkoutTemplateExerciseModel> exercises;

  WorkoutTemplateModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.exercises,
  });

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) {
    final exList = (json['exercises'] as List?)
            ?.map((e) => WorkoutTemplateExerciseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return WorkoutTemplateModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'PPL',
      exercises: exList,
    );
  }
}

class BodyMetricModel {
  final String id;
  final String date;
  final double weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? armsCm;
  final double? legsCm;
  final String? photoUrl;
  final String? notes;
  final double sevenDayAverageKg;

  BodyMetricModel({
    required this.id,
    required this.date,
    required this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.armsCm,
    this.legsCm,
    this.photoUrl,
    this.notes,
    required this.sevenDayAverageKg,
  });

  factory BodyMetricModel.fromJson(Map<String, dynamic> json) {
    return BodyMetricModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      armsCm: (json['armsCm'] as num?)?.toDouble(),
      legsCm: (json['legsCm'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'],
      notes: json['notes'],
      sevenDayAverageKg: (json['sevenDayAverageKg'] as num?)?.toDouble() ?? (json['weightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GymInsightModel {
  final String type;
  final String title;
  final String message;
  final String severity;

  GymInsightModel({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
  });

  factory GymInsightModel.fromJson(Map<String, dynamic> json) {
    return GymInsightModel(
      type: json['type'] ?? 'INFO',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'INFO',
    );
  }
}
