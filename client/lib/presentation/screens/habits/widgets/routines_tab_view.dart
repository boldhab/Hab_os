import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/habits_provider.dart';
import '../../../../data/models/habit_model.dart';
import 'routine_card.dart';

/// The Routines tab view rendering the list of chained habit routines or an empty state.
class RoutinesTabView extends ConsumerWidget {
  final HabitsState state;
  final VoidCallback onCreateRoutine;
  final void Function(RoutineModel routine) onEditRoutine;

  const RoutinesTabView({
    super.key,
    required this.state,
    required this.onCreateRoutine,
    required this.onEditRoutine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = state.routines;
    final colorScheme = Theme.of(context).colorScheme;

    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 48, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.sm + 4),
              const Text(
                'No habit routines yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Chain habits into sequential rituals (e.g. Morning Launchpad: Hydrate → Meditate → Journal).',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Routine'),
                onPressed: onCreateRoutine,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(habitsProvider.notifier).loadRoutines(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, 80),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final r = routines[index];
          return RoutineCard(
            routine: r,
            onEdit: () => onEditRoutine(r),
            onComplete: () async {
              await ref.read(habitsProvider.notifier).completeRoutine(r.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '🎉 Completed "${r.name}" ritual! All streak counts updated.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            onDelete: () async {
              final semantics = AppSemanticColors.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Routine'),
                  content:
                      Text('Delete "${r.name}"? (Habits will remain intact)'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: semantics.danger,
                        foregroundColor: semantics.onDanger,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(habitsProvider.notifier).deleteRoutine(r.id);
              }
            },
          );
        },
      ),
    );
  }
}
