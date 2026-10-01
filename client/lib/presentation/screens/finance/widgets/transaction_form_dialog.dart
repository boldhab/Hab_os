import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class TransactionFormDialog extends StatefulWidget {
  const TransactionFormDialog({super.key});

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _sourceController = TextEditingController(text: 'CASH');

  String _type = 'EXPENSE';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final payload = <String, dynamic>{
      'amount': amount,
      'type': _type,
      'description': _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      'source': _sourceController.text.trim(),
      'date': _date.toIso8601String(),
    };

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final semantics = AppSemanticColors.of(context);

    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type Segmented Button
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'EXPENSE',
                    label: const Text('Expense'),
                    icon: Icon(Icons.arrow_downward_rounded,
                        color: semantics.danger),
                  ),
                  ButtonSegment(
                    value: 'INCOME',
                    label: const Text('Income'),
                    icon: Icon(Icons.arrow_upward_rounded,
                        color: semantics.success),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (sel) {
                  setState(() => _type = sel.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                validator: (val) {
                  final n = double.tryParse(val ?? '');
                  if (n == null || n <= 0) return 'Enter a positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Grocery shopping',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method / Source',
                  hintText: 'e.g. CASH, CARD, BANK',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Transaction Date'),
                subtitle: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded),
                  onPressed: _pickDate,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
