import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_error_state.dart';

class RetrospectiveModel {
  final double totalFocusHours;
  final double totalTrackedHours;
  final int completedTasksCount;
  final int workoutsCount;
  final int habitsCompletedCount;
  final Map<String, double> dailyFocusHours;

  RetrospectiveModel({
    required this.totalFocusHours,
    required this.totalTrackedHours,
    required this.completedTasksCount,
    required this.workoutsCount,
    required this.habitsCompletedCount,
    required this.dailyFocusHours,
  });

  factory RetrospectiveModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final daily = <String, double>{};
    if (json['dailyFocusHours'] is Map) {
      (json['dailyFocusHours'] as Map).forEach((k, v) {
        if (v is num) daily[k.toString()] = v.toDouble();
      });
    }
    return RetrospectiveModel(
      totalFocusHours: (summary['totalFocusHours'] as num?)?.toDouble() ?? 0.0,
      totalTrackedHours: (summary['totalTrackedHours'] as num?)?.toDouble() ?? 0.0,
      completedTasksCount: (summary['completedTasksCount'] as num?)?.toInt() ?? 0,
      workoutsCount: (summary['workoutsCount'] as num?)?.toInt() ?? 0,
      habitsCompletedCount: (summary['habitsCompletedCount'] as num?)?.toInt() ?? 0,
      dailyFocusHours: daily,
    );
  }
}

final retrospectiveProvider =
    FutureProvider.autoDispose<RetrospectiveModel>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.analyticsRetrospective);
  final data = response.data['data'] ?? response.data;
  return RetrospectiveModel.fromJson(Map<String, dynamic>.from(data));
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retroAsync = ref.watch(retrospectiveProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Day Retrospective'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(retrospectiveProvider),
          ),
        ],
      ),
      body: retroAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(retrospectiveProvider),
        ),
        data: (retro) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(retrospectiveProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _StatTile(
                      label: 'Focus Hours',
                      value: '${retro.totalFocusHours}h',
                      icon: Icons.timer_rounded,
                      color: colorScheme.primary,
                    ),
                    _StatTile(
                      label: 'Tasks Completed',
                      value: '${retro.completedTasksCount}',
                      icon: Icons.task_alt_rounded,
                      color: colorScheme.tertiary,
                    ),
                    _StatTile(
                      label: 'Workouts Completed',
                      value: '${retro.workoutsCount}',
                      icon: Icons.fitness_center_rounded,
                      color: Colors.orange,
                    ),
                    _StatTile(
                      label: 'Habits Completed',
                      value: '${retro.habitsCompletedCount}',
                      icon: Icons.loop_rounded,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Daily Focus Breakdown Card
                Text(
                  'Daily Focus Hours (Past 7 Days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: retro.dailyFocusHours.entries.map((e) {
                        final maxVal = 8.0;
                        final pct = (e.value / maxVal).clamp(0.0, 1.0);
                        final dayLabel = e.key.substring(5); // MM-DD

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  dayLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 8,
                                    backgroundColor:
                                        colorScheme.primary.withAlpha(30),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${e.value}h',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
