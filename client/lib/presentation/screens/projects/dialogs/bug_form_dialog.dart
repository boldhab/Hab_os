import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class BugFormDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? initialMilestone;
  final String? initialSteps;
  final String initialSeverity;
  final String initialPriority;
  final String initialStatus;
  final Future<void> Function(String title, String description, String? steps,
      String severity, String priority, String status) onSubmit;

  const BugFormDialog({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.initialMilestone,
    this.initialSteps,
    this.initialSeverity = 'MAJOR',
    this.initialPriority = 'MEDIUM',
    this.initialStatus = 'OPEN',
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialTitle,
    String? initialDescription,
    String? initialMilestone,
    String? initialSteps,
    String initialSeverity = 'MAJOR',
    String initialPriority = 'MEDIUM',
    String initialStatus = 'OPEN',
    required Future<void> Function(
            String, String, String?, String, String, String)
        onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => BugFormDialog(
          initialTitle: initialTitle,
          initialDescription: initialDescription,
          initialMilestone: initialMilestone,
          initialSteps: initialSteps,
          initialSeverity: initialSeverity,
          initialPriority: initialPriority,
          initialStatus: initialStatus,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<BugFormDialog> createState() => _BugFormDialogState();
}

class _BugFormDialogState extends State<BugFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _milestoneCtrl;
  late TextEditingController _stepsCtrl;
  late String _severity;
  late String _priority;
  late String _status;
  bool _saving = false;

  static const _severities = ['MINOR', 'MAJOR', 'CRITICAL'];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  static const _statuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _descCtrl =
        TextEditingController(text: widget.initialDescription ?? '');
    _milestoneCtrl =
        TextEditingController(text: widget.initialMilestone ?? '');
    _stepsCtrl = TextEditingController(text: widget.initialSteps ?? '');
    _severity = widget.initialSeverity;
    _priority = widget.initialPriority;
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _milestoneCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final milestone = _milestoneCtrl.text.trim();
      var desc = _descCtrl.text.trim();
      if (milestone.isNotEmpty) {
        desc = '$desc\n[Milestone: $milestone]';
      }
      await widget.onSubmit(
        _titleCtrl.text.trim(),
        desc,
        _stepsCtrl.text.trim().isNotEmpty ? _stepsCtrl.text.trim() : null,
        _severity,
        _priority,
        _status,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppSemanticColors.of(context).danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final isEdit = widget.initialTitle != null;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cs.outlineVariant.withAlpha(100),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(isEdit ? 'Edit Bug' : 'Report Bug',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Bug Title *',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Description required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _milestoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Milestone / Sprint (optional)',
                  hintText: 'e.g. v1.0.0 or Sprint 1',
                  prefixIcon: const Icon(Icons.flag_outlined, size: 18),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stepsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Steps to Reproduce (optional)',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _severity,
                      decoration: InputDecoration(
                        labelText: 'Severity',
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withAlpha(40),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                      items: _severities
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _severity = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withAlpha(40),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                      items: _priorities
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _priority = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(s.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: semantics.danger,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Save Changes' : 'Report Bug',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
