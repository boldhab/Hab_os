import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Preset accent colors offered in the project color picker.
const List<Color> kProjectColorPresets = [
  Color(0xFF10B981), // Emerald (default)
  Color(0xFF3B82F6), // Blue
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
  Color(0xFFEF4444), // Red
  Color(0xFF06B6D4), // Cyan
  Color(0xFF84CC16), // Lime
  Color(0xFFF97316), // Orange
  Color(0xFF6366F1), // Indigo
];

class EditProjectDialog extends StatefulWidget {
  final String initialTitle;
  final String? initialDescription;
  final String initialStatus;
  final String? initialRepoUrl;
  final List<String> initialTechnologies;
  final String? initialColor;
  final Future<void> Function({
    required String newTitle,
    String? newDescription,
    required String newStatus,
    String? newRepoUrl,
    required List<String> newTechnologies,
    required String newColor,
  }) onSubmit;

  const EditProjectDialog({
    super.key,
    required this.initialTitle,
    this.initialDescription,
    required this.initialStatus,
    this.initialRepoUrl,
    required this.initialTechnologies,
    this.initialColor,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialTitle,
    String? initialDescription,
    required String initialStatus,
    String? initialRepoUrl,
    required List<String> initialTechnologies,
    String? initialColor,
    required Future<void> Function({
      required String newTitle,
      String? newDescription,
      required String newStatus,
      String? newRepoUrl,
      required List<String> newTechnologies,
      required String newColor,
    }) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: EditProjectDialog(
            initialTitle: initialTitle,
            initialDescription: initialDescription,
            initialStatus: initialStatus,
            initialRepoUrl: initialRepoUrl,
            initialTechnologies: initialTechnologies,
            initialColor: initialColor,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _repoCtrl;
  late TextEditingController _techCtrl;
  late String _status;
  late Color _selectedColor;
  bool _isSaving = false;

  static const _statuses = [
    {'id': 'IN_PROGRESS', 'label': 'In Progress'},
    {'id': 'PLANNING', 'label': 'Planning'},
    {'id': 'ON_HOLD', 'label': 'On Hold'},
    {'id': 'COMPLETED', 'label': 'Completed'},
    {'id': 'ARCHIVED', 'label': 'Archived'},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _repoCtrl = TextEditingController(text: widget.initialRepoUrl ?? '');
    _techCtrl = TextEditingController(
        text: widget.initialTechnologies.join(', '));
    _status = widget.initialStatus;
    const valid = ['IN_PROGRESS', 'PLANNING', 'ON_HOLD', 'COMPLETED', 'ARCHIVED'];
    if (!valid.contains(_status)) _status = 'IN_PROGRESS';

    // Parse hex color or fall back to default
    _selectedColor = _parseHex(widget.initialColor) ?? kProjectColorPresets[0];
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _toHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}${c.g.round().toRadixString(16).padLeft(2, '0')}${c.b.round().toRadixString(16).padLeft(2, '0')}';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _repoCtrl.dispose();
    _techCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final techs = _techCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await widget.onSubmit(
        newTitle: _titleCtrl.text.trim(),
        newDescription:
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        newStatus: _status,
        newRepoUrl: _repoCtrl.text.trim().isNotEmpty
            ? _repoCtrl.text.trim()
            : null,
        newTechnologies: techs,
        newColor: _toHex(_selectedColor),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('Edit Project',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800))),
                  IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Project Name *',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _techCtrl,
                decoration: InputDecoration(
                  labelText: 'Tech Stack (comma-separated)',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                        value: s['id'], child: Text(s['label']!)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repoCtrl,
                decoration: InputDecoration(
                  labelText: 'GitHub Repository URL',
                  hintText: 'https://github.com/owner/repo',
                  prefixIcon: const Icon(Icons.code_rounded, size: 20),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(40),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              // ── Color Picker ──────────────────────────────────────────
              const Text('Project Color',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
              const SizedBox(height: 8),
              _ColorSwatchRow(
                selected: _selectedColor,
                onChanged: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: primaryRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal swatch row shared between create and edit dialogs.
class _ColorSwatchRow extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;
  const _ColorSwatchRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kProjectColorPresets.map((c) {
          final isSelected = c == selected;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 10),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2.5)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: c.withAlpha(120), blurRadius: 6)]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Public re-export of [_ColorSwatchRow] for use in [ProjectFormDialog].
typedef ProjectColorSwatchRow = _ColorSwatchRow;
