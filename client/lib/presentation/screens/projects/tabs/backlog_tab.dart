import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../providers/focus_provider.dart';
import '../../../widgets/app_error_state.dart';
import '../controllers/projects_controller.dart';
import '../models/project_models.dart';
import '../dialogs/feature_form_dialog.dart';
import '../dialogs/bug_form_dialog.dart';

enum BacklogSort {
  order('Default'),
  priority('Priority'),
  newest('Newest'),
  alphabetical('A - Z');

  final String label;
  const BacklogSort(this.label);
}

class BacklogTab extends ConsumerStatefulWidget {
  final String projectId;
  const BacklogTab({super.key, required this.projectId});

  @override
  ConsumerState<BacklogTab> createState() => _BacklogTabState();
}

class _BacklogTabState extends ConsumerState<BacklogTab> {
  int _selectedToggle = 0; // 0=Features, 1=Bugs
  String? _selectedMilestone;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  BacklogSort _currentSort = BacklogSort.order;
  Timer? _searchDebounce;

  final _featuresScrollController = ScrollController();
  final _bugsScrollController = ScrollController();

  List<FeatureItemModel>? _extraFeatures;
  int _featurePage = 1;
  bool _hasMoreFeatures = true;
  bool _isLoadingMoreFeatures = false;

  List<BugItemModel>? _extraBugs;
  int _bugPage = 1;
  bool _hasMoreBugs = true;
  bool _isLoadingMoreBugs = false;

