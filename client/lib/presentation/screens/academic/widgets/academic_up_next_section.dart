import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../models/academic_models.dart';

class AcademicUpNextSection extends StatelessWidget {
  final List<CourseOverviewModel> courses;
  final Function(String courseId)? onCourseTap;

  const AcademicUpNextSection({
    super.key,
    required this.courses,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Collect upcoming schedule items across enrolled courses
    final items = <_UpNextItem>[];

    for (final course in courses) {
      if (course.assignmentsCount > 0) {
        items.add(
          _UpNextItem(
            courseId: course.id,
            courseCode:
                course.code ?? course.name.substring(0, 3).toUpperCase(),
            title: '${course.name} Assignment',
            subtext: '${course.assignmentsCount} pending',
            isExam: false,
          ),
        );
      }
      if (course.examsCount > 0) {
        items.add(
          _UpNextItem(
            courseId: course.id,
            courseCode:
                course.code ?? course.name.substring(0, 3).toUpperCase(),
            title: '${course.name} Exam',
            subtext: '${course.examsCount} upcoming',
            isExam: true,
          ),
        );
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UP NEXT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant.withAlpha(160),
          ),
        ),
        AppSpacing.verticalGapSm,
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onCourseTap?.call(item.courseId);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(40),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.isExam
                          ? colorScheme.tertiary.withAlpha(80)
                          : colorScheme.outlineVariant.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isExam
                                  ? colorScheme.tertiary.withAlpha(20)
                                  : colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.courseCode,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: item.isExam
                                    ? colorScheme.tertiary
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                          Icon(
                            item.isExam
                                ? Icons.fact_check_outlined
                                : Icons.assignment_outlined,
                            size: 16,
                            color: item.isExam
                                ? colorScheme.tertiary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.subtext,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UpNextItem {
  final String courseId;
  final String courseCode;
  final String title;
  final String subtext;
  final bool isExam;

  _UpNextItem({
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.subtext,
    required this.isExam,
  });
}
