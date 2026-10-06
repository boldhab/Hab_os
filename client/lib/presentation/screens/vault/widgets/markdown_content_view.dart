import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/vault_note_model.dart';
import 'code_snippet_card.dart';

/// Lightweight, native Flutter Markdown & Wiki-Link renderer
class MarkdownContentView extends StatelessWidget {
  final String content;
  final ValueChanged<String>? onWikiLinkClicked;

  const MarkdownContentView({
    super.key,
    required this.content,
    this.onWikiLinkClicked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (content.trim().isEmpty) {
      return Text(
        'No content written yet.',
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant.withAlpha(140),
        ),
      );
    }

    final List<Widget> widgets = [];
    final lines = content.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // 1. Code Block Fence (```language)
      if (line.trim().startsWith('```')) {
        final language = line.trim().replaceFirst('```', '').trim();
        final List<String> blockLines = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          blockLines.add(lines[i]);
          i++;
        }
        widgets.add(CodeSnippetCard(
          snippet: CodeSnippet(
            language: language.isNotEmpty ? language : 'text',
            code: blockLines.join('\n'),
          ),
        ));
        i++;
        continue;
      }

      // 2. Headings
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.substring(2).trim(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(3).trim(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            line.substring(4).trim(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ));
      }
      // 3. Blockquotes
      else if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.primary, width: 3),
            ),
            color: colorScheme.primary.withAlpha(isDark ? 20 : 10),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            line.substring(2).trim(),
            style: TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface,
            ),
          ),
        ));
      }
      // 4. Bullet list items
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final bulletText = line.trim().substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
              Expanded(
                child: _buildRichTextSpan(bulletText, colorScheme, isDark),
              ),
            ],
          ),
        ));
      }
      // 5. Horizontal divider
      else if (line.trim() == '---' || line.trim() == '***') {
        widgets.add(const Divider(height: 24, thickness: 1));
      }
      // 6. Regular paragraph
      else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _buildRichTextSpan(line, colorScheme, isDark),
        ));
      } else {
        widgets.add(const SizedBox(height: 6));
      }

      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichTextSpan(String text, ColorScheme colorScheme, bool isDark) {
    final List<InlineSpan> spans = [];

    // Regex to match:
    // 1. `code`
    // 2. [[Wiki Link]]
    // 3. **bold**
    final regex = RegExp(r'(`[^`]+`|\[\[[^\]]+\]\]|\*\*[^*]+\*\*)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: colorScheme.onSurface,
          ),
        ));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        // Inline Code
        final code = matchedStr.substring(1, matchedStr.length - 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 140 : 100),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
            ),
            child: Text(
              code,
              style: GoogleFonts.firaCode(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ));
      } else if (matchedStr.startsWith('[[') && matchedStr.endsWith(']]')) {
        // Wiki Link
        final linkTitle = matchedStr.substring(2, matchedStr.length - 2);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InkWell(
            onTap: () => onWikiLinkClicked?.call(linkTitle),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(24),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 12, color: Colors.blue),
                  const SizedBox(width: 3),
                  Text(
                    linkTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      } else if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        // Bold
        final boldText = matchedStr.substring(2, matchedStr.length - 2);
        spans.add(TextSpan(
          text: boldText,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: colorScheme.onSurface,
        ),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}
