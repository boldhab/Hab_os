import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../data/models/habit_model.dart';
import '../../../widgets/app_animated_check.dart';

/// Interactive habit card supporting binary checkboxes for CHECKBOX habits,
/// and rich progress metrics with incremental buttons for COUNT & DURATION habits.
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onToggleComplete;
  final ValueChanged<int>? onIncrement;
  final VoidCallback? onStartFocus;
  final VoidCallback onLogProgress;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onToggleArchive;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleComplete,
    this.onIncrement,
    this.onStartFocus,
    required this.onLogProgress,
    required this.onEdit,
    required this.onHistory,
    required this.onToggleArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    Color? categoryColor;
    if (habit.category?.color != null && habit.category!.color!.isNotEmpty) {
      try {
        final hex = habit.category!.color!.replaceFirst('#', '');
        categoryColor = Color(
            int.parse(hex.length == 6 ? '0xFF$hex' : '0xFF000000'));
      } catch (_) {}
    }

    final isNumeric = habit.isNumericProgress;
    final isDuration = habit.targetType == 'DURATION';
    final unitLabel = isDuration ? 'mins' : 'reps';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: habit.isActive
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerHigh.withAlpha(120),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Action / Status Indicator
            if (!isNumeric)
              // Binary Checkbox for CHECKBOX targetType
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppAnimatedCheck(
                  value: habit.isCompletedToday,
                  isCircle: true,
                  size: 28,
                  activeColor: semantics.success,
                  checkColor: semantics.onSuccess,
                  onChanged: (_) => onToggleComplete(),
                ),
              )
            else
              // Progress Status Icon / Gauge for COUNT & DURATION targetTypes
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: InkWell(
                  onTap: onLogProgress,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.isCompletedToday
                          ? semantics.success.withAlpha(30)
                          : colorScheme.primaryContainer.withAlpha(90),
                      border: Border.all(
                        color: habit.isCompletedToday
                            ? semantics.success
                            : colorScheme.primary.withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: habit.isCompletedToday
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: semantics.success,
                            )
                          : Icon(
                              isDuration
                                  ? Icons.timer_outlined
                                  : Icons.repeat_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                ),
              ),

            const SizedBox(width: AppSpacing.sm + 6),

            // Content Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: (!isNumeric && habit.isCompletedToday)
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: habit.isActive
                                        ? (habit.isCompletedToday && !isNumeric
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                      if (!habit.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Archived',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  if (habit.description != null &&
                      habit.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      habit.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Metadata Badges Wrap
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (habit.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor != null
                                ? categoryColor.withAlpha(35)
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: categoryColor ?? colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                habit.category!.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor ?? colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _Chip(
                        label: habit.frequency,
                        colorScheme: colorScheme,
                      ),
                      if (habit.isWeeklyCount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Week: ${habit.weeklyCompletionsCount}/${habit.targetFrequencyCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      _Chip(
                        label: habit.difficulty,
                        colorScheme: colorScheme,
                      ),
                      if (habit.targetType != 'CHECKBOX')
                        _Chip(
                          label: '${habit.targetValue} $unitLabel',
                          colorScheme: colorScheme,
                        ),
                      if (habit.streakFreezes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: semantics.info.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '❄️ ${habit.streakFreezes}',
                            style:
                                TextStyle(fontSize: 10, color: semantics.info),
                          ),
                        ),
                    ],
                  ),

                  // Numeric / Duration Progress Deck
                  if (isNumeric) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: habit.isCompletedToday
                            ? semantics.success.withAlpha(18)
                            : colorScheme.surfaceContainerHighest.withAlpha(70),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: habit.isCompletedToday
                              ? semantics.success.withAlpha(60)
                              : colorScheme.outlineVariant.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${habit.currentTodayValue}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: habit.isCompletedToday
                                          ? semantics.success
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    ' / ${habit.targetValue} $unitLabel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: habit.isCompletedToday
                                      ? semantics.success.withAlpha(30)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  habit.isCompletedToday
                                      ? 'Done ✓'
                                      : '${(habit.progressRatio * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: habit.isCompletedToday
                                        ? semantics.success
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: habit.progressRatio,
                              minHeight: 6,
                              backgroundColor:
                                  colorScheme.outlineVariant.withAlpha(50),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                habit.isCompletedToday
                                    ? semantics.success
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Incremental Action Buttons Row
                          Row(
                            children: [
                              _QuickIncrementBtn(
                                label: isDuration ? '+5m' : '+1',
                                icon: Icons.add,
                                onPressed: () => onIncrement?.call(isDuration ? 5 : 1),
                              ),
                              const SizedBox(width: 6),
                              _QuickIncrementBtn(
                                label: isDuration ? '+15m' : '+5',
                                icon: Icons.add,
                                onPressed: () => onIncrement?.call(isDuration ? 15 : 5),
                              ),
                              if (isDuration && onStartFocus != null) ...[
                                const SizedBox(width: 6),
                                _QuickIncrementBtn(
                                  label: 'Focus',
                                  icon: Icons.play_arrow_rounded,
                                  isAccent: true,
                                  onPressed: onStartFocus,
                                ),
                              ],
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 14),
                                label: const Text('Input',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: onLogProgress,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Streak Badge & Action Menu
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        habit.isWeeklyCount
                            ? '${habit.currentStreak}w'
                            : '${habit.currentStreak}d',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best ${habit.longestStreak}${habit.isWeeklyCount ? "w" : "d"}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    switch (val) {
                      case 'progress':
                        onLogProgress();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'history':
                        onHistory();
                        break;
                      case 'archive':
                        onToggleArchive();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (habit.isNumericProgress)
                      const PopupMenuItem(
                        value: 'progress',
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Set Progress'),
                          ],
                        ),
                      ),
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
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('History & Heatmap'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(
                            habit.isActive
                                ? Icons.archive_outlined
                                : Icons.unarchive_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(habit.isActive ? 'Archive' : 'Unarchive'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: semantics.danger),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: semantics.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickIncrementBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isAccent;

  const _QuickIncrementBtn({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isAccent ? colorScheme.primaryContainer : colorScheme.surface;
    final fg = isAccent ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAccent
                  ? colorScheme.primary.withAlpha(120)
                  : colorScheme.outlineVariant.withAlpha(90),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: colorScheme.primary),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _Chip({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
      ),
    );
  }
}
