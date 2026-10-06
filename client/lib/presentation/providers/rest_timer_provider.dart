import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 90,
    this.isRunning = false,
    this.isCompleted = false,
  });

  bool get isActive => isRunning || (remainingSeconds < totalSeconds && remainingSeconds > 0);

  double get progress =>
      totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

  String get formattedTime {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  RestTimerNotifier() : super(const RestTimerState());

  void startTimer(int seconds) {
    _timer?.cancel();
    state = state.copyWith(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      isCompleted: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          isCompleted: true,
        );
        _triggerHardwareAlert();
      } else {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          isRunning: true,
          isCompleted: false,
        );
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resumeTimer() {
    if (state.remainingSeconds > 0) {
      _startTicking();
    }
  }

  void addTime(int additionalSeconds) {
    final newRemaining = state.remainingSeconds + additionalSeconds;
    final newTotal = state.totalSeconds + additionalSeconds;
    state = state.copyWith(
      totalSeconds: newTotal,
      remainingSeconds: newRemaining,
      isCompleted: false,
    );
    if (!state.isRunning) {
      _startTicking();
    }
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      isRunning: false,
      isCompleted: false,
    );
  }

  void dismiss() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      isRunning: false,
      isCompleted: false,
    );
  }

  void _startTicking() {
    _timer?.cancel();
    state = state.copyWith(isRunning: true, isCompleted: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          isCompleted: true,
        );
        _triggerHardwareAlert();
      } else {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          isRunning: true,
          isCompleted: false,
        );
      }
    });
  }

  void _triggerHardwareAlert() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);

    // Multi-pulse tactile notification
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      HapticFeedback.vibrate();
    });

    try {
      const androidDetails = AndroidNotificationDetails(
        'gym_rest_timer_channel',
        'Rest Timer Alert',
        channelDescription: 'Alerts when your rest interval countdown completes',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      _notificationsPlugin.show(
        99901,
        '⏰ Rest Complete!',
        'Your rest period has ended. Time for your next set!',
        notificationDetails,
      );
    } catch (_) {
      // Local notification fallback ignored if not initialized
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>(
  (ref) => RestTimerNotifier(),
);
