import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/focus_provider.dart';
import '../../widgets/app_error_state.dart';
import 'widgets/task_form_dialog.dart';

final taskDetailsProvider =
    FutureProvider.autoDispose.family<TaskModel, String>((ref, taskId) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTaskById(taskId);
});

class TaskDetailsScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  Color _priorityColor(String priority, ColorScheme cs) {
    return switch (priority.toUpperCase()) {
      'CRITICAL' => cs.error,
      'HIGH' => Colors.orange,
      'MEDIUM' => cs.tertiary,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailsProvider(taskId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(taskDetailsProvider(taskId)),
          ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(taskDetailsProvider(taskId)),
        ),
        data: (task) {
          final totalFocusMins = task.focusSessions
              .fold(0, (sum, f) => sum + f.durationMinutes);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ─────────────────────────────────────────────
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _priorityColor(task.priority, colorScheme)
                                    .withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.priority,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: _priorityColor(
                                          task.priority, colorScheme),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? Colors.green.withAlpha(40)
                                    : colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.status.replaceAll('_', ' '),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: task.isCompleted
                                          ? Colors.green.shade700
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          task.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withAlpha(200),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Hierarchy & Relationships (Goal -> Project -> Task) ──────
                Text(
                  'Hierarchy & Context',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('Goal'),
                        subtitle: Text(task.goal?.title ?? 'None linked'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: const Text('Project'),
                        subtitle: Text(task.project?.title ?? 'None linked'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Time Tracking Stats ──────────────────────────────────────
                Text(
                  'Time & Dates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due Date',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                task.dueDate != null
                                    ? task.dueDate!.split('T')[0]
                                    : 'No due date',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estimated Time',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                task.estimatedMinutes != null
                                    ? '${task.estimatedMinutes}m'
                                    : 'Unestimated',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Focus Spent',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                '${totalFocusMins}m',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Linked Focus Sessions ────────────────────────────────────
                Text(
                  'Focus Sessions (${task.focusSessions.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (task.focusSessions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No focus sessions recorded for this task yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: task.focusSessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final f = task.focusSessions[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(f.category),
                            const Spacer(),
                            Text('${f.durationMinutes} min',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: taskAsync.whenOrNull(
        data: (task) => _buildBottomActions(context, ref, task),
      ),
    );
  }

  Widget _buildBottomActions(
      BuildContext context, WidgetRef ref, TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Start Focus button
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // Switch to Focus tab with category set
                  ref
                      .read(focusProvider.notifier)
                      .setCategory('CODING');
                  context.go('/focus');
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Focus'),
              ),
            ),
            const SizedBox(width: 8),

            // Complete Toggle
            IconButton.filledTonal(
              icon: Icon(
                task.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_rounded,
              ),
              onPressed: () async {
                await ref
                    .read(tasksProvider.notifier)
                    .toggleTaskComplete(task);
                ref.invalidate(taskDetailsProvider(taskId));
              },
            ),

            // Edit
            IconButton.outlined(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => TaskFormDialog(task: task),
                );
                if (result != null) {
                  await ref
                      .read(tasksProvider.notifier)
                      .updateTask(task.id, result);
                  ref.invalidate(taskDetailsProvider(taskId));
                }
              },
            ),

            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: Text(
                        'Are you sure you want to delete "${task.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(tasksProvider.notifier).deleteTask(task.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
