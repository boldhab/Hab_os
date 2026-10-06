import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/section_header.dart';

class ScheduleTimelineCard extends StatelessWidget {
  final List<DashboardScheduleEvent> events;

  const ScheduleTimelineCard({super.key, required this.events});

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeFormat = DateFormat('hh:mm a');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                icon: Icons.calendar_today_rounded,
                title: "Today's Agenda",
              ),
              if (events.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${events.length} event${events.length > 1 ? "s" : ""}',
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
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No calendar events scheduled for today.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
              itemBuilder: (context, i) {
                final event = events[i];
                final color = _parseColor(event.color);
                final startStr = timeFormat.format(event.startTime);
                final endStr = timeFormat.format(event.endTime);

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '$startStr - $endStr',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (event.location != null &&
                                    event.location!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.place_outlined,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      event.location!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
