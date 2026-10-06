import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/retrospective_model.dart';
import '../../infrastructure/services/notification_service.dart';

enum TimePeriod {
  weekly,
  monthly;

  String get apiValue => this == TimePeriod.monthly ? 'MONTHLY' : 'WEEKLY';
  String get label => this == TimePeriod.monthly ? 'Monthly (30D)' : 'Weekly (7D)';
}

/// Active period selection provider
final selectedPeriodProvider = StateProvider<TimePeriod>((ref) => TimePeriod.weekly);

/// Retrospective data provider bound to selected period
final retrospectiveProvider =
    FutureProvider.autoDispose<RetrospectiveModel>((ref) async {
  final dio = ref.watch(dioProvider);
  final period = ref.watch(selectedPeriodProvider);

  final response = await dio.get(
    ApiEndpoints.analyticsRetrospective,
    queryParameters: {
      'period': period.apiValue,
      'timezone': DateTime.now().timeZoneName,
    },
  );

  final data = response.data['data'] ?? response.data;
  return RetrospectiveModel.fromJson(Map<String, dynamic>.from(data));
});

/// Time Tracker State representation
class TimeTrackerState {
  final List<TimeEntryModel> entries;
  final TimeEntryModel? activeEntry;
  final int activeElapsedSeconds;
  final bool isLoading;
  final String? errorMessage;

  const TimeTrackerState({
    this.entries = const [],
    this.activeEntry,
    this.activeElapsedSeconds = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  TimeTrackerState copyWith({
    List<TimeEntryModel>? entries,
    TimeEntryModel? activeEntry,
    bool clearActiveEntry = false,
    int? activeElapsedSeconds,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TimeTrackerState(
      entries: entries ?? this.entries,
      activeEntry: clearActiveEntry ? null : (activeEntry ?? this.activeEntry),
      activeElapsedSeconds: activeElapsedSeconds ?? this.activeElapsedSeconds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Time Tracker Notifier managing Stopwatch engine and time entries CRUD
class TimeTrackerNotifier extends StateNotifier<TimeTrackerState> {
  final Dio _dio;
  final NotificationService _notificationService;
  Timer? _tickerTimer;

  TimeTrackerNotifier(this._dio, this._notificationService)
      : super(const TimeTrackerState()) {
    fetchEntries();
  }

  String _formatElapsed(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _notificationService.cancelTimeTrackerNotification();
    super.dispose();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.activeEntry != null) {
        final now = DateTime.now();
        final diff = now.difference(state.activeEntry!.startTime).inSeconds;
        final elapsed = diff >= 0 ? diff : 0;
        state = state.copyWith(activeElapsedSeconds: elapsed);

        // Update ongoing foreground/system notification every 5 seconds or upon start
        if (elapsed % 5 == 0 || elapsed <= 1) {
          _notificationService.showTimeTrackerNotification(
            taskTitle: state.activeEntry?.taskTitle ?? 'General Activity',
            formattedElapsed: _formatElapsed(elapsed),
          );
        }
      }
    });
  }

  Future<void> fetchEntries() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _dio.get(
        ApiEndpoints.analyticsTime,
        queryParameters: {'limit': 50},
      );
      final rawList = response.data['data']?['entries'] as List? ?? [];
      final entries = rawList
          .map((e) => TimeEntryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final active = entries.cast<TimeEntryModel?>().firstWhere(
            (e) => e != null && e.isActive,
            orElse: () => null,
          );

      state = state.copyWith(
        entries: entries,
        activeEntry: active,
        clearActiveEntry: active == null,
        isLoading: false,
      );

      if (active != null) {
        _startTicker();
      } else {
        _tickerTimer?.cancel();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> startTimer({String? taskId}) async {
    try {
      final now = DateTime.now();
      final response = await _dio.post(
        ApiEndpoints.analyticsTime,
        data: {
          'startTime': now.toIso8601String(),
          'taskId': taskId,
        },
      );
      final newEntry = TimeEntryModel.fromJson(
        Map<String, dynamic>.from(response.data['data']),
      );

      state = state.copyWith(
        activeEntry: newEntry,
        entries: [newEntry, ...state.entries],
        activeElapsedSeconds: 0,
      );
      _startTicker();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> stopActiveTimer() async {
    final active = state.activeEntry;
    if (active == null) return false;

    try {
      final response = await _dio.post(
        ApiEndpoints.analyticsTimeStop(active.id),
      );
      final updated = TimeEntryModel.fromJson(
        Map<String, dynamic>.from(response.data['data']),
      );

      _tickerTimer?.cancel();
      _notificationService.cancelTimeTrackerNotification();
      final updatedList = state.entries
          .map((e) => e.id == updated.id ? updated : e)
          .toList();

      state = state.copyWith(
        clearActiveEntry: true,
        activeElapsedSeconds: 0,
        entries: updatedList,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateEntry(
    String id, {
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? taskId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (startTime != null) data['startTime'] = startTime.toIso8601String();
      if (endTime != null) data['endTime'] = endTime.toIso8601String();
      if (duration != null) data['duration'] = duration;
      if (taskId != null) data['taskId'] = taskId;

      final response = await _dio.put(
        ApiEndpoints.analyticsTimeById(id),
        data: data,
      );
      final updated = TimeEntryModel.fromJson(
        Map<String, dynamic>.from(response.data['data']),
      );

      final updatedList = state.entries
          .map((e) => e.id == updated.id ? updated : e)
          .toList();

      state = state.copyWith(entries: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _dio.delete(ApiEndpoints.analyticsTimeById(id));
      final updatedList = state.entries.where((e) => e.id != id).toList();

      if (state.activeEntry?.id == id) {
        _tickerTimer?.cancel();
        _notificationService.cancelTimeTrackerNotification();
        state = state.copyWith(clearActiveEntry: true, activeElapsedSeconds: 0);
      }

      state = state.copyWith(entries: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final timeTrackerProvider =
    StateNotifierProvider<TimeTrackerNotifier, TimeTrackerState>((ref) {
  final dio = ref.watch(dioProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TimeTrackerNotifier(dio, notificationService);
});
