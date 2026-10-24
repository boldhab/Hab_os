import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/search/global_search_modal.dart';

/// Interactive top AppBar search bar that replaces the static search icon button (UC-167).
///
/// Features:
/// - Responsive width scaling (compact on mobile, extended pill with shortcut on desktop/web)
/// - Adaptive hint text
/// - Platform-aware shortcut indicator (⌘K on Apple platforms, Ctrl+K on other platforms)
/// - Keyboard shortcut listening (⌘K / Ctrl+K)
/// - Smooth hover state and micro-interactions
/// - Direct trigger to [GlobalSearchModal]
class AppBarSearchBar extends StatefulWidget {
  final double? width;
  final double height;
  final String? hintText;
  final VoidCallback? onTap;

  const AppBarSearchBar({
    super.key,
    this.width,
    this.height = 38.0,
    this.hintText,
    this.onTap,
  });

  @override
  State<AppBarSearchBar> createState() => _AppBarSearchBarState();
}

class _AppBarSearchBarState extends State<AppBarSearchBar> {
  bool _isHovered = false;

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      GlobalSearchModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive width calculation
    final double effectiveWidth = widget.width ??
        (screenWidth > 900
            ? 280.0
            : screenWidth > 600
                ? 220.0
                : screenWidth > 380
                    ? 165.0
                    : 135.0);

    // Adaptive hint based on available width
    final String effectiveHint = widget.hintText ??
        (effectiveWidth >= 240
            ? 'Search tasks, projects, notes...'
            : effectiveWidth >= 155
                ? 'Search HabOS...'
                : 'Search...');

    final isApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final shortcutLabel = isApple ? '⌘K' : 'Ctrl K';
    final showShortcut = effectiveWidth >= 210;

    return Center(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): _handleTap,
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _handleTap,
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Tooltip(
            message: 'Search HabOS ($shortcutLabel)',
            waitDuration: const Duration(milliseconds: 600),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: effectiveWidth,
              height: widget.height,
              margin: const EdgeInsets.only(right: 6.0),
              decoration: BoxDecoration(
                color: _isHovered
                    ? (isDark
                        ? colorScheme.surfaceContainerHighest.withAlpha(120)
                        : colorScheme.surfaceContainerHighest.withAlpha(170))
                    : (isDark
                        ? colorScheme.surfaceContainerHighest.withAlpha(65)
                        : colorScheme.surfaceContainerHighest.withAlpha(100)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered
                      ? colorScheme.primary.withAlpha(140)
                      : colorScheme.outlineVariant.withAlpha(isDark ? 60 : 90),
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _handleTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: _isHovered
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withAlpha(200),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            effectiveHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withAlpha(160),
                            ),
                          ),
                        ),
                        if (showShortcut) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha(22)
                                  : Colors.black.withAlpha(14),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withAlpha(isDark ? 70 : 90),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              shortcutLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color:
                                    colorScheme.onSurfaceVariant.withAlpha(210),
                                letterSpacing: 0.2,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
