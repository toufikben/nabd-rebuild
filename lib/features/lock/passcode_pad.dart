import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/passcode_service.dart';

/// Numeric pad for the app passcode.
///
/// The entry is shown as dots so a shoulder cannot read it, taps stop working
/// while the attempt throttle counts down, and the recovery route only appears
/// where the caller can offer one.
class PasscodePad extends StatefulWidget {
  const PasscodePad({
    super.key,
    required this.onSubmit,
    this.locked = false,
    this.remainingSeconds = 0,
    this.onForgotTap,
    this.dark = false,
  });

  final ValueChanged<String> onSubmit;

  /// True while [PasscodeAttempts] refuses input.
  final bool locked;
  final int remainingSeconds;

  /// Shown when the user cannot remember the passcode. Null hides the button.
  final VoidCallback? onForgotTap;

  /// The lock screen paints the pad on a dark gradient; the settings sheet
  /// paints it on a light surface.
  final bool dark;

  @override
  State<PasscodePad> createState() => _PasscodePadState();
}

class _PasscodePadState extends State<PasscodePad> {
  static const _rows = <List<int>>[
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ];

  String _entry = '';

  bool get _canSubmit =>
      !widget.locked && _entry.length >= PasscodeService.minLength;

  void _tap(int digit) {
    if (widget.locked) return;
    if (_entry.length >= PasscodeService.maxLength) return;
    setState(() => _entry = '$_entry$digit');
  }

  void _backspace() {
    if (widget.locked || _entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  void _submit() {
    if (!_canSubmit) return;
    final pin = _entry;
    setState(() => _entry = '');
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PasscodeDots(filled: _entry.length, color: _foregroundColor),
        const SizedBox(height: 20),
        if (widget.locked) ...[
          Text(
            l10n
                .t('lock.pin.cooldown')
                .replaceAll('{n}', '${widget.remainingSeconds}'),
            style: TextStyle(color: _foregroundColor, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_forDigit(row[0]), _forDigit(row[1]), _forDigit(row[2])],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _keyButton(
              key: const ValueKey('backspace'),
              icon: Icons.backspace_outlined,
              onPressed: widget.locked || _entry.isEmpty ? null : _backspace,
            ),
            _forDigit(0),
            _keyButton(
              key: const ValueKey('submit'),
              icon: Icons.check,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
        if (widget.onForgotTap != null) ...[
          const SizedBox(height: 10),
          TextButton(
            key: const ValueKey('forgot'),
            onPressed: widget.locked ? null : widget.onForgotTap,
            style: TextButton.styleFrom(foregroundColor: _foregroundColor),
            child: Text(l10n.t('lock.pin.forgot')),
          ),
        ],
      ],
    );
  }

  Color get _foregroundColor =>
      widget.dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

  Widget _forDigit(int digit) {
    return _keyButton(
      key: ValueKey<int>(digit),
      label: '$digit',
      onPressed: widget.locked ? null : () => _tap(digit),
    );
  }

  Widget _keyButton({
    required Key key,
    VoidCallback? onPressed,
    String? label,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SizedBox(
        width: 74,
        height: 54,
        child: ElevatedButton(
          key: key,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.dark ? Colors.white.withValues(alpha: 0.18) : null,
            foregroundColor: _foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: icon == null
              ? Text(label!, style: const TextStyle(fontSize: 20))
              : Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _PasscodeDots extends StatelessWidget {
  const _PasscodeDots({required this.filled, required this.color});

  final int filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < PasscodeService.maxLength; i++)
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? color : color.withValues(alpha: 0.28),
            ),
          ),
      ],
    );
  }
}
