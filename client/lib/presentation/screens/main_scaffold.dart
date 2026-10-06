import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../providers/rest_timer_provider.dart';

/// Floating, non-intrusive bottom notification panel layout
/// visible globally across all application tabs while the gym rest timer ticks down.
class RestTimerFloatingOverlay extends ConsumerWidget {
  final VoidCallback? onTap;

  const RestTimerFloatingOverlay({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final timerNotifier = ref.read(restTimerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    final shouldShow = timerState.isActive || timerState.isCompleted;

    if (!shouldShow) return const SizedBox.shrink();

    final isCompleted = timerState.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: isCompleted
            ? semantics.successContainer
            : colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () => RestTimerModalSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted
                    ? semantics.success
                    : colorScheme.primary.withAlpha(70),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: timerState.progress,
                        strokeWidth: 3.5,
                        backgroundColor: isCompleted
                            ? semantics.success.withAlpha(60)
                            : colorScheme.outlineVariant.withAlpha(60),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? semantics.success : colorScheme.primary,
                        ),
                      ),
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.timer_outlined,
                        size: 18,
                        color: isCompleted
                            ? semantics.onSuccessContainer
                            : colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            timerState.formattedTime,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isCompleted
                                  ? semantics.onSuccessContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompleted ? '• READY!' : (timerState.isRunning ? '• Resting' : '• Paused'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? semantics.success
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isCompleted
                            ? 'Rest finished! Tap for next set'
                            : 'Set rest interval running',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted
                              ? semantics.onSuccessContainer.withAlpha(200)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick Controls
                if (!isCompleted) ...[
                  IconButton(
                    iconSize: 20,
                    icon: Icon(
                      timerState.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: colorScheme.primary,
                    ),
                    onPressed: () {
                      if (timerState.isRunning) {
                        timerNotifier.pauseTimer();
                      } else {
                        timerNotifier.resumeTimer();
                      }
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(40, 32),
                    ),
                    onPressed: () => timerNotifier.addTime(30),
                    child: const Text('+30s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                  onPressed: () => timerNotifier.dismiss(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet for controlling the active rest timer
class RestTimerModalSheet extends ConsumerWidget {
  const RestTimerModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const RestTimerModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final timerNotifier = ref.read(restTimerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final progress = timerState.progress;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In-Workout Rest Timer',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (timerState.isRunning)
                IconButton(
                  icon: const Icon(Icons.pause_rounded),
                  tooltip: 'Pause',
                  onPressed: () => timerNotifier.pauseTimer(),
                )
              else if (timerState.remainingSeconds < timerState.totalSeconds &&
                  timerState.remainingSeconds > 0)
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: 'Resume',
                  onPressed: () => timerNotifier.resumeTimer(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: colorScheme.primaryContainer.withAlpha(80),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timerState.isCompleted
                        ? semantics.success
                        : colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timerState.formattedTime,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    timerState.isCompleted
                        ? 'Rest Complete!'
                        : (timerState.isRunning ? 'Resting...' : 'Ready'),
                    style: TextStyle(
                      fontSize: 12,
                      color: timerState.isCompleted
                          ? semantics.success
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _presetChip(60, '60s', timerNotifier),
              const SizedBox(width: AppSpacing.sm),
              _presetChip(90, '90s', timerNotifier),
              const SizedBox(width: AppSpacing.sm),
              _presetChip(120, '2m', timerNotifier),
              const SizedBox(width: AppSpacing.sm),
              _presetChip(180, '3m', timerNotifier),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Reset'),
                onPressed: () => timerNotifier.resetTimer(),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+30s'),
                onPressed: () => timerNotifier.addTime(30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int secs, String label, RestTimerNotifier notifier) {
    return ActionChip(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      label: Text(label),
      onPressed: () => notifier.startTimer(secs),
    );
  }
}
