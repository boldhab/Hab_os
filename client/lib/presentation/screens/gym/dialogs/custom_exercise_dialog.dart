import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/gym_controller.dart';
import '../models/gym_models.dart';
import '../../../widgets/common/form_section_header.dart';

/// Sub-modal configuration dialog to register a new custom exercise into the user's catalog.
class CustomExerciseDialog extends ConsumerStatefulWidget {
  const CustomExerciseDialog({super.key});

  static Future<ExerciseCatalogModel?> show(BuildContext context) {
    return showDialog<ExerciseCatalogModel>(
      context: context,
      builder: (ctx) => const CustomExerciseDialog(),
    );
  }

  @override
  ConsumerState<CustomExerciseDialog> createState() =>
      _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends ConsumerState<CustomExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'CHEST';
  String _muscleGroup = 'CHEST';
  String _equipmentType = 'BARBELL';
  bool _isLoading = false;

  static const _categories = [
    ('CHEST', 'Chest'),
    ('BACK', 'Back'),
    ('LEGS', 'Legs'),
    ('SHOULDERS', 'Shoulders'),
    ('ARMS', 'Arms'),
    ('CORE', 'Core'),
    ('CARDIO', 'Cardio'),
  ];

  static const _equipmentTypes = [
    ('BARBELL', 'Barbell'),
    ('DUMBBELL', 'Dumbbell'),
    ('MACHINE', 'Machine'),
    ('CABLE', 'Cable'),
    ('BODYWEIGHT', 'Bodyweight / Calisthenics'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();

    try {
      await ref.read(gymControllerProvider).createExercise(
            name: name,
            category: _category,
            muscleGroup: _muscleGroup,
            equipmentType: _equipmentType,
            notes: notes.isNotEmpty ? notes : null,
          );

      if (mounted) {
        final created = ExerciseCatalogModel(
          id: '', // Will be reloaded from provider
          name: name,
          category: _category,
          muscleGroup: _muscleGroup,
          equipmentType: _equipmentType,
          isCustom: true,
          notes: notes.isNotEmpty ? notes : null,
        );
        Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create exercise: $e')),
        );
      }
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
        constraints: const BoxConstraints(maxWidth: 520),
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
                    child: Icon(Icons.fitness_center_rounded,
                        size: 20, color: primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Custom Exercise',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Add a custom movement to your catalog',
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FormSectionHeader(
                        title: 'Exercise Profile',
                        icon: Icons.edit_note_rounded,
                      ),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Exercise Name *',
                          hintText: 'e.g. Bulgarian Split Squat',
                          prefixIcon: Icon(Icons.fitness_center_rounded,
                              color: primaryRed, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter an exercise name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Target Category / Split',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: _categories
                            .map((c) =>
                                DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _category = val;
                              _muscleGroup = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _equipmentType,
                        decoration: const InputDecoration(
                          labelText: 'Equipment Type',
                          prefixIcon: Icon(Icons.handyman_outlined, size: 20),
                        ),
                        items: _equipmentTypes
                            .map((e) =>
                                DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _equipmentType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Technique Notes (optional)',
                          hintText: 'e.g. Full range of motion, pause at stretch',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions
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
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Exercise'),
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
