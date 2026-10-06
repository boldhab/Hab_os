import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/dev_integrations_model.dart';
import '../../../providers/dev_integrations_provider.dart';
import 'leetcode_sync_dialog.dart';

/// LeetCode stats breakdown widget showing Easy/Medium/Hard counts and daily streaks (UC-60 to UC-64)
class LeetCodeStatsCard extends ConsumerWidget {
  final bool compact;

  const LeetCodeStatsCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(leetCodeStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return statsAsync.when(
      loading: () => Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.error.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unable to load LeetCode stats: $err',
                style: TextStyle(fontSize: 12, color: colorScheme.onErrorContainer),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: () => ref.read(leetCodeStatsProvider.notifier).loadStats(),
            ),
          ],
        ),
      ),
      data: (stats) {
        if (stats == null) {
          return _buildNotConnectedCard(context, ref, colorScheme, isDark);
        }
        return _buildStatsCard(context, ref, stats, colorScheme, isDark);
      },
    );
  }

  Widget _buildNotConnectedCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA116).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFA116).withAlpha(60)),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Color(0xFFFFA116),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LeetCode Integration',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Track problem difficulty progress & daily streaks',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => LeetCodeSyncDialog.show(context),
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Connect'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    WidgetRef ref,
    LeetCodeStatsModel stats,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final total = stats.computedTotal;
    const easyColor = Color(0xFF00B8A3);
    const mediumColor = Color(0xFFFFC01E);
    const hardColor = Color(0xFFFF375F);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA116).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: Color(0xFFFFA116),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LeetCode Stats',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@${stats.username}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withAlpha(160),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.deepOrange.withAlpha(80),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.deepOrange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.currentStreak}d streak',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.sync_rounded, size: 18),
                tooltip: 'Sync LeetCode profile',
                splashRadius: 16,
                onPressed: () => LeetCodeSyncDialog.show(context, initialStats: stats),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Total Solved & Proportional Multi-Segment Gauge
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Problems Solved',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ),
              const Spacer(),
              if (stats.longestStreak > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Best: ${stats.longestStreak}d',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Multi-Segment Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  if (stats.easyRatio > 0)
                    Expanded(
                      flex: (stats.easyRatio * 1000).toInt(),
                      child: Container(color: easyColor),
                    ),
                  if (stats.mediumRatio > 0)
                    Expanded(
                      flex: (stats.mediumRatio * 1000).toInt(),
                      child: Container(color: mediumColor),
                    ),
                  if (stats.hardRatio > 0)
                    Expanded(
                      flex: (stats.hardRatio * 1000).toInt(),
                      child: Container(color: hardColor),
                    ),
                  if (total == 0)
                    Expanded(
                      child: Container(
                        color: colorScheme.outlineVariant.withAlpha(60),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Difficulty Metric Pills
          Row(
            children: [
              Expanded(
                child: _buildDifficultyChip(
                  label: 'Easy',
                  count: stats.easySolved,
                  accentColor: easyColor,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDifficultyChip(
                  label: 'Medium',
                  count: stats.mediumSolved,
                  accentColor: mediumColor,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDifficultyChip(
                  label: 'Hard',
                  count: stats.hardSolved,
                  accentColor: hardColor,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip({
    required String label,
    required int count,
    required Color accentColor,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(isDark ? 25 : 16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withAlpha(isDark ? 60 : 40),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
