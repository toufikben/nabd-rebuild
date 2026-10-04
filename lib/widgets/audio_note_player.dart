import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/l10n/app_localizations.dart';
import '../services/media_vault.dart';

/// Plays a voice note from the encrypted vault. The note is decrypted to a
/// temporary file only while this widget is on screen.
class AudioNotePlayer extends StatefulWidget {
  const AudioNotePlayer({super.key, required this.storedPath, this.onRemove});

  final String storedPath;
  final VoidCallback? onRemove;

  @override
  State<AudioNotePlayer> createState() => _AudioNotePlayerState();
}

class _AudioNotePlayerState extends State<AudioNotePlayer> {
  final AudioPlayer _player = AudioPlayer();
  File? _plain;
  bool _ready = false;
  bool _failed = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_player.positionStream.listen((value) {
        if (mounted) setState(() => _position = value);
      }))
      ..add(_player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          unawaited(_player.pause());
          unawaited(_player.seek(Duration.zero));
        }
        if (mounted) setState(() {});
      }));
  }

  Future<void> _prepare() async {
    if (_ready) return;
    try {
      final vault = MediaVault();
      final file = await vault.decryptToTemp(widget.storedPath);
      if (MediaVault.isEncrypted(widget.storedPath)) _plain = file;
      final duration = await _player.setFilePath(file.path);
      _duration = duration ?? Duration.zero;
      _ready = true;
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle() async {
    await _prepare();
    if (!_ready) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      unawaited(_player.play());
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    final plain = _plain;
    if (plain != null) {
      unawaited(plain.delete().then((_) => null, onError: (_) => null));
    }
    super.dispose();
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final total = _duration.inMilliseconds;
    final progress =
        total == 0 ? 0.0 : (_position.inMilliseconds / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _failed ? null : _toggle,
            tooltip: l10n.t(_player.playing ? 'audio.pause' : 'audio.play'),
            icon: Icon(
              _failed
                  ? Icons.error_outline
                  : _player.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
              size: 34,
              color: scheme.primary,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _format(_ready ? _duration - _position : Duration.zero),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (widget.onRemove != null)
            IconButton(
              onPressed: widget.onRemove,
              tooltip: l10n.t('audio.remove'),
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}
