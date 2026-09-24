import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/task_model.dart';
import '../../projects/projects_screen.dart';
import '../../goals/goals_screen.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  final TaskModel? task;

  const TaskFormDialog({super.key, this.task});

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
    _selectedGoalId = t?.goalId ?? t?.goal?.id;
    if (t?.dueDate != null) {
      _dueDate = DateTime.tryParse(t!.dueDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estMinutesController.dispose();
    super.dispose();
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
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final projectsAsync = ref.watch(projectsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Refactor API module',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
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
                  onChanged: (val) => setState(() => _selectedGoalId = val),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

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
