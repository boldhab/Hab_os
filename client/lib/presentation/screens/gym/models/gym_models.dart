class SetEntryModel {
  final String id;
  final int setNumber;
  final double weightKg;
  final int repetitions;
  final double? rpe;
  final int? rir;
  final double? estimatedOneRepMax;
  final bool isPR;
  final String tag;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? caloriesBurned;
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
    this.tag = 'N',
    this.durationSeconds,
    this.distanceMeters,
    this.caloriesBurned,
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
      tag: json['tag'] ?? 'N',
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      caloriesBurned: json['caloriesBurned'] as int?,
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
  final String category;
  final String equipmentType;
  final List<SetEntryModel> sets;

  WorkoutExerciseModel({
    required this.id,
    required this.order,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.category = 'CHEST',
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
      category: ex['category'] ?? 'CHEST',
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
            ?.map((e) =>
                WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    double volume = (json['totalVolume'] as num?)?.toDouble() ??
        (json['totalTonnage'] as num?)?.toDouble() ??
        0.0;
    int sets = json['totalSets'] as int? ??
        json['totalSetsCount'] as int? ??
        0;
    int prs = json['prCount'] as int? ??
        (json['detectedPRs'] is List ? (json['detectedPRs'] as List).length : 0);

    if (volume == 0.0 || sets == 0) {
      double calcVol = 0.0;
      int calcSets = 0;
      int calcPrs = 0;
      for (final we in exList) {
        for (final s in we.sets) {
          calcSets++;
          calcVol += s.weightKg * s.repetitions;
          if (s.isPR) calcPrs++;
        }
      }
      if (volume == 0.0) volume = calcVol;
      if (sets == 0) sets = calcSets;
      if (prs == 0) prs = calcPrs;
    }

    return WorkoutDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Workout',
      date: json['date'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 60,
      notes: json['notes'],
      totalSets: sets,
      totalVolume: volume,
      prCount: prs,
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
    final ex = ExerciseCatalogModel.fromJson(
        Map<String, dynamic>.from(json['exercise']));
    final pr = json['currentPR'] != null
        ? PersonalRecordModel.fromJson(
            Map<String, dynamic>.from(json['currentPR']))
        : null;
    final lastPerf = json['lastPerformance'] != null
        ? ExerciseSessionHistoryModel.fromJson(
            Map<String, dynamic>.from(json['lastPerformance']))
        : null;
    final hist = (json['history'] as List?)
            ?.map((h) => ExerciseSessionHistoryModel.fromJson(
                Map<String, dynamic>.from(h)))
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
      calculatedOneRepMax:
          (json['calculatedOneRepMax'] as num?)?.toDouble() ?? 0.0,
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

class MuscleHypertrophySummaryModel {
  final String muscleGroup;
  final double stimulativeVolumeKg;
  final double totalStructuralVolumeKg;
  final int effectiveSetsCount;
  final int totalSetsCount;
  final double efficiencyPercentage;

  MuscleHypertrophySummaryModel({
    required this.muscleGroup,
    required this.stimulativeVolumeKg,
    required this.totalStructuralVolumeKg,
    required this.effectiveSetsCount,
    required this.totalSetsCount,
    required this.efficiencyPercentage,
  });

  factory MuscleHypertrophySummaryModel.fromJson(Map<String, dynamic> json) {
    return MuscleHypertrophySummaryModel(
      muscleGroup: json['muscleGroup'] ?? 'CHEST',
      stimulativeVolumeKg: (json['stimulativeVolumeKg'] as num?)?.toDouble() ?? 0.0,
      totalStructuralVolumeKg: (json['totalStructuralVolumeKg'] as num?)?.toDouble() ?? 0.0,
      effectiveSetsCount: json['effectiveSetsCount'] ?? 0,
      totalSetsCount: json['totalSetsCount'] ?? 0,
      efficiencyPercentage: (json['efficiencyPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GymStatsModel {
  final int workoutsThisWeek;
  final int weeklyTarget;
  final bool workedOutToday;
  final double totalLifetimeTonnage;
  final int calisthenicsTotalReps;
  final double calisthenicsVolumeKg;
  final double stimulativeWorkingVolumeKg;
  final double totalStructuralVolumeKg;
  final double warmupVolumeKg;
  final int stimulativeSetsCount;
  final int warmupSetsCount;
  final double hypertrophicEfficiencyPercentage;
  final List<MuscleHypertrophySummaryModel> hypertrophyMuscleBreakdown;
  final List<MuscleVolumeModel> muscleDistribution;
  final List<WeeklyVolumeBucketModel> weeklyVolumeTrend;

  int get totalSetsCount => stimulativeSetsCount + warmupSetsCount;

  GymStatsModel({
    required this.workoutsThisWeek,
    required this.weeklyTarget,
    required this.workedOutToday,
    required this.totalLifetimeTonnage,
    this.calisthenicsTotalReps = 0,
    this.calisthenicsVolumeKg = 0.0,
    this.stimulativeWorkingVolumeKg = 0.0,
    this.totalStructuralVolumeKg = 0.0,
    this.warmupVolumeKg = 0.0,
    this.stimulativeSetsCount = 0,
    this.warmupSetsCount = 0,
    this.hypertrophicEfficiencyPercentage = 0.0,
    this.hypertrophyMuscleBreakdown = const [],
    required this.muscleDistribution,
    this.weeklyVolumeTrend = const [],
  });

  factory GymStatsModel.fromJson(Map<String, dynamic> json) {
    final dist = (json['muscleDistribution'] as List?)
            ?.map(
                (m) => MuscleVolumeModel.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        [];

    final hypertrophyBreakdown = (json['hypertrophyMuscleBreakdown'] as List?)
            ?.map((m) =>
                MuscleHypertrophySummaryModel.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        [];

    final weeklyTrend = (json['weeklyVolumeTrend'] as List?)
            ?.map((b) =>
                WeeklyVolumeBucketModel.fromJson(Map<String, dynamic>.from(b)))
            .toList() ??
        [];

    final totalTonnage = (json['totalLifetimeTonnage'] as num?)?.toDouble() ?? 0.0;

    return GymStatsModel(
      workoutsThisWeek: json['workoutsThisWeek'] ?? 0,
      weeklyTarget: json['weeklyTarget'] ?? 4,
      workedOutToday: json['workedOutToday'] == true,
      totalLifetimeTonnage: totalTonnage,
      calisthenicsTotalReps:
          (json['calisthenicsTotalReps'] as num?)?.toInt() ?? 0,
      calisthenicsVolumeKg:
          (json['calisthenicsVolumeKg'] as num?)?.toDouble() ?? 0.0,
      stimulativeWorkingVolumeKg:
          (json['stimulativeWorkingVolumeKg'] as num?)?.toDouble() ?? 0.0,
      totalStructuralVolumeKg:
          (json['totalStructuralVolumeKg'] as num?)?.toDouble() ?? totalTonnage,
      warmupVolumeKg: (json['warmupVolumeKg'] as num?)?.toDouble() ?? 0.0,
      stimulativeSetsCount: json['stimulativeSetsCount'] ?? 0,
      warmupSetsCount: json['warmupSetsCount'] ?? 0,
      hypertrophicEfficiencyPercentage:
          (json['hypertrophicEfficiencyPercentage'] as num?)?.toDouble() ?? 0.0,
      hypertrophyMuscleBreakdown: hypertrophyBreakdown,
      muscleDistribution: dist,
      weeklyVolumeTrend: weeklyTrend,
    );
  }
}

class WeeklyVolumeBucketModel {
  final String weekStart;
  final double volumeKg;
  final int workoutsCount;

  WeeklyVolumeBucketModel({
    required this.weekStart,
    required this.volumeKg,
    required this.workoutsCount,
  });

  factory WeeklyVolumeBucketModel.fromJson(Map<String, dynamic> json) {
    return WeeklyVolumeBucketModel(
      weekStart: json['weekStart'] ?? '',
      volumeKg: (json['volumeKg'] as num?)?.toDouble() ?? 0.0,
      workoutsCount: (json['workoutsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TemplateSelectionModel {
  final String templateId;
  final String name;
  final String? description;
  final String category;
  final List<WorkoutTemplateExerciseModel> exercises;

  TemplateSelectionModel({
    required this.templateId,
    required this.name,
    this.description,
    required this.category,
    required this.exercises,
  });

  factory TemplateSelectionModel.fromTemplate(WorkoutTemplateModel template) {
    return TemplateSelectionModel(
      templateId: template.id,
      name: template.name,
      description: template.description,
      category: template.category,
      exercises: template.exercises,
    );
  }
}

class WorkoutTemplateExerciseModel {
  final String id;
  final int order;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String category;
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
    this.category = 'CHEST',
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
      category: ex['category'] ?? 'CHEST',
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
            ?.map((e) => WorkoutTemplateExerciseModel.fromJson(
                Map<String, dynamic>.from(e)))
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
      sevenDayAverageKg: (json['sevenDayAverageKg'] as num?)?.toDouble() ??
          (json['weightKg'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class GymInsightModel {
  final String type;
  final String title;
  final String message;
  final String severity;
  final Map<String, dynamic>? metrics;

  GymInsightModel({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.metrics,
  });

  factory GymInsightModel.fromJson(Map<String, dynamic> json) {
    return GymInsightModel(
      type: json['type'] ?? 'INFO',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'INFO',
      metrics: json['metrics'] is Map
          ? Map<String, dynamic>.from(json['metrics'])
          : null,
    );
  }
}
