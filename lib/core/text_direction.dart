import 'package:flutter/widgets.dart';

final _rtlChar = RegExp('[֐-ࣿיִ-﷿ﹰ-﻿]');
final _ltrChar = RegExp('[A-Za-zÀ-ɏ]');

/// The direction of [text] judged by its first strong letter, so Arabic
/// written in the English interface (or the reverse) still reads from the
/// right side. Falls back to [fallback] when there is no letter yet.
TextDirection textDirectionOf(String text, TextDirection fallback) {
  for (final char in text.characters) {
    if (_rtlChar.hasMatch(char)) return TextDirection.rtl;
    if (_ltrChar.hasMatch(char)) return TextDirection.ltr;
  }
  return fallback;
}
