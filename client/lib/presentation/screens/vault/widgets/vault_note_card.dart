import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/vault_note_model.dart';
import '../../../widgets/common/app_card.dart';

/// Card widget rendering a Knowledge Vault note preview (UC-120)
class VaultNoteCard extends StatelessWidget {
  final VaultNote note;
  final VoidCallback onTap;

  const VaultNoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  String _cleanPreview(String markdown) {
    return markdown
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
        .replaceAll(RegExp(r'\[\[([^\]]+)\]\]'), r'$1')
        .replaceAll(RegExp(r'>\s*'), '')
        .replaceAll(RegExp(r'-\s*'), '')
        .trim();
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.month}/${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _cleanPreview(note.content);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: AppCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Meta Row
            Row(
              children: [
                if (note.isMistakeSolution) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700.withAlpha(24),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.amber.shade700.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.build_circle_outlined, size: 12, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'MISTAKE & SOLUTION',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ] else if (note.category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      note.category!.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                Text(
                  _formatTimestamp(note.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalGapSm,
            // Title
            Text(
              note.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                preview,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            AppSpacing.verticalGapSm,
            // Bottom Badges: Code snippets, Links, Tags
            Row(
              children: [
                if (note.codeSnippets.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.code_rounded, size: 12, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${note.codeSnippets.length}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (note.linkedNotes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${note.linkedNotes.length}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tag in note.tags.take(3))
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
