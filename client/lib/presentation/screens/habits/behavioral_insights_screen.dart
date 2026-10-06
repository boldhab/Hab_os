import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_semantic_colors.dart';
import '../../../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';

/// Dedicated screen detailing behavioral habit correlations, lift percentages,
/// and habit-stacking synergy recommendations.
class BehavioralInsightsScreen extends ConsumerWidget {
  const BehavioralInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsProvider);
    final correlations = state.correlations;
    final habits = state.habits;
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    // Helper map of habit ID to habit name
    final Map<String, String> habitNameMap = {
      for (final h in habits) h.id: h.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Insights'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Insights',
            onPressed: () =>
                ref.read(habitsProvider.notifier).loadCorrelations(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(habitsProvider.notifier).loadCorrelations(),
        child: correlations.isEmpty
            ? _buildEmptyState(context, colorScheme)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 40),
                itemCount: correlations.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(
                            context, colorScheme, correlations.length),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Icon(Icons.hub_rounded,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'DISCOVERED HABIT SYNERGIES',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    );
                  }

                  final correlation = correlations[index - 1];
                  return _buildCorrelationCard(
                    context: context,
                    correlation: correlation,
                    habitNameMap: habitNameMap,
                    colorScheme: colorScheme,
                    semantics: semantics,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeroCard(
      BuildContext context, ColorScheme colorScheme, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withAlpha(120),
            colorScheme.surfaceContainerHighest.withAlpha(90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insights_rounded,
                    color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habit Stacking Matrix',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$count synergistic connection${count == 1 ? "" : "s"} identified',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The engine continuously monitors cross-habit completion rates. '
            'When two habits frequently happen together, stacking them in a sequential routine boosts overall consistency.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard({
    required BuildContext context,
    required HabitCorrelationModel correlation,
    required Map<String, String> habitNameMap,
    required ColorScheme colorScheme,
    required AppSemanticColors semantics,
  }) {
    final habitAName = habitNameMap[correlation.habitAId] ?? 'Primary Habit';
    final habitBName = habitNameMap[correlation.habitBId] ?? 'Linked Habit';
    final isPositive = correlation.liftPercent >= 0;
    final liftPercent = correlation.liftPercent;
    final conditionalPct = (correlation.probBGivenA * 100).round();

    final statusColor = isPositive ? semantics.success : semantics.warning;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Synergy Flow Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          habitAName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          habitBName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(70)),
                  ),
                  child: Text(
                    isPositive ? '+$liftPercent% Lift' : '$liftPercent% Lift',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Expressive Explanation Text
            Text(
              correlation.insightText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),

            // Metric Breakdown Deck
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricColumn(
                    context,
                    label: 'Conditional Likelihood',
                    value: '$conditionalPct%',
                    subtext: 'P($habitBName | $habitAName)',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: colorScheme.outlineVariant.withAlpha(90),
                  ),
                  _metricColumn(
                    context,
                    label: 'Pattern Lift',
                    value: '${correlation.liftPercent >= 0 ? "+" : ""}${(correlation.liftPercent / 100.0).toStringAsFixed(2)}x',
                    subtext: 'Multiplier vs baseline',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: colorScheme.outlineVariant.withAlpha(90),
                  ),
                  _metricColumn(
                    context,
                    label: 'Strength',
                    value: correlation.liftPercent >= 40 ? 'High' : 'Moderate',
                    subtext: 'Statistical signal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Stacking Recommendation Pill
            Row(
              children: [
                Icon(Icons.auto_fix_high_rounded,
                    size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tip: Create a ritual grouping "$habitAName" immediately before "$habitBName".',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricColumn(
    BuildContext context, {
    required String label,
    required String value,
    required String subtext,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bubble_chart_outlined,
                size: 56, color: colorScheme.primary.withAlpha(150)),
            const SizedBox(height: 16),
            const Text(
              'No habit correlations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'As you log habits over consecutive days, the engine analyzes your completion patterns to uncover behavioral synergies.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
