import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';
import 'widgets/task_form_dialog.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  static const _viewFilters = [
    {'id': 'all', 'label': 'All'},
    {'id': 'today', 'label': 'Today'},
    {'id': 'upcoming', 'label': 'Upcoming'},
    {'id': 'overdue', 'label': 'Overdue'},
    {'id': 'matrix', 'label': 'Eisenhower Matrix'},
    {'id': 'completed', 'label': 'Completed'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadTasks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Priority Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  tooltip: 'Filter Priority',
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: state.priorityFilter != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (val) => notifier.setPriorityFilter(val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('All Priorities')),
                    const PopupMenuItem(value: 'CRITICAL', child: Text('Critical')),
                    const PopupMenuItem(value: 'HIGH', child: Text('High')),
                    const PopupMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    const PopupMenuItem(value: 'LOW', child: Text('Low')),
                  ],
                ),
              ],
            ),
          ),

          // Horizontal View Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _viewFilters.map((f) {
                final selected = state.currentViewFilter == f['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']!),
                    selected: selected,
                    onSelected: (_) => notifier.setViewFilter(f['id']!),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Task List
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TasksState state) {
    switch (state.status) {
      case TasksStatus.initial:
      case TasksStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case TasksStatus.error:
        return AppErrorState(
          message: state.errorMessage,
          onRetry: () => ref.read(tasksProvider.notifier).loadTasks(),
        );

      case TasksStatus.loaded:
        if (state.currentViewFilter == 'matrix') {
          return _buildEisenhowerMatrix(context, ref, state.tasks);
        }

        if (state.tasks.isEmpty) {
          return AppEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'No tasks found',
            description: 'Tap "+ New Task" below to add a task.',
            actionLabel: 'New Task',
            onAction: () => _openCreateDialog(context, ref),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: state.tasks.length,
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              return _TaskCard(
                task: task,
                onToggle: () =>
                    ref.read(tasksProvider.notifier).toggleTaskComplete(task),
                onEdit: () => _openEditDialog(context, ref, task),
                onDelete: () => _confirmDelete(context, ref, task),
              );
            },
          ),
        );
    }
  }

  Widget _buildEisenhowerMatrix(BuildContext context, WidgetRef ref, List<TaskModel> tasks) {
    final now = DateTime.now();
    final urgentCutoff = now.add(const Duration(hours: 48));

    bool isUrgent(TaskModel t) {
      if (t.dueDate == null) return false;
      final d = DateTime.tryParse(t.dueDate!);
      return d != null && d.isBefore(urgentCutoff);
    }

    bool isImportant(TaskModel t) {
      final p = t.priority.toUpperCase();
      return p == 'HIGH' || p == 'CRITICAL';
    }

    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final q1 = activeTasks.where((t) => isImportant(t) && isUrgent(t)).toList();
    final q2 = activeTasks.where((t) => isImportant(t) && !isUrgent(t)).toList();
    final q3 = activeTasks.where((t) => !isImportant(t) && isUrgent(t)).toList();
    final q4 = activeTasks.where((t) => !isImportant(t) && !isUrgent(t)).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuadrantCard(
              context: context,
              ref: ref,
              title: 'Q1: Do First',
              subtitle: 'Urgent & Important (Critical / Approaching Deadline)',
              color: Colors.redAccent,
              tasks: q1,
            ),
            const SizedBox(height: 12),
            _buildQuadrantCard(
              context: context,
              ref: ref,
              title: 'Q2: Schedule',
              subtitle: 'Important & Not Urgent (Deep Work / High Leverage)',
              color: Colors.blueAccent,
              tasks: q2,
            ),
            const SizedBox(height: 12),
            _buildQuadrantCard(
              context: context,
              ref: ref,
              title: 'Q3: Delegate',
              subtitle: 'Urgent & Not Important (Time-Sensitive Minor Items)',
              color: Colors.orangeAccent,
              tasks: q3,
            ),
            const SizedBox(height: 12),
            _buildQuadrantCard(
              context: context,
              ref: ref,
              title: 'Q4: Eliminate',
              subtitle: 'Not Urgent & Not Important (Distractions / Backlog)',
              color: Colors.purpleAccent,
              tasks: q4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required Color color,
    required List<TaskModel> tasks,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(80), width: 1.5),
      ),
      color: color.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 8),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                child: Text(
                  'No active tasks in this quadrant',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.outline),
                ),
              )
            else
              ...tasks.map((t) => _TaskCard(
                    task: t,
                    onToggle: () => ref.read(tasksProvider.notifier).toggleTaskComplete(t),
                    onEdit: () => _openEditDialog(context, ref, t),
                    onDelete: () => _confirmDelete(context, ref, t),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const TaskFormDialog(),
    );
    if (result != null) {
      await ref.read(tasksProvider.notifier).createTask(result);
    }
  }

  Future<void> _openEditDialog(
      BuildContext context, WidgetRef ref, TaskModel task) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TaskFormDialog(task: task),
    );
    if (result != null) {
      await ref.read(tasksProvider.notifier).updateTask(task.id, result);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
    }
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color _priorityColor(String priority, ColorScheme cs) {
    return switch (priority.toUpperCase()) {
      'CRITICAL' => cs.error,
      'HIGH' => Colors.orange,
      'MEDIUM' => cs.tertiary,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String? formattedDueDate;
    if (task.dueDate != null) {
      final dt = DateTime.tryParse(task.dueDate!);
      if (dt != null) {
        formattedDueDate = '${dt.month}/${dt.day}';
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
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
                          size: 16, color: colorScheme.onPrimary)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Main Info
            Expanded(
              child: InkWell(
                onTap: () => context.go('/tasks/${task.id}'),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _priorityColor(task.priority, colorScheme)
                              .withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _priorityColor(task.priority, colorScheme),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                      ),

                      // Status Badge (if not TODO/COMPLETED)
                      if (task.status != 'TODO' && task.status != 'COMPLETED')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.status.replaceAll('_', ' '),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                ),
                          ),
                        ),

                      // Due Date Badge
                      if (formattedDueDate != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 12, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              formattedDueDate,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ],

                      // Estimated minutes
                      if (task.estimatedMinutes != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 12, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              '${task.estimatedMinutes}m',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ],

                      // Subtasks Fraction Badge
                      if (task.subtaskFraction != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist_rounded,
                                size: 12, color: colorScheme.primary),
                            const SizedBox(width: 2),
                            Text(
                              task.subtaskFraction!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ],

                      // Blocked Badge
                      if (task.isBlocked) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 10, color: Colors.amber),
                              SizedBox(width: 2),
                              Text(
                                'Blocked',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Recurring Task Indicator
                      if (task.isRecurring) ...[
                        Icon(Icons.repeat_rounded,
                            size: 13, color: colorScheme.secondary),
                      ],

                      // Project tag
                      if (task.project != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.project!.title,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

            // Action Menu
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
