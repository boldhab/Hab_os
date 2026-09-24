import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class GoalItemModel {
  final String id;
  final String title;
  final String? category;
  final String? targetDate;
  final int progress;

  GoalItemModel({
    required this.id,
    required this.title,
    this.category,
    this.targetDate,
    required this.progress,
  });

  factory GoalItemModel.fromJson(Map<String, dynamic> json) {
    return GoalItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'],
      targetDate: json['targetDate'],
      progress: json['progress'] ?? 0,
    );
  }
}

final goalsProvider =
    FutureProvider.autoDispose<List<GoalItemModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.goals);
  final data = response.data['data'];
  List items = [];
  if (data is Map && data.containsKey('data')) {
    items = data['data'] as List;
  } else if (data is List) {
    items = data;
  }
  return items
      .map((i) => GoalItemModel.fromJson(Map<String, dynamic>.from(i)))
      .toList();
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(goalsProvider),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(goalsProvider),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return AppEmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals set yet',
              description: 'Tap "+ New Goal" to map out long-term milestones.',
              actionLabel: 'New Goal',
              onAction: () => _openCreateGoalDialog(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(goalsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final g = goals[index];
                final pct = (g.progress / 100.0).clamp(0.0, 1.0);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                g.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Text(
                              '${g.progress}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: colorScheme.primary.withAlpha(30),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              g.progress == 100
                                  ? colorScheme.tertiary
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
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
    final categoryController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g. Career, Health',
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final dio = ref.read(dioProvider);
      await dio.post(ApiEndpoints.goals, data: {
        'title': titleController.text.trim(),
        if (categoryController.text.trim().isNotEmpty)
          'category': categoryController.text.trim(),
      });
      ref.invalidate(goalsProvider);
    }
  }
}
