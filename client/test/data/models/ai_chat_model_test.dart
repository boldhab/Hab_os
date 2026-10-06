import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/domain/models/ai_chat_model.dart';

void main() {
  group('Conversational AI Assistant Chat Model (UC-131, UC-132, UC-147)', () {
    test('hydrates ChatMessage from assistant API response JSON', () {
      final json = {
        'id': 'msg-123',
        'response': 'You have 3 tasks due today and 2 habits pending.',
        'isUser': false,
        'timestamp': '2026-10-04T12:00:00.000Z',
        'contextScope': 'TASKS',
        'contextSummary': {
          'tasksDue': 3,
          'habitsPending': 2,
          'focusMinutes': 90,
        },
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 'msg-123');
      expect(message.text, 'You have 3 tasks due today and 2 habits pending.');
      expect(message.isUser, isFalse);
      expect(message.contextScope, 'TASKS');
      expect(message.contextSummary, isNotNull);
      expect(message.contextSummary!['tasksDue'], 3);
      expect(message.contextSummary!['habitsPending'], 2);
      expect(message.contextSummary!['focusMinutes'], 90);
    });

    test('hydrates ChatMessage with text key and defaults', () {
      final json = {
        'text': 'What should I do next?',
        'isUser': true,
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, isNotEmpty);
      expect(message.text, 'What should I do next?');
      expect(message.isUser, isTrue);
      expect(message.contextScope, 'ALL');
      expect(message.contextSummary, isNull);
    });

    test('serializes ChatMessage to JSON correctly', () {
      final timestamp = DateTime.parse('2026-10-04T10:00:00.000Z');
      final message = ChatMessage(
        id: 'msg-456',
        text: 'How is my budget?',
        isUser: true,
        timestamp: timestamp,
        contextScope: 'FINANCE',
        contextSummary: {'spent': 250},
      );

      final json = message.toJson();

      expect(json['id'], 'msg-456');
      expect(json['text'], 'How is my budget?');
      expect(json['isUser'], isTrue);
      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['contextScope'], 'FINANCE');
      expect(json['contextSummary'], {'spent': 250});
    });

    test('verifies PromptChipSuggestion defaults cover required domains', () {
      final suggestions = PromptChipSuggestion.defaults;

      expect(suggestions.length, greaterThanOrEqualTo(6));
      expect(suggestions.any((s) => s.scope == 'ALL'), isTrue);
      expect(suggestions.any((s) => s.scope == 'FINANCE'), isTrue);
      expect(suggestions.any((s) => s.scope == 'STUDY'), isTrue);
      expect(suggestions.any((s) => s.scope == 'GYM'), isTrue);
      expect(suggestions.any((s) => s.scope == 'HABITS'), isTrue);
      expect(suggestions.any((s) => s.scope == 'DEV'), isTrue);
    });
  });
}
