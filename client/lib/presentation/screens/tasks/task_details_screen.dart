import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/focus_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
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

  Color _priorityColor(String priority) {
    return switch (priority.toUpperCase()) {
      'CRITICAL' => const Color(0xFFDC2626),
      'HIGH' => const Color(0xFFEA4335),
      'MEDIUM' => const Color(0xFFFBBC05),
      _ => const Color(0xFF4285F4),
    };
  }

  Future<void> _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isAddingSubtask = true);
    try {
      await ref
          .read(taskRepositoryProvider)
          .createSubtask(widget.taskId, title);
      _subtaskController.clear();
      ref.invalidate(taskDetailsProvider(widget.taskId));
      ref.read(tasksProvider.notifier).loadTasks(showLoading: false);
    } catch (e) {
      if (mounted) {
        final semantics = AppSemanticColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subtask: $e'),
            backgroundColor: semantics.danger,
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
      final isAlreadyBlocker =
          currentTask.blockedBy.any((b) => b['blockingTaskId'] == t.id);
      return !isAlreadyBlocker;
    }).toList();

    if (candidateTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No eligible prerequisite tasks found to link.')),
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
    final primaryRed = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
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
          final totalFocusMins =
              task.focusSessions.fold(0, (sum, f) => sum + f.durationMinutes);
          final priorityColor = _priorityColor(task.priority);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Title & Metadata ────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? const Color(0xFF34A853).withAlpha(30)
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.status.replaceAll('_', ' '),
                        style: TextStyle(
                          color: task.isCompleted
                              ? const Color(0xFF34A853)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalGapSm,
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  AppSpacing.verticalGapSm,
                  Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withAlpha(200),
                      height: 1.4,
                    ),
                  ),
                ],
                AppSpacing.verticalGapLg,

                // ── Subtasks Checklist ───────────────────────────────────────
                if (task.parentTaskId == null) ...[
                  _buildSubtasksSection(context, task),
                  AppSpacing.verticalGapLg,
                ],

                // ── Prerequisites & Blockers ─────────────────────────────────
                _buildPrerequisitesSection(context, task),
                AppSpacing.verticalGapLg,

                // ── Context & Hierarchy Breadcrumbs ─────────────────────────
                const SectionHeader(
                  icon: Icons.alt_route_rounded,
                  title: 'Hierarchy & Context',
                ),
                AppSpacing.verticalGapSm,
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.flag_outlined, size: 20),
                        title: const Text('Goal',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(task.goal?.title ?? 'None linked',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined, size: 20),
                        title: const Text('Project',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(task.project?.title ?? 'None linked',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalGapLg,

                // ── Time & Focus 3-Column Stat Row ───────────────────────────
                const SectionHeader(
                  icon: Icons.schedule_rounded,
                  title: 'Time & Metrics',
                ),
                AppSpacing.verticalGapSm,
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Due Date',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              task.dueDate != null
                                  ? task.dueDate!.split('T')[0]
                                  : 'None',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              task.estimatedMinutes != null
                                  ? '${task.estimatedMinutes}m'
                                  : 'None',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Focus Spent',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              '${totalFocusMins}m',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: primaryRed,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalGapLg,

                // ── Linked Focus Sessions ────────────────────────────────────
                SectionHeader(
                  icon: Icons.timer_rounded,
                  title: 'Focus Sessions (${task.focusSessions.length})',
                ),
                AppSpacing.verticalGapSm,
                if (task.focusSessions.isEmpty)
                  AppCard(
                    child: Text(
                      'No focus sessions recorded for this task yet.',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
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
                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(f.category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            Text(
                              '${f.durationMinutes} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
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
        SectionHeader(
          icon: Icons.checklist_rounded,
          title: 'Subtasks ($completedCount/$totalCount)',
          action: totalCount > 0
              ? Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              : null,
        ),
        if (totalCount > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.5,
            ),
          ),
        ],
        AppSpacing.verticalGapSm,
        AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ...task.subtasks.map((s) => CheckboxListTile(
                    dense: true,
                    value: s.isCompleted,
                    activeColor: colorScheme.primary,
                    title: Text(
                      s.title,
                      style: TextStyle(
                        decoration:
                            s.isCompleted ? TextDecoration.lineThrough : null,
                        color: s.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 20),
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
        SectionHeader(
          icon: Icons.lock_clock_rounded,
          title: 'Prerequisites (${task.blockedBy.length})',
          action: TextButton.icon(
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Add Blocker'),
            onPressed: () => _showAddPrerequisiteDialog(task),
          ),
        ),
        if (hasUnfinishedBlockers) ...[
          AppSpacing.verticalGapXs,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEA4335).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEA4335).withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFEA4335), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'This task is blocked. Complete all prerequisite tasks before marking it done.',
                    style: TextStyle(
                      color: Color(0xFFEA4335),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        AppSpacing.verticalGapSm,
        if (task.blockedBy.isEmpty)
          AppCard(
            child: Text(
              'No prerequisites. This task can be worked on freely.',
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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

              return AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.lock_clock_rounded,
                      size: 18,
                      color: isDone
                          ? const Color(0xFF34A853)
                          : const Color(0xFFEA4335),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        blocker['title'] ?? 'Task',
                        style: TextStyle(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
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
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            top: BorderSide(color: colorScheme.outlineVariant.withAlpha(40))),
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
                style: FilledButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Focus',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),

            // Complete Toggle
            OutlinedButton(
              onPressed: () async {
                await ref.read(tasksProvider.notifier).toggleTaskComplete(task);
                ref.invalidate(taskDetailsProvider(widget.taskId));
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: BorderSide(color: primaryRed),
              ),
              child: Text(
                task.isCompleted ? 'Reopen' : 'Complete',
                style:
                    TextStyle(color: primaryRed, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),

            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
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
          ],
        ),
      ),
    );
  }
}
