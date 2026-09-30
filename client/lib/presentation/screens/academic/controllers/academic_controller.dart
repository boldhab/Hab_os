import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/academic_models.dart';

// Filter state for semester
final selectedSemesterProvider = StateProvider<String?>((ref) => 'Fall 2026');

// ==========================================
// DATA PROVIDERS
// ==========================================

final academicCoursesListProvider =
    FutureProvider.autoDispose.family<List<CourseOverviewModel>, String?>((ref, semester) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    ApiEndpoints.courses,
    queryParameters: semester != null && semester.isNotEmpty && semester != 'ALL'
        ? {'semester': semester}
        : null,
  );
  final data = response.data['data'];
  List items = [];
  if (data is List) {
    items = data;
  } else if (data is Map && data.containsKey('data')) {
    items = data['data'] as List;
  }
  return items.map((i) => CourseOverviewModel.fromJson(Map<String, dynamic>.from(i))).toList();
});

final academicSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.academicSummary);
  return Map<String, dynamic>.from(response.data['data']);
});

final academicGpaProvider =
    FutureProvider.autoDispose.family<GpaOverviewModel, String?>((ref, semester) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    ApiEndpoints.academicGpa,
    queryParameters: semester != null && semester.isNotEmpty && semester != 'ALL'
        ? {'semester': semester}
        : null,
  );
  return GpaOverviewModel.fromJson(Map<String, dynamic>.from(response.data['data']));
});

final courseDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.courseById(id));
  return Map<String, dynamic>.from(response.data['data']);
});

// ==========================================
// CONTROLLER (MUTATIONS)
// ==========================================

class AcademicController {
  final Ref ref;
  AcademicController(this.ref);

  Future<void> createCourse({
    required String name,
    String? code,
    String semester = 'Fall 2026',
    String? instructor,
    int credits = 3,
    String color = '#8B5CF6',
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.courses, data: {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      'semester': semester,
      if (instructor != null && instructor.isNotEmpty) 'instructor': instructor,
      'credits': credits,
      'color': color,
    });
    invalidateAll();
  }

  Future<void> deleteCourse(String courseId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.courseById(courseId));
    invalidateAll();
  }

  Future<void> createAssignment({
    required String courseId,
    required String title,
    String? description,
    required DateTime dueDate,
    String type = 'HOMEWORK',
    double weight = 10.0,
    double? grade,
    double maxGrade = 100.0,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.courseAssignments(courseId), data: {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'dueDate': dueDate.toIso8601String(),
      'type': type,
      'weight': weight,
      if (grade != null) 'grade': grade,
      'maxGrade': maxGrade,
      'status': grade != null ? 'GRADED' : 'NOT_STARTED',
    });
    invalidateCourseViews(courseId);
  }

  Future<void> updateAssignment({
    required String courseId,
    required String assignmentId,
    required Map<String, dynamic> data,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.put(ApiEndpoints.courseAssignmentById(courseId, assignmentId), data: data);
    invalidateCourseViews(courseId);
  }

  Future<void> deleteAssignment(String courseId, String assignmentId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.courseAssignmentById(courseId, assignmentId));
    invalidateCourseViews(courseId);
  }

  Future<void> createExam({
    required String courseId,
    required String title,
    required DateTime examDate,
    String? startTime,
    String examType = 'MIDTERM',
    double weight = 25.0,
    double? grade,
    double maxGrade = 100.0,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.courseExams(courseId), data: {
      'title': title,
      'examDate': examDate.toIso8601String(),
      if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
      'examType': examType,
      'weight': weight,
      if (grade != null) 'grade': grade,
      'maxGrade': maxGrade,
    });
    invalidateCourseViews(courseId);
  }

  Future<void> updateExam({
    required String courseId,
    required String examId,
    required Map<String, dynamic> data,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.put(ApiEndpoints.courseExamById(courseId, examId), data: data);
    invalidateCourseViews(courseId);
  }

  Future<void> deleteExam(String courseId, String examId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.courseExamById(courseId, examId));
    invalidateCourseViews(courseId);
  }

  Future<void> recordAttendance({
    required String courseId,
    required String status,
    DateTime? date,
    String? notes,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.courseAttendance(courseId), data: {
      'status': status,
      if (date != null) 'date': date.toIso8601String().split('T')[0],
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    invalidateCourseViews(courseId);
  }

  Future<void> addClassSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.courseSchedules(courseId), data: {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      if (room != null && room.isNotEmpty) 'room': room,
    });
    invalidateCourseViews(courseId);
  }

  Future<void> deleteClassSchedule(String courseId, String scheduleId) async {
    final dio = ref.read(dioProvider);
    await dio.delete(ApiEndpoints.courseScheduleById(courseId, scheduleId));
    invalidateCourseViews(courseId);
  }

  Future<WhatIfResultModel> calculateWhatIf({
    required String courseId,
    required double targetPercentage,
    double finalExamWeight = 30.0,
  }) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post(ApiEndpoints.courseWhatIf(courseId), data: {
      'targetPercentage': targetPercentage,
      'finalExamWeight': finalExamWeight,
    });
    return WhatIfResultModel.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<void> recordStudySession({
    required String courseId,
    required int durationMinutes,
    String? notes,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.courseStudy(courseId), data: {
      'durationMinutes': durationMinutes,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    invalidateCourseViews(courseId);
  }

  void invalidateCourseViews(String courseId) {
    ref.invalidate(courseDetailProvider(courseId));
    invalidateAll();
  }

  void invalidateAll() {
    ref.invalidate(academicCoursesListProvider);
    ref.invalidate(academicSummaryProvider);
    ref.invalidate(academicGpaProvider);
  }
}

final academicControllerProvider = Provider((ref) => AcademicController(ref));
