import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/domain/models/retrospective_model.dart';

void main() {
  group('RetrospectiveModel & Domain Trend Entities Serialization', () {
    test('hydrates completedTasks, comparison deltas, and multiDomain trend charts correctly', () {
      final json = {
        'period': 'WEEKLY',
        'summary': {
          'totalFocusHours': 4.5,
          'totalTrackedHours': 5.0,
          'completedTasksCount': 2,
          'workoutsCount': 3,
          'habitsCompletedCount': 14,
        },
        'comparison': [
          {
            'metric': 'Focus Time',
            'current': 4.5,
            'previous': 3.0,
            'unit': 'hrs',
            'deltaPercentage': 50.0,
          },
        ],
        'dailyFocusHours': {
          '2026-09-28': 1.0,
          '2026-09-29': 2.0,
          '2026-09-30': 1.5,
        },
        'completedTasks': [
          {'id': 'task-1', 'title': 'Implement AIS Metric', 'priority': 'HIGH'},
        ],
        'multiDomain': {
          'study': {
            'totalHours': 6.5,
            'sessionCount': 4,
            'byCourse': [
              {
                'courseName': 'Operating Systems',
                'code': 'CS-601',
                'color': '#8B5CF6',
                'hours': 4.0,
                'sessionsCount': 2,
              },
            ],
          },
          'coding': {
            'totalCommits': 42,
            'currentStreak': 8,
            'leetcodeTotal': 120,
            'leetcodeEasy': 40,
            'leetcodeMedium': 60,
            'leetcodeHard': 20,
          },
          'finance': {
            'totalIncome': 4000.0,
            'totalExpense': 1500.0,
            'netSavings': 2500.0,
            'transactionCount': 10,
            'spendingByCategory': [
              {
                'name': 'Food & Dining',
                'color': '#F59E0B',
                'amount': 450.0,
                'percentage': 30.0,
              },
            ],
          },
          'gym': {
            'workoutsCount': 3,
            'strengthProgression': [
              {
                'exerciseName': 'Barbell Bench Press',
                'weightKg': 100.0,
                'repetitions': 5,
                'oneRepMax': 112.5,
                'date': '2026-10-02',
              },
            ],
          },
          'productivity': {
            'morningHours': 2.5,
            'afternoonHours': 1.5,
            'eveningHours': 0.5,
            'nightHours': 0.0,
            'peakWindow': 'Morning (6 AM - 12 PM)',
          },
        },
      };

      final model = RetrospectiveModel.fromJson(json);

      expect(model.period, 'WEEKLY');
      expect(model.totalFocusHours, 4.5);
      expect(model.multiDomain, isNotNull);
      expect(model.multiDomain!.studyByCourse.length, 1);
      expect(model.multiDomain!.studyByCourse[0].courseName, 'Operating Systems');
      expect(model.multiDomain!.spendingByCategory.length, 1);
      expect(model.multiDomain!.spendingByCategory[0].name, 'Food & Dining');
      expect(model.multiDomain!.strengthProgression.length, 1);
      expect(model.multiDomain!.strengthProgression[0].oneRepMax, 112.5);
      expect(model.multiDomain!.productivity, isNotNull);
      expect(model.multiDomain!.productivity!.peakWindow, 'Morning (6 AM - 12 PM)');
    });
  });
}
