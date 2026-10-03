import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/passcode_service.dart';
import 'passcode_pad.dart';

/// Two-stage passcode entry: choose it, then type it again so a slip of a
/// finger cannot lock the owner out of their own journal.
///
/// Pops with `true` once the passcode is stored.
class PasscodeSetupSheet extends StatefulWidget {
  const PasscodeSetupSheet({super.key});

  @override
  State<PasscodeSetupSheet> createState() => _PasscodeSetupSheetState();
}

class _PasscodeSetupSheetState extends State<PasscodeSetupSheet> {
  final PasscodeService _service = PasscodeService.secure();

  String? _pending;
  String? _error;
  bool _saving = false;

  Future<void> _onSubmit(String pin) async {
    final l10n = AppLocalizations.of(context);
    if (_saving) return;

    if (_pending == null) {
      setState(() => _pending = pin);
      return;
    }
    if (pin != _pending) {
      setState(() {
        _pending = null;
        _error = l10n.t('settings.lock.mismatch');
      });
      return;
    }

    final saved = l10n.t('settings.lock.saved');
    final invalid = l10n.t('settings.lock.invalidLength');
    setState(() => _saving = true);
    try {
      await _service.setPasscode(pin);
    } on PasscodeFormatException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pending = null;
        _error = invalid;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved)),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _pending == null
        ? l10n.t('settings.lock.setupTitle')
        : l10n.t('settings.lock.confirmTitle');
    // Scrollable so a short screen or large font never clips the pad.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('settings.lock.warnBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              PasscodePad(onSubmit: _onSubmit),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.t('dialog.cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
