import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/focus_session_model.dart';
import '../../../providers/focus_provider.dart';

class FocusSessionHistory extends StatelessWidget {
  final FocusState state;
  final FocusNotifier notifier;

  const FocusSessionHistory({
    super.key,
    required this.state,
    required this.notifier,
  });

  IconData _getCategoryIcon(String category) {
    return switch (category.toUpperCase()) {
      'CODING' => Icons.code_rounded,
      'STUDY' => Icons.menu_book_rounded,
      'PROJECT' => Icons.work_outline_rounded,
      'READING' => Icons.book_outlined,
      _ => Icons.more_horiz_rounded,
    };
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    if (state.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme, 0),
          AppSpacing.verticalGapMd,
          ...List.generate(2, (_) => _buildSkeletonRow(colorScheme)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, colorScheme, state.todaySessions.length),
        AppSpacing.verticalGapSm,
        if (state.todaySessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 36,
                  color: colorScheme.onSurfaceVariant.withAlpha(120),
                ),
                AppSpacing.verticalGapSm,
                Text(
                  'No sessions completed yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your first focus block starts with one tap.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.todaySessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final session = state.todaySessions[index];
              return _buildSessionRow(
                  context, session, colorScheme, primaryRed);
            },
          ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme colorScheme, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count sessions',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionRow(
    BuildContext context,
    FocusSessionModel session,
    ColorScheme colorScheme,
    Color primaryRed,
  ) {
    final mins = session.durationMinutes ?? 0;
    final timeStr = _formatTime(session.startTime);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        AppHaptics.light();
        notifier.deleteSession(session.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                notifier.loadTodayData();
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryRed.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(session.category),
                size: 18,
                color: primaryRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.category[0].toUpperCase() +
                        session.category.substring(1).toLowerCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty)
                    Text(
                      session.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${mins}m',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withAlpha(140),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 58,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
