import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/section_header.dart';

class RecentActivityCard extends StatelessWidget {
  final List<GlobalActivityItem> activities;

  const RecentActivityCard({super.key, required this.activities});

  IconData _iconForCategory(String category) {
    return switch (category) {
      'TASK' => Icons.task_alt_rounded,
      'HABIT' => Icons.repeat_rounded,
      'FITNESS' || 'WORKOUT' => Icons.fitness_center_rounded,
      'FINANCE' || 'TRANSACTION' => Icons.account_balance_wallet_rounded,
      'FOCUS' => Icons.timer_rounded,
      'STUDY' || 'ACADEMIC' => Icons.menu_book_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorForCategory(String category, ColorScheme cs) {
    return switch (category) {
      'TASK' => cs.primary,
      'HABIT' => const Color(0xFF4285F4),
      'FITNESS' || 'WORKOUT' => const Color(0xFF34A853),
      'FINANCE' || 'TRANSACTION' => const Color(0xFFFBBC05),
      'FOCUS' => const Color(0xFFEA4335),
      'STUDY' || 'ACADEMIC' => const Color(0xFF8B5CF6),
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.history_rounded,
            title: 'Recent Activity',
          ),
          AppSpacing.verticalGapSm,
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No recent activity recorded today yet.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
              itemBuilder: (context, i) {
                final act = activities[i];
                final color = _colorForCategory(act.category, colorScheme);

                return Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconForCategory(act.category),
                        color: color,
                        size: 15,
                      ),
                    ),
                    AppSpacing.horizontalGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            act.subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(180),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
