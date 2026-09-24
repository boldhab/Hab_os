import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/habit_model.dart';
import '../../../providers/habits_provider.dart';

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
    final logs = await ref.read(habitsProvider.notifier).fetchHistory(widget.habit.id);
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Completion History & Streaks',
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
          // Streak summary row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Current Streak',
                  value: '${widget.habit.currentStreak} days',
                  icon: '🔥',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Longest Streak',
                  value: '${widget.habit.longestStreak} days',
                  icon: '🏆',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Logs (Last 30 Days)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No completion logs recorded yet.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final dateStr = log.date.split('T')[0];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              log.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_outlined,
                              color: log.isCompleted
                                  ? colorScheme.tertiary
                                  : colorScheme.error,
                            ),
                            title: Text(dateStr),
                            subtitle: log.notes != null && log.notes!.isNotEmpty
                                ? Text(log.notes!)
                                : null,
                            trailing: widget.habit.targetType != 'CHECKBOX'
                                ? Text('${log.value} target')
                                : null,
                          );
                        },
                      ),
          ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
