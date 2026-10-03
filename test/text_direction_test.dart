import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/text_direction.dart';

void main() {
  test('the first strong letter decides', () {
    expect(textDirectionOf('مرحبا hello', TextDirection.ltr), TextDirection.rtl);
    expect(textDirectionOf('hello مرحبا', TextDirection.rtl), TextDirection.ltr);
    expect(textDirectionOf('2026 — مرحبا', TextDirection.ltr), TextDirection.rtl);
  });

  test('no letters keeps the interface direction', () {
    expect(textDirectionOf('', TextDirection.rtl), TextDirection.rtl);
    expect(textDirectionOf('123 ...', TextDirection.ltr), TextDirection.ltr);
  });
}
