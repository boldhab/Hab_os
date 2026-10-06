import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/common/form_section_header.dart';

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: primaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Project',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                        ),
                        Text(
                          'Update repository, stack, status, and theme',
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Project Details Section
              const FormSectionHeader(
                title: 'PROJECT DETAILS',
                icon: Icons.workspaces_rounded,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'e.g. HABos Core',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Project scope and goals...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Tech & Repo Section
              const FormSectionHeader(
                title: 'TECH STACK & REPOSITORY',
                icon: Icons.code_rounded,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _techCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tech Stack (comma-separated)',
                  hintText: 'TypeScript, Flutter, Node.js',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repoCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'GitHub Repository URL',
                  hintText: 'https://github.com/owner/repo',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Status & Theme Section
              const FormSectionHeader(
                title: 'STATUS & THEME',
                icon: Icons.palette_outlined,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Project Status',
                  prefixIcon: Icon(Icons.pending_actions_rounded),
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                        value: s['id'], child: Text(s['label']!)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.color_lens_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Project Color',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ColorSwatchRow(
                selected: _selectedColor,
                onChanged: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
