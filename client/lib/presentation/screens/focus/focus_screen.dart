import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/focus_provider.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  static const _categories = [
    {'id': 'CODING', 'label': 'Coding', 'icon': Icons.code_rounded},
    {'id': 'STUDY', 'label': 'Study', 'icon': Icons.menu_book_rounded},
    {'id': 'PROJECT', 'label': 'Project', 'icon': Icons.work_outline_rounded},
    {'id': 'READING', 'label': 'Reading', 'icon': Icons.book_outlined},
    {'id': 'OTHER', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  static const _durations = [15, 25, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadTodayData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadTodayData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // ── Category Selector Pills ────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((c) {
                    final selected = state.category == c['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(c['icon'] as IconData, size: 16),
                        label: Text(c['label'] as String),
                        selected: selected,
                        onSelected: (_) => notifier.setCategory(c['id'] as String),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // ── Circular Pomodoro Timer ─────────────────────────────────────
              _TimerGauge(state: state, colorScheme: colorScheme),
              const SizedBox(height: 20),

              // ── Duration Presets (Only visible when idle) ───────────────────
              if (state.status == PomodoroStatus.idle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _durations.map((d) {
                    final selected = state.targetMinutes == d;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ActionChip(
                        label: Text('$d min'),
                        backgroundColor: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        side: BorderSide.none,
                        onPressed: () => notifier.setDuration(d),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // ── Control Buttons ────────────────────────────────────────────
              _buildControlButtons(context, state, notifier, colorScheme),
              const SizedBox(height: 28),

              // ── Today's Stats Card ──────────────────────────────────────────
              _buildStatsSummaryCard(context, state, colorScheme),
              const SizedBox(height: 20),

              // ── Today's Completed Sessions List ────────────────────────────
              _buildSessionsList(context, state, notifier, colorScheme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    FocusState state,
    FocusNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.status == PomodoroStatus.running) ...[
          FloatingActionButton.large(
            heroTag: 'pauseBtn',
            onPressed: () => notifier.pauseTimer(),
            backgroundColor: colorScheme.tertiaryContainer,
            child: Icon(Icons.pause_rounded,
                size: 36, color: colorScheme.onTertiaryContainer),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => notifier.finishAndSaveSession(),
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Finish Session'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ] else if (state.status == PomodoroStatus.paused) ...[
          FloatingActionButton.large(
            heroTag: 'resumeBtn',
            onPressed: () => notifier.startTimer(),
            child: const Icon(Icons.play_arrow_rounded, size: 36),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => notifier.resetTimer(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => notifier.finishAndSaveSession(),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save'),
          ),
        ] else ...[
          FloatingActionButton.large(
            heroTag: 'startBtn',
            onPressed: () => notifier.startTimer(),
            child: const Icon(Icons.play_arrow_rounded, size: 40),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSummaryCard(
    BuildContext context,
    FocusState state,
    ColorScheme colorScheme,
  ) {
    final stats = state.todayStats;
    final totalMins = stats?.totalMinutesToday ?? 0;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final count = stats?.totalSessionsToday ?? state.todaySessions.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timer_rounded,
                        color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Focus Today',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        timeStr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 36, width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_fire_department_rounded,
                        color: colorScheme.tertiary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessions',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(
    BuildContext context,
    FocusState state,
    FocusNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Focus Sessions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (state.todaySessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 36, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  'No focus sessions completed today yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
              final s = state.todaySessions[index];
              final mins = s.durationMinutes ?? 0;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: colorScheme.tertiary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.category,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (s.notes != null && s.notes!.isNotEmpty)
                            Text(
                              s.notes!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '$mins min',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      onPressed: () => notifier.deleteSession(s.id),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TimerGauge extends StatelessWidget {
  final FocusState state;
  final ColorScheme colorScheme;

  const _TimerGauge({required this.state, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final totalSecs = state.targetMinutes * 60;
    final progress = totalSecs > 0 ? state.remainingSeconds / totalSecs : 0.0;
    final mins = state.remainingSeconds ~/ 60;
    final secs = state.remainingSeconds % 60;
    final formattedTime =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _CircularTimerPainter(
          progress: progress,
          trackColor: colorScheme.primary.withAlpha(30),
          fillColor: state.status == PomodoroStatus.paused
              ? colorScheme.tertiary
              : colorScheme.primary,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.status == PomodoroStatus.running
                      ? 'FOCUSING'
                      : state.status == PomodoroStatus.paused
                          ? 'PAUSED'
                          : 'READY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  const _CircularTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 12;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}
