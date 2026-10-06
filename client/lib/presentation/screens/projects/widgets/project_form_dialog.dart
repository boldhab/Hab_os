import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/common/form_section_header.dart';
import '../dialogs/edit_project_dialog.dart';

class ProjectFormDialog extends StatefulWidget {
  final Future<void> Function({
    required String title,
    String? description,
    required String status,
    String? repoUrl,
    required List<String> technologies,
    String color,
  }) onSubmit;

  const ProjectFormDialog(
      {super.key, required this.onSubmit, this.scrollController});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function({
      required String title,
      String? description,
      required String status,
      String? repoUrl,
      required List<String> technologies,
      String color,
    }) onSubmit,
  }) async {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ProjectFormDialog(onSubmit: onSubmit),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => ProjectFormDialog(
            onSubmit: onSubmit,
            scrollController: controller,
          ),
        ),
      );
    }
  }

  final ScrollController? scrollController;

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _repoUrlController = TextEditingController();
  final _techController = TextEditingController(text: 'TypeScript, Flutter');

  String _status = 'IN_PROGRESS';
  Color _selectedColor = kProjectColorPresets[0];
  bool _isSaving = false;

  static const _statuses = [
    {'id': 'IN_PROGRESS', 'label': 'In Progress'},
    {'id': 'PLANNING', 'label': 'Planning'},
    {'id': 'ON_HOLD', 'label': 'On Hold'},
    {'id': 'COMPLETED', 'label': 'Completed'},
  ];

  String _toHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}${c.g.round().toRadixString(16).padLeft(2, '0')}${c.b.round().toRadixString(16).padLeft(2, '0')}';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _repoUrlController.dispose();
    _techController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final techs = _techController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await widget.onSubmit(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        status: _status,
        repoUrl: _repoUrlController.text.trim().isNotEmpty
            ? _repoUrlController.text.trim()
            : null,
        technologies: techs,
        color: _toHex(_selectedColor),
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with badge and title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Project',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                        ),
                        Text(
                          'Set up repository, tech stack & details',
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
            ),
            const Divider(height: 1),

            // Form Body
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Section: Project Details
                  const FormSectionHeader(
                    title: 'PROJECT IDENTITY',
                    icon: Icons.workspaces_rounded,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Project Name *',
                      hintText: 'e.g. HABos Core, Mobile App',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Project title is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Section: Stack & Repository
                  const FormSectionHeader(
                    title: 'TECH STACK & REPOSITORY',
                    icon: Icons.code_rounded,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _techController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tech Stack (comma-separated)',
                      hintText: 'TypeScript, Flutter, Node.js',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _repoUrlController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'GitHub Repository URL',
                      hintText: 'https://github.com/owner/repo',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section: Status & Color
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
                    items: _statuses.map((s) {
                      return DropdownMenuItem(
                        value: s['id'],
                        child: Text(s['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
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
                        'Accent Color',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProjectColorSwatchRow(
                    selected: _selectedColor,
                    onChanged: (c) => setState(() => _selectedColor = c),
                  ),
                  const SizedBox(height: 20),

                  // Section: Description & Scope
                  const FormSectionHeader(
                    title: 'DESCRIPTION & SCOPE',
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Project scope, objectives, and deliverables...',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Save Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
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
                      : const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Creating Project...' : 'Create Project',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

