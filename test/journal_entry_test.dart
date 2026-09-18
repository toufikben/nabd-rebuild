import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/models/journal_entry.dart';

void main() {
  group('JournalEntry', () {
    test('creates with default values', () {
      final entry = JournalEntry(
        title: 'Test',
        content: 'Content',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(entry.title, 'Test');
      expect(entry.content, 'Content');
      expect(entry.mood, '');
      expect(entry.tags, isEmpty);
      expect(entry.isFavorite, false);
      expect(entry.isPinned, false);
    });

    test('serializes to map', () {
      final entry = JournalEntry(
        id: 'test-id',
        title: 'Test',
        content: 'Content',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        mood: 'happy',
        tags: ['personal', 'work'],
      );

      final map = entry.toMap();
      expect(map['id'], 'test-id');
      expect(map['mood'], 'happy');
      expect(map['tags'], contains('personal'));
    });

    test('deserializes from map', () {
      final map = {
        'id': 'test-id',
        'title': 'Test',
        'content': 'Content',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'mood': 'happy',
        'tags': ['personal'],
        'imagePaths': [],
        'isFavorite': true,
        'isPinned': false,
      };

      final entry = JournalEntry.fromMap(map);
      expect(entry.id, 'test-id');
      expect(entry.isFavorite, true);
      expect(entry.tags, contains('personal'));
    });

    test('copyWith preserves id', () {
      final entry = JournalEntry(
        id: 'test-id',
        title: 'Test',
        content: 'Content',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = entry.copyWith(title: 'New Title');
      expect(updated.id, 'test-id');
      expect(updated.title, 'New Title');
    });
  });
}
