import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/features/stats/advanced/emotion_radar_screen.dart';
import 'package:nabd/models/mood.dart';

void main() {
  group('Emotion radar dimensions', () {
    // The radar used to list mood ids that the editor cannot record
    // (`joyful`, `loved`, `hopeful`, `frustrated`, `confused`). Three of its
    // six axes were therefore permanently near-zero. This guards both
    // directions: every axis id is recordable, and every recordable mood
    // reaches some axis, so no entry silently vanishes from the chart.
    test('every axis mood id can actually be recorded', () {
      final recordable = Mood.journalMoods.map((m) => m.id).toSet();
      for (final axis in emotionRadarDimensions.entries) {
        for (final id in axis.value) {
          expect(
            recordable,
            contains(id),
            reason: 'axis "${axis.key}" uses "$id", which the editor cannot '
                'record, so that axis can never light up',
          );
        }
      }
    });

    test('every recordable mood belongs to an axis', () {
      final charted = emotionRadarDimensions.values.expand((ids) => ids).toSet();
      for (final mood in Mood.journalMoods) {
        expect(
          charted,
          contains(mood.id),
          reason: '"${mood.id}" is recordable but no axis counts it',
        );
      }
    });

    test('no mood is counted on two axes', () {
      final seen = <String>{};
      for (final axis in emotionRadarDimensions.entries) {
        for (final id in axis.value) {
          expect(
            seen.add(id),
            isTrue,
            reason: '"$id" is counted on more than one axis, which inflates '
                'its share of the radar',
          );
        }
      }
    });
  });
}
