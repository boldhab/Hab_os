import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/ai_chat_model.dart';

class AiQuickPromptChips extends StatelessWidget {
  final String activeScope;
  final ValueChanged<String> onPromptSelected;

  const AiQuickPromptChips({
    super.key,
    required this.activeScope,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort or filter suggestions to place current scope first
    final suggestions = List<PromptChipSuggestion>.from(PromptChipSuggestion.defaults);
    suggestions.sort((a, b) {
      if (a.scope == activeScope && b.scope != activeScope) return -1;
      if (b.scope == activeScope && a.scope != activeScope) return 1;
      return 0;
    });

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          final isMatchesScope = item.scope == activeScope;

          return ActionChip(
            avatar: Icon(
              Icons.bolt_rounded,
              size: 14,
              color: isMatchesScope ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            label: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isMatchesScope ? FontWeight.w600 : FontWeight.w400,
                color: isMatchesScope ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            backgroundColor: isDark
                ? (isMatchesScope
                    ? colorScheme.primary.withAlpha(30)
                    : colorScheme.surfaceContainerHigh)
                : (isMatchesScope
                    ? colorScheme.primary.withAlpha(20)
                    : colorScheme.surfaceContainerHighest.withAlpha(100)),
            side: BorderSide(
              color: isMatchesScope
                  ? colorScheme.primary.withAlpha(120)
                  : colorScheme.outlineVariant.withAlpha(60),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onPressed: () => onPromptSelected(item.prompt),
          );
        },
      ),
    );
  }
}
