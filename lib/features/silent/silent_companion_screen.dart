import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SilentCompanionScreen extends StatefulWidget {
  const SilentCompanionScreen({super.key});

  @override
  State<SilentCompanionScreen> createState() => _SilentCompanionScreenState();
}

class _SilentCompanionScreenState extends State<SilentCompanionScreen> {
  static const _assetPath = 'assets/sounds/rain_soft.mp3';

  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.5;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareAudio();
  }

  Future<void> _prepareAudio() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      await _player.setAsset(_assetPath);
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load rain audio.';
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_isLoading || _errorMessage != null) return;

    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to play rain audio.');
    }
  }

  void _setVolume(double value) {
    setState(() => _volume = value);
    _player.setVolume(value);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Silent Companion'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 420),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 96,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Just be here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No words. No tasks. Only rain.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      final isDisabled = _isLoading || _errorMessage != null;

                      return SizedBox(
                        width: 96,
                        height: 96,
                        child: FilledButton(
                          onPressed: _errorMessage != null
                              ? _prepareAudio
                              : isDisabled
                                  ? null
                                  : _togglePlayback,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : _errorMessage != null
                                  ? Icon(
                                      Icons.refresh,
                                      size: 32,
                                      color: colors.onPrimary,
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 40,
                                      color: colors.onPrimary,
                                    ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 280,
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: _setVolume,
                      activeColor: colors.primary,
                      inactiveColor: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
