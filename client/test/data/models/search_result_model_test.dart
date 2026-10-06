import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/domain/models/search_result_model.dart';

void main() {
  group('Global Search Models & Domain Routing (UC-167 to UC-172)', () {
    test('hydrates multi-domain search results and resolves client navigation routes', () {
      final json = {
        'query': 'Docker',
        'domain': 'ALL',
        'totalResults': 4,
        'results': [
          {
            'id': 'task-101',
            'type': 'TASK',
            'title': 'Containerize Node Backend with Multi-Stage Dockerfile',
            'subtitle': 'Status: TODO • Priority: HIGH',
            'route': '/tasks/task-101',
          },
          {
            'id': 'note-202',
            'type': 'NOTE',
            'title': 'Docker Compose Networking & Volume Mounts',
            'subtitle': 'Tags: devops, docker',
            'route': '/vault/note-202',
          },
          {
            'id': 'proj-303',
            'type': 'PROJECT',
            'title': 'HABos Distributed Cluster',
            'subtitle': 'Progress: 45% • Status: IN_PROGRESS',
            'route': '/projects/proj-303',
          },
          {
            'id': 'course-404',
            'type': 'COURSE',
            'title': 'Cloud Computing & Virtualization',
            'subtitle': 'CS-720 • Fall 2026',
            'route': '/courses/course-404',
          },
        ],
      };

      final searchResult = GlobalSearchResult.fromJson(json);

      expect(searchResult.query, 'Docker');
      expect(searchResult.domain, 'ALL');
      expect(searchResult.totalResults, 4);
      expect(searchResult.results.length, 4);

      // 1. Task Item Check
      final taskItem = searchResult.results[0];
      expect(taskItem.type, 'TASK');
      expect(taskItem.domainLabel, 'Task');
      expect(taskItem.clientRoute, '/tasks/task-101');

      // 2. Vault Note Item Check
      final noteItem = searchResult.results[1];
      expect(noteItem.type, 'NOTE');
      expect(noteItem.domainLabel, 'Vault Note');
      expect(noteItem.clientRoute, '/more/vault/note-202');

      // 3. Project Item Check
      final projItem = searchResult.results[2];
      expect(projItem.type, 'PROJECT');
      expect(projItem.domainLabel, 'Project');
      expect(projItem.clientRoute, '/more/projects/proj-303');

      // 4. Course Item Check
      final courseItem = searchResult.results[3];
      expect(courseItem.type, 'COURSE');
      expect(courseItem.domainLabel, 'Course');
      expect(courseItem.clientRoute, '/more/academic/course-404');
    });

    test('handles fallback defaults on empty or minimal search item json', () {
      final json = <String, dynamic>{};
      final item = SearchResultItem.fromJson(json);

      expect(item.id, '');
      expect(item.type, 'TASK');
      expect(item.title, 'Untitled');
      expect(item.subtitle, isNull);
      expect(item.clientRoute, '/tasks/');
    });
  });
}
