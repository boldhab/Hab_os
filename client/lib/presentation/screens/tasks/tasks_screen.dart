import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/focus_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_animated_check.dart';
import 'widgets/task_form_dialog.dart';
import 'widgets/task_filter_sheet.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'task_details_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _isSearching = false;
  bool _isMatrixView = false;
  String? _selectedTaskId;
  late final ScrollController _scrollController;

  static const _tabs = [
    {'id': 'today', 'label': 'Today'},
    {'id': 'upcoming', 'label': 'Upcoming'},
    {'id': 'overdue', 'label': 'Overdue'},
    {'id': 'all', 'label': 'All'},
    {'id': 'completed', 'label': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      ref.read(tasksProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dateString =
        '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final mainListContent = Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withAlpha(140)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) notifier.setSearchQuery('');
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: state.priorityFilter != null
                      ? primaryRed
                      : colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _openFilterSheet(context),
              ),
              IconButton(
                icon: Icon(
                  _isMatrixView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                ),
                tooltip: _isMatrixView
                    ? 'Switch to List'
                    : 'Switch to Eisenhower Matrix',
                onPressed: () {
                  setState(() {
                    _isMatrixView = !_isMatrixView;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.sync_rounded),
                tooltip: 'Sync Google Calendar',
                onPressed: () async {
                  AppHaptics.light();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing with Google Calendar...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  final success = await notifier.syncCalendar();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Google Calendar synced successfully'
                              : (state.errorMessage ?? 'Calendar sync failed'),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Underline Segmented Tabs
              if (!_isMatrixView)
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(40),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final selected = state.currentViewFilter == tab['id'];

                      return InkWell(
                        onTap: () {
                          AppHaptics.selection();
                          notifier.setViewFilter(tab['id']!);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    selected ? primaryRed : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            tab['label']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected
                                  ? primaryRed
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Slim Workload Summary Banner
              if (!_isMatrixView)
                _buildSlimWorkloadBanner(context, ref, state.currentViewFilter),

              // Task List / Matrix Body
              Expanded(
                child: _buildBody(context, ref, state, isWide),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateDialog(context, ref),
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Task',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              SizedBox(width: 440, child: mainListContent),
              VerticalDivider(
                  width: 1, color: colorScheme.outlineVariant.withAlpha(40)),
              Expanded(
                child: _selectedTaskId == null
                    ? Scaffold(
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        body: const Center(
                          child: Text(
                            'Select a task to view details',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : TaskDetailsScreen(taskId: _selectedTaskId!),
              ),
            ],
          );
        }

        return mainListContent;
      },
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskFilterSheet(),
    );
  }

  Widget _buildSlimWorkloadBanner(
      BuildContext context, WidgetRef ref, String view) {
    if (view != 'today' && view != 'upcoming') return const SizedBox.shrink();

    final workloadAsync = ref.watch(tasksWorkloadProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return workloadAsync.when(
      data: (data) {
        if (view == 'today') {
          final today = data.today;
          final color = switch (today.status) {
            'HEAVY' => const Color(0xFFEA4335),
            'OPTIMAL' => const Color(0xFF34A853),
            _ => colorScheme.outline,
          };

          final hours = (today.totalMinutes / 60).floor();
          final mins = today.totalMinutes % 60;
          final timeLabel =
              hours > 0 ? '${hours}h ${mins}m planned' : '${mins}m planned';
          final pct = (today.totalMinutes / 300).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(18),
                    colorScheme.primaryContainer.withAlpha(90),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Today overview',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          today.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Text(
                        '${today.count} tasks',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: colorScheme.outlineVariant.withAlpha(80),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, TasksState state, bool isWide) {
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
        if (_isMatrixView) {
          return _buildEisenhowerMatrix(context, ref);
        }

        if (state.tasks.isEmpty) {
          return AppEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Nothing due right now',
            description: 'Enjoy your free time or add a new task.',
            actionLabel: 'New Task',
            onAction: () => _openCreateDialog(context, ref),
          );
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
          child: ReorderableListView.builder(
            scrollController: _scrollController,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            itemCount: state.tasks.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(tasksProvider.notifier).reorderTask(oldIndex, newIndex);
            },
            footer: state.isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : null,
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              return _TaskRowItem(
                key: ValueKey(task.id),
                task: task,
                reorderIndex: index,
                isSelected: _selectedTaskId == task.id,
                onSelect: () {
                  if (isWide) {
                    setState(() => _selectedTaskId = task.id);
                  } else {
                    context.go('/tasks/${task.id}');
                  }
                },
                onToggle: () => _handleToggleComplete(context, ref, task),
                onEdit: () => _openEditDialog(context, ref, task),
                onDelete: () => _handleDeleteTask(context, ref, task),
                onStartFocus: () => _handleStartFocus(context, ref, task),
              );
            },
          ),
        );
    }
  }

  Widget _buildEisenhowerMatrix(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(tasksMatrixProvider);

    return matrixAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        final quadrants = ref.watch(eisenhowerMatrixProvider);
        return _buildMatrixLayout(
          context,
          ref,
          quadrants.q1,
          quadrants.q2,
          quadrants.q3,
          quadrants.q4,
        );
      },
      data: (data) {
        final quads = data['quadrants'] as Map<String, dynamic>?;
        if (quads == null) {
          final quadrants = ref.watch(eisenhowerMatrixProvider);
          return _buildMatrixLayout(
            context,
            ref,
            quadrants.q1,
            quadrants.q2,
            quadrants.q3,
            quadrants.q4,
          );
        }
        final q1 = ((quads['q1_urgent_important']?['items'] as List?) ?? [])
            .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        final q2 = ((quads['q2_not_urgent_important']?['items'] as List?) ?? [])
            .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        final q3 = ((quads['q3_urgent_not_important']?['items'] as List?) ?? [])
            .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        final q4 = ((quads['q4_not_urgent_not_important']?['items'] as List?) ?? [])
            .map((i) => TaskModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();

        return _buildMatrixLayout(context, ref, q1, q2, q3, q4);
      },
    );
  }

  Widget _buildMatrixLayout(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> q1,
    List<TaskModel> q2,
    List<TaskModel> q3,
    List<TaskModel> q4,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () async {
        ref.invalidate(tasksMatrixProvider);
        await ref.read(tasksProvider.notifier).loadTasks();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Axis Labels
            Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    'URGENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'NOT URGENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  // Left Axis Label
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'IMPORTANT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildQuadrantBox(
                                  context: context,
                                  title: 'Do First',
                                  subtitle: 'Urgent + Important',
                                  color: const Color(0xFFEA4335),
                                  tasks: q1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuadrantBox(
                                  context: context,
                                  title: 'Schedule',
                                  subtitle: 'Important, Not Urgent',
                                  color: const Color(0xFF4285F4),
                                  tasks: q2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildQuadrantBox(
                                  context: context,
                                  title: 'Delegate',
                                  subtitle: 'Urgent, Not Important',
                                  color: const Color(0xFFFBBC05),
                                  tasks: q3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuadrantBox(
                                  context: context,
                                  title: 'Eliminate',
                                  subtitle: 'Not Urgent or Important',
                                  color: colorScheme.outline,
                                  tasks: q4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantBox({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color,
    required List<TaskModel> tasks,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayTasks = tasks.take(3).toList();
    final remainingCount = tasks.length - displayTasks.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.outlineVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayTasks.length,
                    itemBuilder: (context, i) {
                      final t = displayTasks[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${t.title}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
          if (remainingCount > 0)
            Text(
              '+$remainingCount more',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleToggleComplete(
      BuildContext context, WidgetRef ref, TaskModel task) async {
    final err = await ref.read(tasksProvider.notifier).toggleTaskComplete(task);
    if (err != null && context.mounted) {
      final semantics = AppSemanticColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: semantics.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDeleteTask(
      BuildContext context, WidgetRef ref, TaskModel task) async {
    await ref.read(tasksProvider.notifier).deleteTask(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${task.title}"'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(tasksProvider.notifier).createTask({
                'title': task.title,
                'description': task.description,
                'priority': task.priority,
                'status': task.status,
                'dueDate': task.dueDate,
                'estimatedMinutes': task.estimatedMinutes,
                'projectId': task.projectId,
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskFormDialog(),
    );
    if (result != null) {
      final success = await ref.read(tasksProvider.notifier).createTask(result);
      if (!success && context.mounted) {
        final errorMsg = ref.read(tasksProvider).errorMessage ?? 'Failed to create task';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppSemanticColors.of(context).danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog(
      BuildContext context, WidgetRef ref, TaskModel task) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormDialog(task: task),
    );
    if (result != null) {
      final success = await ref.read(tasksProvider.notifier).updateTask(task.id, result);
      if (!success && context.mounted) {
        final errorMsg = ref.read(tasksProvider).errorMessage ?? 'Failed to update task';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppSemanticColors.of(context).danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleStartFocus(BuildContext context, WidgetRef ref, TaskModel task) {
    AppHaptics.medium();
    ref.read(focusProvider.notifier).startTimerForTask(task);
    context.go('/focus');
  }
}

class _TaskRowItem extends StatelessWidget {
  final TaskModel task;
  final bool isSelected;
  final int? reorderIndex;
  final VoidCallback onSelect;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onStartFocus;

  const _TaskRowItem({
    super.key,
    required this.task,
    required this.isSelected,
    this.reorderIndex,
    required this.onSelect,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onStartFocus,
  });

  Color _priorityColor(String priority) {
    return switch (priority.toUpperCase()) {
      'CRITICAL' => const Color(0xFFDC2626),
      'HIGH' => const Color(0xFFEA4335),
      'MEDIUM' => const Color(0xFFFBBC05),
      _ => const Color(0xFF4285F4),
    };
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = _priorityColor(task.priority);

    String? formattedDueDate;
    if (task.dueDate != null) {
      final dt = DateTime.tryParse(task.dueDate!);
      if (dt != null) {
        formattedDueDate = '${dt.month}/${dt.day}';
      }
    }

    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: const Color(0xFF34A853),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check_circle_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: const Color(0xFFEA4335),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false;
        } else {
          onDelete();
          return true;
        }
      },
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(18)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withAlpha(60)
                : colorScheme.outlineVariant.withAlpha(60),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                AppAnimatedCheck(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  size: 22,
                  activeColor: primaryColor,
                ),
                const SizedBox(width: 14),

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
                                fontSize: 15,
                                fontWeight: task.isCompleted
                                    ? FontWeight.w400
                                    : FontWeight.w700,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? colorScheme.onSurfaceVariant.withAlpha(128)
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              task.priority,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (task.isBlocked) ...[
                            _metaChip(
                              context,
                              icon: Icons.lock_rounded,
                              label: 'Blocked',
                              color: const Color(0xFFEA4335),
                            ),
                          ],
                          if (formattedDueDate != null) ...[
                            _metaChip(
                              context,
                              icon: Icons.calendar_today_rounded,
                              label: formattedDueDate,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                          if (task.estimatedMinutes != null) ...[
                            _metaChip(
                              context,
                              icon: Icons.timer_outlined,
                              label: '${task.estimatedMinutes}m',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                          if (task.subtaskFraction != null) ...[
                            _metaChip(
                              context,
                              icon: Icons.checklist_rounded,
                              label: task.subtaskFraction!,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onStartFocus != null && !task.isCompleted) ...[
                  IconButton(
                    icon: Icon(
                      Icons.play_circle_outline_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Start Focus session',
                    onPressed: onStartFocus,
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(80),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (reorderIndex != null) ...[
                  const SizedBox(width: 8),
                  ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 20,
                        color: colorScheme.outlineVariant.withAlpha(140),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
