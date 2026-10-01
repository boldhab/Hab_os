import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AcademicHeroCard extends StatelessWidget {
  final Map<String, dynamic>? summaryData;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onDeadlinesTap;
  final VoidCallback? onExamsTap;

  const AcademicHeroCard({
    super.key,
    required this.summaryData,
    this.onAttendanceTap,
    this.onDeadlinesTap,
    this.onExamsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    final gpa = (summaryData?['cumulativeGpa'] as num?)?.toDouble() ?? 0.0;
    final gpaLetter = summaryData?['cumulativeLetter'] as String? ?? 'N/A';
    final attendance =
        (summaryData?['overallAttendanceRate'] as num?)?.toDouble() ?? 100.0;
    final upcomingAssignments =
        summaryData?['upcomingAssignmentsCount'] as int? ?? 0;
    final upcomingExams = summaryData?['upcomingExamsCount'] as int? ?? 0;

    final isAttendanceWarning = attendance < 85.0;
    final attendanceColor =
        isAttendanceWarning ? semantics.danger : semantics.success;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryRed.withAlpha(28),
            primaryRed.withAlpha(8),
            colorScheme.surfaceContainerHighest.withAlpha(40),
          ],
        ),
        border: Border.all(
          color: primaryRed.withAlpha(45),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // GPA Hero Section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUMULATIVE GPA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colorScheme.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          gpa > 0 ? gpa.toStringAsFixed(2) : '0.00',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            color: colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/4.0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withAlpha(70),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    gpaLetter,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withAlpha(30),
          ),

          // Slim 3-Column KPI Row
          IntrinsicHeight(
            child: Row(
              children: [
                // Attendance KPI
                Expanded(
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      onAttendanceTap?.call();
                    },
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  value: (attendance / 100).clamp(0.0, 1.0),
                                  strokeWidth: 2.5,
                                  backgroundColor:
                                      attendanceColor.withAlpha(30),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      attendanceColor),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${attendance.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: attendanceColor,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ATTENDANCE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                VerticalDivider(
                    width: 1, color: colorScheme.outlineVariant.withAlpha(30)),

                // Deadlines KPI
                Expanded(
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      onDeadlinesTap?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Text(
                            '$upcomingAssignments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'DEADLINES',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                VerticalDivider(
                    width: 1, color: colorScheme.outlineVariant.withAlpha(30)),

                // Exams KPI
                Expanded(
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      onExamsTap?.call();
                    },
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Text(
                            '$upcomingExams',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.tertiary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'EXAMS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(150),
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
        ],
      ),
    );
  }
}
