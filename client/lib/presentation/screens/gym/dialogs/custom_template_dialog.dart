import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/gym_controller.dart';
import 'exercise_picker_dialog.dart';
import '../../../widgets/common/form_section_header.dart';

class _TemplateExerciseDraft {
  final String exerciseId;
  final String exerciseName;
  int targetSets;
  int targetReps;
  double? targetRpe;

  _TemplateExerciseDraft({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetRpe = 8.0,
  });
}

/// Dialog for authoring custom workout templates & routine schemas from scratch
class CustomTemplateDialog extends ConsumerStatefulWidget {
  const CustomTemplateDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const CustomTemplateDialog(),
    );
  }

  @override
  ConsumerState<CustomTemplateDialog> createState() => _CustomTemplateDialogState();
}

class _CustomTemplateDialogState extends ConsumerState<CustomTemplateDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'PPL';
  bool _isLoading = false;

  final List<_TemplateExerciseDraft> _exercises = [];

  static const _categories = ['PPL', 'UPPER_LOWER', 'FULL_BODY', 'BRO_SPLIT', 'CUSTOM'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template title')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise to the routine')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exercisesPayload = _exercises.asMap().entries.map((entry) {
        final idx = entry.key;
        final ex = entry.value;
        return {
          'exerciseId': ex.exerciseId,
          'order': idx + 1,
          'targetSets': ex.targetSets,
          'targetReps': ex.targetReps,
          if (ex.targetRpe != null) 'targetRpe': ex.targetRpe,
        };
      }).toList();

      await ref.read(gymControllerProvider).createTemplate(
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            category: _selectedCategory,
            exercises: exercisesPayload,
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "$name" created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating template: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.copy_rounded, size: 20, color: primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Custom Template',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Design a multi-exercise routine schema',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withAlpha(170),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FormSectionHeader(
                      title: 'Template Details',
                      icon: Icons.edit_note_rounded,
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Template Name *',
                        hintText: 'e.g. Chest & Triceps Hypertrophy',
                        prefixIcon: Icon(Icons.edit_note_rounded,
                            color: primaryRed, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g. Primary hypertrophy session...',
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Split Category',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                      ),
                      items: _categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Exercises Section
                    FormSectionHeader(
                      title: 'Exercises (${_exercises.length})',
                      icon: Icons.fitness_center_rounded,
                      trailing: FilledButton.tonalIcon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Exercise'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: () async {
                          final selected =
                              await ExercisePickerDialog.show(context);
                          if (selected != null && mounted) {
                            setState(() {
                              _exercises.add(_TemplateExerciseDraft(
                                exerciseId: selected.id,
                                exerciseName: selected.name,
                              ));
                            });
                          }
                        },
                      ),
                    ),
                    if (_exercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(70),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'No exercises added yet. Tap "Add Exercise" above to configure routine.',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ..._exercises.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final ex = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha(75),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${idx + 1}. ${ex.exerciseName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Remove',
                                    onPressed: () =>
                                        setState(() => _exercises.removeAt(idx)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: ex.targetSets.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Sets',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) =>
                                          ex.targetSets = int.tryParse(v) ?? 3,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: ex.targetReps.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Reps',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) =>
                                          ex.targetReps = int.tryParse(v) ?? 10,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue:
                                          ex.targetRpe?.toString() ?? '',
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'RPE',
                                        hintText: '8.0',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) =>
                                          ex.targetRpe = double.tryParse(v),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Create Template'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
