import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/task_model.dart';

void main() {
  group('TaskModel', () {
    test('should parse from valid JSON with relations', () {
      final json = {
        'id': 'task-101',
        'title': 'Implement tests',
        'description': 'Write full unit tests',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'isCompleted': false,
        'dueDate': '2026-09-01T12:00:00.000Z',
        'estimatedMinutes': 60,
        'actualMinutes': 45,
        'tags': ['flutter', 'test'],
        'recurrence': 'NONE',
        'project': {
          'id': 'proj-1',
          'title': 'HABos Client',
          'color': '#4285F4',
        },
        'goal': {
          'id': 'goal-1',
          'title': 'Ship HABos 1.0',
        },
        'focusSessions': [
          {
            'id': 'f-1',
            'category': 'CODING',
            'durationMinutes': 25,
            'startTime': '2026-08-31T14:00:00.000Z',
          }
        ],
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, 'task-101');
      expect(task.title, 'Implement tests');
      expect(task.priority, 'HIGH');
      expect(task.status, 'IN_PROGRESS');
      expect(task.isCompleted, isFalse);
      expect(task.estimatedMinutes, 60);
      expect(task.actualMinutes, 45);
      expect(task.tags, contains('flutter'));
      expect(task.project?.title, 'HABos Client');
      expect(task.goal?.title, 'Ship HABos 1.0');
      expect(task.focusSessions.length, 1);
      expect(task.focusSessions.first.durationMinutes, 25);
    });

    test('should support copyWith correctly', () {
      const task = TaskModel(
        id: 't-1',
        title: 'Initial Title',
        priority: 'MEDIUM',
        status: 'TODO',
        isCompleted: false,
      );

      final updated = task.copyWith(
        isCompleted: true,
        status: 'COMPLETED',
      );

      expect(updated.id, 't-1');
      expect(updated.title, 'Initial Title');
      expect(updated.isCompleted, isTrue);
      expect(updated.status, 'COMPLETED');
    });
  });
}
