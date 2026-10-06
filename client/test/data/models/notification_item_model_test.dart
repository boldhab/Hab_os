import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/domain/models/notification_item_model.dart';

void main() {
  group('NotificationItem & Category Domain Logic (UC-159 to UC-166)', () {
    test('hydrates notification from backend JSON and maps categories correctly', () {
      final jsonReminder = {
        'id': 'notif-1',
        'title': 'Task Due Soon: Deploy API',
        'message': 'High priority task due in 2 hours',
        'type': 'TASK_REMINDER',
        'isRead': false,
        'createdAt': '2026-10-04T10:00:00.000Z',
        'metadata': {'taskId': 'task-99'},
      };

      final itemReminder = NotificationItem.fromJson(jsonReminder);
      expect(itemReminder.id, 'notif-1');
      expect(itemReminder.category, NotificationCategory.reminder);
      expect(itemReminder.isRead, isFalse);
      expect(itemReminder.targetRoute, '/tasks/task-99');

      final jsonAlert = {
        'id': 'notif-2',
        'title': 'Streak Alert',
        'message': 'Protect your streak!',
        'type': 'STREAK_ALERT',
        'isRead': true,
        'createdAt': '2026-10-04T10:30:00.000Z',
        'metadata': {'habitId': 'habit-55'},
      };

      final itemAlert = NotificationItem.fromJson(jsonAlert);
      expect(itemAlert.category, NotificationCategory.alert);
      expect(itemAlert.targetRoute, '/habits');

      final jsonAcademic = {
        'id': 'notif-3',
        'title': 'Exam Reminder: CS-701',
        'message': 'Exam scheduled on Thursday',
        'type': 'EXAM_REMINDER',
        'isRead': false,
        'createdAt': '2026-10-04T11:00:00.000Z',
        'metadata': {'examId': 'exam-12'},
      };

      final itemAcademic = NotificationItem.fromJson(jsonAcademic);
      expect(itemAcademic.category, NotificationCategory.academic);
      expect(itemAcademic.targetRoute, '/more/academic');

      final jsonSystem = {
        'id': 'notif-4',
        'title': 'System Maintenance',
        'message': 'Platform updated successfully',
        'type': 'GENERAL',
        'isRead': true,
        'createdAt': '2026-10-04T09:00:00.000Z',
      };

      final itemSystem = NotificationItem.fromJson(jsonSystem);
      expect(itemSystem.category, NotificationCategory.system);
      expect(itemSystem.targetRoute, isNull);
    });

    test('serializes to JSON accurately', () {
      final now = DateTime.parse('2026-10-04T10:00:00.000Z');
      final notif = NotificationItem(
        id: 'notif-10',
        title: 'Budget Alert',
        message: 'Dining budget at 95%',
        type: 'BUDGET_ALERT',
        isRead: false,
        createdAt: now,
        metadata: const {'route': '/more/finance'},
      );

      final json = notif.toJson();
      expect(json['id'], 'notif-10');
      expect(json['type'], 'BUDGET_ALERT');
      expect(json['isRead'], isFalse);
      expect(json['metadata']['route'], '/more/finance');
      expect(notif.targetRoute, '/more/finance');
    });

    test('parses NotificationCategory from strings', () {
      expect(NotificationCategory.fromString('reminder'), NotificationCategory.reminder);
      expect(NotificationCategory.fromString('alert'), NotificationCategory.alert);
      expect(NotificationCategory.fromString('academic'), NotificationCategory.academic);
      expect(NotificationCategory.fromString('system'), NotificationCategory.system);
      expect(NotificationCategory.fromString('all'), NotificationCategory.all);
    });
  });
}
