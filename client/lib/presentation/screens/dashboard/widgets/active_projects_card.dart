import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/dashboard_feed_model.dart';

class ActiveProjectsCard extends StatelessWidget {
  final List<DashboardProjectItem> projects;

  const ActiveProjectsCard({super.key, required this.projects});

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
                Icon(Icons.folder_outlined,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Active Projects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/more/projects'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No active projects in progress.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = projects[i];
                  final pct = (p.progress / 100.0).clamp(0.0, 1.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${p.progress.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor:
                              colorScheme.primary.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
