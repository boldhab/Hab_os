import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/search_result_model.dart';
import '../../providers/search_provider.dart';

/// Interactive Global Search Command Palette (UC-167 to UC-172)
class GlobalSearchModal extends ConsumerStatefulWidget {
  const GlobalSearchModal({super.key});

  /// Static helper to trigger the command palette from any screen
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlobalSearchModal(),
    );
  }

  @override
  ConsumerState<GlobalSearchModal> createState() => _GlobalSearchModalState();
}

class _GlobalSearchModalState extends ConsumerState<GlobalSearchModal> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  static const _domains = [
    {'id': 'ALL', 'label': 'All'},
    {'id': 'TASKS', 'label': 'Tasks'},
    {'id': 'PROJECTS', 'label': 'Projects'},
    {'id': 'COURSES', 'label': 'Academic'},
    {'id': 'VAULT', 'label': 'Vault'},
    {'id': 'HABITS', 'label': 'Habits'},
    {'id': 'GOALS', 'label': 'Goals'},
    {'id': 'GYM', 'label': 'Gym'},
    {'id': 'FINANCE', 'label': 'Finance'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onResultTapped(SearchResultItem item) {
    // 1. Add query to recents
    if (_controller.text.trim().isNotEmpty) {
      ref.read(globalSearchProvider.notifier).addRecentSearch(_controller.text.trim());
    }

    // 2. Dismiss modal
    Navigator.of(context).pop();

    // 3. Direct client navigation
    context.push(item.clientRoute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final searchState = ref.watch(globalSearchProvider);
    final searchNotifier = ref.read(globalSearchProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.sheetRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Search Bar Input Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 50),
                      borderRadius: AppRadius.input,
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(70)),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: searchNotifier.onQueryChanged,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search tasks, vault notes, courses, projects...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant.withAlpha(150),
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: primary, size: 22),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _controller.clear();
                                  searchNotifier.clearSearch();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // Domain Filter Chips (UC-169)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final d in _domains)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: searchState.selectedDomain == d['id'],
                      label: Text(d['label']!),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: searchState.selectedDomain == d['id']
                            ? primary
                            : colorScheme.onSurface,
                      ),
                      selectedColor: primary.withAlpha(24),
                      backgroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: BorderSide(
                          color: searchState.selectedDomain == d['id']
                              ? primary
                              : colorScheme.outlineVariant.withAlpha(70),
                        ),
                      ),
                      onSelected: (_) => searchNotifier.selectDomain(d['id']!),
                    ),
                  ),
              ],
            ),
          ),

          // Loading Progress Bar
          if (searchState.isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: primary,
            )
          else
            const Divider(height: 1, thickness: 1),

          // Search Content Body
          Expanded(
            child: _buildBody(context, searchState, searchNotifier, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GlobalSearchState state,
    GlobalSearchNotifier notifier,
    ColorScheme colorScheme,
  ) {
    // 1. If Query is Empty: Show Recent Searches (UC-170, UC-171)
    if (state.query.trim().isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.recentSearches.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'RECENT SEARCHES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: notifier.clearRecentSearches,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in state.recentSearches)
                  InputChip(
                    label: Text(term, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _controller.text = term;
                      notifier.onQueryChanged(term);
                    },
                    onDeleted: () => notifier.removeRecentSearch(term),
                    deleteIconColor: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // Quick Category Shortcuts
          Text(
            'EXPLORE BY DOMAIN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _buildDomainShortcut(
                icon: Icons.task_alt_rounded,
                label: 'Tasks',
                color: Colors.blue.shade600,
                onTap: () => notifier.selectDomain('TASKS'),
              ),
              _buildDomainShortcut(
                icon: Icons.menu_book_rounded,
                label: 'Vault Notes',
                color: Colors.indigo.shade600,
                onTap: () => notifier.selectDomain('VAULT'),
              ),
              _buildDomainShortcut(
                icon: Icons.folder_rounded,
                label: 'Projects',
                color: Colors.teal.shade600,
                onTap: () => notifier.selectDomain('PROJECTS'),
              ),
              _buildDomainShortcut(
                icon: Icons.school_rounded,
                label: 'Courses',
                color: Colors.deepPurpleAccent,
                onTap: () => notifier.selectDomain('COURSES'),
              ),
            ],
          ),
        ],
      );
    }

    // 2. If Query has Results
    if (state.results.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: state.results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = state.results[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withAlpha(24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.color.withAlpha(50)),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.subtitle ?? item.domainLabel,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                item.domainLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
              ),
            ),
            onTap: () => _onResultTapped(item),
          );
        },
      );
    }

    // 3. If Query returned 0 results
    if (!state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurfaceVariant.withAlpha(120)),
              const SizedBox(height: 12),
              Text(
                'No matching results found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search query or switching domain filter chips.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDomainShortcut({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(16),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
