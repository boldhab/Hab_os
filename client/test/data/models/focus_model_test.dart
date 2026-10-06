import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/focus_session_model.dart';

void main() {
  group('FocusStatsModel Contract & Deserialization', () {
    test('parses real server response with rich period stats and WELLNESS category', () {
      final serverResponse = {
        'today': {
          'minutes': 120,
          'hours': 2.0,
          'sessionsCount': 3,
        },
        'thisWeek': {
          'minutes': 350,
          'hours': 5.8,
          'sessionsCount': 8,
        },
        'thisMonth': {
          'minutes': 1200,
          'hours': 20.0,
          'sessionsCount': 25,
        },
        'totalMinutesToday': 120,
        'totalSessionsToday': 3,
        'categoryBreakdown': {
          'CODING': 200,
          'STUDY': 60,
          'PROJECT': 45,
          'READING': 0,
          'WELLNESS': 45,
          'OTHER': 0,
        },
      };

      final stats = FocusStatsModel.fromJson(serverResponse);

      expect(stats.totalMinutesToday, 120);
      expect(stats.totalSessionsToday, 3);
      expect(stats.today.minutes, 120);
      expect(stats.today.hours, 2.0);
      expect(stats.today.sessionsCount, 3);

      expect(stats.thisWeek.minutes, 350);
      expect(stats.thisWeek.hours, 5.8);
      expect(stats.thisWeek.sessionsCount, 8);

      expect(stats.thisMonth.minutes, 1200);
      expect(stats.thisMonth.hours, 20.0);
      expect(stats.thisMonth.sessionsCount, 25);

      expect(stats.categoryBreakdown['CODING'], 200);
      expect(stats.categoryBreakdown['WELLNESS'], 45);
      expect(stats.categoryBreakdown['READING'], 0);
    });

    test('parses response when top-level totals are missing by extracting from today map', () {
      final responseWithoutTopLevel = {
        'today': {
          'minutes': 75,
          'hours': 1.3,
          'sessionsCount': 2,
        },
        'categoryBreakdown': {
          'CODING': 75,
        },
      };

      final stats = FocusStatsModel.fromJson(responseWithoutTopLevel);

      expect(stats.totalMinutesToday, 75);
      expect(stats.totalSessionsToday, 2);
      expect(stats.today.minutes, 75);
      expect(stats.today.sessionsCount, 2);
      expect(stats.categoryBreakdown['CODING'], 75);
    });
  });

  group('FocusSessionModel Deserialization', () {
    test('parses complete focus session with lifecycle status, courseId and timeEntryId', () {
      final json = {
        'id': 'fs-123',
        'category': 'WELLNESS',
        'status': 'COMPLETED',
        'startTime': '2026-10-03T08:00:00.000Z',
        'endTime': '2026-10-03T08:30:00.000Z',
        'durationMinutes': 30,
        'taskId': 'task-abc',
        'courseId': 'course-xyz',
        'timeEntryId': 'te-999',
        'notes': 'Morning meditation and breathwork',
        'createdAt': '2026-10-03T08:00:00.000Z',
      };

      final session = FocusSessionModel.fromJson(json);

      expect(session.id, 'fs-123');
      expect(session.category, 'WELLNESS');
      expect(session.status, 'COMPLETED');
      expect(session.durationMinutes, 30);
      expect(session.taskId, 'task-abc');
      expect(session.courseId, 'course-xyz');
      expect(session.timeEntryId, 'te-999');
      expect(session.notes, 'Morning meditation and breathwork');
    });

    test('defaults status to COMPLETED when omitted for backwards compatibility', () {
      final json = {
        'id': 'fs-456',
        'category': 'CODING',
        'startTime': '2026-10-03T10:00:00.000Z',
      };

      final session = FocusSessionModel.fromJson(json);

      expect(session.id, 'fs-456');
      expect(session.status, 'COMPLETED');
      expect(session.category, 'CODING');
    });
  });
}
