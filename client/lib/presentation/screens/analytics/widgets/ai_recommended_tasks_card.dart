import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/ai_insights_model.dart';
import '../../../widgets/common/app_card.dart';

/// Renders intelligent task recommendations based on priority, deadlines, and neglected domains (UC-141)
class AiRecommendedTasksCard extends StatelessWidget {
  final List<RecommendedTask> tasks;
  final ValueChanged<RecommendedTask>? onTaskSelected;

  const AiRecommendedTasksCard({
    super.key,
    required this.tasks,
    this.onTaskSelected,
  });

  Color _getPriorityColor(String priority, ColorScheme colorScheme) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return colorScheme.error;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MEDIUM':
        return Colors.blue.shade600;
      case 'LOW':
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colorScheme.primary;

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      borderRadius: AppRadius.lg,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              AppSpacing.horizontalGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI PRIORITY ENGINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: primary,
                      ),
                    ),
                    AppSpacing.verticalGapXs,
                    Text(
                      'Recommended Next Tasks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final prioColor = _getPriorityColor(task.priority, colorScheme);
              final rank = index + 1;

              return InkWell(
                onTap: () => onTaskSelected?.call(task),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 70 : 40),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: rank == 1 ? primary.withAlpha(70) : colorScheme.outlineVariant.withAlpha(60),
                      width: rank == 1 ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank badge
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank == 1 ? primary : colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: rank == 1 ? primary : colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: rank == 1 ? Colors.white : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AppSpacing.horizontalGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: prioColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    task.priority,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: prioColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.verticalGapXs,
                            Text(
                              task.reason,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: rank == 1 ? primary : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.verticalGapXs,
                            Row(
                              children: [
                                if (task.projectName != null) ...[
                                  Text(
                                    'Project: ${task.projectName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else if (task.courseName != null) ...[
                                  Text(
                                    'Course: ${task.courseName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (task.estimatedMinutes != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${task.estimatedMinutes}m',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
