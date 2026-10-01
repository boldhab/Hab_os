import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../data/models/focus_session_model.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/focus_provider.dart';

class FocusTimerGauge extends StatefulWidget {
  final FocusState state;
  final Animation<double> pulseAnimation;

  const FocusTimerGauge({
    super.key,
    required this.state,
    required this.pulseAnimation,
  });

  @override
  State<FocusTimerGauge> createState() => _FocusTimerGaugeState();
}

class _FocusTimerGaugeState extends State<FocusTimerGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(FocusTimerGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.status == PomodoroStatus.paused) {
      if (!_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      }
    } else {
      if (_blinkController.isAnimating) {
        _blinkController.stop();
        _blinkController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toUpperCase()) {
      'CODING' => Icons.code_rounded,
      'STUDY' => Icons.menu_book_rounded,
      'PROJECT' => Icons.work_outline_rounded,
      'READING' => Icons.book_outlined,
      _ => Icons.more_horiz_rounded,
    };
  }

  String _formatCategoryLabel(String category) {
    if (category.isEmpty) return 'Focus';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final totalSecs = state.targetMinutes * 60;
    final progress = totalSecs > 0 ? state.remainingSeconds / totalSecs : 0.0;

    final mins = state.remainingSeconds ~/ 60;
    final secs = state.remainingSeconds % 60;
    final formattedTime =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final isRunning = state.status == PomodoroStatus.running;
    final isPaused = state.status == PomodoroStatus.paused;

    final statusCaption = switch (state.status) {
      PomodoroStatus.running => 'Focusing',
      PomodoroStatus.paused => 'Paused',
      PomodoroStatus.completed => 'Completed',
      _ => 'Ready',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final gaugeSize = math.min(constraints.maxWidth - 32, 280.0);

        return AnimatedBuilder(
          animation:
              Listenable.merge([widget.pulseAnimation, _blinkController]),
          builder: (context, child) {
            final scale = isRunning ? widget.pulseAnimation.value : 1.0;
            final textOpacity =
                isPaused ? (0.4 + 0.6 * _blinkController.value) : 1.0;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: gaugeSize,
                height: gaugeSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(gaugeSize, gaugeSize),
                        painter: _TimerRingPainter(
                          progress: progress,
                          trackColor: colorScheme.outlineVariant.withAlpha(30),
                          activeColor:
                              isPaused ? primaryRed.withAlpha(140) : primaryRed,
                          secondaryColor: primaryRed.withAlpha(160),
                          isRunning: isRunning,
                          isPaused: isPaused,
                          glowIntensity:
                              isRunning ? widget.pulseAnimation.value : 1.0,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: textOpacity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: gaugeSize > 240 ? 56 : 48,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -1.5,
                              color: colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(state.category),
                                size: 14,
                                color:
                                    colorScheme.onSurfaceVariant.withAlpha(180),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatCategoryLabel(state.category),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant
                                      .withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusCaption.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: isRunning
                                  ? primaryRed
                                  : isPaused
                                      ? colorScheme.secondary
                                      : colorScheme.onSurfaceVariant
                                          .withAlpha(120),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color activeColor;
  final Color secondaryColor;
  final bool isRunning;
  final bool isPaused;
  final double glowIntensity;

  const _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.secondaryColor,
    required this.isRunning,
    required this.isPaused,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 18;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // 1. Minute Ticks (60 ticks around the ring)
    final tickPaint = Paint()
      ..color = trackColor.withAlpha(60)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = startAngle + (i * (2 * math.pi / 60));
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? 6.0 : 3.0;
      final outerOffset = Offset(
        cx + (radius + 12) * math.cos(angle),
        cy + (radius + 12) * math.sin(angle),
      );
      final innerOffset = Offset(
        cx + (radius + 12 - tickLen) * math.cos(angle),
        cy + (radius + 12 - tickLen) * math.sin(angle),
      );
      canvas.drawLine(innerOffset, outerOffset, tickPaint);
    }

    // 2. Faint Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 11.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    if (progress <= 0) return;

    // 3. Subtle Ambient Glow (Running state only)
    if (isRunning) {
      final glowPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [activeColor, secondaryColor],
          transform: const GradientRotation(startAngle),
        ).createShader(rect)
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * glowIntensity);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    }

    // 4. Crisp Gradient Progress Stroke
    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: isPaused
            ? [activeColor, activeColor]
            : [activeColor, secondaryColor],
        transform: const GradientRotation(startAngle),
      ).createShader(rect)
      ..strokeWidth = 11.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);

    // 5. Arc End Tick Marker
    final endAngle = startAngle + sweepAngle;
    final endX = cx + radius * math.cos(endAngle);
    final endY = cy + radius * math.sin(endAngle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(endX, endY), 4.0, dotPaint);

    final dotBorderPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(endX, endY), 4.0, dotBorderPaint);
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.isRunning != isRunning ||
      old.isPaused != isPaused ||
      old.glowIntensity != glowIntensity;
}
