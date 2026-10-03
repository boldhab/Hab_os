import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/task_model.dart';
import '../../../../app/theme/app_theme.dart';
import '../../projects/projects_screen.dart';
import '../../../providers/goals_provider.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  final TaskModel? task;
  final String? initialGoalId;
  final String? initialMilestoneId;
  /// Pre-selects the linked project dropdown. Pass the current project's id
  /// when opening this dialog from within a [ProjectDetailScreen] context.
  final String? initialProjectId;

  const TaskFormDialog({
    super.key,
    this.task,
    this.initialGoalId,
    this.initialMilestoneId,
    this.initialProjectId,
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
  bool _showMoreOptions = false;

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
    // initialProjectId takes precedence — allows pre-selection from ProjectDetailScreen
    _selectedProjectId = widget.initialProjectId ?? t?.projectId ?? t?.project?.id;
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
      'description': _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title Field (Large)
          TextFormField(
            controller: _titleController,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'What needs to be done? *',
              hintStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withAlpha(120),
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Title is required' : null,
          ),

          // Smart Date Pill
          if (_detectedDate != null && _detectedLabel != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: _applyDetectedDate,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: primaryRed.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: primaryRed),
                    const SizedBox(width: 6),
                    Text(
                      'Set due date to $_detectedLabel (${_detectedDate!.month}/${_detectedDate!.day})?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryRed,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.check_rounded, size: 14, color: primaryRed),
                  ],
                ),
              ),
            ),
          ],
          AppSpacing.verticalGapMd,

          // Description
          TextFormField(
            controller: _descController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add description or notes (optional)',
              hintStyle:
                  TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(140)),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          AppSpacing.verticalGapLg,

          // Priority Selectors (Chips)
          Text(
            'PRIORITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalGapSm,
          Row(
            children: [
              _buildPriorityChip('LOW', 'Low', const Color(0xFF4285F4)),
              const SizedBox(width: 8),
              _buildPriorityChip('MEDIUM', 'Medium', const Color(0xFFFBBC05)),
              const SizedBox(width: 8),
              _buildPriorityChip('HIGH', 'High', const Color(0xFFEA4335)),
              const SizedBox(width: 8),
              _buildPriorityChip(
                  'CRITICAL', 'Critical', const Color(0xFFDC2626)),
            ],
          ),
          AppSpacing.verticalGapLg,

          // Due Date Row
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: primaryRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Set Due Date'
                          : 'Due: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _dueDate == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _dueDate = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalGapLg,

          // Collapsible More Options Section
          InkWell(
            onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    'More Options',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryRed,
                    ),
                  ),
                  Icon(
                    _showMoreOptions
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: primaryRed,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showMoreOptions) ...[
            AppSpacing.verticalGapMd,
            _buildMoreOptions(context),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 560,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Task' : 'New Task',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Flexible(child: SingleChildScrollView(child: formContent)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isEditing ? 'Save Changes' : 'Create Task'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Mobile Draggable Sheet
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'New Task',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: formContent,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Task',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityChip(String id, String label, Color color) {
    final selected = _priority == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withAlpha(30),
      labelStyle: TextStyle(
        color: selected ? color : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _priority = id),
    );
  }

  Widget _buildMoreOptions(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final goalsAsync = ref.watch(goalsListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Chips
        Text(
          'STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            _buildStatusChip('TODO', 'To Do'),
            _buildStatusChip('IN_PROGRESS', 'In Progress'),
            _buildStatusChip('BLOCKED', 'Blocked'),
            _buildStatusChip('COMPLETED', 'Completed'),
          ],
        ),
        AppSpacing.verticalGapMd,

        // Linked Project Dropdown
        projectsAsync.when(
          data: (projects) => DropdownButtonFormField<String?>(
            value: _selectedProjectId,
            decoration: const InputDecoration(labelText: 'Linked Project'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
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
        AppSpacing.verticalGapMd,

        // Linked Goal Dropdown
        goalsAsync.when(
          data: (goals) => DropdownButtonFormField<String?>(
            value: _selectedGoalId,
            decoration: const InputDecoration(labelText: 'Linked Goal'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
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
        AppSpacing.verticalGapMd,

        // Estimated Time
        TextFormField(
          controller: _estMinutesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Estimated Time (minutes)',
            hintText: 'e.g. 45',
          ),
        ),
        AppSpacing.verticalGapMd,

        // Recurrence Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Recurring Task'),
          subtitle: const Text('Repeats automatically on schedule'),
          value: _isRecurring,
          onChanged: (val) => setState(() => _isRecurring = val),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _recurrenceRule,
            decoration: const InputDecoration(labelText: 'Repeat Frequency'),
            items: const [
              DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
              DropdownMenuItem(
                  value: 'WEEKDAYS', child: Text('Weekdays (Mon-Fri)')),
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
    );
  }

  Widget _buildStatusChip(String id, String label) {
    final selected = _status == id;
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: colorScheme.primary.withAlpha(30),
      labelStyle: TextStyle(
        color: selected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _status = id),
    );
  }
}
