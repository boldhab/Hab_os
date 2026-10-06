import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/gym_controller.dart';
import '../models/gym_models.dart';
import 'custom_exercise_dialog.dart';

/// Modal dialog for browsing, filtering, and selecting exercises from the catalog,
/// with integrated "Add Custom Exercise" entrypoint.
class ExercisePickerDialog extends ConsumerStatefulWidget {
  const ExercisePickerDialog({super.key});

  static Future<ExerciseCatalogModel?> show(BuildContext context) {
    return showDialog<ExerciseCatalogModel>(
      context: context,
      builder: (ctx) => const ExercisePickerDialog(),
    );
  }

  @override
  ConsumerState<ExercisePickerDialog> createState() =>
      _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends ConsumerState<ExercisePickerDialog> {
  String _searchQuery = '';
  String? _selectedCategory;

  static const _categories = [
    'ALL',
    'CHEST',
    'BACK',
    'LEGS',
    'SHOULDERS',
    'ARMS',
    'CORE',
    'CARDIO',
  ];

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(gymExercisesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Select Exercise'),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Custom'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () async {
              final newEx = await CustomExerciseDialog.show(context);
              if (newEx != null && mounted) {
                ref.invalidate(gymExercisesProvider);
                // Return newly created exercise if name matches or re-fetched
                final updatedList = await ref.read(gymExercisesProvider.future);
                final found = updatedList.firstWhere(
                  (e) => e.name.toLowerCase() == newEx.name.toLowerCase(),
                  orElse: () => newEx,
                );
                if (context.mounted) {
                  Navigator.pop(context, found);
                }
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Search TextField
            TextField(
              decoration: InputDecoration(
                hintText: 'Search movements...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            // Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = (_selectedCategory == null && cat == 'ALL') ||
                      _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(
                      cat == 'ALL' ? 'All Splits' : cat[0] + cat.substring(1).toLowerCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat == 'ALL' ? null : cat;
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(height: 16),
            // Exercise Catalog List
            Expanded(
              child: exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (catalog) {
                  final filtered = catalog.where((ex) {
                    final matchesQuery = _searchQuery.isEmpty ||
                        ex.name.toLowerCase().contains(_searchQuery) ||
                        ex.muscleGroup.toLowerCase().contains(_searchQuery);
                    final matchesCat = _selectedCategory == null ||
                        ex.category.toUpperCase() == _selectedCategory;
                    return matchesQuery && matchesCat;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 36, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(
                            'No matching exercises found',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add This Custom Movement'),
                            onPressed: () async {
                              final newEx = await CustomExerciseDialog.show(context);
                              if (newEx != null && context.mounted) {
                                Navigator.pop(context, newEx);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final ex = filtered[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ex.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            if (ex.isCustom)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Custom',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${ex.muscleGroup} • ${ex.equipmentType}',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () => Navigator.pop(ctx, ex),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
