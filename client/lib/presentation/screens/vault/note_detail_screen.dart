import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/app_error_state.dart';
import 'widgets/code_snippet_card.dart';
import 'widgets/markdown_content_view.dart';

/// Screen displaying the full contents of a Knowledge Vault note (UC-121, UC-124, UC-129)
class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note from your Knowledge Vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(vaultProvider.notifier).deleteNote(widget.noteId);
              if (mounted) {
                if (success) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted from vault')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete note')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLinkNoteModal() {
    final vaultState = ref.read(vaultProvider);
    final availableNotes = vaultState.notes.where((n) => n.id != widget.noteId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.sheetRadius,
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Link Another Note',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: availableNotes.isEmpty
                      ? const Center(child: Text('No other notes available to link.'))
                      : ListView.separated(
                          controller: controller,
                          itemCount: availableNotes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final target = availableNotes[index];
                            return ListTile(
                              title: Text(target.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: target.tags.isNotEmpty ? Text('#${target.tags.join(" #")}') : null,
                              trailing: const Icon(Icons.add_link_rounded, color: Colors.blue),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final ok = await ref.read(vaultProvider.notifier).linkNotes(widget.noteId, target.id);
                                if (mounted) {
                                  ref.invalidate(singleVaultNoteProvider(widget.noteId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(ok ? 'Linked to "${target.title}"' : 'Failed to link notes')),
                                  );
                                }
                              },
                            );
                          },
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final noteAsync = ref.watch(singleVaultNoteProvider(widget.noteId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link_rounded),
            tooltip: 'Link Note',
            onPressed: _showLinkNoteModal,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Note',
            onPressed: () => context.push('/more/vault/${widget.noteId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Note',
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: 'Failed to load note: $err',
          onRetry: () => ref.invalidate(singleVaultNoteProvider(widget.noteId)),
        ),
        data: (note) {
          if (note == null) {
            return AppErrorState(
              message: 'Note not found. This note may have been deleted or moved.',
              onRetry: () => ref.invalidate(singleVaultNoteProvider(widget.noteId)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
            children: [
              // 1. Meta Badges Row
              Row(
                children: [
                  if (note.isMistakeSolution) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withAlpha(24),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.amber.shade700.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_circle_outlined, size: 13, color: Colors.amber.shade700),
                          const SizedBox(width: 5),
                          Text(
                            'MISTAKE & SOLUTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (note.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        note.category!.name,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Updated ${note.updatedAt.month}/${note.updatedAt.day}/${note.updatedAt.year}',
                    style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              AppSpacing.verticalGapSm,

              // 2. Title
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.verticalGapSm,

              // 3. Tags Row
              if (note.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in note.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(70),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.verticalGapMd,
              ],

              const Divider(),
              AppSpacing.verticalGapSm,

              // 4. Markdown Content Body
              MarkdownContentView(
                content: note.content,
                onWikiLinkClicked: (targetTitle) {
                  final vaultState = ref.read(vaultProvider);
                  final match = vaultState.notes.firstWhere(
                    (n) => n.title.toLowerCase() == targetTitle.toLowerCase(),
                    orElse: () => note,
                  );
                  if (match.id != note.id) {
                    context.push('/more/vault/${match.id}');
                  }
                },
              ),
              AppSpacing.verticalGapLg,

              // 5. Code Snippets Section (UC-124)
              if (note.codeSnippets.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      'CODE SNIPPETS (${note.codeSnippets.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalGapSm,
                for (final snippet in note.codeSnippets)
                  CodeSnippetCard(snippet: snippet),
                AppSpacing.verticalGapLg,
              ],

              // 6. Linked Notes / Backlinks Section (UC-129, UC-130)
              Row(
                children: [
                  const Icon(Icons.hub_rounded, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'CONNECTED NOTES (${note.linkedNotes.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showLinkNoteModal,
                    icon: const Icon(Icons.add_link_rounded, size: 14),
                    label: const Text('Add Link', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              AppSpacing.verticalGapSm,
              if (note.linkedNotes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(40),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'No notes linked yet. Connect this note to related architecture docs or bug logs.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final link in note.linkedNotes)
                      ActionChip(
                        avatar: Icon(
                          link.direction == 'outgoing' ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                          size: 14,
                          color: Colors.blue,
                        ),
                        label: Text(link.title),
                        onPressed: () => context.push('/more/vault/${link.id}'),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
