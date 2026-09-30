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

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  final _subtaskController = TextEditingController();
  bool _isAddingSubtask = false;

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  Color _priorityColor(String priority, ColorScheme cs) {
    return switch (priority.toUpperCase()) {
      'CRITICAL' => cs.error,
      'HIGH' => Colors.orange,
      'MEDIUM' => cs.tertiary,
      _ => cs.outline,
    };
  }

  Future<void> _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isAddingSubtask = true);
    try {
      await ref.read(taskRepositoryProvider).createSubtask(widget.taskId, title);
      _subtaskController.clear();
      ref.invalidate(taskDetailsProvider(widget.taskId));
      ref.read(tasksProvider.notifier).loadTasks(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subtask: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingSubtask = false);
    }
  }

  Future<void> _showAddPrerequisiteDialog(TaskModel currentTask) async {
    final allTasks = ref.read(tasksProvider).tasks;
    final candidateTasks = allTasks.where((t) {
      if (t.id == currentTask.id) return false;
      if (t.parentTaskId == currentTask.id) return false;
      final isAlreadyBlocker = currentTask.blockedBy
          .any((b) => b['blockingTaskId'] == t.id);
      return !isAlreadyBlocker;
    }).toList();

    if (candidateTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible prerequisite tasks found to link.')),
      );
      return;
    }

    final selected = await showDialog<TaskModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Prerequisite'),
        content: SizedBox(
          width: double.maxFinite,
          child: candidateTasks.isEmpty
              ? const Text('No other tasks available.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidateTasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = candidateTasks[i];
                    return ListTile(
                      title: Text(t.title),
                      subtitle: Text(
                        'Priority: ${t.priority} • ${t.isCompleted ? "Completed" : "Active"}',
                      ),
                      trailing: Icon(
                        t.isCompleted
                            ? Icons.check_circle_outline_rounded
                            : Icons.lock_outline_rounded,
                        size: 20,
                      ),
                      onTap: () => Navigator.pop(ctx, t),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      try {
        await ref
            .read(taskRepositoryProvider)
            .addDependency(currentTask.id, selected.id);
        ref.invalidate(taskDetailsProvider(widget.taskId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailsProvider(widget.taskId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(taskDetailsProvider(widget.taskId)),
          ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(taskDetailsProvider(widget.taskId)),
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

                // ── Subtasks Checklist (when top-level task) ─────────────────
                if (task.parentTaskId == null) ...[
                  _buildSubtasksSection(context, task),
                  const SizedBox(height: 20),
                ],

                // ── Prerequisites & Blockers ─────────────────────────────────
                _buildPrerequisitesSection(context, task),
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
        data: (task) => _buildBottomActions(context, task),
      ),
    );
  }

  Widget _buildSubtasksSection(BuildContext context, TaskModel task) {
    final completedCount = task.subtasks.where((s) => s.isCompleted).length;
    final totalCount = task.subtasks.length;
    final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtasks ($completedCount/$totalCount)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (totalCount > 0)
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
          ],
        ),
        if (totalCount > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              ...task.subtasks.map((s) => CheckboxListTile(
                    dense: true,
                    value: s.isCompleted,
                    title: Text(
                      s.title,
                      style: TextStyle(
                        decoration:
                            s.isCompleted ? TextDecoration.lineThrough : null,
                        color: s.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    onChanged: (val) async {
                      await ref
                          .read(taskRepositoryProvider)
                          .toggleComplete(s.id);
                      ref.invalidate(taskDetailsProvider(widget.taskId));
                      ref
                          .read(tasksProvider.notifier)
                          .loadTasks(showLoading: false);
                    },
                  )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: const InputDecoration(
                          hintText: 'Add subtask...',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    _isAddingSubtask
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: _addSubtask,
                            tooltip: 'Add subtask',
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrerequisitesSection(BuildContext context, TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUnfinishedBlockers =
        task.blockedBy.any((b) => b['blockingTask']?['isCompleted'] != true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Prerequisites (${task.blockedBy.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (hasUnfinishedBlockers) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock_rounded, size: 16, color: Colors.amber),
                ],
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: const Text('Add Blocker'),
              onPressed: () => _showAddPrerequisiteDialog(task),
            ),
          ],
        ),
        if (hasUnfinishedBlockers) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This task is blocked. Complete all prerequisite tasks before marking it as done.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (task.blockedBy.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No prerequisites. This task can be worked on freely.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: task.blockedBy.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final dep = task.blockedBy[i];
              final blocker = dep['blockingTask'] ?? {};
              final isDone = blocker['isCompleted'] == true;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.lock_clock_rounded,
                      size: 20,
                      color: isDone ? Colors.green : Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        blocker['title'] ?? 'Task',
                        style: TextStyle(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Remove blocker',
                      onPressed: () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .removeDependency(task.id, dep['blockingTaskId']);
                        ref.invalidate(taskDetailsProvider(widget.taskId));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        if (task.blocking.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Tasks Waiting on This (${task.blocking.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: task.blocking.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final dep = task.blocking[i];
              final blocked = dep['blockedTask'] ?? {};
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        blocked['title'] ?? 'Task',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, TaskModel task) {
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
                  ref.read(focusProvider.notifier).setCategory('CODING');
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
                final err = await ref
                    .read(tasksProvider.notifier)
                    .toggleTaskComplete(task);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                ref.invalidate(taskDetailsProvider(widget.taskId));
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
                  ref.invalidate(taskDetailsProvider(widget.taskId));
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
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
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
