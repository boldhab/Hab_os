import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Interactive micro-animated check control for tasks and habits.
/// Provides a spring scale animation, color transition, and tactile haptics.
class AppAnimatedCheck extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isCircle;
  final double size;
  final Color? activeColor;
  final Color? checkColor;

  const AppAnimatedCheck({
    super.key,
    required this.value,
    this.onChanged,
    this.isCircle = false,
    this.size = 22.0,
    this.activeColor,
    this.checkColor,
  });

  @override
  State<AppAnimatedCheck> createState() => _AppAnimatedCheckState();
}

class _AppAnimatedCheckState extends State<AppAnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.value ? 1.0 : 0.0,
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AppAnimatedCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse(from: 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onChanged == null) return;
    final newValue = !widget.value;
    if (newValue) {
      AppHaptics.medium();
    } else {
      AppHaptics.light();
    }
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeBg = widget.activeColor ?? colorScheme.primary;
    final checkIconColor = widget.checkColor ?? colorScheme.onPrimary;

    return GestureDetector(
      onTap: widget.onChanged != null ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.value ? _scaleAnim.value : 1.0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.size * 0.28),
            color: widget.value ? activeBg : Colors.transparent,
            border: Border.all(
              color:
                  widget.value ? activeBg : colorScheme.outline.withAlpha(140),
              width: 1.8,
            ),
          ),
          child: widget.value
              ? Icon(
                  Icons.check_rounded,
                  size: widget.size * 0.65,
                  color: checkIconColor,
                )
              : null,
        ),
      ),
    );
  }
}
