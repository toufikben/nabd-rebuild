import 'package:speech_to_text/speech_to_text.dart';

class VoiceToTextService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  Future<void> startListening({
    required void Function(String) onResult,
    String? localeId,
  }) async {
    if (!await initialize()) return;
    // speech_to_text 7.0 exposes localeId directly; newer versions replace
    // it with SpeechListenOptions. Keep this compatibility shim local.
    await _speech.listen(
      // ignore: deprecated_member_use
      localeId: localeId ?? 'en-US',
      onResult: (result) => onResult(result.recognizedWords),
    );
  }

  Future<void> stopListening() => _speech.stop();

  bool get isListening => _speech.isListening;
}
