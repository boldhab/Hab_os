import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/common/form_section_header.dart';

class GoalFormDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const GoalFormDialog(
      {super.key, required this.onSubmit, this.scrollController});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(Map<String, dynamic> payload) onSubmit,
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
            child: GoalFormDialog(onSubmit: onSubmit),
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
          builder: (_, controller) => GoalFormDialog(
            onSubmit: onSubmit,
            scrollController: controller,
          ),
        ),
      );
    }
  }

  final ScrollController? scrollController;

  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetAmountController = TextEditingController();

  String _category = 'PERSONAL';
  String _priority = 'MEDIUM';
  DateTime? _targetDate;
  bool _showMoreDetails = false;
  bool _isSaving = false;

  static const _categories = [
    {'id': 'CAREER', 'label': 'Career', 'icon': Icons.work_outline_rounded},
    {'id': 'HEALTH', 'label': 'Health', 'icon': Icons.fitness_center_rounded},
    {'id': 'EDUCATION', 'label': 'Education', 'icon': Icons.school_outlined},
    {'id': 'FINANCIAL', 'label': 'Financial', 'icon': Icons.savings_outlined},
    {'id': 'PERSONAL', 'label': 'Personal', 'icon': Icons.flag_outlined},
  ];

  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final targetAmt = _category == 'FINANCIAL'
          ? double.tryParse(_targetAmountController.text.trim())
          : null;

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        if (_descController.text.trim().isNotEmpty)
          'description': _descController.text.trim(),
        'category': _category,
        'priority': _priority,
        if (_targetDate != null) 'targetDate': _targetDate!.toIso8601String(),
        if (targetAmt != null) 'targetAmount': targetAmt,
      };

      await widget.onSubmit(payload);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.flag_rounded, size: 20, color: primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Goal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                        ),
                        Text(
                          'Set an ambitious milestone to work toward',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withAlpha(170),
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
                  // Title Field
                  const FormSectionHeader(
                    title: 'Goal Objective',
                    icon: Icons.edit_note_rounded,
                  ),
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Goal Title *',
                      hintText: 'What is your goal?',
                      prefixIcon: Icon(Icons.flag_rounded,
                          color: primaryRed, size: 20),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Goal title is required'
                        : null,
                  ),
                  AppSpacing.verticalGapLg,

                  // Category Selection Icons
                  const FormSectionHeader(
                    title: 'Category Domain',
                    icon: Icons.category_outlined,
                  ),
                  AppSpacing.verticalGapXs,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((c) {
                        final catId = c['id'] as String;
                        final selected = _category == catId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(c['icon'] as IconData,
                                size: 16,
                                color: selected ? primaryRed : colorScheme.onSurfaceVariant),
                            label: Text(c['label'] as String),
                            selected: selected,
                            selectedColor: primaryRed.withAlpha(25),
                            labelStyle: TextStyle(
                              color:
                                  selected ? primaryRed : colorScheme.onSurface,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            onSelected: (_) {
                              AppHaptics.selection();
                              setState(() => _category = catId);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // Financial Amount Input if FINANCIAL selected
                  if (_category == 'FINANCIAL') ...[
                    const FormSectionHeader(
                      title: 'Financial Target',
                      icon: Icons.savings_outlined,
                    ),
                    TextFormField(
                      controller: _targetAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Savings Amount *',
                        prefixIcon: Icon(Icons.attach_money_rounded,
                            color: primaryRed, size: 20),
                        hintText: '0.00',
                      ),
                    ),
                    AppSpacing.verticalGapLg,
                  ],

                  // Priority Segmented Selector
                  const FormSectionHeader(
                    title: 'Priority',
                    icon: Icons.priority_high_rounded,
                  ),
                  AppSpacing.verticalGapXs,
                  Row(
                    children: _priorities.map((p) {
                      final selected = _priority == p;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              setState(() => _priority = p);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? primaryRed
                                    : colorScheme.surfaceContainerHighest
                                        .withAlpha(45),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? primaryRed
                                      : colorScheme.outlineVariant.withAlpha(70),
                                ),
                              ),
                              child: Text(
                                p[0] + p.substring(1).toLowerCase(),
                                style: TextStyle(
                                  fontSize: 12,
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

                  // Target Date Picker Tile
                  const FormSectionHeader(
                    title: 'Target Date',
                    icon: Icons.calendar_today_rounded,
                  ),
                  AppSpacing.verticalGapXs,
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHighest.withAlpha(45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _targetDate != null
                              ? primaryRed.withAlpha(120)
                              : colorScheme.outlineVariant.withAlpha(85),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryRed.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.calendar_today_rounded,
                                    size: 18, color: primaryRed),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _targetDate == null
                                    ? 'Set Target Completion Date'
                                    : 'Target: ${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // More Details Collapsible
                  InkWell(
                    onTap: () =>
                        setState(() => _showMoreDetails = !_showMoreDetails),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _showMoreDetails
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: primaryRed,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showMoreDetails
                                ? 'Hide description'
                                : 'More details (Motivation & Notes)',
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
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description & Motivation',
                        hintText: 'Why is this goal important? Add motivation or milestones...',
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        alignLabelWithHint: true,
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
                child: FilledButton.icon(
                  icon: _isSaving
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_rounded, size: 18),
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  label: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Goal',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
