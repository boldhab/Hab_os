import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/goal_model.dart';
import '../../providers/goals_provider.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static const _categories = [
    {'id': 'ALL', 'label': 'All'},
    {'id': 'CAREER', 'label': 'Career'},
    {'id': 'HEALTH', 'label': 'Health'},
    {'id': 'EDUCATION', 'label': 'Education'},
    {'id': 'FINANCIAL', 'label': 'Financial'},
    {'id': 'PERSONAL', 'label': 'Personal'},
  ];

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);
    final healthAsync = ref.watch(goalsHealthProvider);
    final selectedCategory = ref.watch(selectedGoalCategoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Milestones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(goalsListProvider);
              ref.invalidate(goalsHealthProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((c) {
                final isSelected = selectedCategory == c['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(c['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedGoalCategoryProvider.notifier).state =
                          c['id']!;
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Stale / At-Risk Health Banner
          healthAsync.when(
            data: (health) {
              if (health.atRiskCount == 0 && health.behindCount == 0) {
                return const SizedBox.shrink();
              }
              final count = health.atRiskCount + health.behindCount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          '$count goal${count > 1 ? "s" : ""} need attention (slipping behind or inactive).',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Main Goals List
          Expanded(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AppErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(goalsListProvider),
              ),
              data: (goals) {
                if (goals.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No goals found',
                    description:
                        'Tap "+ New Goal" to map out long-term milestones and track auto-derived progress.',
                    actionLabel: 'New Goal',
                    onAction: () => _openCreateGoalDialog(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(goalsListProvider);
                    ref.invalidate(goalsHealthProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final g = goals[index];
                      final catColor = _categoryColor(g.category, colorScheme);
                      final pct = (g.progress / 100.0).clamp(0.0, 1.0);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: colorScheme.surfaceContainerHighest,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go('/goals/${g.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: catColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_categoryIcon(g.category),
                                              size: 13, color: catColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            g.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        g.priority,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${g.progress.toInt()}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  g.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (g.description != null &&
                                    g.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    g.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (g.isFinancial &&
                                        g.targetAmount != null &&
                                        g.targetAmount! > 0) ...[
                                      Text(
                                        '\$${(g.currentAmount ?? 0).toInt()} / \$${g.targetAmount!.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ] else ...[
                                      Text(
                                        '${g.milestones.where((m) => m.isCompleted).length}/${g.milestones.length} milestones',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    if (g.targetDate != null) ...[
                                      Icon(Icons.calendar_today_rounded,
                                          size: 11,
                                          color: colorScheme.outline),
                                      const SizedBox(width: 3),
                                      Text(
                                        g.targetDate!.split('T')[0],
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.outline),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGoalDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
    );
  }

  Future<void> _openCreateGoalDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetAmountController = TextEditingController();
    String selectedCategory = 'PERSONAL';
    String selectedPriority = 'MEDIUM';
    DateTime? selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title *',
                    hintText: 'e.g. Master Flutter Framework',
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
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'CAREER', child: Text('Career')),
                    DropdownMenuItem(value: 'HEALTH', child: Text('Health')),
                    DropdownMenuItem(value: 'EDUCATION', child: Text('Education')),
                    DropdownMenuItem(value: 'FINANCIAL', child: Text('Financial')),
                    DropdownMenuItem(value: 'PERSONAL', child: Text('Personal')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedCategory = val);
                    }
                  },
                ),
                if (selectedCategory == 'FINANCIAL') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Target Savings Amount (\$)',
                      hintText: 'e.g. 10000',
                      prefixText: '\$ ',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedPriority = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Target Date'),
                  subtitle: Text(
                    selectedDate == null
                        ? 'No target date set'
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
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final targetAmt = selectedCategory == 'FINANCIAL'
          ? double.tryParse(targetAmountController.text.trim())
          : null;

      final payload = <String, dynamic>{
        'title': titleController.text.trim(),
        if (descController.text.trim().isNotEmpty)
          'description': descController.text.trim(),
        'category': selectedCategory,
        'priority': selectedPriority,
        if (selectedDate != null) 'targetDate': selectedDate!.toIso8601String(),
        if (targetAmt != null) 'targetAmount': targetAmt,
      };

      await ref.read(goalsActionsProvider.notifier).createGoal(payload);
    }
  }
}
