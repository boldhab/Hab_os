import 'package:flutter/services.dart';

/// Centralized haptic feedback utility for HABos.
/// Provides tactile physical sensations for micro-interactions,
/// completions, selections, timer controls, and celebratory milestones.
class AppHaptics {
  AppHaptics._();

  /// Subtle click for filter chips, tab switches, navigation bar items, and toggles.
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light impact for standard button presses, card taps, and minor actions.
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact for task completions, habit check-ins, and timer play/pause.
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for destructive deletions, resets, and major domain actions.
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Celebratory double-pulse success haptic pattern (Focus session done, goal reached).
  static Future<void> success() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Triple-tap milestone haptic pattern (streak celebration, life score level-up).
  static Future<void> celebration() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Warning / error haptic pattern.
  static Future<void> warning() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Error haptic pattern.
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
