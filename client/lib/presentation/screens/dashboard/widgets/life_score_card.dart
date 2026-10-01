import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/dashboard_feed_model.dart';
import '../../../widgets/common/app_card.dart';

/// Hero Showpiece: Circular Life Score gauge + domain breakdown row/grid.
class LifeScoreCard extends StatelessWidget {
  final LifeScoreModel lifeScore;

  const LifeScoreCard({super.key, required this.lifeScore});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryRed = colorScheme.primary;
    final score = lifeScore.overallScore.clamp(0.0, 100.0);

    return AppCard(
      borderRadius: 24.0,
      enableGlow: true,
      glowColor: primaryRed.withAlpha(isDark ? 25 : 15),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing Gauge
              _GlowingScoreGauge(score: score, colorScheme: colorScheme),
              const SizedBox(width: 14),
              // Level & Domain Component Progress Bars
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Overall Momentum',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryRed.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryRed.withAlpha(45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 11,
                                color: primaryRed,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                lifeScore.level.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: primaryRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...lifeScore.components
                        .take(4)
                        .map((c) => _DomainComponentBar(
                              component: c,
                              colorScheme: colorScheme,
                            )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowingScoreGauge extends StatelessWidget {
  final double score;
  final ColorScheme colorScheme;

  const _GlowingScoreGauge({required this.score, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryRed = colorScheme.primary;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(96, 96),
            painter: _IlluminatedGaugePainter(
              progress: score / 100.0,
              trackColor: isDark
                  ? colorScheme.outlineVariant.withAlpha(50)
                  : colorScheme.outlineVariant.withAlpha(80),
              gradientColors: [
                primaryRed,
                Color.lerp(primaryRed, Colors.orange, 0.4) ?? primaryRed,
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'LIFE SCORE',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IlluminatedGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;

  const _IlluminatedGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 7;
    const startAngle = math.pi * 0.75;
    const totalSweepAngle = math.pi * 1.5;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // 1. Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, startAngle, totalSweepAngle, false, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = totalSweepAngle * progress.clamp(0.0, 1.0);

    // 2. Ambient Glow Pass
    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(startAngle),
      ).createShader(rect)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // 3. Crisp Foreground Arc
    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(startAngle),
      ).createShader(rect)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(_IlluminatedGaugePainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}

class _DomainComponentBar extends StatelessWidget {
  final LifeScoreComponentModel component;
  final ColorScheme colorScheme;

  const _DomainComponentBar(
      {required this.component, required this.colorScheme});

  IconData _getDomainIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fitness') || lower.contains('gym'))
      return Icons.fitness_center_rounded;
    if (lower.contains('finance')) return Icons.account_balance_wallet_rounded;
    if (lower.contains('focus') || lower.contains('deep'))
      return Icons.timer_rounded;
    if (lower.contains('habit')) return Icons.repeat_rounded;
    return Icons.task_alt_rounded;
  }

  Color _getDomainColor(String name, ColorScheme cs) {
    final lower = name.toLowerCase();
    if (lower.contains('fitness') || lower.contains('gym')) return cs.primary;
    if (lower.contains('finance')) return const Color(0xFF34A853);
    if (lower.contains('focus') || lower.contains('deep'))
      return const Color(0xFFFBBC05);
    if (lower.contains('habit')) return const Color(0xFF4285F4);
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (component.score / 100.0).clamp(0.0, 1.0);
    final domainColor = _getDomainColor(component.name, colorScheme);
    final domainIcon = _getDomainIcon(component.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(domainIcon, size: 11, color: domainColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  component.name,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withAlpha(220),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${component.score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: domainColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4.0,
              backgroundColor: colorScheme.outlineVariant.withAlpha(45),
              valueColor: AlwaysStoppedAnimation<Color>(domainColor),
            ),
          ),
        ],
      ),
    );
  }
}
