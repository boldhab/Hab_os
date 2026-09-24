import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/dashboard_feed_model.dart';

void main() {
  group('DashboardFeedModel', () {
    test('should parse from valid JSON feed', () {
      final json = {
        'user': {
          'name': 'Alex',
          'email': 'alex@example.com',
          'avatarUrl': null,
        },
        'lifeScore': {
          'overallScore': 84.5,
          'level': 'Advanced',
          'components': [
            {'name': 'Habits', 'score': 90.0, 'weight': 25.0},
            {'name': 'Tasks', 'score': 80.0, 'weight': 20.0},
          ],
        },
        'timeline': {
          'tasksDueToday': [
            {
              'id': 'task-1',
              'title': 'Finish review',
              'priority': 'HIGH',
              'status': 'COMPLETED',
              'isCompleted': true,
            }
          ],
        },
        'habits': {
          'total': 3,
          'completedToday': 2,
          'items': [
            {
              'id': 'h-1',
              'name': 'Morning Jog',
              'frequency': 'DAILY',
              'currentStreak': 7,
              'isCompletedToday': true,
            }
          ],
        },
        'projects': [
          {
            'id': 'p-1',
            'title': 'HABos App',
            'status': 'IN_PROGRESS',
            'progress': 75.0,
            '_count': {'tasks': 10, 'features': 4, 'bugs': 1},
          }
        ],
        'fitness': {
          'workoutsThisWeekCount': 3,
          'targetWorkouts': 4,
          'workedOutToday': true,
          'latestWorkout': {'name': 'Push Day'},
        },
        'finance': {
          'spentThisMonth': 450.0,
          'totalBudgetCap': 1000.0,
          'budgetRemaining': 550.0,
          'isWarning': false,
        },
        'aiRecommendation': 'Great consistency! Focus on deep coding next.',
      };

      final feed = DashboardFeedModel.fromJson(json);

      expect(feed.userName, 'Alex');
      expect(feed.lifeScore.overallScore, 84.5);
      expect(feed.lifeScore.level, 'Advanced');
      expect(feed.habits.completedToday, 2);
      expect(feed.tasksDueToday.length, 1);
      expect(feed.tasksDueToday.first.isCompleted, isTrue);
      expect(feed.activeProjects.length, 1);
      expect(feed.activeProjects.first.progress, 75.0);
      expect(feed.fitness.workedOutToday, isTrue);
      expect(feed.fitness.latestWorkoutName, 'Push Day');
      expect(feed.finance.budgetRemaining, 550.0);
      expect(feed.aiRecommendation, contains('Great consistency'));
      expect(feed.recentActivities.length, greaterThanOrEqualTo(2));
    });
  });
}
