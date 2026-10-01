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

  const AcademicEnrollDialog(
      {super.key, required this.onEnroll, this.scrollController});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function({
      required String name,
      String? code,
      required String semester,
      String? instructor,
      required int credits,
    }) onEnroll,
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
            child: AcademicEnrollDialog(onEnroll: onEnroll),
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
            scrollController: controller,
          ),
        ),
      );
    }
  }

  final ScrollController? scrollController;

  @override
  State<AcademicEnrollDialog> createState() => _AcademicEnrollDialogState();
}

class _AcademicEnrollDialogState extends State<AcademicEnrollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _instructorController = TextEditingController();

  String _selectedSemester = 'Fall 2026';
  int _selectedCredits = 3;
  bool _showMoreDetails = false;
  bool _isSaving = false;

  static const _semesters = ['Fall 2026', 'Spring 2026', 'Summer 2026'];

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
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isSaving = false);
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
                    'Enroll Course',
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
                  // Course Name Field (Large)
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Course Name *',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant.withAlpha(120),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Course name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Code & Credits Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Code (e.g. CS401)',
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
                    ],
                  ),
                  AppSpacing.verticalGapLg,

                  // Credits Chips
                  Text(
                    'CREDITS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                  AppSpacing.verticalGapSm,
                  Row(
                    children: [1, 2, 3, 4, 5, 6].map((c) {
                      final selected = _selectedCredits == c;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              setState(() => _selectedCredits = c);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? primaryRed
                                    : colorScheme.surfaceContainerHighest
                                        .withAlpha(50),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$c cr',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: selected
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

                  // Semester Pill Selection
                  Text(
                    'SEMESTER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                  AppSpacing.verticalGapSm,
                  Wrap(
                    spacing: 8,
                    children: _semesters.map((s) {
                      final selected = _selectedSemester == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        selectedColor: primaryRed.withAlpha(30),
                        labelStyle: TextStyle(
                          color: selected ? primaryRed : colorScheme.onSurface,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) {
                          AppHaptics.selection();
                          setState(() => _selectedSemester = s);
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.verticalGapLg,

                  // Expandable Instructor Field
                  InkWell(
                    onTap: () =>
                        setState(() => _showMoreDetails = !_showMoreDetails),
                    child: Row(
                      children: [
                        Icon(
                          _showMoreDetails
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: primaryRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showMoreDetails
                              ? 'Hide details'
                              : 'More details (Instructor)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryRed,
                          ),
                        ),
                      ],
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
                      : const Text('Enroll Course',
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
