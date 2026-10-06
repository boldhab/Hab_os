import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/domain/models/vault_note_model.dart';

void main() {
  group('VaultNote Model & Entities Serialization (UC-120 to UC-130)', () {
    test('hydrates note with code snippets, category, and bidirectional links correctly', () {
      final json = {
        'id': 'note-123',
        'title': 'Distributed Consensus via Raft',
        'content': '# Raft Architecture\nLeader election and log replication algorithm.\n```typescript\nconst term = 1;\n```',
        'tags': ['distributed', 'algorithms', 'consensus'],
        'isMistakeSolution': true,
        'categoryId': 'cat-eng',
        'category': {
          'id': 'cat-eng',
          'name': 'System Architecture',
          'color': '#3B82F6',
          'icon': 'hub',
        },
        'codeSnippets': [
          {
            'language': 'typescript',
            'code': 'function requestVote(candidateId: string, term: number): boolean {\n  return true;\n}',
            'description': 'RPC vote handler',
          },
        ],
        'sourceLinks': [
          {
            'targetNote': {
              'id': 'note-456',
              'title': 'Paxos vs Raft Comparison',
            },
          },
        ],
        'targetLinks': [
          {
            'sourceNote': {
              'id': 'note-789',
              'title': 'Distributed Key-Value Store',
            },
          },
        ],
        'createdAt': '2026-10-04T10:00:00.000Z',
        'updatedAt': '2026-10-04T11:00:00.000Z',
      };

      final note = VaultNote.fromJson(json);

      expect(note.id, 'note-123');
      expect(note.title, 'Distributed Consensus via Raft');
      expect(note.isMistakeSolution, isTrue);
      expect(note.tags, ['distributed', 'algorithms', 'consensus']);
      expect(note.category?.name, 'System Architecture');
      expect(note.codeSnippets.length, 1);
      expect(note.codeSnippets.first.language, 'typescript');
      expect(note.codeSnippets.first.description, 'RPC vote handler');
      expect(note.codeSnippets.first.code.contains('requestVote'), isTrue);

      // Verify bidirectional links
      expect(note.linkedNotes.length, 2);
      expect(note.linkedNotes.any((l) => l.title == 'Paxos vs Raft Comparison' && l.direction == 'outgoing'), isTrue);
      expect(note.linkedNotes.any((l) => l.title == 'Distributed Key-Value Store' && l.direction == 'incoming'), isTrue);

      // Verify serialization roundtrip
      final serialized = note.toJson();
      expect(serialized['id'], 'note-123');
      expect(serialized['title'], 'Distributed Consensus via Raft');
      expect(serialized['tags'], ['distributed', 'algorithms', 'consensus']);
      expect(serialized['isMistakeSolution'], isTrue);
    });

    test('handles fallback defaults on empty or minimal note json', () {
      final json = <String, dynamic>{};
      final note = VaultNote.fromJson(json);

      expect(note.id, '');
      expect(note.title, 'Untitled Note');
      expect(note.content, '');
      expect(note.tags, isEmpty);
      expect(note.codeSnippets, isEmpty);
      expect(note.linkedNotes, isEmpty);
      expect(note.isMistakeSolution, isFalse);
    });

    test('CodeSnippet copyWith produces updated immutable instance', () {
      const snippet = CodeSnippet(
        language: 'python',
        code: 'def add(a, b): return a + b',
        description: 'Sum utility',
      );

      final updated = snippet.copyWith(language: 'py', description: 'Updated sum');
      expect(updated.language, 'py');
      expect(updated.description, 'Updated sum');
      expect(updated.code, snippet.code);
    });
  });
}
