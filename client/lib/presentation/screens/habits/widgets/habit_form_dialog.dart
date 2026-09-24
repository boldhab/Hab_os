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

  String _frequency = 'DAILY';
  String _targetType = 'CHECKBOX';
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _targetValueController = TextEditingController(text: (h?.targetValue ?? 1).toString());
    _frequency = h?.frequency ?? 'DAILY';
    _targetType = h?.targetType ?? 'CHECKBOX';

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

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'frequency': _frequency,
      'targetType': _targetType,
      'targetValue': int.tryParse(_targetValueController.text.trim()) ?? 1,
      'reminderTime': formattedReminder,
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name *',
                  hintText: 'e.g. Read 20 pages',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Before bedtime',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                  DropdownMenuItem(value: 'CUSTOM', child: Text('Custom')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
              const SizedBox(height: 16),
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
