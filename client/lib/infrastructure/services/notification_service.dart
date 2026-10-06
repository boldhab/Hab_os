import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/habit_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

/// Production-ready background notification scheduler for daily/weekly habit reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _channelId = 'habit_reminders_channel';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription =
      'Notifications reminding you to complete your daily and weekly habits';

  static const String _timerChannelId = 'time_tracker_channel';
  static const String _timerChannelName = 'Live Time Tracker';
  static const String _timerChannelDescription =
      'Ongoing active stopwatch tracking notification';
  static const int _timerNotificationId = 999901;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          developer.log('Habit notification tapped: ${response.payload}');
        },
      );

      // Create Android channel
      final androidPlatformChannelSpecifics =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatformChannelSpecifics != null) {
        await androidPlatformChannelSpecifics.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
        await androidPlatformChannelSpecifics.createNotificationChannel(
          const AndroidNotificationChannel(
            _timerChannelId,
            _timerChannelName,
            description: _timerChannelDescription,
            importance: Importance.low,
          ),
        );
        // Request notification permissions for Android 13+
        await androidPlatformChannelSpecifics.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e, stack) {
      developer.log('Failed to initialize NotificationService: $e',
          error: e, stackTrace: stack);
    }
  }

  int _getNotificationId(String habitId) {
    // Non-overflowing 31-bit positive integer hash (avoids abs(-2^31) overflow bug)
    return habitId.hashCode & 0x7FFFFFFF;
  }

  /// Schedules or updates a recurring daily/weekly reminder for a habit
  Future<void> scheduleHabitReminder(HabitModel habit) async {
    if (!habit.isActive ||
        habit.reminderTime == null ||
        habit.reminderTime!.trim().isEmpty) {
      await cancelHabitReminder(habit.id);
      return;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }

      final timeParts = _parseReminderTime(habit.reminderTime!);
      if (timeParts == null) return;

      final hour = timeParts.$1;
      final minute = timeParts.$2;

      final scheduledDate = _nextInstanceOfTime(hour, minute);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = _getNotificationId(habit.id);

      final subtitle = habit.targetType == 'COUNT'
          ? 'Target: ${habit.targetValue} reps! Tap to log progress.'
          : (habit.targetType == 'DURATION'
              ? 'Target: ${habit.targetValue} mins! Tap to start.'
              : 'Keep your ${habit.currentStreak}-day streak alive! Tap to complete.');

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          '⏰ Reminder: ${habit.name}',
          subtitle,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: habit.id,
        );
      } catch (scheduleException) {
        // Fallback for Android 13/14+ if SCHEDULE_EXACT_ALARM permission is revoked
        developer.log('Exact alarm scheduling denied, falling back to inexact: $scheduleException');
        await _notificationsPlugin.zonedSchedule(
          id,
          '⏰ Reminder: ${habit.name}',
          subtitle,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: habit.id,
        );
      }
    } catch (e, stack) {
      developer.log('Error scheduling habit reminder for ${habit.id}: $e',
          error: e, stackTrace: stack);
    }
  }

  /// Cancels an active habit reminder by habit id
  Future<void> cancelHabitReminder(String habitId) async {
    try {
      final id = _getNotificationId(habitId);
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      developer.log('Error canceling habit reminder: $e');
    }
  }

  /// Batch syncs all reminders against current habit state
  Future<void> syncHabitReminders(List<HabitModel> habits) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      for (final habit in habits) {
        if (habit.isActive &&
            habit.reminderTime != null &&
            habit.reminderTime!.isNotEmpty) {
          await scheduleHabitReminder(habit);
        } else {
          await cancelHabitReminder(habit.id);
        }
      }
    } catch (e) {
      developer.log('Error syncing habit reminders: $e');
    }
  }

  (int, int)? _parseReminderTime(String timeStr) {
    try {
      if (timeStr.contains('T')) {
        final dt = DateTime.parse(timeStr);
        return (dt.hour, dt.minute);
      }
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        if (h >= 0 && h < 24 && m >= 0 && m < 60) {
          return (h, m);
        }
      }
    } catch (_) {}
    return null;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      // Direct calendar day + 1 addition accounts for daylight saving transitions
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return scheduledDate;
  }

  /// Displays or updates ongoing persistent notification for the active Time Tracker stopwatch
  Future<void> showTimeTrackerNotification({
    required String taskTitle,
    required String formattedElapsed,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      const androidDetails = AndroidNotificationDetails(
        _timerChannelId,
        _timerChannelName,
        channelDescription: _timerChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        _timerNotificationId,
        '⏱️ $formattedElapsed — Recording Time',
        taskTitle,
        details,
      );
    } catch (e) {
      developer.log('Error showing timer notification: $e');
    }
  }

  /// Cancels the ongoing Time Tracker notification when the timer is stopped or deleted
  Future<void> cancelTimeTrackerNotification() async {
    try {
      await _notificationsPlugin.cancel(_timerNotificationId);
    } catch (e) {
      developer.log('Error canceling timer notification: $e');
    }
  }
}
