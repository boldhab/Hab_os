import 'package:flutter/material.dart';

/// Semantic colors extension for HABos: Success, Warning, Danger, and Info.
///
/// Hand-tuned to integrate harmoniously with HABos's warm ember and charcoal palette
/// without using aggressive, oversaturated primary defaults.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  // ── Success (Forest Sage) ──────────────────────────────────────────────────
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  // ── Warning (Warm Honey / Ochre) ───────────────────────────────────────────
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  // ── Danger (Deep Vermilion / Crimson) ──────────────────────────────────────
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  // ── Info (Calm Slate / Steel) ──────────────────────────────────────────────
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Convenience alias for [danger] to support standard Flutter conventions
  Color get error => danger;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  // ── Light Theme Semantic Palette ───────────────────────────────────────────
  static const light = AppSemanticColors(
    success: Color(0xFF2E6B47),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD6F5E3),
    onSuccessContainer: Color(0xFF072113),
    warning: Color(0xFFB45309),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFEF3C7),
    onWarningContainer: Color(0xFF451A03),
    danger: Color(0xFFC5221F),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFCE8E6),
    onDangerContainer: Color(0xFF49120F),
    info: Color(0xFF1D6F8A),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFD8EEF5),
    onInfoContainer: Color(0xFF09252F),
  );

  // ── Dark Theme Semantic Palette ────────────────────────────────────────────
  static const dark = AppSemanticColors(
    success: Color(0xFF5ABF86),
    onSuccess: Color(0xFF062B17),
    successContainer: Color(0xFF1B4930),
    onSuccessContainer: Color(0xFFD6F5E3),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF451A03),
    warningContainer: Color(0xFF78350F),
    onWarningContainer: Color(0xFFFEF3C7),
    danger: Color(0xFFF28B82),
    onDanger: Color(0xFF49120F),
    dangerContainer: Color(0xFF781E1B),
    onDangerContainer: Color(0xFFFCE8E6),
    info: Color(0xFF67B7D1),
    onInfo: Color(0xFF082732),
    infoContainer: Color(0xFF184B5D),
    onInfoContainer: Color(0xFFD8EEF5),
  );

  /// Quick accessor from BuildContext:
  /// `final semantics = AppSemanticColors.of(context);`
  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer:
          Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
