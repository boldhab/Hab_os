import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_error_state.dart';
import 'controllers/projects_controller.dart';
import 'models/project_models.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(projectDetailProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Developer Hub')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Developer Hub')),
        body: AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(projectDetailProvider(widget.projectId)),
        ),
      ),
      data: (data) {
        final title = data['title'] ?? 'Project';
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        final health = data['health'] as Map<String, dynamic>? ?? {};
        final healthStatus = health['healthStatus'] ?? 'HEALTHY';
        final repoUrl = data['repoUrl'] as String?;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}% Completed • Health: $healthStatus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getHealthColor(healthStatus, colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            actions: [
              if (repoUrl != null && repoUrl.isNotEmpty)
                IconButton(
                  tooltip: 'GitHub Repository',
                  icon: const Icon(Icons.code_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Repo: $repoUrl')),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.read(projectsControllerProvider).invalidateProjectViews(widget.projectId);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _confirmDeleteProject(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.view_kanban_outlined), text: 'Kanban Board'),
                Tab(icon: Icon(Icons.bug_report_outlined), text: 'Features & Bugs'),
                Tab(icon: Icon(Icons.commit_rounded), text: 'GitHub & Commits'),
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Metrics & Velocity'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _KanbanBoardTab(projectId: widget.projectId),
              _FeaturesBugsTab(projectId: widget.projectId),
              _GitHubCommitsTab(projectId: widget.projectId, repoUrl: repoUrl),
              _ProjectAnalyticsTab(projectId: widget.projectId),
            ],
          ),
        );
      },
    );
  }

  Color _getHealthColor(String status, ColorScheme cs) {
    switch (status) {
      case 'HEALTHY':
        return Colors.green;
      case 'NEEDS_ATTENTION':
        return Colors.orange;
      case 'AT_RISK':
        return Colors.redAccent;
      default:
        return cs.primary;
    }
  }

  Future<void> _confirmDeleteProject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text('This will delete all features, bugs, and linked items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(projectsControllerProvider).deleteProject(widget.projectId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// ==========================================
// TAB 1: KANBAN BOARD
// ==========================================

class _KanbanBoardTab extends ConsumerWidget {
  final String projectId;
  const _KanbanBoardTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(projectBoardProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;

    return boardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectBoardProvider(projectId)),
      ),
      data: (board) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKanbanColumn(
                context,
                ref,
                title: 'To Do',
                statusKey: 'TODO',
                items: board.todo,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 12),
              _buildKanbanColumn(
                context,
                ref,
                title: 'In Progress',
                statusKey: 'IN_PROGRESS',
                items: board.inProgress,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _buildKanbanColumn(
                context,
                ref,
                title: 'Blocked',
                statusKey: 'BLOCKED',
                items: board.blocked,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              _buildKanbanColumn(
                context,
                ref,
                title: 'Done',
                statusKey: 'COMPLETED',
                items: board.completed,
                color: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String statusKey,
    required List<KanbanCardModel> items,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final card = items[index];
              return _KanbanCard(
                card: card,
                projectId: projectId,
                onMove: (targetStatus) {
                  ref.read(projectsControllerProvider).moveBoardItem(
                        projectId: projectId,
                        entityType: card.type,
                        entityId: card.id,
                        targetStatus: targetStatus,
                      );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Deliverable', style: TextStyle(fontSize: 12)),
              onPressed: () => _showQuickAddDialog(context, ref, statusKey),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context, WidgetRef ref, String statusKey) {
    final titleCtrl = TextEditingController();
    String type = 'FEATURE';
    String priority = 'MEDIUM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Deliverable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'FEATURE', label: Text('Feature')),
                  ButtonSegment(value: 'BUG', label: Text('Bug')),
                ],
                selected: {type},
                onSelectionChanged: (val) => setState(() => type = val.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: type == 'BUG' ? 'Bug Title *' : 'Feature Title *',
                  hintText: 'e.g. Implement Webhook Parser',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => priority = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                if (type == 'BUG') {
                  await ref.read(projectsControllerProvider).createBug(
                        projectId: projectId,
                        title: titleCtrl.text.trim(),
                        description: 'Created from Kanban',
                        priority: priority,
                        severity: priority == 'CRITICAL' ? 'CRITICAL' : 'MAJOR',
                        status: statusKey == 'COMPLETED' ? 'RESOLVED' : 'OPEN',
                      );
                } else {
                  await ref.read(projectsControllerProvider).createFeature(
                        projectId: projectId,
                        name: titleCtrl.text.trim(),
                        priority: priority,
                        status: statusKey,
                      );
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final KanbanCardModel card;
  final String projectId;
  final ValueChanged<String> onMove;

  const _KanbanCard({
    required this.card,
    required this.projectId,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color typeColor;
    IconData typeIcon;
    switch (card.type) {
      case 'FEATURE':
        typeColor = Colors.cyan;
        typeIcon = Icons.star_outline_rounded;
        break;
      case 'BUG':
        typeColor = Colors.redAccent;
        typeIcon = Icons.bug_report_outlined;
        break;
      default:
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.check_circle_outline_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 14, color: typeColor),
                const SizedBox(width: 4),
                Text(
                  card.type,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
                if (card.severity != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: card.severity == 'CRITICAL' ? Colors.red.withAlpha(40) : Colors.orange.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      card.severity!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: card.severity == 'CRITICAL' ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  tooltip: 'Move to Column',
                  onSelected: onMove,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'TODO', child: Text('Move to: To Do')),
                    const PopupMenuItem(value: 'IN_PROGRESS', child: Text('Move to: In Progress')),
                    const PopupMenuItem(value: 'BLOCKED', child: Text('Move to: Blocked')),
                    const PopupMenuItem(value: 'COMPLETED', child: Text('Move to: Done')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              card.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (card.description != null && card.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                card.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    card.priority,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: card.priority == 'CRITICAL' ? Colors.red : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (card.githubIssueNumber != null) ...[
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 10, color: Colors.grey),
                      Text(
                        '${card.githubIssueNumber}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: FEATURES & BUGS
// ==========================================

class _FeaturesBugsTab extends ConsumerStatefulWidget {
  final String projectId;
  const _FeaturesBugsTab({required this.projectId});

  @override
  ConsumerState<_FeaturesBugsTab> createState() => _FeaturesBugsTabState();
}

class _FeaturesBugsTabState extends ConsumerState<_FeaturesBugsTab> {
  int _selectedView = 0; // 0 = Features, 1 = Bugs

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(projectFeaturesProvider(widget.projectId));
    final bugsAsync = ref.watch(projectBugsProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Features'), icon: Icon(Icons.star_outline)),
                    ButtonSegment(value: 1, label: Text('Bugs'), icon: Icon(Icons.bug_report_outlined)),
                  ],
                  selected: {_selectedView},
                  onSelectionChanged: (v) => setState(() => _selectedView = v.first),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(_selectedView == 0 ? 'New Feature' : 'Report Bug'),
                onPressed: () {
                  if (_selectedView == 0) {
                    _openCreateFeatureDialog(context);
                  } else {
                    _openCreateBugDialog(context);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedView == 0
              ? featuresAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => AppErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(projectFeaturesProvider(widget.projectId)),
                  ),
                  data: (features) {
                    if (features.isEmpty) {
                      return const Center(child: Text('No features tracked yet. Tap "New Feature" above.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: features.length,
                      itemBuilder: (context, i) {
                        final f = features[i];
                        final isCompleted = f.status == 'COMPLETED';
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isCompleted ? Icons.check_circle : Icons.star_outline_rounded,
                              color: isCompleted ? Colors.green : Colors.cyan,
                            ),
                            title: Text(
                              f.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              'Priority: ${f.priority} • Status: ${f.status}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => ref
                                  .read(projectsControllerProvider)
                                  .deleteFeature(widget.projectId, f.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              : bugsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => AppErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(projectBugsProvider(widget.projectId)),
                  ),
                  data: (bugs) {
                    if (bugs.isEmpty) {
                      return const Center(child: Text('No open bugs! Project is clean.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: bugs.length,
                      itemBuilder: (context, i) {
                        final b = bugs[i];
                        final isResolved = b.status == 'RESOLVED' || b.status == 'CLOSED';
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isResolved ? Icons.check_circle : Icons.bug_report_rounded,
                              color: isResolved ? Colors.green : Colors.redAccent,
                            ),
                            title: Text(
                              b.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: isResolved ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              'Severity: ${b.severity} • Priority: ${b.priority} • Status: ${b.status}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'RESOLVE') {
                                  ref.read(projectsControllerProvider).updateBug(
                                        projectId: widget.projectId,
                                        bugId: b.id,
                                        data: {'status': 'RESOLVED'},
                                      );
                                } else if (val == 'DELETE') {
                                  ref
                                      .read(projectsControllerProvider)
                                      .deleteBug(widget.projectId, b.id);
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (!isResolved)
                                  const PopupMenuItem(value: 'RESOLVE', child: Text('Mark Resolved')),
                                const PopupMenuItem(value: 'DELETE', child: Text('Delete Bug')),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openCreateFeatureDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'MEDIUM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Feature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Feature Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => priority = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(projectsControllerProvider).createFeature(
                      projectId: widget.projectId,
                      name: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      priority: priority,
                    );
              },
              child: const Text('Save Feature'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateBugDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String severity = 'MAJOR';
    String priority = 'MEDIUM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Report Bug'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Bug Title *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description / Steps *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: const [
                  DropdownMenuItem(value: 'MINOR', child: Text('Minor (low impact)')),
                  DropdownMenuItem(value: 'MAJOR', child: Text('Major (broken feature)')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical (blocking/crash)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => severity = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => priority = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(projectsControllerProvider).createBug(
                      projectId: widget.projectId,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty ? 'No description' : descCtrl.text.trim(),
                      severity: severity,
                      priority: priority,
                    );
              },
              child: const Text('Log Bug'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 3: GITHUB & COMMITS
// ==========================================

class _GitHubCommitsTab extends ConsumerWidget {
  final String projectId;
  final String? repoUrl;
  const _GitHubCommitsTab({required this.projectId, this.repoUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitsAsync = ref.watch(projectCommitsProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Webhook & Integration banner
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.webhook_rounded, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'GitHub Webhook Integration',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point your repository webhook to:\nPOST /api/v1/integrations/github/webhook\nEvents: Push, Pull Request, Issues',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: Use "fixes #12" in commit messages or conventional tags like "feat:" to auto-progress deliverables.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Commit Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          commitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Could not fetch commits: $err'),
            data: (commits) {
              if (commits.isEmpty) {
                return const Text('No commits found or repository not linked.');
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = commits[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  c.sha,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.author,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(c.message, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: METRICS & VELOCITY
// ==========================================

class _ProjectAnalyticsTab extends ConsumerWidget {
  final String projectId;
  const _ProjectAnalyticsTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(projectAnalyticsProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectAnalyticsProvider(projectId)),
      ),
      data: (an) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High Level KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Focus Hours Logged',
                      value: '${an.totalFocusHours}h',
                      icon: Icons.timer_outlined,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Project Health',
                      value: an.healthStatus,
                      icon: Icons.health_and_safety_outlined,
                      color: an.healthStatus == 'HEALTHY'
                          ? Colors.green
                          : an.healthStatus == 'NEEDS_ATTENTION'
                              ? Colors.orange
                              : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Velocity Trend',
                      value: an.velocityTrend,
                      icon: an.velocityTrend == 'UP'
                          ? Icons.trending_up
                          : an.velocityTrend == 'DOWN'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: an.velocityTrend == 'UP' ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Firefighting Mode',
                      value: an.isFirefighting ? 'YES (Bugs > Feat)' : 'NO (Normal)',
                      icon: Icons.warning_amber_rounded,
                      color: an.isFirefighting ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress breakdown formula
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Progress Calculation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        an.formula.isNotEmpty ? an.formula : 'Derived from completed tasks & features minus bug penalties',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Weekly Velocity (Past 8 Weeks)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: an.weeklyVelocity.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final w = an.weeklyVelocity[i];
                  final hours = (w.focusMinutes / 60.0).toStringAsFixed(1);
                  final deliverables = w.tasksCompleted + w.featuresCompleted;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Week of ${w.weekStart}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Chip(
                              label: Text('${hours}h focus'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 6),
                            Chip(
                              label: Text('$deliverables done'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
