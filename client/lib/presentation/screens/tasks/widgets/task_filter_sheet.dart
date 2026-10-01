import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/tasks_provider.dart';

/// Bottom Sheet for filtering Tasks by Priority and View Category.
class TaskFilterSheet extends ConsumerWidget {
  const TaskFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryRed = colorScheme.primary;

    final priorities = [
      {'id': null, 'label': 'All Priorities'},
      {'id': 'CRITICAL', 'label': 'Critical'},
      {'id': 'HIGH', 'label': 'High'},
      {'id': 'MEDIUM', 'label': 'Medium'},
      {'id': 'LOW', 'label': 'Low'},
    ];

    final viewFilters = [
      {'id': 'today', 'label': 'Today'},
      {'id': 'upcoming', 'label': 'Upcoming'},
      {'id': 'overdue', 'label': 'Overdue'},
      {'id': 'all', 'label': 'All Tasks'},
      {'id': 'completed', 'label': 'Completed'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tasks',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {
                  notifier.setPriorityFilter(null);
                  notifier.setViewFilter('today');
                  Navigator.pop(context);
                },
                child: Text('Reset', style: TextStyle(color: primaryRed)),
              ),
            ],
          ),
          AppSpacing.verticalGapMd,

          // View Section
          Text(
            'VIEW CATEGORY',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalGapSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: viewFilters.map((v) {
              final selected = state.currentViewFilter == v['id'];
              return ChoiceChip(
                label: Text(v['label'] as String),
                selected: selected,
                selectedColor: primaryRed.withAlpha(30),
                labelStyle: TextStyle(
                  color: selected ? primaryRed : colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) {
                  notifier.setViewFilter(v['id'] as String);
                },
              );
            }).toList(),
          ),
          AppSpacing.verticalGapLg,

          // Priority Section
          Text(
            'PRIORITY',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalGapSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: priorities.map((p) {
              final selected = state.priorityFilter == p['id'];
              return ChoiceChip(
                label: Text(p['label'] as String),
                selected: selected,
                selectedColor: primaryRed.withAlpha(30),
                labelStyle: TextStyle(
                  color: selected ? primaryRed : colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) {
                  notifier.setPriorityFilter(p['id'] as String?);
                },
              );
            }).toList(),
          ),
          AppSpacing.verticalGapLg,

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: primaryRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
