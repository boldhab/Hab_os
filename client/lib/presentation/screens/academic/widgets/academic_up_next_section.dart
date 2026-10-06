import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../models/academic_models.dart';

class AcademicUpNextSection extends StatelessWidget {
  final List<UpcomingDeliverableModel> deliverables;
  final int? totalCount;
  final Function(String courseId)? onCourseTap;

  const AcademicUpNextSection({
    super.key,
    required this.deliverables,
    this.totalCount,
    this.onCourseTap,
  });

  String _formatDate(DateTime date, bool isExam, String? startTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    final prefix = isExam ? 'Exam: ' : 'Due ';
    if (diffDays == 0) {
      return '$prefix Today${startTime != null ? " ($startTime)" : ""}';
    } else if (diffDays == 1) {
      return '$prefix Tomorrow${startTime != null ? " ($startTime)" : ""}';
    } else if (diffDays > 1 && diffDays <= 7) {
      return '$prefix in $diffDays days';
    } else {
      final df = DateFormat('MMM d');
      return '$prefix${df.format(date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (deliverables.isEmpty) return const SizedBox.shrink();

    final label = (totalCount != null && totalCount! > deliverables.length)
        ? 'UP NEXT (${deliverables.length} of $totalCount)'
        : 'UP NEXT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant.withAlpha(160),
          ),
        ),
        AppSpacing.verticalGapSm,
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: deliverables.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = deliverables[index];
              final code = item.courseCode ??
                  (item.courseName.length >= 3
                      ? item.courseName.substring(0, 3).toUpperCase()
                      : item.courseName);
              final subtext = _formatDate(item.date, item.isExam, item.startTime);

              return InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onCourseTap?.call(item.courseId);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 220,
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
                              code,
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
                        subtext,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: item.isExam
                              ? colorScheme.tertiary
                              : colorScheme.onSurfaceVariant.withAlpha(150),
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
