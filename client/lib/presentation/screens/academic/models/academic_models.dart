class CourseGradeDetailsModel {
  final double runningPercentage;
  final String letter;
  final double gradePoints;
  final double totalEvaluatedWeight;
  final double totalPossibleWeight;
  final int gradedItemsCount;
  final double earnedWeightPoints;

  CourseGradeDetailsModel({
    required this.runningPercentage,
    required this.letter,
    required this.gradePoints,
    required this.totalEvaluatedWeight,
    required this.totalPossibleWeight,
    required this.gradedItemsCount,
    required this.earnedWeightPoints,
  });

  factory CourseGradeDetailsModel.fromJson(Map<String, dynamic> json) {
    return CourseGradeDetailsModel(
      runningPercentage: (json['runningPercentage'] as num?)?.toDouble() ?? 0.0,
      letter: json['letter'] ?? 'N/A',
      gradePoints: (json['gradePoints'] as num?)?.toDouble() ?? 0.0,
      totalEvaluatedWeight:
          (json['totalEvaluatedWeight'] as num?)?.toDouble() ?? 0.0,
      totalPossibleWeight:
          (json['totalPossibleWeight'] as num?)?.toDouble() ?? 0.0,
      gradedItemsCount: json['gradedItemsCount'] as int? ?? 0,
      earnedWeightPoints:
          (json['earnedWeightPoints'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ClassScheduleItemModel {
  final String id;
  final String courseId;
  final int dayOfWeek; // 1 = Monday .. 7 = Sunday
  final String startTime;
  final String endTime;
  final String? room;

  ClassScheduleItemModel({
    required this.id,
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Day $dayOfWeek';
    }
  }

  factory ClassScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ClassScheduleItemModel(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      dayOfWeek: json['dayOfWeek'] as int? ?? 1,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      room: json['room'],
    );
  }
}

class AssignmentItemModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String type;
  final double weight;
  final String status;
  final double? grade;
  final double maxGrade;

  AssignmentItemModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.type,
    required this.weight,
    required this.status,
    this.grade,
    required this.maxGrade,
  });

  bool get isCompleted => status == 'SUBMITTED' || status == 'GRADED';

  double? get percentage =>
      grade != null && maxGrade > 0 ? (grade! / maxGrade) * 100.0 : null;

  factory AssignmentItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? 'HOMEWORK',
      weight: (json['weight'] as num?)?.toDouble() ?? 10.0,
      status: json['status'] ?? 'NOT_STARTED',
      grade: (json['grade'] as num?)?.toDouble(),
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class ExamItemModel {
  final String id;
  final String title;
  final DateTime examDate;
  final String? startTime;
  final String examType;
  final double? weight;
  final double? grade;
  final double maxGrade;

  ExamItemModel({
    required this.id,
    required this.title,
    required this.examDate,
    this.startTime,
    required this.examType,
    this.weight,
    this.grade,
    required this.maxGrade,
  });

  bool get isGraded => grade != null;

  double? get percentage =>
      grade != null && maxGrade > 0 ? (grade! / maxGrade) * 100.0 : null;

  factory ExamItemModel.fromJson(Map<String, dynamic> json) {
    return ExamItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      examDate: DateTime.tryParse(json['examDate'] ?? '') ?? DateTime.now(),
      startTime: json['startTime'],
      examType: json['examType'] ?? 'MIDTERM',
      weight: (json['weight'] as num?)?.toDouble(),
      grade: (json['grade'] as num?)?.toDouble(),
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class AttendanceItemModel {
  final String id;
  final DateTime date;
  final String status;
  final String? notes;

  AttendanceItemModel({
    required this.id,
    required this.date,
    required this.status,
    this.notes,
  });

  factory AttendanceItemModel.fromJson(Map<String, dynamic> json) {
    return AttendanceItemModel(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PRESENT',
      notes: json['notes'],
    );
  }
}

class CourseOverviewModel {
  final String id;
  final String name;
  final String? code;
  final String semester;
  final String? instructor;
  final int credits;
  final double progress;
  final String color;
  final double attendanceRate;
  final CourseGradeDetailsModel gradeDetails;
  final int assignmentsCount;
  final int examsCount;
  final List<ClassScheduleItemModel> classSchedules;

  CourseOverviewModel({
    required this.id,
    required this.name,
    this.code,
    required this.semester,
    this.instructor,
    required this.credits,
    required this.progress,
    required this.color,
    required this.attendanceRate,
    required this.gradeDetails,
    required this.assignmentsCount,
    required this.examsCount,
    required this.classSchedules,
  });

  factory CourseOverviewModel.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    final gradeMap = json['gradeDetails'] as Map<String, dynamic>? ?? {};
    final schedList = (json['classSchedules'] as List?)
            ?.map((e) =>
                ClassScheduleItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return CourseOverviewModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      semester: json['semester'] ?? 'Fall 2026',
      instructor: json['instructor'],
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] ?? '#8B5CF6',
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 100.0,
      gradeDetails: CourseGradeDetailsModel.fromJson(gradeMap),
      assignmentsCount: counts['assignments'] ?? 0,
      examsCount: counts['exams'] ?? 0,
      classSchedules: schedList,
    );
  }
}

class SemesterGpaModel {
  final String semester;
  final double semesterGpa;
  final int creditsCount;
  final int coursesCount;

  SemesterGpaModel({
    required this.semester,
    required this.semesterGpa,
    required this.creditsCount,
    required this.coursesCount,
  });

  factory SemesterGpaModel.fromJson(Map<String, dynamic> json) {
    return SemesterGpaModel(
      semester: json['semester'] ?? '',
      semesterGpa: (json['semesterGpa'] as num?)?.toDouble() ?? 0.0,
      creditsCount: (json['creditsCount'] as num?)?.toInt() ?? 0,
      coursesCount: (json['coursesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class GpaOverviewModel {
  final double cumulativeGpa;
  final String cumulativeLetter;
  final int totalCreditsGraded;
  final int totalCoursesCount;
  final List<SemesterGpaModel> semesters;

  GpaOverviewModel({
    required this.cumulativeGpa,
    required this.cumulativeLetter,
    required this.totalCreditsGraded,
    required this.totalCoursesCount,
    required this.semesters,
  });

  factory GpaOverviewModel.fromJson(Map<String, dynamic> json) {
    final sems = (json['semesters'] as List?)
            ?.map(
                (s) => SemesterGpaModel.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];

    return GpaOverviewModel(
      cumulativeGpa: (json['cumulativeGpa'] as num?)?.toDouble() ?? 0.0,
      cumulativeLetter: json['cumulativeLetter'] ?? 'N/A',
      totalCreditsGraded: (json['totalCreditsGraded'] as num?)?.toInt() ?? 0,
      totalCoursesCount: (json['totalCoursesCount'] as num?)?.toInt() ?? 0,
      semesters: sems,
    );
  }
}

class WhatIfResultModel {
  final double targetPercentage;
  final String targetLetter;
  final double finalExamWeight;
  final double currentRunningPercentage;
  final double currentEarnedTowardsFinal;
  final double requiredScorePercentage;
  final double maxPossibleGrade;
  final String status;
  final String message;
  final double? currentAverageOnGradedWork;
  final double? earnedContributionTowardsFinal;
  final double? remainingUngradedWeight;
  final double? maxAchievableGrade;
  final double? totalEvaluatedWeight;

  WhatIfResultModel({
    required this.targetPercentage,
    required this.targetLetter,
    required this.finalExamWeight,
    required this.currentRunningPercentage,
    required this.currentEarnedTowardsFinal,
    required this.requiredScorePercentage,
    required this.maxPossibleGrade,
    required this.status,
    required this.message,
    this.currentAverageOnGradedWork,
    this.earnedContributionTowardsFinal,
    this.remainingUngradedWeight,
    this.maxAchievableGrade,
    this.totalEvaluatedWeight,
  });

  factory WhatIfResultModel.fromJson(Map<String, dynamic> json) {
    return WhatIfResultModel(
      targetPercentage: (json['targetPercentage'] as num?)?.toDouble() ?? 0.0,
      targetLetter: json['targetLetter'] ?? 'A',
      finalExamWeight: (json['finalExamWeight'] as num?)?.toDouble() ?? 30.0,
      currentRunningPercentage:
          (json['currentRunningPercentage'] as num?)?.toDouble() ?? 0.0,
      currentEarnedTowardsFinal:
          (json['currentEarnedTowardsFinal'] as num?)?.toDouble() ?? 0.0,
      requiredScorePercentage:
          (json['requiredScorePercentage'] as num?)?.toDouble() ?? 0.0,
      maxPossibleGrade: (json['maxPossibleGrade'] as num?)?.toDouble() ?? 100.0,
      status: json['status'] ?? 'ACHIEVABLE',
      message: json['message'] ?? '',
      currentAverageOnGradedWork:
          (json['currentAverageOnGradedWork'] as num?)?.toDouble(),
      earnedContributionTowardsFinal:
          (json['earnedContributionTowardsFinal'] as num?)?.toDouble(),
      remainingUngradedWeight:
          (json['remainingUngradedWeight'] as num?)?.toDouble(),
      maxAchievableGrade: (json['maxAchievableGrade'] as num?)?.toDouble(),
      totalEvaluatedWeight: (json['totalEvaluatedWeight'] as num?)?.toDouble(),
    );
  }
}

class UpcomingDeliverableModel {
  final String id;
  final String title;
  final String courseId;
  final String courseName;
  final String? courseCode;
  final String courseColor;
  final DateTime date;
  final bool isExam;
  final String? typeOrStatus;
  final double? weight;
  final String? startTime;

  UpcomingDeliverableModel({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseName,
    this.courseCode,
    required this.courseColor,
    required this.date,
    required this.isExam,
    this.typeOrStatus,
    this.weight,
    this.startTime,
  });

  factory UpcomingDeliverableModel.fromAssignment(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>? ?? {};
    return UpcomingDeliverableModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Assignment',
      courseId: course['id'] ?? '',
      courseName: course['name'] ?? 'Course',
      courseCode: course['code'],
      courseColor: course['color'] ?? '#8B5CF6',
      date: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      isExam: false,
      typeOrStatus: json['status'] ?? json['type'],
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  factory UpcomingDeliverableModel.fromExam(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>? ?? {};
    return UpcomingDeliverableModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Exam',
      courseId: course['id'] ?? '',
      courseName: course['name'] ?? 'Course',
      courseCode: course['code'],
      courseColor: course['color'] ?? '#8B5CF6',
      date: DateTime.tryParse(json['examDate'] ?? '') ?? DateTime.now(),
      isExam: true,
      typeOrStatus: json['examType'],
      weight: (json['weight'] as num?)?.toDouble(),
      startTime: json['startTime'],
    );
  }
}

class StudySessionItemModel {
  final String id;
  final int durationMinutes;
  final String? notes;
  final DateTime startTime;

  StudySessionItemModel({
    required this.id,
    required this.durationMinutes,
    this.notes,
    required this.startTime,
  });

  factory StudySessionItemModel.fromJson(Map<String, dynamic> json) {
    return StudySessionItemModel(
      id: json['id'] ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: json['notes'],
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
    );
  }
}

class AcademicSummaryModel {
  final int totalCourses;
  final double overallAttendanceRate;
  final double cumulativeGpa;
  final String cumulativeLetter;
  final int upcomingAssignmentsCount;
  final int upcomingAssignmentsTotal;
  final int upcomingExamsCount;
  final int upcomingExamsTotal;
  final List<UpcomingDeliverableModel> upcomingDeliverables;

  AcademicSummaryModel({
    required this.totalCourses,
    required this.overallAttendanceRate,
    required this.cumulativeGpa,
    required this.cumulativeLetter,
    required this.upcomingAssignmentsCount,
    this.upcomingAssignmentsTotal = 0,
    required this.upcomingExamsCount,
    this.upcomingExamsTotal = 0,
    required this.upcomingDeliverables,
  });

  factory AcademicSummaryModel.fromJson(Map<String, dynamic> json) {
    final assignments = (json['upcomingAssignments'] as List?)
            ?.map((i) => UpcomingDeliverableModel.fromAssignment(
                Map<String, dynamic>.from(i)))
            .toList() ??
        [];
    final exams = (json['upcomingExams'] as List?)
            ?.map((i) =>
                UpcomingDeliverableModel.fromExam(Map<String, dynamic>.from(i)))
            .toList() ??
        [];
    final deliverables = [...assignments, ...exams];
    deliverables.sort((a, b) => a.date.compareTo(b.date));

    final assignmentsCount =
        (json['upcomingAssignmentsCount'] as num?)?.toInt() ?? 0;
    final assignmentsTotal =
        (json['upcomingAssignmentsTotal'] as num?)?.toInt() ?? assignmentsCount;
    final examsCount = (json['upcomingExamsCount'] as num?)?.toInt() ?? 0;
    final examsTotal =
        (json['upcomingExamsTotal'] as num?)?.toInt() ?? examsCount;

    return AcademicSummaryModel(
      totalCourses: (json['totalCourses'] as num?)?.toInt() ?? 0,
      overallAttendanceRate:
          (json['overallAttendanceRate'] as num?)?.toDouble() ?? 100.0,
      cumulativeGpa: (json['cumulativeGpa'] as num?)?.toDouble() ?? 0.0,
      cumulativeLetter: json['cumulativeLetter'] ?? 'N/A',
      upcomingAssignmentsCount: assignmentsCount,
      upcomingAssignmentsTotal: assignmentsTotal,
      upcomingExamsCount: examsCount,
      upcomingExamsTotal: examsTotal,
      upcomingDeliverables: deliverables,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCourses': totalCourses,
      'overallAttendanceRate': overallAttendanceRate,
      'cumulativeGpa': cumulativeGpa,
      'cumulativeLetter': cumulativeLetter,
      'upcomingAssignmentsCount': upcomingAssignmentsCount,
      'upcomingExamsCount': upcomingExamsCount,
    };
  }
}

