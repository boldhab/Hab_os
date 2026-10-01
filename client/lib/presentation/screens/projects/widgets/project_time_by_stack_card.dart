import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../models/project_models.dart';

class ProjectTimeByStackCard extends StatefulWidget {
  final List<TechStackInsightModel> insights;

  const ProjectTimeByStackCard({super.key, required this.insights});

  @override
  State<ProjectTimeByStackCard> createState() => _ProjectTimeByStackCardState();
}

class _ProjectTimeByStackCardState extends State<ProjectTimeByStackCard> {
  bool _isExpanded = false;

  static const _palette = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.insights.isEmpty) return const SizedBox.shrink();

    final displayedInsights =
        _isExpanded ? widget.insights : widget.insights.take(4).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'TIME BY TECH STACK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                ],
              ),
              if (widget.insights.length > 4)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded
                        ? 'Collapse'
                        : 'Show All (${widget.insights.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.verticalGapSm,

          // Horizontal Stacked Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: widget.insights.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final flex = (item.percentage * 10).round().clamp(1, 1000);
                  final color = _palette[idx % _palette.length];

                  return Expanded(
                    flex: flex,
                    child: Container(
                      color: color,
                      margin: const EdgeInsets.only(right: 1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          AppSpacing.verticalGapSm,

          // Legend Row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: displayedInsights.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final color = _palette[idx % _palette.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.technology,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.percentage.toStringAsFixed(0)}% (${item.totalHours}h)',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withAlpha(140),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
