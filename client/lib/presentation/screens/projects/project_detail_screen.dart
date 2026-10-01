import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/app_error_state.dart';
import '../../../app/theme/app_theme.dart';
import 'controllers/projects_controller.dart';
import 'models/project_models.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        final health = data['health'] as Map<String, dynamic>? ?? {};
        final healthStatus = health['healthStatus'] ?? 'HEALTHY';
        final repoUrl = data['repoUrl'] as String?;

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
                  } else if (val == 'delete') {
                    _confirmDeleteProject(context, semantics);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh'),
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
                        Text('Delete Project',
                            style: TextStyle(color: semantics.danger)),
                      ],
                    ),
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
                Tab(text: 'Commits'),
                Tab(text: 'Metrics'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics:
                const NeverScrollableScrollPhysics(), // Handled internally to avoid Kanban gesture conflict
            children: [
              _KanbanBoardTab(projectId: widget.projectId),
              _BacklogTab(projectId: widget.projectId),
              _GitHubCommitsTab(projectId: widget.projectId, repoUrl: repoUrl),
              _MetricsTab(projectId: widget.projectId),
            ],
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// 1. BOARD TAB (KANBAN)
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanBoardTab extends ConsumerStatefulWidget {
  final String projectId;
  const _KanbanBoardTab({required this.projectId});

  @override
  ConsumerState<_KanbanBoardTab> createState() => _KanbanBoardTabState();
}

class _KanbanBoardTabState extends ConsumerState<_KanbanBoardTab> {
  int _phoneSelectedColumnIndex = 0;
  static const _columnKeys = ['TODO', 'IN_PROGRESS', 'CODE_REVIEW', 'DONE'];
  static const _columnLabels = ['To Do', 'In Progress', 'In Review', 'Done'];

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(projectBoardProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return boardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectBoardProvider(widget.projectId)),
      ),
      data: (board) {
        final columnsMap = <String, List<dynamic>>{
          'TODO': board.columns['TODO'] ?? [],
          'IN_PROGRESS': board.columns['IN_PROGRESS'] ?? [],
          'CODE_REVIEW': board.columns['CODE_REVIEW'] ?? [],
          'DONE': board.columns['DONE'] ?? [],
        };

        return LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;

            if (isPhone) {
              // Phone Layout: Segmented Column Switcher on top
              final activeColKey = _columnKeys[_phoneSelectedColumnIndex];
              final activeItems = columnsMap[activeColKey] ?? [];

              return Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: colorScheme.surfaceContainerHighest.withAlpha(30),
                    child: Row(
                      children: _columnKeys.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final key = entry.value;
                        final count = (columnsMap[key] ?? []).length;
                        final selected = _phoneSelectedColumnIndex == idx;

                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              setState(() => _phoneSelectedColumnIndex = idx);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    selected ? primaryRed : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_columnLabels[idx]} ($count)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activeItems.length,
                      itemBuilder: (context, index) {
                        final item = activeItems[index];
                        return _buildKanbanCard(
                            context, ref, item, colorScheme, primaryRed);
                      },
                    ),
                  ),
                ],
              );
            }

            // Desktop / Tablet Layout: Horizontally Scrollable 280px Columns
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _columnKeys.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final colKey = entry.value;
                  final items = columnsMap[colKey] ?? [];

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: primaryRed, width: 3),
                              bottom: BorderSide(
                                  color:
                                      colorScheme.outlineVariant.withAlpha(30)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _columnLabels[idx],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  '${items.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Column Task List
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Text(
                                    'No tasks',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant
                                          .withAlpha(120),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: items.length,
                                  itemBuilder: (context, itemIdx) {
                                    final item = items[itemIdx];
                                    return _buildKanbanCard(context, ref, item,
                                        colorScheme, primaryRed);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKanbanCard(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    ColorScheme colorScheme,
    Color primaryRed,
  ) {
    final title = item.title ?? item.name ?? 'Untitled Task';
    final priority = item.priority ?? 'MEDIUM';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: priority.toUpperCase() == 'CRITICAL' ||
                          priority.toUpperCase() == 'HIGH'
                      ? primaryRed
                      : colorScheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. BACKLOG TAB (FEATURES & BUGS)
// ─────────────────────────────────────────────────────────────────────────────
class _BacklogTab extends ConsumerStatefulWidget {
  final String projectId;
  const _BacklogTab({required this.projectId});

  @override
  ConsumerState<_BacklogTab> createState() => _BacklogTabState();
}

class _BacklogTabState extends ConsumerState<_BacklogTab> {
  int _selectedToggleIndex = 0; // 0 = Features, 1 = Bugs

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(projectFeaturesProvider(widget.projectId));
    final bugsAsync = ref.watch(projectBugsProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Segmented Toggle (Features / Bugs)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(40),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    setState(() => _selectedToggleIndex = 0);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedToggleIndex == 0
                          ? primaryRed
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Features',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _selectedToggleIndex == 0
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    setState(() => _selectedToggleIndex = 1);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedToggleIndex == 1
                          ? primaryRed
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Bugs',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _selectedToggleIndex == 1
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapLg,

        if (_selectedToggleIndex == 0)
          featuresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () =>
                  ref.invalidate(projectFeaturesProvider(widget.projectId)),
            ),
            data: (features) {
              if (features.isEmpty) {
                return Text(
                  'No features in backlog.',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withAlpha(140)),
                );
              }
              return Column(
                children: features.map((f) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_outline_rounded,
                            size: 18, color: primaryRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          )
        else
          bugsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () =>
                  ref.invalidate(projectBugsProvider(widget.projectId)),
            ),
            data: (bugs) {
              if (bugs.isEmpty) {
                return Text(
                  'No bugs reported.',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withAlpha(140)),
                );
              }
              return Column(
                children: bugs.map((b) {
                  final isCritical = b.severity.toUpperCase() == 'CRITICAL' ||
                      b.severity.toUpperCase() == 'MAJOR';
                  final bugColor =
                      isCritical ? semantics.danger : semantics.warning;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bug_report_outlined,
                            size: 18, color: bugColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                'Severity: ${b.severity}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: bugColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. COMMITS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _GitHubCommitsTab extends ConsumerWidget {
  final String projectId;
  final String? repoUrl;

  const _GitHubCommitsTab({
    required this.projectId,
    required this.repoUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitsAsync = ref.watch(projectCommitsProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;

    if (repoUrl == null || repoUrl!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code_rounded,
                  size: 40, color: colorScheme.onSurfaceVariant.withAlpha(120)),
              AppSpacing.verticalGapSm,
              Text(
                'No repository linked',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Link a GitHub repository to track commit history and webhook events.',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return commitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectCommitsProvider(projectId)),
      ),
      data: (commits) {
        if (commits.isEmpty) {
          return Center(
            child: Text(
              'No commit activity recorded yet.',
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withAlpha(140)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: commits.length,
          itemBuilder: (context, index) {
            final c = commits[index];
            final shortSha = c.sha.length >= 7 ? c.sha.substring(0, 7) : c.sha;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      shortSha,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${c.authorName} • ${c.timestamp.split('T')[0]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. METRICS TAB (CHARTS)
// ─────────────────────────────────────────────────────────────────────────────
class _MetricsTab extends ConsumerWidget {
  final String projectId;
  const _MetricsTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(projectAnalyticsProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectAnalyticsProvider(projectId)),
      ),
      data: (analytics) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Stat Tiles Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${analytics.totalFocusHours}h',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'FOCUS HOURS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${analytics.totalCommits}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryRed,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'TOTAL COMMITS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalGapLg,

            // Velocity Chart Card (RepaintBoundary wrapped)
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engineering Velocity',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryRed),
                    ),
                    AppSpacing.verticalGapMd,
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 1, barRods: [
                              BarChartRodData(toY: 8, color: primaryRed)
                            ]),
                            BarChartGroupData(x: 2, barRods: [
                              BarChartRodData(toY: 14, color: primaryRed)
                            ]),
                            BarChartGroupData(x: 3, barRods: [
                              BarChartRodData(toY: 10, color: primaryRed)
                            ]),
                            BarChartGroupData(x: 4, barRods: [
                              BarChartRodData(toY: 18, color: primaryRed)
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
