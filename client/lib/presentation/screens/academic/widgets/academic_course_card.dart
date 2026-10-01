import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../models/academic_models.dart';

class AcademicCourseCard extends StatelessWidget {
  final CourseOverviewModel course;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AcademicCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onDelete,
  });

  Color _parseHexColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    final pct = (course.progress / 100.0).clamp(0.0, 1.0);
    final hasGrade = course.gradeDetails.gradedItemsCount > 0;
    final isAttendanceWarning = course.attendanceRate < 85.0;
    final attendanceColor =
        isAttendanceWarning ? semantics.danger : semantics.success;

    final accentColor = _parseHexColor(course.color, primaryRed);

    // Summary line for schedule and counts
    final summaryParts = <String>[];
    if (course.assignmentsCount > 0) {
      summaryParts.add('${course.assignmentsCount} assignments');
    }
    if (course.examsCount > 0) {
      summaryParts.add('${course.examsCount} exams');
    }
    if (course.classSchedules.isNotEmpty) {
      final sched = course.classSchedules
          .map((s) => '${s.dayName} ${s.startTime}')
          .join(', ');
      summaryParts.add(sched);
    }
    final summaryText = summaryParts.isEmpty
        ? 'No active deliverables'
        : summaryParts.join(' · ');

    final subtitleParts = <String>[];
    if (course.code != null && course.code!.isNotEmpty) {
      subtitleParts.add(course.code!);
    }
    subtitleParts.add('${course.credits} Credits');
    if (course.instructor != null && course.instructor!.isNotEmpty) {
      subtitleParts.add(course.instructor!);
    }
    final subtitleText = subtitleParts.join(' · ');

    return Dismissible(
      key: Key(course.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Course?'),
            content: Text('Are you sure you want to delete "${course.name}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    FilledButton.styleFrom(backgroundColor: colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(9),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Thin Left Accent Bar derived from course color
                Container(
                  width: 4,
                  color: accentColor.withAlpha(200),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      onTap();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Top Metrics
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant
                                      .withAlpha(160),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                children: [
                                  // Attendance Badge
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.how_to_reg_rounded,
                                          size: 14, color: attendanceColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course.attendanceRate.toStringAsFixed(0)}% attendance',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: attendanceColor,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Grade Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hasGrade
                                          ? primaryRed.withAlpha(20)
                                          : colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.pill),
                                      border: Border.all(
                                        color: hasGrade
                                            ? primaryRed.withAlpha(60)
                                            : colorScheme.outlineVariant
                                                .withAlpha(40),
                                      ),
                                    ),
                                    child: Text(
                                      hasGrade
                                          ? '${course.gradeDetails.runningPercentage.toStringAsFixed(0)}% (${course.gradeDetails.letter})'
                                          : 'Not Graded',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: hasGrade
                                            ? primaryRed
                                            : colorScheme.onSurfaceVariant,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.verticalGapMd,

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor:
                                  colorScheme.outlineVariant.withAlpha(30),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryRed),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Single Muted Summary Line
                          Text(
                            summaryText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
