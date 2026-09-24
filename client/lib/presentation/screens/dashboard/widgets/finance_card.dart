import 'package:flutter/material.dart';
import '../../../../data/models/dashboard_feed_model.dart';

class FinanceCard extends StatelessWidget {
  final DashboardFinanceSection finance;

  const FinanceCard({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasBudget = finance.totalBudgetCap > 0;
    final pct = hasBudget
        ? (finance.spentThisMonth / finance.totalBudgetCap).clamp(0.0, 1.0)
        : 0.0;
    final barColor = finance.isWarning ? colorScheme.error : colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: finance.isWarning
          ? colorScheme.errorContainer
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  finance.isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_outlined,
                  color: finance.isWarning
                      ? colorScheme.error
                      : colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Finance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: finance.isWarning
                            ? colorScheme.onErrorContainer
                            : null,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              '\$${finance.spentThisMonth.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: finance.isWarning
                        ? colorScheme.error
                        : colorScheme.onSurface,
                  ),
            ),
            Text(
              'spent this month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: finance.isWarning
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurfaceVariant,
                  ),
            ),

            if (hasBudget) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: barColor.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${finance.budgetRemaining.toStringAsFixed(0)} remaining',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: finance.isWarning
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
