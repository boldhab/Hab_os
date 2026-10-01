import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_error_state.dart';
import '../../../app/theme/app_theme.dart';
import 'controllers/academic_controller.dart';
import 'models/academic_models.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(courseDetailProvider(widget.courseId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: AppErrorState(
          message: err.toString(),
          onRetry: () => ref
              .read(academicControllerProvider)
              .invalidateCourseViews(widget.courseId),
        ),
      ),
      data: (data) {
        final name = data['name'] ?? 'Course';
        final code = data['code'] as String?;
        final semester = data['semester'] ?? 'Fall 2026';
        final instructor = data['instructor'] as String?;
        final credits = (data['credits'] as num?)?.toInt() ?? 3;
        final gradeMap = data['gradeDetails'] as Map<String, dynamic>? ?? {};
        final grade = CourseGradeDetailsModel.fromJson(gradeMap);
        final attendanceRate =
            (data['attendanceRate'] as num?)?.toDouble() ?? 100.0;
        final totalStudyHours =
            (data['totalStudyHours'] as num?)?.toDouble() ?? 0.0;

        final assignmentsList = (data['assignments'] as List?)
                ?.map((i) =>
                    AssignmentItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList() ??
            [];
        final examsList = (data['exams'] as List?)
                ?.map(
                    (i) => ExamItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList() ??
            [];
        final schedulesList = (data['classSchedules'] as List?)
                ?.map((i) => ClassScheduleItemModel.fromJson(
                    Map<String, dynamic>.from(i)))
                .toList() ??
            [];

        final hasGrade = grade.gradedItemsCount > 0;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Row(
                  children: [
                    if (code != null && code.isNotEmpty) ...[
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•',
                          style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '$semester • $credits Credits',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasGrade
                      ? primaryRed.withAlpha(20)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: hasGrade
                        ? primaryRed.withAlpha(60)
                        : colorScheme.outlineVariant.withAlpha(40),
                  ),
                ),
                child: Text(
                  hasGrade
                      ? '${grade.runningPercentage.toStringAsFixed(0)}% (${grade.letter})'
                      : 'Not Graded',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: hasGrade ? primaryRed : colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'refresh') {
                    ref
                        .read(academicControllerProvider)
                        .invalidateCourseViews(widget.courseId);
                  } else if (val == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete Course',
                            style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: primaryRed,
              labelColor: primaryRed,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Work'),
                Tab(text: 'Grades'),
                Tab(text: 'Study'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                courseId: widget.courseId,
                instructor: instructor,
                attendanceRate: attendanceRate,
                schedules: schedulesList,
              ),
              _WorkTab(
                courseId: widget.courseId,
                assignments: assignmentsList,
                exams: examsList,
              ),
              _GradesTab(
                courseId: widget.courseId,
                grade: grade,
                assignments: assignmentsList,
                exams: examsList,
              ),
              _StudyTab(
                courseId: widget.courseId,
                totalStudyHours: totalStudyHours,
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: const Text(
            'This will permanently delete the course and all associated deliverables.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(academicControllerProvider)
                  .deleteCourse(widget.courseId);
              if (context.canPop()) context.pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  final String courseId;
  final String? instructor;
  final double attendanceRate;
  final List<ClassScheduleItemModel> schedules;

  const _OverviewTab({
    required this.courseId,
    required this.instructor,
    required this.attendanceRate,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    final isAttendanceWarning = attendanceRate < 85.0;
    final attendanceColor =
        isAttendanceWarning ? semantics.danger : semantics.success;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Instructor Contact Block
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryRed.withAlpha(20),
                radius: 20,
                child: Icon(Icons.person_outline_rounded,
                    color: primaryRed, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor ?? 'No Instructor Listed',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      'Course Instructor',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapLg,

        // Attendance Quick Log (Present / Absent / Excused)
        Text(
          'LOG ATTENDANCE TODAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant.withAlpha(160),
          ),
        ),
        AppSpacing.verticalGapSm,
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.success();
                    ref.read(academicControllerProvider).recordAttendance(
                          courseId: courseId,
                          status: 'PRESENT',
                        );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: semantics.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Present',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: semantics.success,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.warning();
                    ref.read(academicControllerProvider).recordAttendance(
                          courseId: courseId,
                          status: 'ABSENT',
                        );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: semantics.danger.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Absent',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: semantics.danger,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.light();
                    ref.read(academicControllerProvider).recordAttendance(
                          courseId: courseId,
                          status: 'EXCUSED',
                        );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Excused',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapLg,

        // Attendance Overall Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OVERALL ATTENDANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant.withAlpha(160),
              ),
            ),
            Text(
              '${attendanceRate.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: attendanceColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        AppSpacing.verticalGapSm,
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (attendanceRate / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: colorScheme.outlineVariant.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(attendanceColor),
          ),
        ),
        AppSpacing.verticalGapXl,

        // Class Schedule List
        Text(
          'CLASS SCHEDULE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant.withAlpha(160),
          ),
        ),
        AppSpacing.verticalGapSm,
        if (schedules.isEmpty)
          Text(
            'No class schedule added yet.',
            style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withAlpha(140)),
          )
        else
          ...schedules.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.dayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.startTime} - ${s.endTime}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        if (s.room != null && s.room!.isNotEmpty)
                          Text(
                            'Room: ${s.room}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. WORK TAB (ASSIGNMENTS & EXAMS)
// ─────────────────────────────────────────────────────────────────────────────
class _WorkTab extends ConsumerWidget {
  final String courseId;
  final List<AssignmentItemModel> assignments;
  final List<ExamItemModel> exams;

  const _WorkTab({
    required this.courseId,
    required this.assignments,
    required this.exams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Section: Assignments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASSIGNMENTS (${assignments.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapSm,
          if (assignments.isEmpty)
            Text(
              'No assignments added.',
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withAlpha(140)),
            )
          else
            ...assignments.map((a) {
              final isOverdue =
                  !a.isCompleted && a.dueDate.isBefore(DateTime.now());
              final df = DateFormat('MMM d');

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    Icon(
                      a.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.assignment_outlined,
                      size: 20,
                      color: a.isCompleted ? colorScheme.secondary : primaryRed,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Due ${df.format(a.dueDate)} · ${a.weight.toStringAsFixed(0)}% weight',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue
                                  ? Theme.of(context).colorScheme.error
                                  : colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (a.grade != null)
                      Text(
                        '${a.grade!.toStringAsFixed(0)}/${a.maxGrade.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primaryRed,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              );
            }),

          AppSpacing.verticalGapLg,

          // Section: Exams
          Text(
            'EXAMS (${exams.length})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
          AppSpacing.verticalGapSm,
          if (exams.isEmpty)
            Text(
              'No exams scheduled.',
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withAlpha(140)),
            )
          else
            ...exams.map((e) {
              final df = DateFormat('MMM d');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.tertiary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fact_check_outlined,
                        size: 20, color: colorScheme.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Exam Date: ${df.format(e.examDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.grade != null)
                      Text(
                        '${e.grade!.toStringAsFixed(0)}/${e.maxGrade.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.tertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. GRADES TAB & WHAT-IF SIMULATOR
// ─────────────────────────────────────────────────────────────────────────────
class _GradesTab extends ConsumerStatefulWidget {
  final String courseId;
  final CourseGradeDetailsModel grade;
  final List<AssignmentItemModel> assignments;
  final List<ExamItemModel> exams;

  const _GradesTab({
    required this.courseId,
    required this.grade,
    required this.assignments,
    required this.exams,
  });

  @override
  ConsumerState<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends ConsumerState<_GradesTab> {
  double _simulatedTarget = 90.0;
  WhatIfResultModel? _simResult;
  bool _isSimulating = false;

  Future<void> _runSimulation() async {
    setState(() => _isSimulating = true);
    try {
      final res = await ref.read(academicControllerProvider).calculateWhatIf(
            courseId: widget.courseId,
            targetPercentage: _simulatedTarget,
          );
      setState(() {
        _simResult = res;
        _isSimulating = false;
      });
    } catch (_) {
      setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Grade Summary Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT GRADE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                  Text(
                    '${widget.grade.runningPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryRed,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.grade.letter,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapXl,

        // What-If Calculator Simulator Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: primaryRed.withAlpha(12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryRed.withAlpha(60), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: primaryRed),
                      const SizedBox(width: 6),
                      Text(
                        'Grade Simulator (What-If)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryRed,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Hypothetical - Not saved',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryRed),
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalGapMd,
              Text(
                'Target Grade: ${_simulatedTarget.toInt()}%',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Slider(
                value: _simulatedTarget,
                min: 60,
                max: 100,
                divisions: 40,
                activeColor: primaryRed,
                onChanged: (val) {
                  setState(() => _simulatedTarget = val);
                },
                onChangeEnd: (_) => _runSimulation(),
              ),
              if (_simResult != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: primaryRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _simResult!.message,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. STUDY & VAULT TAB
// ─────────────────────────────────────────────────────────────────────────────
class _StudyTab extends ConsumerWidget {
  final String courseId;
  final double totalStudyHours;

  const _StudyTab({
    required this.courseId,
    required this.totalStudyHours,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Total Study Hours Hero Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Column(
            children: [
              Icon(Icons.timer_rounded, size: 36, color: primaryRed),
              AppSpacing.verticalGapSm,
              Text(
                '${totalStudyHours.toStringAsFixed(1)} hrs',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'TOTAL STUDY TIME LOGGED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapLg,

        Text(
          'LINKED VAULT NOTES & DECKS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant.withAlpha(160),
          ),
        ),
        AppSpacing.verticalGapSm,
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
          ),
          child: Column(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 32, color: colorScheme.onSurfaceVariant.withAlpha(120)),
              AppSpacing.verticalGapSm,
              Text(
                'No notes or study decks linked yet.',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withAlpha(160)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
