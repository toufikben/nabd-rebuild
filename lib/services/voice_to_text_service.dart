import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/storage.dart';

/// Why a dictation session stopped early.
enum DictationProblem {
  /// Offline was asked for but the phone has no voice pack for the language
  /// (the recogniser answers with a language or network error).
  noOfflinePack,

  /// Online recognition was allowed but there is no connection.
  network,

  /// Nothing was heard. Not worth a message.
  silence,

  other,
}

/// Classifies a recogniser error. Kept apart from the plugin so it can be
/// tested: Android reports a missing offline pack in several ways.
DictationProblem dictationProblemFor(String errorMsg, {required bool offline}) {
  switch (errorMsg) {
    case 'error_no_match':
    case 'error_speech_timeout':
      return DictationProblem.silence;
    case 'error_language_not_supported':
    case 'error_language_unavailable':
      return offline ? DictationProblem.noOfflinePack : DictationProblem.other;
    case 'error_network':
    case 'error_network_timeout':
    case 'error_server':
    case 'error_server_disconnected':
      // With "prefer offline" and no pack, Android falls back to the network
      // path and fails there, so offline network errors mean a missing pack.
      return offline ? DictationProblem.noOfflinePack : DictationProblem.network;
    default:
      return DictationProblem.other;
  }
}

class VoiceToTextService {
  static const onlineKey = 'dictation_allow_online';

  /// Whether the phone's online speech service may be used. Off until the
  /// user agrees, when the offline voice pack turns out to be missing.
  static bool get onlineAllowed =>
      Hive.box(HiveBoxes.settings).get(onlineKey, defaultValue: false) == true;

  static Future<void> setOnlineAllowed(bool value) =>
      Hive.box(HiveBoxes.settings).put(onlineKey, value);

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _offline = true;
  void Function(DictationProblem)? _onProblem;
  void Function()? _onDone;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: _handleError,
      onStatus: (status) {
        if (status == SpeechToText.doneStatus) _onDone?.call();
      },
    );
    return _initialized;
  }

  void _handleError(SpeechRecognitionError error) {
    if (!error.permanent && error.errorMsg != 'error_language_unavailable') {
      return;
    }
    _onProblem?.call(dictationProblemFor(error.errorMsg, offline: _offline));
  }

  /// Listens for a long, free-form dictation. With [offline] the phone's
  /// on-device recogniser is used, so speech never leaves the phone; that
  /// needs the language's offline voice pack.
  Future<void> startListening({
    required void Function(String) onResult,
    required String localeId,
    required bool offline,
    void Function(DictationProblem)? onProblem,
    void Function()? onDone,
  }) async {
    if (!await initialize()) return;
    _offline = offline;
    _onProblem = onProblem;
    _onDone = onDone;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        onDevice: offline,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> stopListening() => _speech.stop();

  bool get isListening => _speech.isListening;
}
