import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/section_header.dart';

class ActiveProjectsCard extends StatelessWidget {
  final List<DashboardProjectItem> projects;

  const ActiveProjectsCard({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryRed = colorScheme.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.folder_rounded,
            title: 'Active Projects',
            action: TextButton(
              onPressed: () => context.go('/more/projects'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: textTheme.labelMedium?.copyWith(
                  color: primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AppSpacing.verticalGapSm,
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No active projects in progress.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
              itemBuilder: (context, i) {
                final p = projects[i];
                final pct = (p.progress / 100.0).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${p.progress.toStringAsFixed(0)}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: primaryRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: primaryRed.withAlpha(25),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
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
