import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/finance_model.dart';
import '../../../widgets/common/form_section_header.dart';

class BudgetFormDialog extends StatefulWidget {
  final BudgetModel? initialBudget;
  final String? initialCategoryId;
  final String? initialCategoryName;

  const BudgetFormDialog({
    super.key,
    this.initialBudget,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryIdController;
  late final TextEditingController _limitController;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.initialBudget?.month ?? now.month;
    _year = widget.initialBudget?.year ?? now.year;
    _categoryIdController = TextEditingController(
      text: widget.initialBudget?.categoryId ?? widget.initialCategoryId ?? '',
    );
    _limitController = TextEditingController(
      text: widget.initialBudget != null
          ? widget.initialBudget!.monthlyLimit.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _categoryIdController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) return;

    final payload = <String, dynamic>{
      'categoryId': _categoryIdController.text.trim(),
      'monthlyLimit': limit,
      'month': _month,
      'year': _year,
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.initialBudget != null;
    final primaryRed = colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    child: Icon(Icons.savings_rounded,
                        size: 20, color: primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Category Budget'
                              : 'Set Category Budget',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Configure monthly spending limit targets',
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FormSectionHeader(
                        title: 'Budget Target',
                        icon: Icons.track_changes_rounded,
                      ),
                      if (widget.initialCategoryName != null &&
                          widget.initialCategoryName!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withAlpha(45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha(85),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.category_rounded,
                                  size: 18, color: primaryRed),
                              const SizedBox(width: 10),
                              Text(
                                'Category: ${widget.initialCategoryName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        TextFormField(
                          controller: _categoryIdController,
                          decoration: const InputDecoration(
                            labelText: 'Finance Category ID',
                            hintText: 'UUID of the finance category',
                            prefixIcon: Icon(Icons.category_rounded, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter category ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _limitController,
                        autofocus: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Monthly Limit *',
                          prefixIcon: Icon(Icons.attach_money_rounded,
                              color: primaryRed, size: 20),
                          hintText: '0.00',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter budget limit';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a positive valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      const FormSectionHeader(
                        title: 'Target Period',
                        icon: Icons.calendar_month_outlined,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _month,
                              decoration: const InputDecoration(
                                labelText: 'Month',
                                prefixIcon:
                                    Icon(Icons.calendar_view_month_rounded, size: 20),
                              ),
                              items: List.generate(12, (index) {
                                final m = index + 1;
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text('Month $m'),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) setState(() => _month = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _year,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                prefixIcon:
                                    Icon(Icons.calendar_today_rounded, size: 20),
                              ),
                              items: [2025, 2026, 2027, 2028].map((y) {
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text('$y'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _year = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(isEditing ? 'Update Budget' : 'Save Budget'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
