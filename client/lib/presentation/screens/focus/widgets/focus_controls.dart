import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/focus_provider.dart';

class FocusControls extends StatelessWidget {
  final FocusState state;
  final FocusNotifier notifier;

  const FocusControls({
    super.key,
    required this.state,
    required this.notifier,
  });

  void _confirmReset(BuildContext context) {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppSpacing.verticalGapLg,
              Icon(Icons.refresh_rounded, size: 36, color: colorScheme.primary),
              AppSpacing.verticalGapSm,
              Text(
                'Reset focus session?',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              AppSpacing.verticalGapXs,
              Text(
                'Current elapsed time will be discarded.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGapLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Keep Focusing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        notifier.resetTimer();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Reset Session'),
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalGapSm,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (state.status) {
        PomodoroStatus.running => Row(
            key: const ValueKey('running_controls'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                size: 72,
                color: colorScheme.surfaceContainerHighest,
                iconColor: colorScheme.onSurface,
                icon: Icons.pause_rounded,
                iconSize: 36,
                label: 'Pause',
                onPressed: () {
                  AppHaptics.medium();
                  notifier.pauseTimer();
                },
              ),
              const SizedBox(width: 28),
              _ControlButton(
                size: 56,
                color: primaryRed,
                iconColor: Colors.white,
                icon: Icons.check_rounded,
                iconSize: 28,
                label: 'Finish',
                onPressed: () {
                  AppHaptics.success();
                  notifier.finishAndSaveSession();
                },
              ),
            ],
          ),
        PomodoroStatus.paused => Row(
            key: const ValueKey('paused_controls'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                size: 52,
                color: colorScheme.surfaceContainerHighest,
                iconColor: colorScheme.onSurfaceVariant,
                icon: Icons.refresh_rounded,
                iconSize: 24,
                label: 'Reset',
                onPressed: () => _confirmReset(context),
              ),
              const SizedBox(width: 24),
              _ControlButton(
                size: 72,
                color: primaryRed,
                iconColor: Colors.white,
                icon: Icons.play_arrow_rounded,
                iconSize: 40,
                label: 'Resume',
                onPressed: () {
                  AppHaptics.medium();
                  notifier.startTimer();
                },
              ),
              const SizedBox(width: 24),
              _ControlButton(
                size: 52,
                color: primaryRed.withAlpha(25),
                iconColor: primaryRed,
                icon: Icons.check_rounded,
                iconSize: 26,
                label: 'Save',
                onPressed: () {
                  AppHaptics.success();
                  notifier.finishAndSaveSession();
                },
              ),
            ],
          ),
        _ => Row(
            key: const ValueKey('idle_controls'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                size: 76,
                color: primaryRed,
                iconColor: Colors.white,
                icon: Icons.play_arrow_rounded,
                iconSize: 42,
                label: 'Start Focus',
                elevation: 6,
                onPressed: () {
                  AppHaptics.medium();
                  notifier.startTimer();
                },
              ),
            ],
          ),
      },
    );
  }
}

class _ControlButton extends StatefulWidget {
  final double size;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final double iconSize;
  final String label;
  final double elevation;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.size,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.iconSize,
    required this.label,
    this.elevation = 0,
    required this.onPressed,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: widget.elevation > 0
                    ? [
                        BoxShadow(
                          color: widget.color.withAlpha(80),
                          blurRadius: widget.elevation * 2.5,
                          offset: Offset(0, widget.elevation / 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(180),
          ),
        ),
      ],
    );
  }
}
