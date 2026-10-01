import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String? healthStatus; // 'ON_TRACK', 'BEHIND', 'AT_RISK'
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.healthStatus,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    return switch (category.toUpperCase()) {
      'CAREER' => Icons.work_outline_rounded,
      'HEALTH' || 'FITNESS' => Icons.fitness_center_rounded,
      'EDUCATION' || 'LEARNING' => Icons.school_outlined,
      'FINANCIAL' => Icons.savings_outlined,
      _ => Icons.flag_outlined,
    };
  }

  Color _getCategoryColor(
      String category, ColorScheme cs, AppSemanticColors semantics) {
    return switch (category.toUpperCase()) {
      'CAREER' => cs.tertiary,
      'HEALTH' || 'FITNESS' => cs.secondary,
      'EDUCATION' || 'LEARNING' => semantics.info,
      'FINANCIAL' => semantics.success,
      _ => cs.primary,
    };
  }

  Color _getHealthColor(
      String status, AppSemanticColors semantics, ColorScheme cs) {
    return switch (status.toUpperCase()) {
      'BEHIND' => semantics.warning,
      'AT_RISK' => semantics.danger,
      _ => semantics.success,
    };
  }

  String _getHealthLabel(String status) {
    return switch (status.toUpperCase()) {
      'BEHIND' => 'Behind',
      'AT_RISK' => 'At risk',
      _ => 'On track',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    final catColor = _getCategoryColor(goal.category, colorScheme, semantics);
    final isCompleted =
        goal.status.toUpperCase() == 'COMPLETED' || goal.progress >= 100;
    final pct = (goal.progress / 100.0).clamp(0.0, 1.0);

    final health = healthStatus ?? 'ON_TRACK';
    final healthColor = isCompleted
        ? semantics.success
        : _getHealthColor(health, semantics, colorScheme);
    final healthLabel = isCompleted ? 'Completed' : _getHealthLabel(health);

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Goal?'),
            content: Text('Are you sure you want to delete "${goal.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    FilledButton.styleFrom(backgroundColor: colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Opacity(
        opacity: isCompleted ? 0.75 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(9),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              onTap();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category Icon Badge & Health Indicator
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(goal.category),
                                size: 14, color: catColor),
                            const SizedBox(width: 6),
                            Text(
                              goal.category[0].toUpperCase() +
                                  goal.category.substring(1).toLowerCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Health Dot + Label
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: healthColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            healthLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: healthColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.verticalGapSm,

                  // Title & Optional Description
                  Text(
                    goal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (goal.description != null &&
                      goal.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      goal.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                      ),
                    ),
                  ],
                  AppSpacing.verticalGapMd,

                  // Financial vs Non-Financial Hero Row & Progress Bar
                  if (goal.isFinancial &&
                      goal.targetAmount != null &&
                      goal.targetAmount! > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${(goal.currentAmount ?? 0).toInt()} of \$${goal.targetAmount!.toInt()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: semantics.success,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '${(goal.financialProgressRatio * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: primaryRed,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: goal.financialProgressRatio,
                        minHeight: 4,
                        backgroundColor:
                            colorScheme.outlineVariant.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${goal.milestones.where((m) => m.isCompleted).length}/${goal.milestones.length} milestones',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                        ),
                        Text(
                          '${goal.progress.toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: primaryRed,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor:
                            colorScheme.outlineVariant.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                      ),
                    ),
                  ],
                  AppSpacing.verticalGapSm,

                  // Bottom Meta Row: Target Date
                  if (goal.targetDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${goal.targetDate!.split('T')[0]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
