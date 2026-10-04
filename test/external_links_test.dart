import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/router.dart';

void main() {
  test('shortcut and widget links open their screens', () {
    expect(externalLocation(Uri.parse('nabd://editor')), '/editor');
    expect(externalLocation(Uri.parse('nabd://garden')), '/garden');
    expect(externalLocation(Uri.parse('nabd://calendar')), '/calendar');
    expect(externalLocation(Uri.parse('nabd://stats')), '/stats');
  });

  test('a widget mood button opens a new entry with that mood', () {
    expect(externalLocation(Uri.parse('nabd://editor?mood=sad')), '/editor?mood=sad');
    expect(externalLocation(Uri.parse('nabd://editor?mood=happy')), '/editor?mood=happy');
  });

  test('an unknown mood is dropped, not passed through', () {
    expect(externalLocation(Uri.parse('nabd://editor?mood=%2Fsettings')), '/editor');
    expect(externalLocation(Uri.parse('nabd://editor?id=x&mood=nope')), '/editor');
  });

  test('App Links map onto the app, in-app locations pass through', () {
    expect(externalLocation(Uri.parse('https://nabd.app/journal')), '/editor');
    expect(externalLocation(Uri.parse('https://nabd.app/garden')), '/garden');
    expect(externalLocation(Uri.parse('https://nabd.app/other')), isNull);
    expect(externalLocation(Uri.parse('/today')), isNull);
    expect(externalLocation(Uri.parse('/editor?mood=sad')), isNull);
  });
}
