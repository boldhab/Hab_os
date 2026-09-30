import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../providers/goals_provider.dart';
import '../../providers/tasks_provider.dart';
import '../tasks/widgets/task_form_dialog.dart';
import '../../widgets/app_error_state.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _categoryColor(String category, ColorScheme cs) {
    return switch (category.toUpperCase()) {
      'CAREER' => Colors.purple,
      'HEALTH' || 'FITNESS' => Colors.teal,
      'EDUCATION' || 'LEARNING' => Colors.indigo,
      'FINANCIAL' => Colors.green,
      _ => cs.primary,
    };
  }

  IconData _categoryIcon(String category) {
    return switch (category.toUpperCase()) {
      'CAREER' => Icons.work_outline_rounded,
      'HEALTH' || 'FITNESS' => Icons.fitness_center_rounded,
      'EDUCATION' || 'LEARNING' => Icons.school_outlined,
      'FINANCIAL' => Icons.savings_outlined,
      _ => Icons.flag_outlined,
    };
  }

  Color _confidenceColor(String confidence) {
    return switch (confidence.toUpperCase()) {
      'ON_TRACK' => Colors.green,
      'BEHIND' => Colors.orange,
      'AT_RISK' => Colors.redAccent,
      _ => Colors.blueGrey,
    };
  }

  Future<void> _openAddMilestoneDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final weightController = TextEditingController(text: '1.0');
    DateTime? selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Milestone Title *',
                    hintText: 'e.g. Pass AWS Exam',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (relative impact)',
                    hintText: 'e.g. 1.0, 2.0',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Target Date'),
                  subtitle: Text(
                    selectedDate == null
                        ? 'No date set'
                        : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final weight = double.tryParse(weightController.text.trim()) ?? 1.0;
      await ref.read(goalsActionsProvider.notifier).createMilestone(
        widget.goalId,
        {
          'title': titleController.text.trim(),
          if (descController.text.trim().isNotEmpty)
            'description': descController.text.trim(),
          'weight': weight,
          if (selectedDate != null) 'targetDate': selectedDate!.toIso8601String(),
        },
      );
    }
  }

  Future<void> _openContributeDialog(BuildContext context, GoalModel goal) async {
    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: \$${(goal.currentAmount ?? 0).toStringAsFixed(2)} / \$${(goal.targetAmount ?? 0).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount to Add (\$)',
                hintText: 'e.g. 250.00',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add Savings'),
          ),
        ],
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text.trim());
      if (amount != null && amount > 0) {
        await ref
            .read(goalsActionsProvider.notifier)
            .contributeFinancial(goal.id, amount);
      }
    }
  }

  Future<void> _openCheckInDialog(BuildContext context) async {
    String selectedConfidence = 'ON_TRACK';
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Goal Check-in'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How is progress feeling right now?'),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ON_TRACK',
                      label: Text('On Track'),
                      icon: Icon(Icons.check_circle_outline_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'BEHIND',
                      label: Text('Behind'),
                      icon: Icon(Icons.schedule_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'AT_RISK',
                      label: Text('At Risk'),
                      icon: Icon(Icons.warning_amber_rounded, size: 16),
                    ),
                  ],
                  selected: {selectedConfidence},
                  onSelectionChanged: (set) {
                    setModalState(() => selectedConfidence = set.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reflection Notes (optional)',
                    hintText: 'What went well? Any obstacles or blockers?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Check-in'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await ref.read(goalsActionsProvider.notifier).recordCheckIn(
            widget.goalId,
            selectedConfidence,
            noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          );
    }
  }

  Future<void> _openAddTaskForMilestone(
    BuildContext context,
    GoalModel goal,
    MilestoneModel milestone,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TaskFormDialog(
        initialGoalId: goal.id,
        initialMilestoneId: milestone.id,
      ),
    );

    if (result != null) {
      await ref.read(tasksProvider.notifier).createTask(result);
      ref.invalidate(goalDetailsProvider(widget.goalId));
      ref.invalidate(goalTreeProvider(widget.goalId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(goalDetailsProvider(widget.goalId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(goalDetailsProvider(widget.goalId));
              ref.invalidate(goalTreeProvider(widget.goalId));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Roadmap', icon: Icon(Icons.alt_route_rounded)),
            Tab(text: 'Hierarchy Tree', icon: Icon(Icons.account_tree_rounded)),
            Tab(text: 'Check-ins', icon: Icon(Icons.fact_check_outlined)),
          ],
        ),
      ),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(goalDetailsProvider(widget.goalId)),
        ),
        data: (goal) {
          final catColor = _categoryColor(goal.category, colorScheme);

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Roadmap Tab
              _buildRoadmapTab(context, goal, catColor),

              // 2. Hierarchy Tree Tab
              _buildTreeTab(context, goal),

              // 3. Check-ins Tab
              _buildCheckInsTab(context, goal),
            ],
          );
        },
      ),
    );
  }

  // ── 1. ROADMAP TAB ──────────────────────────────────────────────────────────

  Widget _buildRoadmapTab(BuildContext context, GoalModel goal, Color catColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Header Overview Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categoryIcon(goal.category), size: 14, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            goal.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal.priority,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${goal.progress.toInt()}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (goal.description != null && goal.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    goal.description!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (goal.progress / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                  ),
                ),
                if (goal.targetDate != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${goal.targetDate!.split('T')[0]}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Financial Goal Progress Card
        if (goal.isFinancial) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.green.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.savings_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Financial Savings Target',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _openContributeDialog(context, goal),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Savings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved: \$${(goal.currentAmount ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Goal: \$${(goal.targetAmount ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.financialProgressRatio,
                      minHeight: 8,
                      backgroundColor: Colors.green.withAlpha(40),
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Milestones Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sequential Milestones (${goal.milestones.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Milestone'),
              onPressed: () => _openAddMilestoneDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (goal.milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.flag_outlined, size: 36, color: colorScheme.outline),
                const SizedBox(height: 8),
                const Text('No milestones defined yet.'),
                const SizedBox(height: 4),
                Text(
                  'Break your goal down into sequential steps to auto-calculate progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          ...goal.milestones.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return _buildMilestoneCard(context, goal, m, idx + 1);
          }),
      ],
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context,
    GoalModel goal,
    MilestoneModel m,
    int stepNumber,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        initiallyExpanded: !m.isCompleted,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: m.isCompleted
              ? Colors.green
              : colorScheme.primary.withAlpha(40),
          child: m.isCompleted
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                m.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                  color: m.isCompleted ? colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${m.weight}x weight',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.description != null && m.description!.isNotEmpty)
              Text(m.description!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  m.totalTasksCount > 0
                      ? '${m.completedTasksCount}/${m.totalTasksCount} tasks (${m.progressPercent}%)'
                      : (m.isCompleted ? 'Completed' : 'Manual milestone'),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                if (m.targetDate != null) ...[
                  const SizedBox(width: 8),
                  Text('• Due ${m.targetDate!.split('T')[0]}',
                      style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                ],
              ],
            ),
          ],
        ),
        trailing: m.totalTasksCount == 0
            ? Checkbox(
                value: m.isCompleted,
                onChanged: (val) async {
                  await ref
                      .read(goalsActionsProvider.notifier)
                      .updateMilestone(goal.id, m.id, {'isCompleted': val ?? false});
                },
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (m.tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No tasks linked. Toggle completion manually or link tasks.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...m.tasks.map((t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: IconButton(
                          icon: Icon(
                            t.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: t.isCompleted ? Colors.green : colorScheme.outline,
                          ),
                          onPressed: () async {
                            await ref.read(taskRepositoryProvider).toggleComplete(t.id);
                            ref.invalidate(goalDetailsProvider(widget.goalId));
                            ref.invalidate(goalTreeProvider(widget.goalId));
                            ref.read(tasksProvider.notifier).loadTasks();
                          },
                        ),
                        title: Text(
                          t.title,
                          style: TextStyle(
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                            fontSize: 13,
                            color: t.isCompleted ? colorScheme.onSurfaceVariant : null,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.priority,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                      onPressed: () => _openAddTaskForMilestone(context, goal, m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      tooltip: 'Delete Milestone',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Milestone'),
                            content: Text('Delete "${m.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(goalsActionsProvider.notifier)
                              .deleteMilestone(goal.id, m.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. HIERARCHY TREE TAB ───────────────────────────────────────────────────

  Widget _buildTreeTab(BuildContext context, GoalModel goal) {
    final treeAsync = ref.watch(goalTreeProvider(goal.id));
    final colorScheme = Theme.of(context).colorScheme;

    return treeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(goalTreeProvider(goal.id)),
      ),
      data: (tree) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Root Goal Node
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_tree_rounded, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tree.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${tree.overallProgress.toInt()}%',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Category: ${tree.category} • ${tree.branches.length} Milestones • ${tree.directTasksCount} Direct Tasks',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Milestone Branches
              if (tree.branches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No milestones or hierarchy branches yet.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...tree.branches.map((b) => _buildTreeBranch(context, b)),

              // Direct / Unassigned Tasks Branch
              if (tree.unassignedTasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Direct Goal Tasks (No milestone assigned)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      ...tree.unassignedTasks.map((t) => InkWell(
                            onTap: () async {
                              await ref.read(taskRepositoryProvider).toggleComplete(t.id);
                              ref.invalidate(goalDetailsProvider(widget.goalId));
                              ref.invalidate(goalTreeProvider(widget.goalId));
                              ref.read(tasksProvider.notifier).loadTasks();
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Row(
                                children: [
                                  const Text(' └─ ', style: TextStyle(color: Colors.grey)),
                                  Icon(
                                    t.isCompleted
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    size: 15,
                                    color: t.isCompleted ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      style: TextStyle(
                                        decoration:
                                            t.isCompleted ? TextDecoration.lineThrough : null,
                                        fontSize: 12,
                                        color: t.isCompleted ? colorScheme.onSurfaceVariant : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreeBranch(BuildContext context, GoalTreeBranchModel b) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: b.isCompleted ? Colors.green : colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  b.isCompleted ? Icons.check_circle_rounded : Icons.adjust_rounded,
                  size: 18,
                  color: b.isCompleted ? Colors.green : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: b.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  '${b.progress}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: b.isCompleted ? Colors.green : colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (b.tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...b.tasks.map((t) => InkWell(
                    onTap: () async {
                      await ref.read(taskRepositoryProvider).toggleComplete(t.id);
                      ref.invalidate(goalDetailsProvider(widget.goalId));
                      ref.invalidate(goalTreeProvider(widget.goalId));
                      ref.read(tasksProvider.notifier).loadTasks();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          const Text('├─ ', style: TextStyle(color: Colors.grey)),
                          Icon(
                            t.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 15,
                            color: t.isCompleted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                decoration:
                                    t.isCompleted ? TextDecoration.lineThrough : null,
                                fontSize: 12,
                                color: t.isCompleted ? colorScheme.onSurfaceVariant : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ── 3. CHECK-INS TAB ────────────────────────────────────────────────────────

  Widget _buildCheckInsTab(BuildContext context, GoalModel goal) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Action Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accountability Journal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Log weekly confidence ratings to maintain momentum and detect blockers early.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openCheckInDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Check In'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (goal.checkIns.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 36, color: colorScheme.outline),
                const SizedBox(height: 8),
                const Text('No check-ins logged yet'),
                const SizedBox(height: 4),
                Text(
                  'Tap "Check In" to record your first progress and confidence sentiment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          ...goal.checkIns.map((c) {
            final confColor = _confidenceColor(c.confidence);
            final dateStr = c.date.split('T')[0];

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: confColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: confColor.withAlpha(80)),
                          ),
                          child: Text(
                            c.confidence.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: confColor,
                            ),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (c.note != null && c.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.note!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
