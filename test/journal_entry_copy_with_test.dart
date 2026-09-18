import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/models/journal_entry.dart';

void main() {
  final created = DateTime(2026, 1, 1);

  JournalEntry entry() => JournalEntry(
        id: 'entry-1',
        title: 'Title',
        content: 'Content',
        createdAt: created,
        updatedAt: created,
        audioPath: '/documents/audio/a.m4a',
        location: 'Home',
      );

  test('copyWith preserves omitted nullable fields', () {
    final result = entry().copyWith(title: 'Updated');
    expect(result.audioPath, '/documents/audio/a.m4a');
    expect(result.location, 'Home');
  });

  test('copyWith explicitly clears audioPath and location', () {
    final result = entry().copyWith(audioPath: null, location: null);
    expect(result.audioPath, isNull);
    expect(result.location, isNull);
  });

  test('copyWith replaces nullable fields with new values', () {
    final result = entry().copyWith(audioPath: '/new.m4a', location: 'Office');
    expect(result.audioPath, '/new.m4a');
    expect(result.location, 'Office');
  });
}
