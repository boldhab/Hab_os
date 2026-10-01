import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../models/project_models.dart';

class ProjectCard extends StatelessWidget {
  final ProjectOverviewModel project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  Color _getHealthColor(
      String status, AppSemanticColors semantics, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'HEALTHY':
        return semantics.success;
      case 'NEEDS_ATTENTION':
        return semantics.warning;
      case 'AT_RISK':
        return semantics.danger;
      default:
        return cs.primary;
    }
  }

  String _getHealthLabel(String status) {
    switch (status.toUpperCase()) {
      case 'HEALTHY':
        return 'Healthy';
      case 'NEEDS_ATTENTION':
        return 'Needs attention';
      case 'AT_RISK':
        return 'At risk';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    final pct = (project.progress / 100.0).clamp(0.0, 1.0);
    final healthColor =
        _getHealthColor(project.healthStatus, semantics, colorScheme);
    final healthLabel = _getHealthLabel(project.healthStatus);

    final completedItems =
        project.completedTasksCount + project.completedFeaturesCount;
    final totalItems = project.tasksCount + project.featuresCount;

    final displayedTechs = project.technologies.take(3).toList();
    final remainingTechsCount =
        project.technologies.length - displayedTechs.length;

    return Dismissible(
      key: Key(project.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Project?'),
            content:
                Text('Are you sure you want to delete "${project.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    FilledButton.styleFrom(backgroundColor: colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(9),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, GitHub icon, and Health Dot
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              project.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (project.repoUrl != null &&
                              project.repoUrl!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.code_rounded,
                              size: 14,
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(140),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Health Dot + Label (Semantic color applied strictly to dot & label)
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: healthColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          healthLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: healthColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Description
                if (project.description != null &&
                    project.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                ],
                AppSpacing.verticalGapMd,

                // Progress Bar & Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedItems/$totalItems items',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '${project.progress.toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primaryRed,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: colorScheme.outlineVariant.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                  ),
                ),
                AppSpacing.verticalGapSm,

                // Bottom Meta Row: Focus Hours, Open Bugs, Tech Stack Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${project.totalFocusHours}h logged',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withAlpha(140),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (project.openBugsCount > 0)
                      Text(
                        '${project.openBugsCount} open bugs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: semantics.danger,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ...displayedTechs.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withAlpha(100),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }),
                    if (remainingTechsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withAlpha(100),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$remainingTechsCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
