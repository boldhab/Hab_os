import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'controllers/academic_controller.dart';
import 'models/academic_models.dart';

export 'controllers/academic_controller.dart';
export 'models/academic_models.dart';

class AcademicScreen extends ConsumerWidget {
  const AcademicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSemester = ref.watch(selectedSemesterProvider);
    final coursesAsync = ref.watch(academicCoursesListProvider(selectedSemester));
    final summaryAsync = ref.watch(academicSummaryProvider);

    return Scaffold(

      appBar: AppBar(
        title: const Text('Academic & Student Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(academicControllerProvider).invalidateAll();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(academicControllerProvider).invalidateAll();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            // 1. Academic High-Level KPI Strip (Cumulative GPA, Attendance, Evaluations)
            summaryAsync.when(
              loading: () => const SizedBox(height: 70, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                final gpa = (summary['cumulativeGpa'] as num?)?.toDouble() ?? 0.0;
                final gpaLetter = summary['cumulativeLetter'] ?? 'N/A';
                final attendance = (summary['overallAttendanceRate'] as num?)?.toDouble() ?? 100.0;
                final upcomingAssignments = summary['upcomingAssignmentsCount'] ?? 0;
                final upcomingExams = summary['upcomingExamsCount'] ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Cumulative GPA',
                            value: gpa > 0 ? '${gpa.toStringAsFixed(2)} ($gpaLetter)' : 'N/A',
                            icon: Icons.school_outlined,
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Overall Attendance',
                            value: '${attendance.toStringAsFixed(0)}%',
                            icon: Icons.how_to_reg_outlined,
                            color: attendance >= 85 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Upcoming Deadlines',
                            value: '$upcomingAssignments Assignments',
                            icon: Icons.assignment_outlined,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Upcoming Exams',
                            value: '$upcomingExams Exams',
                            icon: Icons.fact_check_outlined,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // 2. Semester Filter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Enrolled Courses',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: selectedSemester ?? 'Fall 2026',
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: const [
                    DropdownMenuItem(value: 'Fall 2026', child: Text('Fall 2026')),
                    DropdownMenuItem(value: 'Spring 2026', child: Text('Spring 2026')),
                    DropdownMenuItem(value: 'ALL', child: Text('All Semesters')),
                  ],
                  onChanged: (val) {
                    ref.read(selectedSemesterProvider.notifier).state = val;
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Courses List or Empty State
            coursesAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => AppErrorState(
                message: err.toString(),
                onRetry: () => ref.read(academicControllerProvider).invalidateAll(),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.school_outlined,
                    title: 'No academic courses enrolled',
                    description: 'Tap "+ Add Course" to track assignments, exams, and grades.',
                    actionLabel: 'Add Course',
                    onAction: () => _openCreateCourseDialog(context, ref),
                  );
                }

                return Column(
                  children: courses.map((c) => _CourseCard(course: c)).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateCourseDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Course'),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateCourseDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final instructorCtrl = TextEditingController();
    final semesterCtrl = TextEditingController(text: 'Fall 2026');
    int credits = 3;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Enroll New Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course Name *',
                    hintText: 'e.g. Operating Systems',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Code (optional)',
                          hintText: 'CS401',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: credits,
                        decoration: const InputDecoration(labelText: 'Credits'),
                        items: [1, 2, 3, 4, 5, 6].map((c) {
                          return DropdownMenuItem(value: c, child: Text('$c cr'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => credits = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: semesterCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    hintText: 'Fall 2026',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instructor (optional)',
                    hintText: 'Dr. Jane Smith',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enroll'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(academicControllerProvider).createCourse(
            name: nameCtrl.text.trim(),
            code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : null,
            semester: semesterCtrl.text.trim(),
            instructor: instructorCtrl.text.trim().isNotEmpty ? instructorCtrl.text.trim() : null,
            credits: credits,
          );
    }
  }
}

class _CourseCard extends StatelessWidget {
  final CourseOverviewModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (course.progress / 100.0).clamp(0.0, 1.0);
    final hasGrade = course.gradeDetails.gradedItemsCount > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      color: colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/more/academic/${course.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Grade Pill
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${course.code != null ? '${course.code} • ' : ''}${course.credits} Credits • ${course.instructor ?? 'No Instructor'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasGrade ? Colors.deepPurpleAccent.withAlpha(30) : colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasGrade
                          ? '${course.gradeDetails.runningPercentage.toStringAsFixed(0)}% (${course.gradeDetails.letter})'
                          : 'Not Graded',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasGrade ? Colors.deepPurpleAccent : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Evaluations Completed (${course.progress.toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    'Attendance: ${course.attendanceRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: course.attendanceRate >= 85 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: colorScheme.primary.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Badges: Schedule Times & Deliverable counts
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${course.assignmentsCount} assignments',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${course.examsCount} exams',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (course.classSchedules.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 10, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text(
                            course.classSchedules.map((s) => '${s.dayName} ${s.startTime}').join(', '),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
