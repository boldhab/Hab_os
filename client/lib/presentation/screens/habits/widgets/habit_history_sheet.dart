import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/habit_model.dart';
import '../../../providers/habits_provider.dart';
import '../../../../app/theme/app_theme.dart';
import 'habit_contribution_heatmap.dart';

class HabitHistorySheet extends ConsumerStatefulWidget {
  final HabitModel habit;

  const HabitHistorySheet({super.key, required this.habit});

  @override
  ConsumerState<HabitHistorySheet> createState() => _HabitHistorySheetState();
}

class _HabitHistorySheetState extends ConsumerState<HabitHistorySheet> {
  bool _loading = true;
  List<HabitLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final logs =
        await ref.read(habitsProvider.notifier).fetchHistory(widget.habit.id);
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _refillFreeze() async {
    final prevError = ref.read(habitsProvider).errorMessage;
    await ref
        .read(habitsProvider.notifier)
        .refillStreakFreeze(widget.habit.id, count: 1);
    if (!mounted) return;
    final currentError = ref.read(habitsProvider).errorMessage;
    if (currentError != null && currentError != prevError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentError.replaceAll('Exception: ', ''))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Streak Freeze added! ❄️ Your streak is protected.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.habit.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.habit.difficulty,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.habit.isWeeklyCount
                          ? 'Count-based habit (${widget.habit.targetFrequencyCount}x / ${widget.habit.targetFrequencyPeriod})'
                          : 'Daily habit consistency & streak shields',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Streak & Freeze Summary Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: widget.habit.isWeeklyCount
                      ? 'Weekly Streak'
                      : 'Current Streak',
                  value: widget.habit.isWeeklyCount
                      ? '${widget.habit.currentStreak} wks'
                      : '${widget.habit.currentStreak} days',
                  icon: '🔥',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Best Record',
                  value: widget.habit.isWeeklyCount
                      ? '${widget.habit.longestStreak} wks'
                      : '${widget.habit.longestStreak} days',
                  icon: '🏆',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Freezes',
                  value: '${widget.habit.streakFreezes}/3 left',
                  icon: '❄️',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Freeze Refill Banner
          Builder(
            builder: (context) {
              final semantics = AppSemanticColors.of(context);
              final isAtMaxFreezes = widget.habit.streakFreezes >= 3;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 4, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: semantics.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                  border: Border.all(color: semantics.info.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 18, color: semantics.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isAtMaxFreezes
                            ? 'Maximum streak shield capacity reached (3/3).'
                            : 'Streak Freezes protect against 1 missed day without breaking your streak.',
                        style: TextStyle(fontSize: 11, color: semantics.info),
                      ),
                    ),
                    TextButton(
                      onPressed: isAtMaxFreezes ? null : _refillFreeze,
                      child: Text(
                        isAtMaxFreezes ? 'Max Shields' : '+ Add Freeze',
                        style: TextStyle(
                          fontSize: 11,
                          color: isAtMaxFreezes
                              ? semantics.info.withAlpha(120)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Heatmap Widget
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else ...[
            HabitContributionHeatmap(
              logs: _logs,
              primaryColor: colorScheme.primary,
              weeksToShow: 18,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              'Recent Logs',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'No completion logs recorded yet.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final parsedDate =
                            DateTime.tryParse(log.date)?.toLocal();
                        final dateStr = parsedDate != null
                            ? '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}'
                            : log.date.split('T')[0];
                        final semantics = AppSemanticColors.of(context);

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            log.wasFrozen
                              ? Icons.ac_unit_rounded
                              : (log.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.cancel_outlined),
                            color: log.wasFrozen
                              ? semantics.info
                              : (log.isCompleted
                                ? semantics.success
                                : semantics.danger),
                            size: 18,
                          ),
                          title: Text(dateStr,
                            style: const TextStyle(fontSize: 13)),
                          subtitle: log.wasFrozen
                            ? Text('Streak Shield Applied ❄️',
                              style: TextStyle(
                                fontSize: 11, color: semantics.info))
                            : (log.notes != null
                              ? Text(log.notes!,
                                style: const TextStyle(fontSize: 11))
                              : null),
                          trailing: widget.habit.targetType != 'CHECKBOX'
                            ? Text(
                              '${log.value} ${widget.habit.targetType.toLowerCase()}',
                              style: const TextStyle(fontSize: 11))
                            : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
