import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/retrospective_model.dart';

class AnalyticsMultiDomainCard extends StatelessWidget {
  final RetrospectiveModel retro;

  const AnalyticsMultiDomainCard({super.key, required this.retro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final md = retro.multiDomain;

    if (md == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MULTI-DOMAIN PERFORMANCE MATRIX',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
          AppSpacing.verticalGapMd,

          // 3 Domain Sections
          // 1. Study
          _buildDomainRow(
            context,
            icon: Icons.school_rounded,
            title: 'Academic Study',
            statPrimary: '${md.studyHours.toStringAsFixed(1)} hrs',
            statSecondary: '${md.studySessionsCount} sessions',
            accent: colorScheme.tertiary,
          ),
          Divider(height: 20, thickness: 0.6, color: colorScheme.outlineVariant.withAlpha(30)),

          // 2. Engineering
          _buildDomainRow(
            context,
            icon: Icons.code_rounded,
            title: 'Engineering & LeetCode',
            statPrimary: '${md.totalCommits} commits',
            statSecondary: '${md.leetcodeTotal} solved (E:${md.leetcodeEasy} M:${md.leetcodeMedium} H:${md.leetcodeHard})',
            accent: colorScheme.primary,
          ),
          Divider(height: 20, thickness: 0.6, color: colorScheme.outlineVariant.withAlpha(30)),

          // 3. Finance
          _buildDomainRow(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: 'Financial Cash Flow',
            statPrimary: '\$${md.netSavings.toStringAsFixed(2)} net',
            statSecondary: 'In: \$${md.totalIncome.toStringAsFixed(0)} • Out: \$${md.totalExpense.toStringAsFixed(0)}',
            accent: md.netSavings >= 0 ? semantics.success : semantics.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildDomainRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String statPrimary,
    required String statSecondary,
    required Color accent,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statSecondary,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statPrimary,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
