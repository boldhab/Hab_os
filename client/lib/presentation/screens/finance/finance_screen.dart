import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/finance_model.dart';
import '../../providers/finance_provider.dart';
import 'widgets/transaction_form_dialog.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final notifier = ref.read(financeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadFinanceData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadFinanceData(),
        child: Column(
          children: [
            // ── Summary Cards ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildSummaryCard(context, state, colorScheme),
            ),

            // ── Search & Filter Row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => notifier.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All'),
                    selected: state.selectedType == null,
                    onSelected: (_) => notifier.setTypeFilter(null),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Expense'),
                    selected: state.selectedType == 'EXPENSE',
                    onSelected: (_) => notifier.setTypeFilter('EXPENSE'),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Income'),
                    selected: state.selectedType == 'INCOME',
                    onSelected: (_) => notifier.setTypeFilter('INCOME'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Transactions List ────────────────────────────────────────────
            Expanded(
              child: _buildBody(context, ref, state),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    FinanceState state,
    ColorScheme colorScheme,
  ) {
    final income = state.analytics?.totalIncome ?? state.totalIncome;
    final expense = state.analytics?.totalExpense ?? state.totalExpense;
    final net = income - expense;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Balance',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withAlpha(180),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${net.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_downward_rounded,
                            color: Colors.green, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            '+\$${income.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.red, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            '-\$${expense.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FinanceState state) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (state.status) {
      case FinanceStatus.initial:
      case FinanceStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case FinanceStatus.error:
        return AppErrorState(
          message: state.errorMessage,
          onRetry: () => ref.read(financeProvider.notifier).loadFinanceData(),
        );

      case FinanceStatus.loaded:
        if (state.transactions.isEmpty) {
          return AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No transactions found',
            description: 'Tap "+ Add Transaction" below to record expenses or income.',
            actionLabel: 'Add Transaction',
            onAction: () => _openCreateDialog(context, ref),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: state.transactions.length,
          itemBuilder: (context, index) {
            final t = state.transactions[index];
            final isIncome = t.type == 'INCOME';
            final dateStr = t.date.split('T')[0];

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: colorScheme.surfaceContainerHighest,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? Colors.green.withAlpha(30)
                        : Colors.red.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  t.description != null && t.description!.isNotEmpty
                      ? t.description!
                      : (isIncome ? 'Income' : 'Expense'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Text('$dateStr • ${t.source}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isIncome
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      onPressed: () => _confirmDelete(context, ref, t),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const TransactionFormDialog(),
    );
    if (result != null) {
      await ref.read(financeProvider.notifier).createTransaction(result);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(financeProvider.notifier).deleteTransaction(transaction.id);
    }
  }
}
