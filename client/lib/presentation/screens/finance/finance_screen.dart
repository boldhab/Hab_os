import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/finance_model.dart';
import '../../providers/finance_provider.dart';
import '../../../app/theme/app_theme.dart';
import 'widgets/transaction_form_dialog.dart';
import 'widgets/budget_form_dialog.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/hero_card.dart';

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
            icon: const Icon(Icons.add_chart_rounded),
            tooltip: 'Set Budget',
            onPressed: () => _openBudgetDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _buildSummaryCard(context, state, colorScheme),
            ),

            // ── Budgets Section (Horizontal Carousel) ────────────────────────
            _buildBudgetsSection(context, ref, state, colorScheme),

            // ── Search & Filter Row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: state.selectedType == null,
                          onSelected: (_) => notifier.setTypeFilter(null),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: const Text('Expenses'),
                          selected: state.selectedType == 'EXPENSE',
                          onSelected: (_) => notifier.setTypeFilter('EXPENSE'),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: const Text('Income'),
                          selected: state.selectedType == 'INCOME',
                          onSelected: (_) => notifier.setTypeFilter('INCOME'),
                        ),
                      ],
                    ),
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
    final semantics = AppSemanticColors.of(context);
    final isNetPositive = net >= 0;

    return HeroCard(
      enableGlow: true,
      glowColor: isNetPositive
          ? semantics.success.withAlpha(25)
          : semantics.danger.withAlpha(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Balance',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              if (isNetPositive)
                AppBadge.success(
                  label: 'POSITIVE',
                  icon: Icons.trending_up_rounded,
                  size: AppBadgeSize.compact,
                  context: context,
                )
              else
                AppBadge.danger(
                  label: 'DEFICIT',
                  icon: Icons.trending_down_rounded,
                  size: AppBadgeSize.compact,
                  context: context,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${isNetPositive ? '' : '-'}\$${net.abs().toStringAsFixed(2)}',
            style: AppTypography.statNumeral(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: semantics.successContainer.withAlpha(80),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: semantics.success.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: semantics.successContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_downward_rounded,
                            color: semantics.onSuccessContainer, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    semantics.onSuccessContainer.withAlpha(180),
                              ),
                            ),
                            Text(
                              '+\$${income.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: semantics.onSuccessContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: semantics.dangerContainer.withAlpha(80),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: semantics.danger.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: semantics.dangerContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_upward_rounded,
                            color: semantics.onDangerContainer, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    semantics.onDangerContainer.withAlpha(180),
                              ),
                            ),
                            Text(
                              '-\$${expense.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: semantics.onDangerContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsSection(
    BuildContext context,
    WidgetRef ref,
    FinanceState state,
    ColorScheme colorScheme,
  ) {
    if (state.budgets.isEmpty) return const SizedBox.shrink();

    final semantics = AppSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budgets',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              TextButton(
                onPressed: () => _openBudgetDialog(context, ref),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Manage'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 115,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.budgets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final b = state.budgets[index];
              final categoryName = b.category?.name ?? 'Category';
              final pct = (b.percentageUsed / 100).clamp(0.0, 1.0);
              final isWarn = b.isWarning || b.isExceeded;
              final accentColor = b.isExceeded
                  ? semantics.danger
                  : (b.isWarning ? Colors.orange : colorScheme.primary);

              return GestureDetector(
                onTap: () => _openBudgetDialog(context, ref, initialBudget: b),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isWarn
                          ? accentColor.withAlpha(120)
                          : colorScheme.outlineVariant.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isWarn)
                            Icon(
                              b.isExceeded
                                  ? Icons.error_rounded
                                  : Icons.warning_amber_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${b.spent.toStringAsFixed(0)} / \$${b.monthlyLimit.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${b.percentageUsed.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FinanceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

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
            icon: Icons.account_balance_wallet_rounded,
            title: 'No transactions found',
            description:
                'Tap "+ Add Transaction" below to record expenses or income.',
            actionLabel: 'Add Transaction',
            onAction: () => _openCreateDialog(context, ref),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200 &&
                !state.isLoadingMore &&
                state.hasMore) {
              ref.read(financeProvider.notifier).loadMoreTransactions();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, 80),
            itemCount: state.transactions.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.transactions.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              final t = state.transactions[index];
              final isIncome = t.type == 'INCOME';
              final dateStr = t.date.split('T')[0];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: colorScheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? semantics.success.withAlpha(30)
                            : semantics.danger.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isIncome ? semantics.success : semantics.danger,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t.description != null && t.description!.isNotEmpty
                          ? t.description!
                          : (isIncome ? 'Income' : 'Expense'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    subtitle: Text(
                      '$dateStr • ${t.source}${t.category?.name == null ? '' : ' • ${t.category!.name}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isIncome
                                    ? semantics.success
                                    : semantics.danger,
                              ),
                        ),
                        IconButton(
                          tooltip: 'Delete transaction',
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: semantics.danger),
                          onPressed: () => _confirmDelete(context, ref, t),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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

  Future<void> _openBudgetDialog(
    BuildContext context,
    WidgetRef ref, {
    BudgetModel? initialBudget,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BudgetFormDialog(
        initialBudget: initialBudget,
        initialCategoryId: initialBudget?.categoryId,
        initialCategoryName: initialBudget?.category?.name,
      ),
    );
    if (result != null) {
      await ref.read(financeProvider.notifier).setBudget(result);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TransactionModel transaction) async {
    final semantics = AppSemanticColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: semantics.danger,
              foregroundColor: semantics.onDanger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(financeProvider.notifier)
          .deleteTransaction(transaction.id);
    }
  }
}