  @override
  void initState() {
    super.initState();
    _featuresScrollController.addListener(_onFeaturesScroll);
    _bugsScrollController.addListener(_onBugsScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _featuresScrollController.dispose();
    _bugsScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = val.trim().toLowerCase());
      }
    });
  }

  void _onFeaturesScroll() {
    if (_featuresScrollController.position.pixels >=
        _featuresScrollController.position.maxScrollExtent - 200) {
      _loadMoreFeatures();
    }
  }

  void _onBugsScroll() {
    if (_bugsScrollController.position.pixels >=
        _bugsScrollController.position.maxScrollExtent - 200) {
      _loadMoreBugs();
    }
  }

  Future<void> _loadMoreFeatures() async {
    if (_isLoadingMoreFeatures || !_hasMoreFeatures) return;
    setState(() => _isLoadingMoreFeatures = true);
    try {
      final nextPage = _featurePage + 1;
      final result = await ref
          .read(projectsControllerProvider)
          .getFeaturesPage(widget.projectId, page: nextPage, limit: 20);
      if (mounted) {
        setState(() {
          _featurePage = nextPage;
          _hasMoreFeatures = result.hasMore;
          _extraFeatures = [...(_extraFeatures ?? []), ...result.items];
          _isLoadingMoreFeatures = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreFeatures = false);
    }
  }

  Future<void> _loadMoreBugs() async {
    if (_isLoadingMoreBugs || !_hasMoreBugs) return;
    setState(() => _isLoadingMoreBugs = true);
    try {
      final nextPage = _bugPage + 1;
      final result = await ref
          .read(projectsControllerProvider)
          .getBugsPage(widget.projectId, page: nextPage, limit: 20);
      if (mounted) {
        setState(() {
          _bugPage = nextPage;
          _hasMoreBugs = result.hasMore;
          _extraBugs = [...(_extraBugs ?? []), ...result.items];
          _isLoadingMoreBugs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreBugs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(projectFeaturesProvider(widget.projectId));
    final bugsAsync = ref.watch(projectBugsProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return Column(
      children: [
        // Toggle + Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleBtn('Features', 0, colorScheme, primaryRed),
                      _buildToggleBtn('Bugs', 1, colorScheme, primaryRed),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () {
                  if (_selectedToggle == 0) {
                    _showAddFeature(context);
                  } else {
                    _showAddBug(context);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(_selectedToggle == 0 ? 'Feature' : 'Bug'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryRed,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search & Sort bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _selectedToggle == 0
                          ? 'Search features...'
                          : 'Search bugs...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withAlpha(140),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withAlpha(35),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(30),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<BacklogSort>(
                tooltip: 'Sort By',
                initialValue: _currentSort,
                onSelected: (sort) => setState(() => _currentSort = sort),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: _currentSort != BacklogSort.order
                            ? primaryRed
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentSort.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentSort != BacklogSort.order
                              ? primaryRed
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: BacklogSort.order,
                    child: Text('Default (Board Order)'),
                  ),
                  const PopupMenuItem(
                    value: BacklogSort.priority,
                    child: Text('Priority (Highest First)'),
                  ),
                  const PopupMenuItem(
                    value: BacklogSort.newest,
                    child: Text('Newest'),
                  ),
                  const PopupMenuItem(
                    value: BacklogSort.alphabetical,
                    child: Text('Alphabetical (A - Z)'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedToggle == 0
              ? featuresAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(
                          projectFeaturesProvider(widget.projectId))),
                  data: (initialItems) {
                    final allItems = [
                      ...initialItems,
                      ...?_extraFeatures,
                    ];

                    if (allItems.isEmpty) {
                      return _EmptyBacklogState(
                        icon: Icons.star_outline_rounded,
                        title: 'No features yet',
                        description:
                            'Add features to track what needs to be built.',
                        actionLabel: 'Add Feature',
                        onAction: () => _showAddFeature(context),
                      );
                    }

                    final milestones = allItems
                        .map((f) => f.milestone)
                        .where((m) => m != null && m.isNotEmpty)
                        .toSet()
                        .cast<String>()
                        .toList()
                      ..sort();

                    var displayedItems = _selectedMilestone == null
                        ? allItems
                        : allItems
                            .where((f) => f.milestone == _selectedMilestone)
                            .toList();

                    if (_searchQuery.isNotEmpty) {
                      displayedItems = displayedItems.where((f) {
                        final name = f.name.toLowerCase();
                        final desc = f.description?.toLowerCase() ?? '';
                        return name.contains(_searchQuery) ||
                            desc.contains(_searchQuery);
                      }).toList();
                    }

                    const priorityWeight = {
                      'CRITICAL': 4,
                      'HIGH': 3,
                      'MEDIUM': 2,
                      'LOW': 1,
                    };

                    switch (_currentSort) {
                      case BacklogSort.priority:
                        displayedItems.sort((a, b) =>
                            (priorityWeight[b.priority.toUpperCase()] ?? 0)
                                .compareTo(
                                    priorityWeight[a.priority.toUpperCase()] ?? 0));
                        break;
                      case BacklogSort.alphabetical:
                        displayedItems.sort(
                            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                        break;
                      case BacklogSort.newest:
                        displayedItems.sort((a, b) => b.order.compareTo(a.order));
                        break;
                      case BacklogSort.order:
                        displayedItems.sort((a, b) => a.order.compareTo(b.order));
                        break;
                    }

                    if (displayedItems.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No features matching "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant.withAlpha(160),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (milestones.isNotEmpty)
                          _buildMilestoneFilterBar(
                              milestones, colorScheme, primaryRed),
                        Expanded(
                          child: RefreshIndicator(
                            color: primaryRed,
                            onRefresh: () async {
                              setState(() {
                                _featurePage = 1;
                                _extraFeatures = null;
                                _hasMoreFeatures = true;
                              });
                              ref.invalidate(
                                  projectFeaturesProvider(widget.projectId));
                            },
                            child: ListView.builder(
                              controller: _featuresScrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: displayedItems.length +
                                  (_isLoadingMoreFeatures ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i >= displayedItems.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                return _buildFeatureCard(
                                    context,
                                    displayedItems[i],
                                    colorScheme,
                                    primaryRed,
                                    semantics);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : bugsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(
                          projectBugsProvider(widget.projectId))),
                  data: (initialItems) {
                    final allItems = [
                      ...initialItems,
                      ...?_extraBugs,
                    ];

                    if (allItems.isEmpty) {
                      return _EmptyBacklogState(
                        icon: Icons.bug_report_outlined,
                        title: 'No bugs reported',
                        description:
                            'Report bugs to track issues and resolve them.',
                        actionLabel: 'Report Bug',
                        onAction: () => _showAddBug(context),
                      );
                    }

                    final milestones = allItems
                        .map((b) => b.milestone)
                        .where((m) => m != null && m.isNotEmpty)
                        .toSet()
                        .cast<String>()
                        .toList()
                      ..sort();

                    var displayedItems = _selectedMilestone == null
                        ? allItems
                        : allItems
                            .where((b) => b.milestone == _selectedMilestone)
                            .toList();

                    if (_searchQuery.isNotEmpty) {
                      displayedItems = displayedItems.where((b) {
                        final title = b.title.toLowerCase();
                        final desc = b.description.toLowerCase();
                        return title.contains(_searchQuery) ||
                            desc.contains(_searchQuery);
                      }).toList();
                    }

                    const priorityWeight = {
                      'CRITICAL': 4,
                      'HIGH': 3,
                      'MEDIUM': 2,
                      'LOW': 1,
                    };

                    switch (_currentSort) {
                      case BacklogSort.priority:
                        displayedItems.sort((a, b) =>
                            (priorityWeight[b.priority.toUpperCase()] ?? 0)
                                .compareTo(
                                    priorityWeight[a.priority.toUpperCase()] ?? 0));
                        break;
                      case BacklogSort.alphabetical:
                        displayedItems.sort(
                            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                        break;
                      case BacklogSort.newest:
                        displayedItems.sort((a, b) => b.order.compareTo(a.order));
                        break;
                      case BacklogSort.order:
                        displayedItems.sort((a, b) => a.order.compareTo(b.order));
                        break;
                    }

                    if (displayedItems.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No bugs matching "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant.withAlpha(160),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (milestones.isNotEmpty)
                          _buildMilestoneFilterBar(
                              milestones, colorScheme, primaryRed),
                        Expanded(
                          child: RefreshIndicator(
                            color: primaryRed,
                            onRefresh: () async {
                              setState(() {
                                _bugPage = 1;
                                _extraBugs = null;
                                _hasMoreBugs = true;
                              });
                              ref.invalidate(
                                  projectBugsProvider(widget.projectId));
                            },
                            child: ListView.builder(
                              controller: _bugsScrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: displayedItems.length +
                                  (_isLoadingMoreBugs ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i >= displayedItems.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                return _buildBugCard(
                                    context,
                                    displayedItems[i],
                                    colorScheme,
                                    primaryRed,
                                    semantics);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMilestoneFilterBar(
    List<String> milestones,
    ColorScheme colorScheme,
    Color primaryRed,
  ) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('All'),
              selected: _selectedMilestone == null,
              onSelected: (_) => setState(() => _selectedMilestone = null),
              selectedColor: primaryRed.withAlpha(30),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: _selectedMilestone == null
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _selectedMilestone == null
                    ? primaryRed
                    : colorScheme.onSurface,
              ),
              side: BorderSide(
                color: _selectedMilestone == null
                    ? primaryRed
                    : colorScheme.outlineVariant.withAlpha(50),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
          ...milestones.map((m) {
            final isSelected = _selectedMilestone == m;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color:
                      isSelected ? primaryRed : colorScheme.onSurfaceVariant,
                ),
                label: Text(m),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedMilestone = isSelected ? null : m;
                }),
                selectedColor: primaryRed.withAlpha(30),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryRed : colorScheme.onSurface,
                ),
                side: BorderSide(
                  color: isSelected
                      ? primaryRed
                      : colorScheme.outlineVariant.withAlpha(50),
                ),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
      String label, int idx, ColorScheme cs, Color primary) {
    final selected = _selectedToggle == idx;
    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          setState(() {
            _selectedToggle = idx;
            _selectedMilestone = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    FeatureItemModel f,
    ColorScheme cs,
    Color primary,
    AppSemanticColors semantics,
  ) {
    final isDone = f.status == 'COMPLETED';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withAlpha(30)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final newStatus = isDone ? 'TODO' : 'COMPLETED';
              try {
                await ref.read(projectsControllerProvider).updateFeature(
                      projectId: widget.projectId,
                      featureId: f.id,
                      data: {'status': newStatus},
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: semantics.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? semantics.success : Colors.transparent,
                border: Border.all(
                    color: isDone ? semantics.success : cs.outlineVariant,
                    width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? cs.onSurfaceVariant.withAlpha(140)
                        : cs.onSurface,
                  ),
                ),
                if (f.description != null && f.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(f.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withAlpha(140))),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  _statusChip(f.status, cs, semantics),
                  const SizedBox(width: 6),
                  _priorityDot(f.priority, primary, cs),
                  if (f.milestone != null && f.milestone!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 10, color: cs.primary),
                          const SizedBox(width: 3),
                          Text(f.milestone!,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary)),
                        ],
                      ),
                    ),
                  ],
                  if (f.assignedTaskId != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: semantics.info.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.task_alt_rounded,
                              size: 10, color: semantics.info),
                          const SizedBox(width: 3),
                          Text('Task Linked',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: semantics.info)),
                        ],
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              f.status == 'IN_PROGRESS'
                  ? Icons.timer_rounded
                  : Icons.play_arrow_rounded,
              size: 20,
              color: f.status == 'IN_PROGRESS' ? primary : semantics.success,
            ),
            tooltip: 'Start Working (Task + Pomodoro)',
            onPressed: () => _startWorkingOnFeature(context, f),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                size: 18, color: cs.onSurfaceVariant),
            onSelected: (val) {
              if (val == 'start_working') _startWorkingOnFeature(context, f);
              if (val == 'edit') _showEditFeature(context, f);
              if (val == 'delete') _deleteFeature(context, f, semantics);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'start_working',
                child: Row(children: [
                  Icon(Icons.play_circle_outline_rounded,
                      size: 18, color: semantics.success),
                  const SizedBox(width: 8),
                  const Text('Start Working (Focus)'),
                ]),
              ),
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: semantics.danger),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: semantics.danger)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBugCard(
    BuildContext context,
    BugItemModel b,
    ColorScheme cs,
    Color primary,
    AppSemanticColors semantics,
  ) {
    final isResolved = b.status == 'RESOLVED' || b.status == 'CLOSED';
    final isCritical = b.severity.toUpperCase() == 'CRITICAL';
    final isMajor = b.severity.toUpperCase() == 'MAJOR';
    final bugColor = isCritical
        ? semantics.danger
        : isMajor
            ? semantics.warning
            : cs.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withAlpha(30)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final newStatus = isResolved ? 'OPEN' : 'RESOLVED';
              try {
                await ref.read(projectsControllerProvider).updateBug(
                      projectId: widget.projectId,
                      bugId: b.id,
                      data: {'status': newStatus},
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: semantics.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isResolved ? semantics.success : Colors.transparent,
                border: Border.all(
                    color: isResolved ? semantics.success : bugColor,
                    width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isResolved
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : Icon(Icons.bug_report_outlined,
                      size: 13, color: bugColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    decoration:
                        isResolved ? TextDecoration.lineThrough : null,
                    color: isResolved
                        ? cs.onSurfaceVariant.withAlpha(140)
                        : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  _statusChip(b.status, cs, semantics),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: bugColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(b.severity,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: bugColor)),
                  ),
                  if (b.milestone != null && b.milestone!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 10, color: cs.primary),
                          const SizedBox(width: 3),
                          Text(b.milestone!,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary)),
                        ],
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              b.status == 'IN_PROGRESS'
                  ? Icons.timer_rounded
                  : Icons.play_arrow_rounded,
              size: 20,
              color: b.status == 'IN_PROGRESS' ? primary : semantics.success,
            ),
            tooltip: 'Start Working (Task + Pomodoro)',
            onPressed: () => _startWorkingOnBug(context, b),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                size: 18, color: cs.onSurfaceVariant),
            onSelected: (val) {
              if (val == 'start_working') _startWorkingOnBug(context, b);
              if (val == 'edit') _showEditBug(context, b);
              if (val == 'delete') _deleteBug(context, b, semantics);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'start_working',
                child: Row(children: [
                  Icon(Icons.play_circle_outline_rounded,
                      size: 18, color: semantics.success),
                  const SizedBox(width: 8),
                  const Text('Start Working (Focus)'),
                ]),
              ),
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: semantics.danger),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: semantics.danger)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
      String status, ColorScheme cs, AppSemanticColors semantics) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'RESOLVED':
        color = semantics.success;
        break;
      case 'IN_PROGRESS':
        color = semantics.warning;
        break;
      case 'BLOCKED':
        color = semantics.danger;
        break;
      default:
        color = cs.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _priorityDot(String priority, Color primary, ColorScheme cs) {
    final isHigh = priority.toUpperCase() == 'HIGH' ||
        priority.toUpperCase() == 'CRITICAL';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: isHigh ? primary : cs.outline,
              shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(priority,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withAlpha(140))),
    ]);
  }

  void _showAddFeature(BuildContext context) {
    FeatureFormDialog.show(
      context,
      onSubmit: (name, description, priority, status) async {
        await ref.read(projectsControllerProvider).createFeature(
              projectId: widget.projectId,
              name: name,
              description: description,
              priority: priority,
              status: status,
            );
      },
    );
  }

  void _showEditFeature(BuildContext context, FeatureItemModel f) {
    FeatureFormDialog.show(
      context,
      initialName: f.name,
      initialDescription: f.description,
      initialMilestone: f.milestone,
      initialPriority: f.priority,
      initialStatus: f.status,
      onSubmit: (name, description, priority, status) async {
        await ref.read(projectsControllerProvider).updateFeature(
              projectId: widget.projectId,
              featureId: f.id,
              data: {
                'name': name,
                'description': description,
                'priority': priority,
                'status': status,
              },
            );
      },
    );
  }

  void _deleteFeature(
      BuildContext context, FeatureItemModel f, AppSemanticColors semantics) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feature?'),
        content: Text('Delete "${f.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(projectsControllerProvider)
                  .deleteFeature(widget.projectId, f.id);
            },
            style: FilledButton.styleFrom(backgroundColor: semantics.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddBug(BuildContext context) {
    BugFormDialog.show(
      context,
      onSubmit: (title, description, steps, severity, priority, status) async {
        await ref.read(projectsControllerProvider).createBug(
              projectId: widget.projectId,
              title: title,
              description: description,
              stepsToReproduce: steps,
              severity: severity,
              priority: priority,
              status: status,
            );
      },
    );
  }

  void _showEditBug(BuildContext context, BugItemModel b) {
    BugFormDialog.show(
      context,
      initialTitle: b.title,
      initialDescription: b.description,
      initialMilestone: b.milestone,
      initialSteps: b.stepsToReproduce,
      initialSeverity: b.severity,
      initialPriority: b.priority,
      initialStatus: b.status,
      onSubmit: (title, description, steps, severity, priority, status) async {
        await ref.read(projectsControllerProvider).updateBug(
              projectId: widget.projectId,
              bugId: b.id,
              data: {
                'title': title,
                'description': description,
                if (steps != null) 'stepsToReproduce': steps,
                'severity': severity,
                'priority': priority,
                'status': status,
              },
            );
      },
    );
  }

  void _deleteBug(
      BuildContext context, BugItemModel b, AppSemanticColors semantics) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bug?'),
        content: Text('Delete "${b.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(projectsControllerProvider)
                  .deleteBug(widget.projectId, b.id);
            },
            style: FilledButton.styleFrom(backgroundColor: semantics.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkingOnFeature(
      BuildContext context, FeatureItemModel f) async {
    final semantics = AppSemanticColors.of(context);
    try {
      String taskId = f.assignedTaskId ?? '';

      // If no task is linked yet, create a task in the project
      if (taskId.isEmpty) {
        final task = await ref.read(taskRepositoryProvider).createTask({
          'title': '[Feature] ${f.name}',
          'description': f.description ?? 'Feature implementation',
          'projectId': widget.projectId,
          'priority': f.priority,
          'status': 'IN_PROGRESS',
        });
        taskId = task.id;

        // Link task to feature and update feature status to IN_PROGRESS
        await ref.read(projectsControllerProvider).updateFeature(
          projectId: widget.projectId,
          featureId: f.id,
          data: {
            'assignedTaskId': taskId,
            'status': 'IN_PROGRESS',
          },
        );
      } else if (f.status == 'TODO') {
        await ref.read(projectsControllerProvider).updateFeature(
          projectId: widget.projectId,
          featureId: f.id,
          data: {'status': 'IN_PROGRESS'},
        );
      }

      // Start focus timer on this task
      await ref.read(focusProvider.notifier).startTimer(
        taskId: taskId,
        notes: 'Feature: ${f.name}',
        category: 'CODING',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.timer_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Focus timer started for "${f.name}"'),
                ),
              ],
            ),
            backgroundColor: semantics.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start focus session: $e'),
            backgroundColor: semantics.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startWorkingOnBug(BuildContext context, BugItemModel b) async {
    final semantics = AppSemanticColors.of(context);
    try {
      final task = await ref.read(taskRepositoryProvider).createTask({
        'title': '[Bug] ${b.title}',
        'description': 'Severity: ${b.severity}\n${b.description}',
        'projectId': widget.projectId,
        'priority': b.priority,
        'status': 'IN_PROGRESS',
      });

      if (b.status == 'OPEN') {
        await ref.read(projectsControllerProvider).updateBug(
          projectId: widget.projectId,
          bugId: b.id,
          data: {'status': 'IN_PROGRESS'},
        );
      }

      await ref.read(focusProvider.notifier).startTimer(
        taskId: task.id,
        notes: 'Bug Fix: ${b.title}',
        category: 'CODING',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.timer_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Focus timer started for bug "${b.title}"'),
                ),
              ],
            ),
            backgroundColor: semantics.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start focus session: $e'),
            backgroundColor: semantics.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _EmptyBacklogState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  const _EmptyBacklogState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: cs.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant.withAlpha(160))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ),
    );
  }
}
