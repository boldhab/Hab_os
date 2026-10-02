import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
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
  bool _showMoreOptions = false;
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
    final primaryRed = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Sticky Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Project',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Project Name *',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant.withAlpha(120),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Project title is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Tech Stack Input
                  TextFormField(
                    controller: _techController,
                    decoration: InputDecoration(
                      labelText: 'Tech Stack (comma-separated)',
                      hintText: 'TypeScript, Flutter, Node.js',
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withAlpha(40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: 'Project Status',
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withAlpha(40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
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
                  AppSpacing.verticalGapLg,

                  // GitHub Repo URL Field
                  TextFormField(
                    controller: _repoUrlController,
                    decoration: InputDecoration(
                      labelText: 'GitHub Repository URL',
                      hintText: 'https://github.com/owner/repo',
                      prefixIcon: const Icon(Icons.code_rounded, size: 20),
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withAlpha(40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // Color Swatches Picker (Item 10)
                  const Text(
                    'Project Color',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProjectColorSwatchRow(
                    selected: _selectedColor,
                    onChanged: (c) => setState(() => _selectedColor = c),
                  ),
                  AppSpacing.verticalGapLg,

                  // More Details Collapsible
                  InkWell(
                    onTap: () =>
                        setState(() => _showMoreOptions = !_showMoreOptions),
                    child: Row(
                      children: [
                        Icon(
                          _showMoreOptions
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: primaryRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showMoreOptions
                              ? 'Hide description'
                              : 'More details (Description)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showMoreOptions) ...[
                    AppSpacing.verticalGapSm,
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Project description & scope...',
                        filled: true,
                        fillColor:
                            colorScheme.surfaceContainerHighest.withAlpha(40),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Sticky Save Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Project',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
