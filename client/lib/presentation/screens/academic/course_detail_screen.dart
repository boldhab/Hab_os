import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_error_state.dart';
import '../../../app/theme/app_theme.dart';
import 'controllers/academic_controller.dart';
import 'models/academic_models.dart';
import 'widgets/academic_enroll_dialog.dart';

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

  void _openEditCourse(BuildContext context, Map<String, dynamic> data) {
    AcademicEnrollDialog.show(
      context,
      isEditing: true,
      initialName: data['name'],
      initialCode: data['code'],
      initialSemester: data['semester'],
      initialInstructor: data['instructor'],
      initialCredits: (data['credits'] as num?)?.toInt(),
      onEnroll: ({
        required name,
        code,
        required semester,
        instructor,
        required credits,
      }) async {
        await ref.read(academicControllerProvider).updateCourse(
              courseId: widget.courseId,
              name: name,
              code: code,
              semester: semester,
              instructor: instructor,
              credits: credits,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully')),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(academicControllerProvider)
                    .deleteCourse(widget.courseId);
                if (context.mounted && context.canPop()) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete course: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        final studySessionsList = (data['studySessions'] as List?)
                ?.map((i) => StudySessionItemModel.fromJson(
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
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openEditCourse(context, data);
                  } else if (val == 'refresh') {
                    ref
                        .read(academicControllerProvider)
                        .invalidateCourseViews(widget.courseId);
                  } else if (val == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Course'),
                      ],
                    ),
                  ),
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
                studySessions: studySessionsList,
              ),
            ],
          ),
        );
      },
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

  Future<void> _logAttendance(
      BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(academicControllerProvider).recordAttendance(
            courseId: courseId,
            status: status,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance recorded as $status'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record attendance: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openAddScheduleDialog(BuildContext context, WidgetRef ref) {
    int dayOfWeek = 1;
    final startTimeController = TextEditingController(text: '09:00');
    final endTimeController = TextEditingController(text: '10:30');
    final roomController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Class Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: dayOfWeek,
                  decoration: const InputDecoration(labelText: 'Day of Week'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 2, child: Text('Tuesday')),
                    DropdownMenuItem(value: 3, child: Text('Wednesday')),
                    DropdownMenuItem(value: 4, child: Text('Thursday')),
                    DropdownMenuItem(value: 5, child: Text('Friday')),
                    DropdownMenuItem(value: 6, child: Text('Saturday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => dayOfWeek = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (HH:MM)',
                    hintText: '09:00',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time (HH:MM)',
                    hintText: '10:30',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room (Optional)',
                    hintText: 'e.g. Hall 101',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(academicControllerProvider).addClassSchedule(
                        courseId: courseId,
                        dayOfWeek: dayOfWeek,
                        startTime: startTimeController.text.trim(),
                        endTime: endTimeController.text.trim(),
                        room: roomController.text.trim().isNotEmpty
                            ? roomController.text.trim()
                            : null,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class schedule added')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add schedule: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSchedule(
      BuildContext context, WidgetRef ref, String scheduleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Schedule?'),
        content: const Text('Remove this class time from your schedule?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(academicControllerProvider)
                    .deleteClassSchedule(courseId, scheduleId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule removed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove schedule: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

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

        // Attendance Quick Log (Present / Late / Absent / Excused)
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
                    _logAttendance(context, ref, 'PRESENT');
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
                    AppHaptics.light();
                    _logAttendance(context, ref, 'LATE');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Late',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.amber,
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
                    _logAttendance(context, ref, 'ABSENT');
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
                    _logAttendance(context, ref, 'EXCUSED');
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

        // Class Schedule List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CLASS SCHEDULE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant.withAlpha(160),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAddScheduleDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Time', style: TextStyle(fontSize: 12)),
            ),
          ],
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
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: colorScheme.onSurfaceVariant.withAlpha(140)),
                    onPressed: () => _deleteSchedule(context, ref, s.id),
                    tooltip: 'Remove',
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

  void _openAddAssignmentDialog(BuildContext context, WidgetRef ref,
      [AssignmentItemModel? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    DateTime dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String type = existing?.type ?? 'HOMEWORK';
    double weight = existing?.weight ?? 10.0;
    double maxGrade = existing?.maxGrade ?? 100.0;
    double? grade = existing?.grade;
    String status = existing?.status ?? 'NOT_STARTED';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Assignment' : 'Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'HOMEWORK', child: Text('Homework')),
                    DropdownMenuItem(value: 'ESSAY', child: Text('Essay')),
                    DropdownMenuItem(value: 'PROJECT', child: Text('Project')),
                    DropdownMenuItem(value: 'LAB', child: Text('Lab')),
                    DropdownMenuItem(value: 'QUIZ', child: Text('Quiz')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => type = val);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date', style: TextStyle(fontSize: 14)),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: weight.toStringAsFixed(0),
                        decoration:
                            const InputDecoration(labelText: 'Weight (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          if (v != null) weight = v;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: maxGrade.toStringAsFixed(0),
                        decoration:
                            const InputDecoration(labelText: 'Max Grade'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          if (v != null) maxGrade = v;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                        value: 'NOT_STARTED', child: Text('Not Started')),
                    DropdownMenuItem(
                        value: 'IN_PROGRESS', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'SUBMITTED', child: Text('Submitted')),
                    DropdownMenuItem(value: 'GRADED', child: Text('Graded')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => status = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: grade != null ? grade.toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'Score / Grade (Optional)',
                    hintText: 'e.g. 95',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    grade = double.tryParse(val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await ref.read(academicControllerProvider).createAssignment(
                          courseId: courseId,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isNotEmpty
                              ? descriptionController.text.trim()
                              : null,
                          dueDate: dueDate,
                          type: type,
                          weight: weight,
                          maxGrade: maxGrade,
                          grade: grade,
                        );
                  } else {
                    await ref.read(academicControllerProvider).updateAssignment(
                          courseId: courseId,
                          assignmentId: existing.id,
                          data: {
                            'title': titleController.text.trim(),
                            'type': type,
                            'dueDate': dueDate.toIso8601String(),
                            'weight': weight,
                            'maxGrade': maxGrade,
                            'grade': grade,
                            'status': grade != null ? 'GRADED' : status,
                          },
                        );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existing == null
                            ? 'Assignment added'
                            : 'Assignment updated'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExamDialog(BuildContext context, WidgetRef ref,
      [ExamItemModel? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    DateTime examDate =
        existing?.examDate ?? DateTime.now().add(const Duration(days: 14));
    final startTimeController =
        TextEditingController(text: existing?.startTime ?? '10:00');
    String examType = existing?.examType ?? 'MIDTERM';
    double weight = existing?.weight ?? 25.0;
    double maxGrade = existing?.maxGrade ?? 100.0;
    double? grade = existing?.grade;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Exam' : 'Edit Exam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: examType,
                  decoration: const InputDecoration(labelText: 'Exam Type'),
                  items: const [
                    DropdownMenuItem(value: 'MIDTERM', child: Text('Midterm')),
                    DropdownMenuItem(value: 'FINAL', child: Text('Final')),
                    DropdownMenuItem(value: 'QUIZ', child: Text('Quiz')),
                    DropdownMenuItem(value: 'ORAL', child: Text('Oral')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => examType = val);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exam Date', style: TextStyle(fontSize: 14)),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(examDate)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: examDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => examDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (HH:MM)',
                    hintText: '10:00',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: weight.toStringAsFixed(0),
                        decoration:
                            const InputDecoration(labelText: 'Weight (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          if (v != null) weight = v;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: maxGrade.toStringAsFixed(0),
                        decoration:
                            const InputDecoration(labelText: 'Max Grade'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          if (v != null) maxGrade = v;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: grade != null ? grade.toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'Score / Grade (Optional)',
                    hintText: 'e.g. 88',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    grade = double.tryParse(val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await ref.read(academicControllerProvider).createExam(
                          courseId: courseId,
                          title: titleController.text.trim(),
                          examDate: examDate,
                          startTime: startTimeController.text.trim().isNotEmpty
                              ? startTimeController.text.trim()
                              : null,
                          examType: examType,
                          weight: weight,
                          maxGrade: maxGrade,
                          grade: grade,
                        );
                  } else {
                    await ref.read(academicControllerProvider).updateExam(
                          courseId: courseId,
                          examId: existing.id,
                          data: {
                            'title': titleController.text.trim(),
                            'examType': examType,
                            'examDate': examDate.toIso8601String(),
                            'startTime': startTimeController.text.trim().isNotEmpty
                                ? startTimeController.text.trim()
                                : null,
                            'weight': weight,
                            'maxGrade': maxGrade,
                            'grade': grade,
                          },
                        );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existing == null
                            ? 'Exam scheduled'
                            : 'Exam updated'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentOptions(
      BuildContext context, WidgetRef ref, AssignmentItemModel item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Assignment'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddAssignmentDialog(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Assignment',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAssignment(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAssignment(
      BuildContext context, WidgetRef ref, AssignmentItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(academicControllerProvider)
                    .deleteAssignment(courseId, item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExamOptions(
      BuildContext context, WidgetRef ref, ExamItemModel item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Exam'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddExamDialog(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title:
                  const Text('Delete Exam', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteExam(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExam(
      BuildContext context, WidgetRef ref, ExamItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(academicControllerProvider)
                    .deleteExam(courseId, item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Section: Assignments Header
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
              TextButton.icon(
                onPressed: () => _openAddAssignmentDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label:
                    const Text('Add Assignment', style: TextStyle(fontSize: 12)),
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

              return InkWell(
                onTap: () => _showAssignmentOptions(context, ref, a),
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
                              'Due ${df.format(a.dueDate)} · ${a.weight.toStringAsFixed(0)}% weight · ${a.status}',
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
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.more_horiz_rounded,
                          size: 18, color: colorScheme.onSurfaceVariant.withAlpha(120)),
                    ],
                  ),
                ),
              );
            }),

          AppSpacing.verticalGapLg,

          // Section: Exams Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXAMS (${exams.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openAddExamDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Exam', style: TextStyle(fontSize: 12)),
              ),
            ],
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
              return InkWell(
                onTap: () => _showExamOptions(context, ref, e),
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
                              'Date: ${df.format(e.examDate)}${e.startTime != null ? " at ${e.startTime}" : ""}',
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
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.more_horiz_rounded,
                          size: 18, color: colorScheme.onSurfaceVariant.withAlpha(120)),
                    ],
                  ),
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
      if (mounted) {
        setState(() {
          _simResult = res;
          _isSimulating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSimulating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulation error: $e')),
        );
      }
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
              Row(
                children: [
                  Text(
                    'Target Grade: ${_simulatedTarget.toInt()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  if (_isSimulating) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              Slider(
                value: _simulatedTarget,
                min: 60,
                max: 100,
                divisions: 40,
                activeColor: primaryRed,
                onChanged: _isSimulating
                    ? null
                    : (val) {
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
                if (_simResult!.remainingUngradedWeight != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWhatIfMetric(
                        context,
                        'Earned',
                        '${(_simResult!.earnedContributionTowardsFinal ?? _simResult!.currentEarnedTowardsFinal).toStringAsFixed(1)}%',
                      ),
                      _buildWhatIfMetric(
                        context,
                        'Ungraded',
                        '${_simResult!.remainingUngradedWeight!.toStringAsFixed(1)}%',
                      ),
                      _buildWhatIfMetric(
                        context,
                        'Max Final',
                        '${(_simResult!.maxAchievableGrade ?? _simResult!.maxPossibleGrade).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatIfMetric(BuildContext context, String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. STUDY & VAULT TAB
// ─────────────────────────────────────────────────────────────────────────────
class _StudyTab extends ConsumerWidget {
  final String courseId;
  final double totalStudyHours;
  final List<StudySessionItemModel> studySessions;

  const _StudyTab({
    required this.courseId,
    required this.totalStudyHours,
    required this.studySessions,
  });

  void _openLogStudySessionDialog(BuildContext context, WidgetRef ref) {
    int durationMinutes = 45;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Log Study Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: durationMinutes.toString(),
                decoration:
                    const InputDecoration(labelText: 'Duration (Minutes) *'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final v = int.tryParse(val);
                  if (v != null) durationMinutes = v;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Chapter 4 review & practice exercises',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (durationMinutes <= 0) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(academicControllerProvider).recordStudySession(
                        courseId: courseId,
                        durationMinutes: durationMinutes,
                        notes: notesController.text.trim().isNotEmpty
                            ? notesController.text.trim()
                            : null,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Study session logged')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

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
              AppSpacing.verticalGapMd,
              FilledButton.icon(
                onPressed: () => _openLogStudySessionDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log Study Session'),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapLg,

        // Recent Study Sessions Section
        Text(
          'RECENT STUDY SESSIONS (${studySessions.length})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant.withAlpha(160),
          ),
        ),
        AppSpacing.verticalGapSm,
        if (studySessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No study sessions logged yet. Tap "Log Study Session" above to track your study hours.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
          )
        else
          ...studySessions.map((s) {
            final df = DateFormat('MMM d, yyyy · HH:mm');
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
                    child: Icon(Icons.school_outlined,
                        size: 20, color: primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.durationMinutes} minutes',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          df.format(s.startTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                        if (s.notes != null && s.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              s.notes!,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant.withAlpha(160),
                              ),
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
