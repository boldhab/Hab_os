import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/habit_model.dart';
import '../../../providers/habits_provider.dart';
import '../../../widgets/common/form_section_header.dart';

/// Modal dialog for creating and editing habits, featuring a category selection matrix.
class HabitFormDialog extends ConsumerStatefulWidget {
  final HabitModel? habit;
  final List<HabitCategoryModel> categories;

  const HabitFormDialog({
    super.key,
    this.habit,
    this.categories = const [],
  });

  @override
  ConsumerState<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends ConsumerState<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _targetValueController;
  late TextEditingController _freqCountController;

  String? _categoryId;
  String _frequency = 'DAILY';
  String _targetFrequencyPeriod = 'WEEK';
  String _targetType = 'CHECKBOX';
  String _difficulty = 'MEDIUM';
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _categoryId = h?.category?.id;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _targetValueController =
        TextEditingController(text: (h?.targetValue ?? 1).toString());
    _freqCountController =
        TextEditingController(text: (h?.targetFrequencyCount ?? 3).toString());
    _frequency = h?.frequency ?? 'DAILY';
    _targetFrequencyPeriod = h?.targetFrequencyPeriod ?? 'WEEK';
    _targetType = h?.targetType ?? 'CHECKBOX';
    _difficulty = h?.difficulty ?? 'MEDIUM';

    if (h?.reminderTime != null && h!.reminderTime!.contains(':')) {
      final parts = h.reminderTime!.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetValueController.dispose();
    _freqCountController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    String? formattedReminder;
    if (_reminderTime != null) {
      final hh = _reminderTime!.hour.toString().padLeft(2, '0');
      final mm = _reminderTime!.minute.toString().padLeft(2, '0');
      formattedReminder = '$hh:$mm';
    }

    final isCustom = _frequency == 'CUSTOM';

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      'categoryId': _categoryId,
      'frequency': _frequency,
      'targetFrequencyCount':
          isCustom ? (int.tryParse(_freqCountController.text.trim()) ?? 3) : 1,
      'targetFrequencyPeriod': isCustom ? _targetFrequencyPeriod : 'DAY',
      'targetType': _targetType,
      'targetValue': int.tryParse(_targetValueController.text.trim()) ?? 1,
      'reminderTime': formattedReminder,
      'difficulty': _difficulty,
    };

