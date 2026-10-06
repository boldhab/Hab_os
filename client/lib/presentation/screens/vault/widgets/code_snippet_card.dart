import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/vault_note_model.dart';

/// Renders a syntax-styled code snippet card with copy-to-clipboard action (UC-124)
class CodeSnippetCard extends StatelessWidget {
  final CodeSnippet snippet;
  final VoidCallback? onDelete;

  const CodeSnippetCard({
    super.key,
    required this.snippet,
    this.onDelete,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: snippet.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 8),
            Text('Copied ${snippet.language.toUpperCase()} snippet to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getLanguageAccentColor(String language) {
    switch (language.toLowerCase()) {
      case 'typescript':
      case 'ts':
        return Colors.blue.shade400;
      case 'javascript':
      case 'js':
        return Colors.amber.shade400;
      case 'python':
      case 'py':
        return Colors.teal.shade400;
      case 'dart':
        return Colors.cyan.shade400;
      case 'sql':
      case 'postgres':
        return Colors.indigo.shade300;
      case 'json':
        return Colors.orange.shade400;
      case 'bash':
      case 'sh':
        return Colors.green.shade400;
      case 'html':
      case 'css':
        return Colors.pink.shade400;
      default:
        return Colors.purple.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langColor = _getLanguageAccentColor(snippet.language);
    final lines = snippet.code.split('\n');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF181B20), // Dark terminal canvas
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFF2D3139)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E2229),
            child: Row(
              children: [
                // Terminal window dots
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 12),
                // Language Tag Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: langColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: langColor.withAlpha(60)),
                  ),
                  child: Text(
                    snippet.language.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: langColor,
                    ),
                  ),
                ),
                if (snippet.description != null && snippet.description!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      snippet.description!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9AA0A6),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                // Copy Button
                IconButton(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF9AA0A6)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy Code',
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove Snippet',
                  ),
                ],
              ],
            ),
          ),
          // Code Area with Line Numbers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 1; i <= lines.length; i++)
                        Text(
                          '$i',
                          style: GoogleFonts.firaCode(
                            fontSize: 12,
                            height: 1.45,
                            color: const Color(0xFF4E5562),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Vertical separator
                  Container(
                    width: 1,
                    height: (lines.length * 17.4),
                    color: const Color(0xFF282C34),
                  ),
                  const SizedBox(width: 12),
                  // Code content
                  SelectableText(
                    snippet.code,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      height: 1.45,
                      color: const Color(0xFFE6EDF3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
