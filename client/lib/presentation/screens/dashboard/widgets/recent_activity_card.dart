import 'package:flutter/material.dart';
import '../../../../data/models/dashboard_feed_model.dart';

class RecentActivityCard extends StatelessWidget {
  final List<GlobalActivityItem> activities;

  const RecentActivityCard({super.key, required this.activities});

  IconData _iconForCategory(String category) {
    return switch (category) {
      'TASK' => Icons.task_alt_rounded,
      'HABIT' => Icons.loop_rounded,
      'FITNESS' => Icons.fitness_center_rounded,
      'FINANCE' => Icons.account_balance_wallet_outlined,
      'FOCUS' => Icons.timer_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }

  Color _colorForCategory(String category, ColorScheme cs) {
    return switch (category) {
      'TASK' => cs.primary,
      'HABIT' => Colors.purple,
      'FITNESS' => Colors.orange,
      'FINANCE' => Colors.green,
      'FOCUS' => cs.tertiary,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No recent activity recorded today yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final act = activities[i];
                  final color = _colorForCategory(act.category, colorScheme);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconForCategory(act.category),
                              color: color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                act.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
