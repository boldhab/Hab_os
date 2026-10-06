import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/app_empty_state.dart';
import 'widgets/vault_note_card.dart';

/// Main Knowledge Vault hub screen (UC-120, UC-127, UC-128)
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(vaultProvider.notifier).setSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final vaultState = ref.watch(vaultProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Knowledge Vault',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${vaultState.notes.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Engineering notes, snippets & mistake logs',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Vault',
            onPressed: () => ref.read(vaultProvider.notifier).refresh(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/more/vault/create'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(vaultProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            // 1. Search Bar
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 50),
                borderRadius: AppRadius.input,
                border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search title, content, or code...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            AppSpacing.verticalGapMd,

            // 2. Filter & Tags Carousel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // All filter chip
                  FilterChip(
                    selected: vaultState.selectedTag == null && !vaultState.onlyMistakes,
                    label: const Text('All Notes'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (vaultState.selectedTag == null && !vaultState.onlyMistakes)
                          ? primary
                          : colorScheme.onSurface,
                    ),
                    backgroundColor: colorScheme.surface,
                    selectedColor: primary.withAlpha(24),
                    checkmarkColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: (vaultState.selectedTag == null && !vaultState.onlyMistakes)
                            ? primary
                            : colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    onSelected: (_) {
                      if (vaultState.onlyMistakes) {
                        ref.read(vaultProvider.notifier).toggleOnlyMistakes();
                      }
                      ref.read(vaultProvider.notifier).selectTag(null);
                    },
                  ),
                  const SizedBox(width: 8),

                  // Mistake & Solution Toggle Chip
                  FilterChip(
                    selected: vaultState.onlyMistakes,
                    avatar: Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: vaultState.onlyMistakes ? Colors.amber.shade700 : colorScheme.onSurfaceVariant,
                    ),
                    label: const Text('Mistakes & Fixes'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: vaultState.onlyMistakes ? Colors.amber.shade700 : colorScheme.onSurface,
                    ),
                    backgroundColor: colorScheme.surface,
                    selectedColor: Colors.amber.shade700.withAlpha(24),
                    checkmarkColor: Colors.amber.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: vaultState.onlyMistakes ? Colors.amber.shade700 : colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    onSelected: (_) => ref.read(vaultProvider.notifier).toggleOnlyMistakes(),
                  ),
                  const SizedBox(width: 8),

                  // Dynamic Tags Chips
                  for (final tag in vaultState.allTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: vaultState.selectedTag == tag,
                        label: Text('#$tag'),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vaultState.selectedTag == tag ? primary : colorScheme.onSurface,
                        ),
                        backgroundColor: colorScheme.surface,
                        selectedColor: primary.withAlpha(24),
                        checkmarkColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          side: BorderSide(
                            color: vaultState.selectedTag == tag
                                ? primary
                                : colorScheme.outlineVariant.withAlpha(80),
                          ),
                        ),
                        onSelected: (_) => ref.read(vaultProvider.notifier).selectTag(tag),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.verticalGapMd,

            // 3. Notes Grid / Feed
            if (vaultState.isLoading && vaultState.notes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (vaultState.notes.isEmpty)
              AppEmptyState(
                icon: Icons.menu_book_rounded,
                title: 'No Notes Found',
                description: vaultState.searchQuery.isNotEmpty || vaultState.selectedTag != null
                    ? 'Try clearing your search or filter criteria.'
                    : 'Capture your first engineering architecture, note, or code snippet.',
                actionLabel: 'Create Note',
                onAction: () => context.push('/more/vault/create'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vaultState.notes.length,
                separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
                itemBuilder: (context, index) {
                  final note = vaultState.notes[index];
                  return VaultNoteCard(
                    note: note,
                    onTap: () => context.push('/more/vault/${note.id}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
