import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_error_state.dart';
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

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: AppErrorState(
          message: err.toString(),
          onRetry: () => ref.read(academicControllerProvider).invalidateCourseViews(widget.courseId),
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
        final attendanceRate = (data['attendanceRate'] as num?)?.toDouble() ?? 100.0;
        final totalStudyHours = (data['totalStudyHours'] as num?)?.toDouble() ?? 0.0;

        final assignmentsList = (data['assignments'] as List?)
                ?.map((i) => AssignmentItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList() ??
            [];
        final examsList = (data['exams'] as List?)
                ?.map((i) => ExamItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList() ??
            [];
        final schedulesList = (data['classSchedules'] as List?)
                ?.map((i) => ClassScheduleItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList() ??
            [];
        final tasksList = (data['tasks'] as List?) ?? [];
        final vaultNotes = (data['vaultNotes'] as List?) ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${code != null ? '$code • ' : ''}$semester • $credits Credits',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.read(academicControllerProvider).invalidateCourseViews(widget.courseId);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _confirmDeleteCourse(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview & Schedule'),
                Tab(icon: Icon(Icons.assignment_outlined), text: 'Assignments & Exams'),
                Tab(icon: Icon(Icons.calculate_outlined), text: 'Gradebook & What-If'),
                Tab(icon: Icon(Icons.menu_book_outlined), text: 'Study & Vault'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                courseId: widget.courseId,
                instructor: instructor,
                grade: grade,
                attendanceRate: attendanceRate,
                totalStudyHours: totalStudyHours,
                schedules: schedulesList,
              ),
              _DeliverablesTab(
                courseId: widget.courseId,
                assignments: assignmentsList,
                exams: examsList,
                linkedTasks: tasksList,
              ),
              _GradebookTab(
                courseId: widget.courseId,
                grade: grade,
                assignments: assignmentsList,
                exams: examsList,
              ),
              _StudyVaultTab(
                courseId: widget.courseId,
                totalStudyHours: totalStudyHours,
                vaultNotes: vaultNotes,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteCourse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: const Text(
          'This will delete all assignments, exams, schedules, and attendance records associated with this course.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(academicControllerProvider).deleteCourse(widget.courseId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// ==========================================
// TAB 1: OVERVIEW & SCHEDULE
// ==========================================

class _OverviewTab extends ConsumerWidget {
  final String courseId;
  final String? instructor;
  final CourseGradeDetailsModel grade;
  final double attendanceRate;
  final double totalStudyHours;
  final List<ClassScheduleItemModel> schedules;

  const _OverviewTab({
    required this.courseId,
    this.instructor,
    required this.grade,
    required this.attendanceRate,
    required this.totalStudyHours,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context,
                  label: 'Running Grade',
                  value: grade.gradedItemsCount > 0
                      ? '${grade.runningPercentage.toStringAsFixed(1)}% (${grade.letter})'
                      : 'Not Graded',
                  icon: Icons.grade_outlined,
                  color: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  label: 'Attendance Rate',
                  value: '${attendanceRate.toStringAsFixed(0)}%',
                  icon: Icons.how_to_reg_outlined,
                  color: attendanceRate >= 85 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context,
                  label: 'Study Time Logged',
                  value: '${totalStudyHours.toStringAsFixed(1)} hrs',
                  icon: Icons.timer_outlined,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  label: 'Instructor',
                  value: instructor != null && instructor!.isNotEmpty ? instructor! : 'TBA',
                  icon: Icons.person_outline_rounded,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Attendance Quick Check-In
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Attendance Check-In',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Present'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.withAlpha(30),
                    foregroundColor: Colors.green.shade700,
                  ),
                  onPressed: () => _logAttendance(context, ref, 'PRESENT'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  label: const Text('Late'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.withAlpha(30),
                    foregroundColor: Colors.orange.shade800,
                  ),
                  onPressed: () => _logAttendance(context, ref, 'LATE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Absent'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha(30),
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: () => _logAttendance(context, ref, 'ABSENT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Class Timetable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Timetable & Schedule',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Time'),
                onPressed: () => _openAddScheduleDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (schedules.isEmpty)
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No recurring class times set. Tap "+ Add Time" above.'),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final s = schedules[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withAlpha(30),
                      child: Text(
                        s.dayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      '${s.startTime} - ${s.endTime}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(s.room != null && s.room!.isNotEmpty ? 'Room: ${s.room}' : 'No room specified'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => ref.read(academicControllerProvider).deleteClassSchedule(courseId, s.id),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _logAttendance(BuildContext context, WidgetRef ref, String status) async {
    await ref.read(academicControllerProvider).recordAttendance(
          courseId: courseId,
          status: status,
          date: DateTime.now(),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as $status for today.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAddScheduleDialog(BuildContext context, WidgetRef ref) {
    int dayOfWeek = 1;
    final startCtrl = TextEditingController(text: '09:30');
    final endCtrl = TextEditingController(text: '10:50');
    final roomCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Class Time'),
          content: Column(
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
                onChanged: (v) {
                  if (v != null) setState(() => dayOfWeek = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Start (HH:MM)', hintText: '09:30'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End (HH:MM)', hintText: '10:50'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'Room / Hall (optional)', hintText: 'e.g. Science 204'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (startCtrl.text.trim().isEmpty || endCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(academicControllerProvider).addClassSchedule(
                      courseId: courseId,
                      dayOfWeek: dayOfWeek,
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      room: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : null,
                    );
              },
              child: const Text('Save Time'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: DELIVERABLES & EXAMS
// ==========================================

class _DeliverablesTab extends ConsumerStatefulWidget {
  final String courseId;
  final List<AssignmentItemModel> assignments;
  final List<ExamItemModel> exams;
  final List<dynamic> linkedTasks;

  const _DeliverablesTab({
    required this.courseId,
    required this.assignments,
    required this.exams,
    required this.linkedTasks,
  });

  @override
  ConsumerState<_DeliverablesTab> createState() => _DeliverablesTabState();
}

class _DeliverablesTabState extends ConsumerState<_DeliverablesTab> {
  int _selectedView = 0; // 0 = Assignments, 1 = Exams, 2 = Course Tasks

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text('Assignments (${widget.assignments.length})'),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Exams (${widget.exams.length})'),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('Tasks (${widget.linkedTasks.length})'),
                    ),
                  ],
                  selected: {_selectedView},
                  onSelectionChanged: (v) => setState(() => _selectedView = v.first),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(_selectedView == 0
                  ? 'Add Assignment'
                  : _selectedView == 1
                      ? 'Add Exam'
                      : 'Link Task'),
              onPressed: () {
                if (_selectedView == 0) {
                  _openAddAssignmentDialog(context);
                } else if (_selectedView == 1) {
                  _openAddExamDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create or tag tasks with this course in Tasks module.')),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedView == 0
              ? _buildAssignmentsList(colorScheme)
              : _selectedView == 1
                  ? _buildExamsList(colorScheme)
                  : _buildTasksList(colorScheme),
        ),
      ],
    );
  }

  Widget _buildAssignmentsList(ColorScheme cs) {
    if (widget.assignments.isEmpty) {
      return const Center(child: Text('No assignments recorded yet. Tap "+ Add Assignment" above.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.assignments.length,
      itemBuilder: (ctx, i) {
        final a = widget.assignments[i];
        final dueFormatted = DateFormat('MMM d, y').format(a.dueDate);
        final isDueSoon = a.dueDate.difference(DateTime.now()).inDays <= 3 && !a.isCompleted;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outlineVariant.withAlpha(60)),
          ),
          child: ListTile(
            leading: Icon(
              a.isCompleted ? Icons.check_circle : Icons.assignment_outlined,
              color: a.isCompleted ? Colors.green : (isDueSoon ? Colors.orange : Colors.blueAccent),
            ),
            title: Text(
              a.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: a.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${a.type} • Weight: ${a.weight.toStringAsFixed(0)}% • Due: $dueFormatted',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (a.grade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${a.grade!.toStringAsFixed(0)}/${a.maxGrade.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'GRADE') {
                      _openGradeAssignmentDialog(context, a);
                    } else if (val == 'DELETE') {
                      ref.read(academicControllerProvider).deleteAssignment(widget.courseId, a.id);
                    }
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(value: 'GRADE', child: Text('Enter Score / Grade')),
                    const PopupMenuItem(value: 'DELETE', child: Text('Delete Assignment')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamsList(ColorScheme cs) {
    if (widget.exams.isEmpty) {
      return const Center(child: Text('No exams scheduled yet. Tap "+ Add Exam" above.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.exams.length,
      itemBuilder: (ctx, i) {
        final e = widget.exams[i];
        final dateFormatted = DateFormat('MMM d, y').format(e.examDate);
        final daysAway = e.examDate.difference(DateTime.now()).inDays;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outlineVariant.withAlpha(60)),
          ),
          child: ListTile(
            leading: Icon(
              e.isGraded ? Icons.fact_check_rounded : Icons.pending_actions_rounded,
              color: e.isGraded ? Colors.green : Colors.purpleAccent,
            ),
            title: Text(
              e.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${e.examType} • Weight: ${e.weight != null ? '${e.weight!.toStringAsFixed(0)}%' : 'N/A'} • $dateFormatted ${e.startTime ?? ''}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (e.grade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${e.grade!.toStringAsFixed(0)}/${e.maxGrade.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                    ),
                  )
                else if (daysAway >= 0)
                  Chip(
                    label: Text(daysAway == 0 ? 'Today' : 'in $daysAway d'),
                    visualDensity: VisualDensity.compact,
                  ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'GRADE') {
                      _openGradeExamDialog(context, e);
                    } else if (val == 'DELETE') {
                      ref.read(academicControllerProvider).deleteExam(widget.courseId, e.id);
                    }
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(value: 'GRADE', child: Text('Enter Exam Score')),
                    const PopupMenuItem(value: 'DELETE', child: Text('Delete Exam')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksList(ColorScheme cs) {
    if (widget.linkedTasks.isEmpty) {
      return const Center(child: Text('No general tasks linked to this course.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.linkedTasks.length,
      itemBuilder: (ctx, i) {
        final t = widget.linkedTasks[i];
        final isCompleted = t['isCompleted'] == true;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withAlpha(60)),
          ),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.blueGrey,
            ),
            title: Text(
              t['title'] ?? '',
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text('Status: ${t['status']} • Priority: ${t['priority']}'),
          ),
        );
      },
    );
  }

  void _openAddAssignmentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '10');
    String type = 'HOMEWORK';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Lab 3 - Process Scheduling'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Assignment Type'),
                items: const [
                  DropdownMenuItem(value: 'HOMEWORK', child: Text('Homework')),
                  DropdownMenuItem(value: 'LAB', child: Text('Lab Report')),
                  DropdownMenuItem(value: 'PROJECT', child: Text('Project')),
                  DropdownMenuItem(value: 'ESSAY', child: Text('Essay')),
                  DropdownMenuItem(value: 'QUIZ', child: Text('Quiz')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (% of course)', hintText: '10'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Due: ${DateFormat('MMM d, y').format(dueDate)}'),
                trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(academicControllerProvider).createAssignment(
                      courseId: widget.courseId,
                      title: titleCtrl.text.trim(),
                      type: type,
                      weight: double.tryParse(weightCtrl.text.trim()) ?? 10.0,
                      dueDate: dueDate,
                    );
              },
              child: const Text('Save Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExamDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '25');
    final timeCtrl = TextEditingController(text: '09:00');
    String examType = 'MIDTERM';
    DateTime examDate = DateTime.now().add(const Duration(days: 21));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Exam'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Exam Title *', hintText: 'e.g. Midterm Examination'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: examType,
                decoration: const InputDecoration(labelText: 'Exam Type'),
                items: const [
                  DropdownMenuItem(value: 'MIDTERM', child: Text('Midterm')),
                  DropdownMenuItem(value: 'FINAL', child: Text('Final Exam')),
                  DropdownMenuItem(value: 'QUIZ', child: Text('Quiz')),
                  DropdownMenuItem(value: 'ORAL', child: Text('Oral Defense')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => examType = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weight (%)', hintText: '25'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: timeCtrl,
                      decoration: const InputDecoration(labelText: 'Start Time', hintText: '09:00'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('MMM d, y').format(examDate)}'),
                trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: examDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => examDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(academicControllerProvider).createExam(
                      courseId: widget.courseId,
                      title: titleCtrl.text.trim(),
                      examType: examType,
                      weight: double.tryParse(weightCtrl.text.trim()) ?? 25.0,
                      startTime: timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : null,
                      examDate: examDate,
                    );
              },
              child: const Text('Schedule Exam'),
            ),
          ],
        ),
      ),
    );
  }

  void _openGradeAssignmentDialog(BuildContext context, AssignmentItemModel a) {
    final gradeCtrl = TextEditingController(text: a.grade?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: a.maxGrade.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade: ${a.title}'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: gradeCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Score Earned'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(fontSize: 20)),
            ),
            Expanded(
              child: TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Points'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final g = double.tryParse(gradeCtrl.text.trim());
              final m = double.tryParse(maxCtrl.text.trim()) ?? 100.0;
              Navigator.pop(ctx);
              await ref.read(academicControllerProvider).updateAssignment(
                courseId: widget.courseId,
                assignmentId: a.id,
                data: {
                  'grade': g,
                  'maxGrade': m,
                  'status': g != null ? 'GRADED' : 'SUBMITTED',
                },
              );
            },
            child: const Text('Save Score'),
          ),
        ],
      ),
    );
  }

  void _openGradeExamDialog(BuildContext context, ExamItemModel e) {
    final gradeCtrl = TextEditingController(text: e.grade?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: e.maxGrade.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade: ${e.title}'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: gradeCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Score Earned'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(fontSize: 20)),
            ),
            Expanded(
              child: TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Points'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final g = double.tryParse(gradeCtrl.text.trim());
              final m = double.tryParse(maxCtrl.text.trim()) ?? 100.0;
              Navigator.pop(ctx);
              await ref.read(academicControllerProvider).updateExam(
                courseId: widget.courseId,
                examId: e.id,
                data: {
                  'grade': g,
                  'maxGrade': m,
                },
              );
            },
            child: const Text('Save Score'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: GRADEBOOK & WHAT-IF
// ==========================================

class _GradebookTab extends ConsumerStatefulWidget {
  final String courseId;
  final CourseGradeDetailsModel grade;
  final List<AssignmentItemModel> assignments;
  final List<ExamItemModel> exams;

  const _GradebookTab({
    required this.courseId,
    required this.grade,
    required this.assignments,
    required this.exams,
  });

  @override
  ConsumerState<_GradebookTab> createState() => _GradebookTabState();
}

class _GradebookTabState extends ConsumerState<_GradebookTab> {
  double _targetPercent = 90.0;
  double _finalExamWeight = 30.0;
  WhatIfResultModel? _whatIfResult;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _runWhatIf();
  }

  Future<void> _runWhatIf() async {
    setState(() => _isCalculating = true);
    try {
      final res = await ref.read(academicControllerProvider).calculateWhatIf(
            courseId: widget.courseId,
            targetPercentage: _targetPercent,
            finalExamWeight: _finalExamWeight,
          );
      if (mounted) setState(() => _whatIfResult = res);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Running Grade Card
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Course Standing',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.grade.gradedItemsCount > 0 ? widget.grade.letter : 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.grade.gradedItemsCount > 0
                            ? '${widget.grade.runningPercentage.toStringAsFixed(1)}%'
                            : 'No Graded Items',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.grade.gradePoints.toStringAsFixed(1)} / 4.0 GP)',
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Evaluated Weight: ${widget.grade.totalEvaluatedWeight.toStringAsFixed(0)}% of total course (${widget.grade.gradedItemsCount} items completed)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Interactive What-If Final Exam Calculator
          Text(
            'Interactive "What-If" Calculator',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Determine what score you need on your remaining final exam to hit your target letter grade.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Final Grade:'),
                      Text(
                        '${_targetPercent.toStringAsFixed(0)}% (${_getLetterForPct(_targetPercent)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetPercent,
                    min: 60.0,
                    max: 100.0,
                    divisions: 40,
                    label: '${_targetPercent.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setState(() => _targetPercent = val);
                      _runWhatIf();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Exam Weight:'),
                      Text(
                        '${_finalExamWeight.toStringAsFixed(0)}% of Course',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _finalExamWeight,
                    min: 10.0,
                    max: 60.0,
                    divisions: 10,
                    label: '${_finalExamWeight.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setState(() => _finalExamWeight = val);
                      _runWhatIf();
                    },
                  ),
                  const Divider(height: 24),
                  if (_isCalculating)
                    const Center(child: CircularProgressIndicator())
                  else if (_whatIfResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _whatIfResult!.status == 'ACHIEVABLE'
                            ? Colors.green.withAlpha(25)
                            : _whatIfResult!.status == 'ALREADY_SECURED'
                                ? Colors.blue.withAlpha(25)
                                : Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _whatIfResult!.status == 'ACHIEVABLE'
                                    ? Icons.check_circle_outline
                                    : _whatIfResult!.status == 'ALREADY_SECURED'
                                        ? Icons.celebration_outlined
                                        : Icons.warning_amber_rounded,
                                color: _whatIfResult!.status == 'ACHIEVABLE'
                                    ? Colors.green
                                    : _whatIfResult!.status == 'ALREADY_SECURED'
                                        ? Colors.blueAccent
                                        : Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _whatIfResult!.status.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _whatIfResult!.status == 'ACHIEVABLE'
                                      ? Colors.green
                                      : _whatIfResult!.status == 'ALREADY_SECURED'
                                          ? Colors.blueAccent
                                          : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _whatIfResult!.message,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLetterForPct(double pct) {
    if (pct >= 93) return 'A';
    if (pct >= 90) return 'A-';
    if (pct >= 87) return 'B+';
    if (pct >= 83) return 'B';
    if (pct >= 80) return 'B-';
    if (pct >= 77) return 'C+';
    if (pct >= 73) return 'C';
    if (pct >= 70) return 'C-';
    if (pct >= 60) return 'D';
    return 'F';
  }
}

// ==========================================
// TAB 4: STUDY & VAULT
// ==========================================

class _StudyVaultTab extends ConsumerWidget {
  final String courseId;
  final double totalStudyHours;
  final List<dynamic> vaultNotes;

  const _StudyVaultTab({
    required this.courseId,
    required this.totalStudyHours,
    required this.vaultNotes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study Hours Banner
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent.withAlpha(30),
                    child: const Icon(Icons.timer_outlined, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${totalStudyHours.toStringAsFixed(1)} Focus Hours Logged',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Combined from Focus Timer and Study Sessions.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log'),
                    onPressed: () => _openLogStudyDialog(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Course Vault Notes & Syllabus
          Text(
            'Course Notes & Syllabus (Knowledge Vault)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (vaultNotes.isEmpty)
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No notes attached to this course yet. Link notes from the Vault module.'),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vaultNotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = vaultNotes[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined, color: Colors.indigoAccent),
                    title: Text(n['title'] ?? 'Note', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Last updated: ${n['updatedAt']?.toString().split('T')[0] ?? ''}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openLogStudyDialog(BuildContext context, WidgetRef ref) {
    final minutesCtrl = TextEditingController(text: '45');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Study Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minutesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes Studied *', hintText: '45'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Topics Covered (optional)', hintText: 'Chapters 4 & 5'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final mins = int.tryParse(minutesCtrl.text.trim());
              if (mins == null || mins <= 0) return;
              Navigator.pop(ctx);
              await ref.read(academicControllerProvider).recordStudySession(
                    courseId: courseId,
                    durationMinutes: mins,
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
            },
            child: const Text('Log Time'),
          ),
        ],
      ),
    );
  }
}
