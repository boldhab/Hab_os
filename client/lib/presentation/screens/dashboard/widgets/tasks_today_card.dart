import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/app_animated_check.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/section_header.dart';

/// Tasks due today with tap-to-complete toggle and priority chips.
class TasksTodayCard extends StatelessWidget {
  final List<DashboardTaskItem> tasks;
  final void Function(String taskId, bool currentValue) onToggle;

  const TasksTodayCard({
    super.key,
    required this.tasks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryRed = colorScheme.primary;
    final remaining = tasks.where((t) => !t.isCompleted).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SectionHeader(
            icon: Icons.task_alt_rounded,
            title: 'Tasks Due Today',
            action: remaining > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$remaining left',
                      style: textTheme.labelSmall?.copyWith(
                        color: primaryRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
          ),
          AppSpacing.verticalGapSm,

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF34A853),
                    size: 18,
                  ),
                  AppSpacing.horizontalGapSm,
                  Text(
                    'Nothing due today!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...tasks.map((t) => _TaskRow(
                  task: t,
                  onToggle: onToggle,
                  colorScheme: colorScheme,
                )),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DashboardTaskItem task;
  final void Function(String, bool) onToggle;
  final ColorScheme colorScheme;

  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.colorScheme,
  });

  Color _priorityColor(String priority) {
    return switch (priority.toUpperCase()) {
      'HIGH' || 'URGENT' || 'CRITICAL' => const Color(0xFFEA4335),
      'MEDIUM' => const Color(0xFFFBBC05),
      _ => const Color(0xFF4285F4),
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final priorityColor = _priorityColor(task.priority);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: InkWell(
        onTap: () => onToggle(task.id, task.isCompleted),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Checkbox
              AppAnimatedCheck(
                value: task.isCompleted,
                onChanged: (_) => onToggle(task.id, task.isCompleted),
                size: 22,
                activeColor: colorScheme.primary,
              ),
              AppSpacing.horizontalGapMd,

              // Title
              Expanded(
                child: Text(
                  task.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        task.isCompleted ? FontWeight.w400 : FontWeight.w600,
                    fontSize: 14,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? colorScheme.onSurfaceVariant.withAlpha(150)
                        : colorScheme.onSurface,
                  ),
                ),
              ),

              // Priority Pill Tag
              AppSpacing.horizontalGapSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: priorityColor.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: priorityColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
