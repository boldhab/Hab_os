import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/habit_model.dart';

void main() {
  group('HabitModel', () {
    test('should parse from valid JSON with category and todayLog', () {
      final json = {
        'id': 'habit-1',
        'name': 'Drink 2L Water',
        'frequency': 'DAILY',
        'targetType': 'COUNT',
        'targetValue': 2000,
        'currentStreak': 5,
        'longestStreak': 12,
        'isActive': true,
        'isCompletedToday': true,
        'category': {
          'id': 'cat-1',
          'name': 'Health',
          'color': '#00FF00',
        },
        'todayLog': {
          'id': 'log-1',
          'habitId': 'habit-1',
          'date': '2026-08-31T00:00:00.000Z',
          'value': 2000,
          'isCompleted': true,
        },
      };

      final habit = HabitModel.fromJson(json);

      expect(habit.id, 'habit-1');
      expect(habit.name, 'Drink 2L Water');
      expect(habit.frequency, 'DAILY');
      expect(habit.currentStreak, 5);
      expect(habit.longestStreak, 12);
      expect(habit.isActive, isTrue);
      expect(habit.category?.name, 'Health');
      expect(habit.todayLog?.value, 2000);
      expect(habit.isCompletedToday, isTrue);
    });
  });
}
