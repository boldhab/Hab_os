import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import 'controllers/projects_controller.dart';
import 'models/project_models.dart';
import 'widgets/project_time_by_stack_card.dart';
import 'widgets/project_card.dart';
import 'widgets/project_form_dialog.dart';
import 'project_detail_screen.dart';

export 'controllers/projects_controller.dart';
export 'models/project_models.dart';

typedef ProjectItemModel = ProjectOverviewModel;
final projectsProvider = projectsListProvider;

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter =
      'ALL'; // 'ALL', 'ACTIVE', 'NEEDS_ATTENTION', 'COMPLETED'
  String? _selectedProjectId;

  static const _filters = [
    {'id': 'ALL', 'label': 'All'},
    {'id': 'ACTIVE', 'label': 'Active'},
    {'id': 'NEEDS_ATTENTION', 'label': 'Needs Attention'},
    {'id': 'COMPLETED', 'label': 'Completed'},
  ];

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsListProvider);
    final techInsightsAsync = ref.watch(techStackInsightsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        final mainListContent = Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Filter projects or tech stack...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withAlpha(140)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projects',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      projectsAsync.when(
                        data: (projects) {
                          final activeCount = projects
                              .where(
                                  (p) => p.status.toUpperCase() != 'COMPLETED')
                              .length;
                          final atRiskCount = projects
                              .where((p) =>
                                  p.healthStatus.toUpperCase() == 'AT_RISK' ||
                                  p.healthStatus.toUpperCase() ==
                                      'NEEDS_ATTENTION')
                              .length;

                          return Text(
                            '$activeCount active · $atRiskCount need attention',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(180),
                            ),
                          );
                        },
                        loading: () => Text(
                          'Developer Hub',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchQuery = '';
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: colorScheme.onSurfaceVariant),
                tooltip: 'Refresh',
                onPressed: () {
                  AppHaptics.light();
                  ref.invalidate(projectsListProvider);
                  ref.invalidate(techStackInsightsProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Underline Segmented Filter Controls
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(40),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final f = _filters[index];
                    final selected = _selectedFilter == f['id'];

                    return InkWell(
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _selectedFilter = f['id']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: selected ? primaryRed : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          f['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected
                                ? primaryRed
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main Projects Body
              Expanded(
                child: projectsAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        height: 110,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              colorScheme.surfaceContainerHighest.withAlpha(40),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  error: (err, _) => AppErrorState(
                    message: err.toString(),
                    onRetry: () {
                      ref.invalidate(projectsListProvider);
                      ref.invalidate(techStackInsightsProvider);
                    },
                  ),
                  data: (projects) {
                    // Filter projects by status & search query
                    var filtered = projects.where((p) {
                      if (_selectedFilter == 'ACTIVE') {
                        return p.status.toUpperCase() != 'COMPLETED';
                      } else if (_selectedFilter == 'NEEDS_ATTENTION') {
                        return p.healthStatus.toUpperCase() ==
                                'NEEDS_ATTENTION' ||
                            p.healthStatus.toUpperCase() == 'AT_RISK';
                      } else if (_selectedFilter == 'COMPLETED') {
                        return p.status.toUpperCase() == 'COMPLETED';
                      }
                      return true;
                    }).toList();

                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((p) {
                        final titleMatch =
                            p.title.toLowerCase().contains(_searchQuery);
                        final techMatch = p.technologies
                            .any((t) => t.toLowerCase().contains(_searchQuery));
                        return titleMatch || techMatch;
                      }).toList();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(projectsListProvider);
                        ref.invalidate(techStackInsightsProvider);
                      },
                      color: primaryRed,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        children: [
                          _buildPortfolioOverview(context, projects),
                          const SizedBox(height: 16),

                          // 1. Time By Tech Stack Card
                          techInsightsAsync.when(
                            data: (insights) =>
                                ProjectTimeByStackCard(insights: insights),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                          // 2. Project List Header
                          Text(
                            'ENGINEERING PROJECTS (${filtered.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(160),
                            ),
                          ),
                          AppSpacing.verticalGapSm,

                          // 3. Projects List or Empty State
                          if (filtered.isEmpty)
                            AppEmptyState(
                              icon: Icons.folder_outlined,
                              title: 'No engineering projects found',
                              description:
                                  'Tap "+ New Project" to track your code, tasks, and commits.',
                              actionLabel: 'New Project',
                              onAction: () => _openCreateProject(context),
                            )
                          else
                            ...filtered.map((project) {
                              return ProjectCard(
                                project: project,
                                onTap: () {
                                  if (isWide) {
                                    setState(
                                        () => _selectedProjectId = project.id);
                                  } else {
                                    context
                                        .push('/more/projects/${project.id}');
                                  }
                                },
                                onDelete: () {
                                  ref
                                      .read(projectsControllerProvider)
                                      .deleteProject(project.id);
                                },
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateProject(context),
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Project',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              SizedBox(width: 420, child: mainListContent),
              VerticalDivider(
                  width: 1, color: colorScheme.outlineVariant.withAlpha(40)),
              Expanded(
                child: _selectedProjectId == null
                    ? Scaffold(
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        body: const Center(
                          child: Text(
                            'Select a project to view Developer Hub details',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ProjectDetailScreen(projectId: _selectedProjectId!),
              ),
            ],
          );
        }

        return mainListContent;
      },
    );
  }

  Widget _buildPortfolioOverview(
      BuildContext context, List<ProjectOverviewModel> projects) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = projects
        .where((project) => project.status.toUpperCase() != 'COMPLETED')
        .toList();
    final needsAttention = projects.where((project) {
      final health = project.healthStatus.toUpperCase();
      return health == 'AT_RISK' || health == 'NEEDS_ATTENTION';
    }).length;
    final averageProgress = projects.isEmpty
        ? 0.0
        : projects.map((project) => project.progress).reduce((a, b) => a + b) /
            projects.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(20),
            colorScheme.primaryContainer.withAlpha(105),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Project portfolio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.folder_special_outlined,
                  size: 20, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            projects.isEmpty
                ? 'Your engineering workspace is ready for its first project.'
                : '${active.length} active projects in motion',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (averageProgress / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: colorScheme.outlineVariant.withAlpha(70),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _portfolioMetric(
                context,
                value: '${averageProgress.toInt()}%',
                label: 'average progress',
              ),
              _portfolioMetric(
                context,
                value: '${projects.length}',
                label: 'total projects',
              ),
              _portfolioMetric(
                context,
                value: '$needsAttention',
                label: 'need attention',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _portfolioMetric(BuildContext context,
      {required String value, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _openCreateProject(BuildContext context) {
    ProjectFormDialog.show(
      context,
      onSubmit: ({
        required title,
        description,
        required status,
        repoUrl,
        required technologies,
        color = '#10B981',
      }) async {
        await ref.read(projectsControllerProvider).createProject(
              title: title,
              description: description,
              status: status,
              repoUrl: repoUrl,
              technologies: technologies,
              color: color,
            );
      },
    );
  }
}
