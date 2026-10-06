import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class ScopeMeta {
  final String key;
  final String label;
  final IconData icon;

  const ScopeMeta(this.key, this.label, this.icon);
}

class AiScopeSelector extends StatelessWidget {
  final String selectedScope;
  final ValueChanged<String> onScopeSelected;

  const AiScopeSelector({
    super.key,
    required this.selectedScope,
    required this.onScopeSelected,
  });

  static const List<ScopeMeta> scopes = [
    ScopeMeta('ALL', 'All Context', Icons.auto_awesome_rounded),
    ScopeMeta('TASKS', 'Tasks', Icons.task_alt_rounded),
    ScopeMeta('HABITS', 'Habits', Icons.repeat_rounded),
    ScopeMeta('STUDY', 'Study & Exams', Icons.school_rounded),
    ScopeMeta('DEV', 'Dev & Code', Icons.code_rounded),
    ScopeMeta('GYM', 'Gym & Fitness', Icons.fitness_center_rounded),
    ScopeMeta('FINANCE', 'Finance', Icons.account_balance_wallet_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: scopes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final scope = scopes[index];
          final isSelected = scope.key == selectedScope;

          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              scope.icon,
              size: 15,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            label: Text(
              scope.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            selected: isSelected,
            selectedColor: colorScheme.primary,
            backgroundColor: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerHighest.withAlpha(120),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withAlpha(80),
                width: 1,
              ),
            ),
            onSelected: (_) => onScopeSelected(scope.key),
          );
        },
      ),
    );
  }
}
