import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'controllers/academic_controller.dart';
import 'widgets/academic_hero_card.dart';
import 'widgets/academic_up_next_section.dart';
import 'widgets/academic_course_card.dart';
import 'widgets/academic_semester_sheet.dart';
import 'widgets/academic_enroll_dialog.dart';
import 'course_detail_screen.dart';

export 'controllers/academic_controller.dart';
export 'models/academic_models.dart';

class AcademicScreen extends ConsumerStatefulWidget {
  const AcademicScreen({super.key});

  @override
  ConsumerState<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends ConsumerState<AcademicScreen> {
  String? _selectedCourseId;

  void _openSemesterSheet(BuildContext context, String? currentSemester) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AcademicSemesterSheet(
        currentSemester: currentSemester,
        onSelectSemester: (sem) {
          ref.read(selectedSemesterProvider.notifier).state = sem;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSemester = ref.watch(selectedSemesterProvider);
    final coursesAsync =
        ref.watch(academicCoursesListProvider(selectedSemester));
    final summaryAsync = ref.watch(academicSummaryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        final mainListContent = Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Academic',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () =>
                          _openSemesterSheet(context, selectedSemester),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryRed.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: primaryRed.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedSemester ?? 'Fall 2026',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryRed,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 14, color: primaryRed),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  AppHaptics.light();
                  ref.read(academicControllerProvider).invalidateAll();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.read(academicControllerProvider).invalidateAll();
            },
            color: primaryRed,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                // 1. Hero Summary Card (GPA + Slim 3-column KPI row)
                summaryAsync.when(
                  loading: () => Container(
                    height: 140,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (summaryData) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AcademicHeroCard(summaryData: summaryData),
                  ),
                ),

                // 2. Up Next Section (Horizontal Deadline Cards)
                coursesAsync.when(
                  data: (courses) {
                    if (courses.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: AcademicUpNextSection(
                        courses: courses,
                        onCourseTap: (id) {
                          if (isWide) {
                            setState(() => _selectedCourseId = id);
                          } else {
                            context.push('/more/academic/$id');
                          }
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 3. Enrolled Courses Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENROLLED COURSES',
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

                // 4. Enrolled Courses List
                coursesAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        height: 90,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color:
                              colorScheme.surfaceContainerHighest.withAlpha(40),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  error: (err, _) => AppErrorState(
                    message: err.toString(),
                    onRetry: () =>
                        ref.read(academicControllerProvider).invalidateAll(),
                  ),
                  data: (courses) {
                    if (courses.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.school_outlined,
                        title: 'No academic courses enrolled',
                        description:
                            'Add your first course to start tracking your grades.',
                        actionLabel: 'Enroll Course',
                        onAction: () => _openCreateCourse(context),
                      );
                    }

                    return Column(
                      children: courses.map((course) {
                        return AcademicCourseCard(
                          course: course,
                          onTap: () {
                            if (isWide) {
                              setState(() => _selectedCourseId = course.id);
                            } else {
                              context.push('/more/academic/${course.id}');
                            }
                          },
                          onDelete: () {
                            ref
                                .read(academicControllerProvider)
                                .deleteCourse(course.id);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateCourse(context),
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Course',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              SizedBox(width: 420, child: mainListContent),
              VerticalDivider(
                  width: 1, color: colorScheme.outlineVariant.withAlpha(40)),
              Expanded(
                child: _selectedCourseId == null
                    ? Scaffold(
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        body: const Center(
                          child: Text(
                            'Select a course to view details',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : CourseDetailScreen(courseId: _selectedCourseId!),
              ),
            ],
          );
        }

        return mainListContent;
      },
    );
  }

  void _openCreateCourse(BuildContext context) {
    AcademicEnrollDialog.show(
      context,
      onEnroll: ({
        required name,
        code,
        required semester,
        instructor,
        required credits,
      }) async {
        await ref.read(academicControllerProvider).createCourse(
              name: name,
              code: code,
              semester: semester,
              instructor: instructor,
              credits: credits,
            );
      },
    );
  }
}
