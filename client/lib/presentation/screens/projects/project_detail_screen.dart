import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_error_state.dart';
import '../../../app/theme/app_theme.dart';
import 'controllers/projects_controller.dart';
import 'dialogs/edit_project_dialog.dart';
import 'dialogs/github_webhook_dialog.dart';
import 'tabs/kanban_board_tab.dart';
import 'tabs/backlog_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/commits_tab.dart';
import 'tabs/metrics_tab.dart';
import '../../../data/repositories/project_repository.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getHealthColor(
      String status, ColorScheme cs, AppSemanticColors semantics) {
    switch (status.toUpperCase()) {
      case 'HEALTHY':
        return semantics.success;
      case 'NEEDS_ATTENTION':
        return semantics.warning;
      case 'AT_RISK':
        return semantics.danger;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time project events (SSE)
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      projectEventsStreamProvider(widget.projectId),
      (prev, next) {
        next.whenData((event) {
          final type = event['type'] ?? 'PROJECT_UPDATED';
          ref
              .read(projectsControllerProvider)
              .invalidateProjectViews(widget.projectId);

          if (mounted) {
            final msg = type == 'GITHUB_WEBHOOK'
                ? 'GitHub webhook synced automatically'
                : 'Project updated in real-time';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.sync_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(msg),
                  ],
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      },
    );

    final detailAsync = ref.watch(projectDetailProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Developer Hub')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Developer Hub')),
        body: AppErrorState(
          message: err.toString(),
          onRetry: () => ref
              .read(projectsControllerProvider)
              .invalidateProjectViews(widget.projectId),
        ),
      ),
      data: (data) {
        final title = data['title'] ?? 'Project';
        final description = data['description'] as String?;
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        final health = data['health'] as Map<String, dynamic>? ?? {};
        final healthStatus = health['healthStatus'] ?? 'HEALTHY';
        final repoUrl = data['repoUrl'] as String?;
        final status = data['status'] ?? 'IN_PROGRESS';
        final technologies = (data['technologies'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final color = data['color'] as String?;

        final healthColor =
            _getHealthColor(healthStatus, colorScheme, semantics);

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      healthStatus.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: healthColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•',
                        style: TextStyle(
                            fontSize: 10, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Text(
                      '${progress.toInt()}% Completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (repoUrl != null && repoUrl.isNotEmpty)
                IconButton(
                  tooltip: 'GitHub Repo ($repoUrl)',
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Repo: $repoUrl')),
                    );
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'refresh') {
                    ref
                        .read(projectsControllerProvider)
                        .invalidateProjectViews(widget.projectId);
                  } else if (val == 'edit') {
                    _openEditProject(context, title, description, status,
                        repoUrl, technologies, color);
                  } else if (val == 'webhook') {
                    GitHubWebhookDialog.show(context,
                        projectId: widget.projectId, repoUrl: repoUrl);
                  } else if (val == 'delete') {
                    _confirmDeleteProject(context, semantics);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Project'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'webhook',
                    child: Row(children: [
                      Icon(Icons.webhook_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('GitHub Webhook'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: semantics.danger),
                      const SizedBox(width: 8),
                      Text('Delete Project',
                          style: TextStyle(color: semantics.danger)),
                    ]),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: primaryRed,
              labelColor: primaryRed,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Board'),
                Tab(text: 'Backlog'),
                Tab(text: 'Tasks'),
                Tab(text: 'Commits'),
                Tab(text: 'Metrics'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              KanbanBoardTab(projectId: widget.projectId),
              BacklogTab(projectId: widget.projectId),
              TasksTab(projectId: widget.projectId),
              GitHubCommitsTab(projectId: widget.projectId, repoUrl: repoUrl),
              MetricsTab(projectId: widget.projectId),
            ],
          ),
        );
      },
    );
  }

  void _openEditProject(
    BuildContext context,
    String title,
    String? description,
    String status,
    String? repoUrl,
    List<String> technologies,
    String? color,
  ) {
    EditProjectDialog.show(
      context,
      initialTitle: title,
      initialDescription: description,
      initialStatus: status,
      initialRepoUrl: repoUrl,
      initialTechnologies: technologies,
      initialColor: color,
      onSubmit: ({
        required String newTitle,
        String? newDescription,
        required String newStatus,
        String? newRepoUrl,
        required List<String> newTechnologies,
        required String newColor,
      }) async {
        await ref.read(projectsControllerProvider).updateProject(
              projectId: widget.projectId,
              title: newTitle,
              description: newDescription,
              status: newStatus,
              repoUrl: newRepoUrl,
              technologies: newTechnologies,
              color: newColor,
            );
      },
    );
  }

  void _confirmDeleteProject(
      BuildContext context, AppSemanticColors semantics) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text(
            'This will delete all features, bugs, and linked items.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(projectsControllerProvider)
                  .deleteProject(widget.projectId);
              if (context.canPop()) context.pop();
            },
            style: FilledButton.styleFrom(backgroundColor: semantics.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
