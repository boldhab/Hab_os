import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/app_error_state.dart';
import '../controllers/projects_controller.dart';
import '../../../providers/tasks_provider.dart';
import '../../../screens/tasks/widgets/task_form_dialog.dart';

class TasksTab extends ConsumerWidget {
  final String projectId;
  const TasksTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(projectTasksProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final primaryRed = colorScheme.primary;

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(projectTasksProvider(projectId)),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyTasksState(
            onAddTask: () => _showAddTask(context, ref),
          );
        }

        final todo =
            tasks.where((t) => !t.isCompleted && t.status == 'TODO').toList();
        final inProgress = tasks
            .where((t) => !t.isCompleted && t.status == 'IN_PROGRESS')
            .toList();
        final blocked = tasks
            .where((t) => !t.isCompleted && t.status == 'BLOCKED')
            .toList();
        final done = tasks.where((t) => t.isCompleted).toList();

        return RefreshIndicator(
          color: primaryRed,
          onRefresh: () async =>
              ref.invalidate(projectTasksProvider(projectId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // Progress summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${done.length}/${tasks.length} tasks completed',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: tasks.isEmpty
                                  ? 0
                                  : done.length / tasks.length,
                              minHeight: 5,
                              backgroundColor:
                                  colorScheme.outlineVariant.withAlpha(40),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _showAddTask(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Task'),
                      style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (inProgress.isNotEmpty) ...[
                _sectionLabel('IN PROGRESS', semantics.warning),
                ...inProgress.map((t) =>
                    _taskTile(context, ref, t, colorScheme, semantics, primaryRed)),
                const SizedBox(height: 12),
              ],
              if (blocked.isNotEmpty) ...[
                _sectionLabel('BLOCKED', semantics.danger),
                ...blocked.map((t) =>
                    _taskTile(context, ref, t, colorScheme, semantics, primaryRed)),
                const SizedBox(height: 12),
              ],
              if (todo.isNotEmpty) ...[
                _sectionLabel('TO DO', colorScheme.onSurfaceVariant),
                ...todo.map((t) =>
                    _taskTile(context, ref, t, colorScheme, semantics, primaryRed)),
                const SizedBox(height: 12),
              ],
              if (done.isNotEmpty) ...[
                _sectionLabel('DONE', semantics.success),
                ...done.map((t) =>
                    _taskTile(context, ref, t, colorScheme, semantics, primaryRed)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _taskTile(
    BuildContext context,
    WidgetRef ref,
    dynamic task,
    ColorScheme cs,
    AppSemanticColors semantics,
    Color primary,
  ) {
    final isDone = task.isCompleted as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withAlpha(30)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(tasksProvider.notifier).toggleTaskComplete(task);
              ref.invalidate(projectTasksProvider(projectId));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? semantics.success : Colors.transparent,
                border: Border.all(
                    color: isDone ? semantics.success : cs.outlineVariant,
                    width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? cs.onSurfaceVariant.withAlpha(140)
                        : cs.onSurface,
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Due: ${(task.dueDate as String).split('T')[0]}',
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withAlpha(140)),
                  ),
                ],
              ],
            ),
          ),
          _priorityPill(task.priority as String, primary, cs, semantics),
        ],
      ),
    );
  }

  Widget _priorityPill(
      String priority, Color primary, ColorScheme cs, AppSemanticColors semantics) {
    Color color;
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        color = semantics.danger;
        break;
      case 'HIGH':
        color = primary;
        break;
      case 'LOW':
        color = cs.onSurfaceVariant.withAlpha(100);
        break;
      default:
        color = semantics.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(priority,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showAddTask(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormDialog(
        task: null,
        initialProjectId: projectId,
      ),
    );
    if (result != null) {
      result.putIfAbsent('projectId', () => projectId);
      await ref.read(tasksProvider.notifier).createTask(result);
      ref.invalidate(projectTasksProvider(projectId));
    }
  }
}

class _EmptyTasksState extends StatelessWidget {
  final VoidCallback onAddTask;
  const _EmptyTasksState({required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined,
                size: 40, color: cs.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: 12),
            const Text('No tasks linked',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Create tasks and link them to this project to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant.withAlpha(160)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Task'),
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ),
    );
  }
}
