import 'package:flutter/material.dart';
import '../../../../data/models/dashboard_feed_model.dart';

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
    final remaining = tasks.where((t) => !t.isCompleted).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tasks Due Today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (remaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$remaining left',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: colorScheme.tertiary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Nothing due today!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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

  Color _priorityColor(String priority, ColorScheme cs) {
    return switch (priority.toUpperCase()) {
      'HIGH' || 'URGENT' => cs.error,
      'MEDIUM' => cs.tertiary,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(task.id, task.isCompleted),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: task.isCompleted
                    ? colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? colorScheme.primary
                      : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? Icon(Icons.check_rounded,
                      size: 13, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
              ),
            ),

            // Priority dot
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _priorityColor(task.priority, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
