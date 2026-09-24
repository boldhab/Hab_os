import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'controllers/projects_controller.dart';
import 'models/project_models.dart';

export 'controllers/projects_controller.dart';
export 'models/project_models.dart';

typedef ProjectItemModel = ProjectOverviewModel;
final projectsProvider = projectsListProvider;

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsListProvider);
    final techInsightsAsync = ref.watch(techStackInsightsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Hub & Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(projectsListProvider);
              ref.invalidate(techStackInsightsProvider);
            },
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () {
            ref.invalidate(projectsListProvider);
            ref.invalidate(techStackInsightsProvider);
          },
        ),
        data: (projects) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectsListProvider);
              ref.invalidate(techStackInsightsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // 1. Tech Stack Insights Carousel
                techInsightsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (insights) {
                    if (insights.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pie_chart_outline_rounded,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Coding Focus Distribution',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: insights.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final item = insights[i];
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor:
                                      colorScheme.primary.withAlpha(40),
                                  child: Text(
                                    item.technology.isNotEmpty
                                        ? item.technology[0].toUpperCase()
                                        : 'T',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                label: Text(
                                  '${item.technology} ${item.percentage.toStringAsFixed(0)}% (${item.totalHours}h)',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // 2. Projects List or Empty State
                if (projects.isEmpty)
                  AppEmptyState(
                    icon: Icons.folder_outlined,
                    title: 'No projects found',
                    description:
                        'Tap "+ New Project" to initialize your developer workspace.',
                    actionLabel: 'New Project',
                    onAction: () => _openCreateProjectDialog(context, ref),
                  )
                else
                  ...projects.map((p) => _ProjectCard(project: p)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateProjectDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
    );
  }

  Future<void> _openCreateProjectDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final repoUrlController = TextEditingController();
    final techController = TextEditingController(text: 'TypeScript, Flutter');
    String status = 'IN_PROGRESS';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Developer Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Project Title *',
                    hintText: 'e.g. HABos Developer Hub',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'GitHub Repo URL (optional)',
                    hintText: 'https://github.com/owner/repo',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: techController,
                  decoration: const InputDecoration(
                    labelText: 'Technologies (comma-separated)',
                    hintText: 'TypeScript, Node.js, Flutter',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                        value: 'IN_PROGRESS', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'PLANNING', child: Text('Planning')),
                    DropdownMenuItem(
                        value: 'ON_HOLD', child: Text('On Hold')),
                    DropdownMenuItem(
                        value: 'COMPLETED', child: Text('Completed')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => status = val);
                  },
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
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final techs = techController.text
          .split(',')
          .map((s) => s.trim())
          .filter((s) => s.isNotEmpty)
          .toList();

      await ref.read(projectsControllerProvider).createProject(
            title: titleController.text.trim(),
            description: descController.text.trim(),
            status: status,
            repoUrl: repoUrlController.text.trim(),
            technologies: techs,
          );
    }
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectOverviewModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (project.progress / 100.0).clamp(0.0, 1.0);

    Color healthColor;
    switch (project.healthStatus) {
      case 'HEALTHY':
        healthColor = Colors.green;
        break;
      case 'NEEDS_ATTENTION':
        healthColor = Colors.orange;
        break;
      case 'AT_RISK':
        healthColor = Colors.redAccent;
        break;
      default:
        healthColor = colorScheme.primary;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      color: colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/more/projects/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: healthColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 12, color: healthColor),
                        const SizedBox(width: 4),
                        Text(
                          project.healthStatus.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: healthColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],

              const SizedBox(height: 12),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress (${project.completedTasksCount + project.completedFeaturesCount}/${project.tasksCount + project.featuresCount} items)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${project.progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: colorScheme.primary,
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
                  backgroundColor: colorScheme.primary.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Metadata Row: Tech Tags, Focus Hours, Bugs
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 12, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          '${project.totalFocusHours}h logged',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (project.openBugsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bug_report_outlined,
                              size: 12, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${project.openBugsCount} open bugs',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...project.technologies.take(3).map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ListFilter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}
