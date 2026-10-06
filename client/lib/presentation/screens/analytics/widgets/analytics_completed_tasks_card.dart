import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class AnalyticsCompletedTasksCard extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsCompletedTasksCard({super.key, required this.retro});

  Color _getPriorityColor(String priority, BuildContext context) {
    final semantics = AppSemanticColors.of(context);
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return semantics.danger;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return semantics.info;
      case 'LOW':
      default:
        return semantics.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final tasks = retro.completedTasks;

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPLETED TASKS RECAP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: semantics.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: semantics.success.withAlpha(50)),
                ),
                child: Text(
                  '${tasks.length} finished',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: semantics.success,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,

          // Virtualized List of Completed Tasks with bounded constraints
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tasks.length,
              separatorBuilder: (_, __) => Divider(
                height: 12,
                thickness: 0.8,
                color: colorScheme.outlineVariant.withAlpha(30),
              ),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final priorityColor = _getPriorityColor(task.priority, context);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: semantics.success.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: semantics.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: priorityColor.withAlpha(45), width: 0.8),
                        ),
                        child: Text(
                          task.priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: priorityColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
