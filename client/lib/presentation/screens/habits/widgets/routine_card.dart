import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/habit_model.dart';

/// Card rendering an individual habit routine with sequential step items, completion status, and quick actions.
class RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      color: colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary.withAlpha(40),
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 18, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (routine.description != null &&
                            routine.description!.isNotEmpty)
                          Text(
                            routine.description!,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Routine',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: semantics.danger),
                    tooltip: 'Delete Routine',
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),

              // Step items
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: routine.items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: item.isCompletedToday
                                ? semantics.success
                                : colorScheme.primary.withAlpha(50),
                            child: item.isCompletedToday
                                ? Icon(Icons.check,
                                    size: 12, color: semantics.onSuccess)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.habitName,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: item.isCompletedToday
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isCompletedToday
                                    ? colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                          ),
                          Text('🔥 ${item.currentStreak}d',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),

              // Actions row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 12,
                children: [
                  Text(
                    '${routine.completedCount}/${routine.totalHabits} completed today',
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  FilledButton.icon(
                    icon: Icon(
                      routine.isCompletedToday
                          ? Icons.check_circle_rounded
                          : Icons.play_arrow_rounded,
                      size: 16,
                    ),
                    label: Text(routine.isCompletedToday
                        ? 'Ritual Done'
                        : 'Complete Ritual'),
                    onPressed: routine.isCompletedToday ? null : onComplete,
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
