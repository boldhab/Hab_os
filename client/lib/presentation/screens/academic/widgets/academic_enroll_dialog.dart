import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AcademicEnrollDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    String? code,
    required String semester,
    String? instructor,
    required int credits,
  }) onEnroll;

  final String? initialName;
  final String? initialCode;
  final String? initialSemester;
  final String? initialInstructor;
  final int? initialCredits;
  final bool isEditing;
  final ScrollController? scrollController;

  const AcademicEnrollDialog({
    super.key,
    required this.onEnroll,
    this.initialName,
    this.initialCode,
    this.initialSemester,
    this.initialInstructor,
    this.initialCredits,
    this.isEditing = false,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function({
      required String name,
      String? code,
      required String semester,
      String? instructor,
      required int credits,
    }) onEnroll,
    String? initialName,
    String? initialCode,
    String? initialSemester,
    String? initialInstructor,
    int? initialCredits,
    bool isEditing = false,
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
            child: AcademicEnrollDialog(
              onEnroll: onEnroll,
              initialName: initialName,
              initialCode: initialCode,
              initialSemester: initialSemester,
              initialInstructor: initialInstructor,
              initialCredits: initialCredits,
              isEditing: isEditing,
            ),
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
          builder: (_, controller) => AcademicEnrollDialog(
            onEnroll: onEnroll,
            initialName: initialName,
            initialCode: initialCode,
            initialSemester: initialSemester,
            initialInstructor: initialInstructor,
            initialCredits: initialCredits,
            isEditing: isEditing,
            scrollController: controller,
          ),
        ),
      );
    }
  }

  @override
  State<AcademicEnrollDialog> createState() => _AcademicEnrollDialogState();
}

class _AcademicEnrollDialogState extends State<AcademicEnrollDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _instructorController;

  late String _selectedSemester;
  late int _selectedCredits;
  bool _showMoreDetails = false;
  bool _isSaving = false;

  static const _semesters = ['Fall 2026', 'Spring 2026', 'Summer 2026', 'Winter 2026'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    _instructorController =
        TextEditingController(text: widget.initialInstructor ?? '');
    _selectedSemester = widget.initialSemester ?? 'Fall 2026';
    if (!_semesters.contains(_selectedSemester)) {
      _selectedSemester = 'Fall 2026';
    }
    _selectedCredits = widget.initialCredits ?? 3;
    if (widget.isEditing || (widget.initialInstructor?.isNotEmpty ?? false)) {
      _showMoreDetails = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.onEnroll(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : null,
        semester: _selectedSemester,
        instructor: _instructorController.text.trim().isNotEmpty
            ? _instructorController.text.trim()
            : null,
        credits: _selectedCredits,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save course: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final title = widget.isEditing ? 'Edit Course' : 'Enroll Course';
    final buttonLabel = widget.isEditing ? 'Save Changes' : 'Enroll Course';

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
                    title,
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
            const Divider(height: 1, thickness: 1),

            // Form Body
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Course Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Course Name *',
                      hintText: 'e.g. Distributed Systems',
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withAlpha(40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Course name is required';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalGapMd,

                  // Course Code & Semester Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Code (Optional)',
                            hintText: 'e.g. CS-401',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withAlpha(40),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSemester,
                          decoration: InputDecoration(
                            labelText: 'Semester',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withAlpha(40),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _semesters
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSemester = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalGapMd,

                  // Credits Picker
                  Text(
                    'CREDITS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                  AppSpacing.verticalGapSm,
                  Row(
                    children: [1, 2, 3, 4, 5, 6].map((c) {
                      final isSelected = _selectedCredits == c;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _selectedCredits = c),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryRed
                                    : colorScheme.surfaceContainerHighest
                                        .withAlpha(40),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$c',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  AppSpacing.verticalGapLg,

                  // Advanced details toggle
                  InkWell(
                    onTap: () =>
                        setState(() => _showMoreDetails = !_showMoreDetails),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _showMoreDetails
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: primaryRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showMoreDetails
                                ? 'Fewer Details'
                                : 'More Details (Instructor, etc.)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showMoreDetails) ...[
                    AppSpacing.verticalGapSm,
                    TextFormField(
                      controller: _instructorController,
                      decoration: InputDecoration(
                        labelText: 'Instructor Name',
                        hintText: 'e.g. Dr. Jane Smith',
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

            // Sticky Bottom Button
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
                      : Text(buttonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
