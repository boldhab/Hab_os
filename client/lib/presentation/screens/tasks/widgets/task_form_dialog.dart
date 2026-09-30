import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/task_model.dart';
import '../../projects/projects_screen.dart';
import '../../../providers/goals_provider.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  final TaskModel? task;
  final String? initialGoalId;
  final String? initialMilestoneId;

  const TaskFormDialog({
    super.key,
    this.task,
    this.initialGoalId,
    this.initialMilestoneId,
  });

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _estMinutesController;

  String _priority = 'MEDIUM';
  String _status = 'TODO';
  DateTime? _dueDate;
  String? _selectedProjectId;
  String? _selectedGoalId;
  String? _selectedMilestoneId;
  bool _isRecurring = false;
  String _recurrenceRule = 'WEEKLY';

  DateTime? _detectedDate;
  String? _detectedLabel;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _estMinutesController =
        TextEditingController(text: t?.estimatedMinutes?.toString() ?? '');
    _priority = t?.priority ?? 'MEDIUM';
    _status = t?.status ?? 'TODO';
    _selectedProjectId = t?.projectId ?? t?.project?.id;
    _selectedGoalId = widget.initialGoalId ?? t?.goalId ?? t?.goal?.id;
    _selectedMilestoneId = widget.initialMilestoneId ?? t?.milestoneId;
    _isRecurring = t?.isRecurring ?? false;
    _recurrenceRule = t?.recurrenceRule ?? 'WEEKLY';
    if (t?.dueDate != null) {
      _dueDate = DateTime.tryParse(t!.dueDate!);
    }

    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descController.dispose();
    _estMinutesController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    _parseDateFromText(_titleController.text);
  }

  void _parseDateFromText(String text) {
    if (text.trim().isEmpty) {
      if (_detectedDate != null) {
        setState(() {
          _detectedDate = null;
          _detectedLabel = null;
        });
      }
      return;
    }

    final lower = text.toLowerCase();
    final now = DateTime.now();

    DateTime? matchDate;
    String? label;

    if (RegExp(r'\btoday\b').hasMatch(lower)) {
      matchDate = DateTime(now.year, now.month, now.day);
      label = 'Today';
    } else if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      matchDate = DateTime(now.year, now.month, now.day + 1);
      label = 'Tomorrow';
    } else if (RegExp(r'\bnext week\b').hasMatch(lower)) {
      matchDate = DateTime(now.year, now.month, now.day + 7);
      label = 'Next Week';
    } else {
      final daysMap = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };

      for (final entry in daysMap.entries) {
        if (RegExp('\\b${entry.key}\\b').hasMatch(lower)) {
          var daysToAdd = entry.value - now.weekday;
          if (daysToAdd <= 0) daysToAdd += 7;
          matchDate = DateTime(now.year, now.month, now.day + daysToAdd);
          label = entry.key[0].toUpperCase() + entry.key.substring(1);
          break;
        }
      }

      if (matchDate == null) {
        final inDaysMatch = RegExp(r'\bin\s+(\d+)\s+days?\b').firstMatch(lower);
        if (inDaysMatch != null) {
          final days = int.tryParse(inDaysMatch.group(1) ?? '');
          if (days != null && days > 0) {
            matchDate = DateTime(now.year, now.month, now.day + days);
            label = 'In $days days';
          }
        }
      }
    }

    if (matchDate != _detectedDate || label != _detectedLabel) {
      setState(() {
        _detectedDate = matchDate;
        _detectedLabel = label;
      });
    }
  }

  void _applyDetectedDate() {
    if (_detectedDate != null) {
      setState(() {
        _dueDate = _detectedDate;
        _detectedDate = null;
        _detectedLabel = null;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final est = int.tryParse(_estMinutesController.text.trim());

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description':
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'priority': _priority,
      'status': _status,
      'dueDate': _dueDate?.toIso8601String(),
      'estimatedMinutes': est,
      'projectId': _selectedProjectId,
      'goalId': _selectedGoalId,
      'milestoneId': _selectedMilestoneId,
      'isRecurring': _isRecurring,
      'recurrenceRule': _isRecurring ? _recurrenceRule : null,
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final projectsAsync = ref.watch(projectsProvider);
    final goalsAsync = ref.watch(goalsListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Finish report tomorrow',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              if (_detectedDate != null && _detectedLabel != null) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: _applyDetectedDate,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Set due date to $_detectedLabel (${_detectedDate!.month}/${_detectedDate!.day})?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.check_rounded,
                            size: 14, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _priority = val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'TODO', child: Text('To Do')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                  DropdownMenuItem(value: 'BLOCKED', child: Text('Blocked')),
                  DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 16),

              // Project Dropdown
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String?>(
                  initialValue: _selectedProjectId,
                  decoration:
                      const InputDecoration(labelText: 'Linked Project'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('None')),
                    ...projects.map((p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text(p.title),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedProjectId = val),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Goal Dropdown
              goalsAsync.when(
                data: (goals) => DropdownButtonFormField<String?>(
                  initialValue: _selectedGoalId,
                  decoration: const InputDecoration(labelText: 'Linked Goal'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('None')),
                    ...goals.map((g) => DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(g.title),
                        )),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedGoalId = val;
                    _selectedMilestoneId = null;
                  }),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Milestone Dropdown (when Goal is selected)
              if (_selectedGoalId != null) ...[
                ref.watch(goalDetailsProvider(_selectedGoalId!)).when(
                  data: (goalDetail) => DropdownButtonFormField<String?>(
                    initialValue: _selectedMilestoneId,
                    decoration: const InputDecoration(
                      labelText: 'Linked Milestone',
                      hintText: 'Select milestone or leave as direct task',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('None (Direct Goal Task)')),
                      ...goalDetail.milestones.map((m) => DropdownMenuItem<String?>(
                            value: m.id,
                            child: Text(m.title),
                          )),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedMilestoneId = val),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),
              TextFormField(
                controller: _estMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Time (minutes)',
                  hintText: 'e.g. 45',
                ),
              ),
              const SizedBox(height: 16),

              // Due date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date'),
                subtitle: Text(
                  _dueDate == null
                      ? 'No due date set'
                      : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_rounded),
                      onPressed: _pickDueDate,
                    ),
                  ],
                ),
              ),

              // Recurrence Section
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring Task'),
                subtitle: const Text('Repeats automatically upon schedule'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _recurrenceRule,
                  decoration: const InputDecoration(labelText: 'Repeat Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                    DropdownMenuItem(value: 'WEEKDAYS', child: Text('Weekdays (Mon-Fri)')),
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                    DropdownMenuItem(value: 'BIWEEKLY', child: Text('Every 2 Weeks')),
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _recurrenceRule = val);
                  },
                ),
              ],
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
