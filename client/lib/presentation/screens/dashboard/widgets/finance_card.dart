import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/common/app_card.dart';

class FinanceCard extends StatelessWidget {
  final DashboardFinanceSection finance;

  const FinanceCard({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasBudget = finance.totalBudgetCap > 0;
    final pct = hasBudget
        ? (finance.spentThisMonth / finance.totalBudgetCap).clamp(0.0, 1.0)
        : 0.0;
    final barColor =
        finance.isWarning ? const Color(0xFFEA4335) : colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(14.0),
      backgroundColor:
          finance.isWarning ? const Color(0xFFEA4335).withAlpha(18) : null,
      border: finance.isWarning
          ? BorderSide(color: const Color(0xFFEA4335).withAlpha(60), width: 1.0)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: barColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  finance.isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: barColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Finance',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: finance.isWarning
                        ? const Color(0xFFEA4335)
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${finance.spentThisMonth.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: finance.isWarning
                  ? const Color(0xFFEA4335)
                  : colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'spent this month',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(180),
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasBudget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4.0,
                backgroundColor: barColor.withAlpha(25),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${finance.budgetRemaining.toStringAsFixed(0)} left',
              style: textTheme.labelSmall?.copyWith(
                color: finance.isWarning
                    ? const Color(0xFFEA4335)
                    : colorScheme.onSurfaceVariant.withAlpha(180),
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
