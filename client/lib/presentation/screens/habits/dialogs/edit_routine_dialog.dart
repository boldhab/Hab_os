import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/habit_model.dart';
import '../../../providers/habits_provider.dart';
import '../../../widgets/common/form_section_header.dart';

/// Modal dialog for modifying an existing habit routine and re-bundling / re-ordering its steps.
class EditRoutineDialog extends ConsumerStatefulWidget {
  final RoutineModel routine;
  final List<HabitModel> availableHabits;

  const EditRoutineDialog({
    super.key,
    required this.routine,
    required this.availableHabits,
  });

  @override
  ConsumerState<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends ConsumerState<EditRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late List<String> _selectedHabitIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descController =
        TextEditingController(text: widget.routine.description ?? '');

    // Initialize with ordered habit IDs from current routine
    _selectedHabitIds = widget.routine.items.map((i) => i.habitId).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _selectedHabitIds.removeAt(index);
      _selectedHabitIds.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index >= _selectedHabitIds.length - 1) return;
    setState(() {
      final item = _selectedHabitIds.removeAt(index);
      _selectedHabitIds.insert(index + 1, item);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHabitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one habit for this routine.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      'habitIds': _selectedHabitIds,
    };

    final success = await ref
        .read(habitsProvider.notifier)
        .updateRoutine(widget.routine.id, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routine "${_nameController.text.trim()}" updated successfully.'),
        ),
      );
    } else {
      final error = ref.read(habitsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to update routine.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Combine habits: first selected in order, then remaining available
    final allHabits = <HabitModel>[];
    for (final id in _selectedHabitIds) {
      final h =
          widget.availableHabits.where((item) => item.id == id).firstOrNull;
      if (h != null) allHabits.add(h);
    }
    for (final h in widget.availableHabits) {
      if (!_selectedHabitIds.contains(h.id)) allHabits.add(h);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge and close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome_motion_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Habit Routine',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                          ),
                          Text(
                            'Sequence and bundle your daily rituals',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Routine Details Section
                const FormSectionHeader(
                  title: 'ROUTINE IDENTITY',
                  icon: Icons.label_outline_rounded,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Routine Name *',
                    hintText: 'e.g. Morning Launchpad',
                    prefixIcon: Icon(Icons.stars_rounded),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Routine name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. Sequence before starting work',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Habit Sequence Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const FormSectionHeader(
                      title: 'BUNDLE & SEQUENCE ORDER',
                      icon: Icons.low_priority_rounded,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedHabitIds.length} selected',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (allHabits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No habits found to add.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(80)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allHabits.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final habit = allHabits[index];
                        final isChecked = _selectedHabitIds.contains(habit.id);
                        final orderIndex = _selectedHabitIds.indexOf(habit.id);

                        return CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          title: Text(
                            habit.name,
                            style: TextStyle(
                              fontWeight: isChecked
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: isChecked
                              ? Text(
                                  'Step ${orderIndex + 1} of ${_selectedHabitIds.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                          value: isChecked,
                          secondary: isChecked && _selectedHabitIds.length > 1
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (orderIndex > 0)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.arrow_upward,
                                            size: 16),
                                        tooltip: 'Move step up',
                                        onPressed: () => _moveUp(orderIndex),
                                      ),
                                    if (orderIndex <
                                        _selectedHabitIds.length - 1)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.arrow_downward,
                                            size: 16),
                                        tooltip: 'Move step down',
                                        onPressed: () => _moveDown(orderIndex),
                                      ),
                                  ],
                                )
                              : null,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedHabitIds.add(habit.id);
                              } else {
                                _selectedHabitIds.remove(habit.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