    Navigator.of(context).pop(payload);
  }

  Color _resolveCategoryColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final hex = hexString.replaceFirst('#', '');
      return Color(int.parse(hex.length == 6 ? '0xFF$hex' : '0xFF000000'));
    } catch (_) {
      return defaultColor;
    }
  }

  Widget _buildCategoryChip({
    required String? id,
    required String name,
    required String? color,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = _resolveCategoryColor(color, colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: isSelected,
        avatar: id == null
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
        label: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? dotColor : colorScheme.onSurface,
          ),
        ),
        selectedColor: dotColor.withAlpha(35),
        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(70),
        side: BorderSide(
          color: isSelected ? dotColor : colorScheme.outlineVariant.withAlpha(90),
          width: isSelected ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() {
            _categoryId = isSelected ? null : id;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    // Use categories passed via props or fallback to stream/provider
    final availableCategories = widget.categories.isNotEmpty
        ? widget.categories
        : ref.watch(habitsProvider).categories;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
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
                    child: Icon(Icons.repeat_rounded, size: 20, color: primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Habit' : 'New Habit',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          isEditing
                              ? 'Update cadence, target and preferences'
                              : 'Build consistency one day at a time',
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Basic Information
                      const FormSectionHeader(
                        title: 'Habit Information',
                        icon: Icons.edit_note_rounded,
                      ),
                      TextFormField(
                        controller: _nameController,
                        autofocus: !isEditing,
                        decoration: InputDecoration(
                          labelText: 'Habit Name *',
                          hintText: 'e.g. Read 20 pages or Go to gym',
                          prefixIcon: Icon(Icons.check_circle_outline_rounded,
                              color: primaryRed, size: 20),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Habit name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'e.g. Before bedtime / workout routine',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Category
                      FormSectionHeader(
                        title: 'Life Domain / Category',
                        icon: Icons.category_outlined,
                        trailing: _categoryId != null
                            ? InkWell(
                                onTap: () => setState(() => _categoryId = null),
                                child: Text(
                                  'Clear Selection',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryRed,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (availableCategories.isEmpty)
                        Text(
                          'No categories available',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                        )
                      else
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildCategoryChip(
                                id: null,
                                name: 'General',
                                color: null,
                                isSelected: _categoryId == null,
                              ),
                              ...availableCategories.map((c) => _buildCategoryChip(
                                    id: c.id,
                                    name: c.name,
                                    color: c.color,
                                    isSelected: _categoryId == c.id,
                                  )),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Section 3: Cadence & Frequency
                      const FormSectionHeader(
                        title: 'Cadence & Schedule',
                        icon: Icons.calendar_month_outlined,
                      ),
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency Cadence',
                          prefixIcon: Icon(Icons.repeat_rounded, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'DAILY', child: Text('Daily (Every day)')),
                          DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text('Weekly (Once a week)')),
                          DropdownMenuItem(
                              value: 'CUSTOM',
                              child: Text('Custom (X per period)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
                        },
                      ),
                      if (_frequency == 'CUSTOM') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _freqCountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Target Times',
                                  prefixIcon: Icon(Icons.pin_outlined, size: 20),
                                ),
                                validator: (val) {
                                  final n = int.tryParse(val ?? '');
                                  if (n == null || n <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _targetFrequencyPeriod,
                                decoration: const InputDecoration(
                                  labelText: 'Per Period',
                                  prefixIcon:
                                      Icon(Icons.timelapse_rounded, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'DAY', child: Text('Day')),
                                  DropdownMenuItem(
                                      value: 'WEEK', child: Text('Week')),
                                  DropdownMenuItem(
                                      value: 'MONTH', child: Text('Month')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _targetFrequencyPeriod = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Section 4: Goal Target & Measurement
                      const FormSectionHeader(
                        title: 'Goal Target',
                        icon: Icons.track_changes_rounded,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _targetType,
                              decoration: const InputDecoration(
                                labelText: 'Goal Type',
                                prefixIcon:
                                    Icon(Icons.flag_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'CHECKBOX',
                                    child: Text('Yes / No (Done)')),
                                DropdownMenuItem(
                                    value: 'COUNT',
                                    child: Text('Numeric (Reps/Count)')),
                                DropdownMenuItem(
                                    value: 'DURATION',
                                    child: Text('Duration (Minutes)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _targetType = val);
                                }
                              },
                            ),
                          ),
                          if (_targetType != 'CHECKBOX') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _targetValueController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: _targetType == 'DURATION'
                                      ? 'Minutes'
                                      : 'Target Units',
                                  prefixIcon: const Icon(
                                      Icons.numbers_rounded,
                                      size: 20),
                                ),
                                validator: (val) {
                                  final n = int.tryParse(val ?? '');
                                  if (n == null || n <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 5: Difficulty
                      const FormSectionHeader(
                        title: 'Difficulty & Motivation',
                        icon: Icons.military_tech_outlined,
                      ),
                      DropdownButtonFormField<String>(
                        value: _difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty Level',
                          prefixIcon: Icon(Icons.bolt_rounded, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'TRIVIAL',
                              child: Text('Trivial (+1 XP)')),
                          DropdownMenuItem(
                              value: 'EASY', child: Text('Easy (+2 XP)')),
                          DropdownMenuItem(
                              value: 'MEDIUM', child: Text('Medium (+3 XP)')),
                          DropdownMenuItem(
                              value: 'HARD', child: Text('Hard (+5 XP)')),
                          DropdownMenuItem(
                              value: 'EPIC', child: Text('Epic (+8 XP)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _difficulty = val);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Section 6: Reminder
                      const FormSectionHeader(
                        title: 'Daily Reminder',
                        icon: Icons.alarm_rounded,
                      ),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withAlpha(45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _reminderTime != null
                                  ? primaryRed.withAlpha(120)
                                  : colorScheme.outlineVariant.withAlpha(85),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryRed.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.alarm_rounded,
                                    size: 18, color: primaryRed),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _reminderTime == null
                                          ? 'No Reminder Set'
                                          : 'Reminder: ${_reminderTime!.format(context)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _reminderTime == null
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      _reminderTime == null
                                          ? 'Tap to receive repeating daily alert'
                                          : 'Local repeating push alert enabled',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant
                                            .withAlpha(160),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_reminderTime != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  tooltip: 'Remove reminder',
                                  onPressed: () =>
                                      setState(() => _reminderTime = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              else
                                Text(
                                  'Set Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primaryRed,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(isEditing ? 'Save Changes' : 'Create Habit'),
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
