import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/voice_to_text_service.dart';

void main() {
  test('offline language and network errors mean the voice pack is missing', () {
    for (final error in [
      'error_language_unavailable',
      'error_language_not_supported',
      'error_network',
      'error_server_disconnected',
    ]) {
      expect(dictationProblemFor(error, offline: true),
          DictationProblem.noOfflinePack, reason: error);
    }
  });

  test('online network errors are reported as network problems', () {
    expect(dictationProblemFor('error_network', offline: false),
        DictationProblem.network);
  });

  test('silence is not a problem worth a message', () {
    expect(dictationProblemFor('error_no_match', offline: true),
        DictationProblem.silence);
    expect(dictationProblemFor('error_speech_timeout', offline: false),
        DictationProblem.silence);
  });
}
