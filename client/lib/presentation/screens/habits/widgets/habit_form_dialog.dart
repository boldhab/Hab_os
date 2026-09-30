import 'package:flutter/material.dart';
import '../../../../data/models/habit_model.dart';

class HabitFormDialog extends StatefulWidget {
  final HabitModel? habit;

  const HabitFormDialog({super.key, this.habit});

  @override
  State<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _targetValueController;
  late TextEditingController _freqCountController;

  String _frequency = 'DAILY';
  String _targetFrequencyPeriod = 'WEEK';
  String _targetType = 'CHECKBOX';
  String _difficulty = 'MEDIUM';
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _targetValueController = TextEditingController(text: (h?.targetValue ?? 1).toString());
    _freqCountController = TextEditingController(text: (h?.targetFrequencyCount ?? 3).toString());
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
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'frequency': _frequency,
      'targetFrequencyCount': isCustom ? (int.tryParse(_freqCountController.text.trim()) ?? 3) : 1,
      'targetFrequencyPeriod': isCustom ? _targetFrequencyPeriod : 'DAY',
      'targetType': _targetType,
      'targetValue': int.tryParse(_targetValueController.text.trim()) ?? 1,
      'reminderTime': formattedReminder,
      'difficulty': _difficulty,
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name *',
                  hintText: 'e.g. Read 20 pages or Go to gym',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Before bedtime / workout routine',
                ),
              ),
              const SizedBox(height: 16),

              // Frequency
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency Cadence'),
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('Daily (Everyday)')),
                  DropdownMenuItem(value: 'CUSTOM', child: Text('Flexible (e.g. 3x per week)')),
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly (Specific day)')),
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
                          labelText: 'Times',
                          hintText: '3',
                        ),
                        validator: (val) {
                          final n = int.tryParse(val ?? '');
                          if (n == null || n < 1) return '>= 1';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('times per'),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _targetFrequencyPeriod,
                        items: const [
                          DropdownMenuItem(value: 'WEEK', child: Text('Week')),
                          DropdownMenuItem(value: 'MONTH', child: Text('Month')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _targetFrequencyPeriod = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Target Type
              DropdownButtonFormField<String>(
                initialValue: _targetType,
                decoration: const InputDecoration(labelText: 'Target Type'),
                items: const [
                  DropdownMenuItem(value: 'CHECKBOX', child: Text('Simple Checkbox')),
                  DropdownMenuItem(value: 'COUNT', child: Text('Count (Repetitions)')),
                  DropdownMenuItem(value: 'DURATION', child: Text('Duration (Minutes)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _targetType = val);
                },
              ),
              if (_targetType != 'CHECKBOX') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _targetType == 'DURATION'
                        ? 'Target Duration (minutes)'
                        : 'Target Count',
                  ),
                  validator: (val) {
                    final n = int.tryParse(val ?? '');
                    if (n == null || n < 1) return 'Must be 1 or greater';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Difficulty level (Life Score weighting)
              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty (Life Score Impact)',
                  helperText: 'Harder habits contribute more to your score',
                ),
                items: const [
                  DropdownMenuItem(value: 'TRIVIAL', child: Text('Trivial (0.5x) - Drink water')),
                  DropdownMenuItem(value: 'EASY', child: Text('Easy (0.8x) - Vitamins')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium (1.0x) - Standard')),
                  DropdownMenuItem(value: 'HARD', child: Text('Hard (1.5x) - Gym, Coding')),
                  DropdownMenuItem(value: 'EPIC', child: Text('Epic (2.0x) - 10km run, Deep study')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _difficulty = val);
                },
              ),

              const SizedBox(height: 16),

              // Reminder
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder Time'),
                subtitle: Text(
                  _reminderTime == null
                      ? 'No reminder set'
                      : _reminderTime!.format(context),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time_rounded),
                  onPressed: _pickTime,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
