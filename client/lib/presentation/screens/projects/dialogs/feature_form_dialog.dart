import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class FeatureFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final String? initialMilestone;
  final String initialPriority;
  final String initialStatus;
  final Future<void> Function(
      String name, String? description, String priority, String status)
      onSubmit;

  const FeatureFormDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialMilestone,
    this.initialPriority = 'MEDIUM',
    this.initialStatus = 'TODO',
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialName,
    String? initialDescription,
    String? initialMilestone,
    String initialPriority = 'MEDIUM',
    String initialStatus = 'TODO',
    required Future<void> Function(
            String name, String? description, String priority, String status)
        onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => FeatureFormDialog(
          initialName: initialName,
          initialDescription: initialDescription,
          initialMilestone: initialMilestone,
          initialPriority: initialPriority,
          initialStatus: initialStatus,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<FeatureFormDialog> createState() => _FeatureFormDialogState();
}

class _FeatureFormDialogState extends State<FeatureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _milestoneCtrl;
  late String _priority;
  late String _status;
  bool _saving = false;

  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  static const _statuses = ['TODO', 'IN_PROGRESS', 'BLOCKED', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _milestoneCtrl = TextEditingController(text: widget.initialMilestone ?? '');
    _priority = widget.initialPriority;
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _milestoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final milestone = _milestoneCtrl.text.trim();
      var desc = _descCtrl.text.trim();
      if (milestone.isNotEmpty) {
        desc = desc.isNotEmpty ? '$desc\n[Milestone: $milestone]' : '[Milestone: $milestone]';
      }
      await widget.onSubmit(
        _nameCtrl.text.trim(),
        desc.isNotEmpty ? desc : null,
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
    final primary = cs.primary;
    final isEdit = widget.initialName != null;
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
            Text(isEdit ? 'Edit Feature' : 'Add Feature',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Feature Name *',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withAlpha(40),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withAlpha(40),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
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
            Row(
              children: [
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
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                            value: s,
                            child: Text(s.replaceAll('_', ' '))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Add Feature',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
