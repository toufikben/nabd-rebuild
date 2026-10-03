import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/passcode_service.dart';
import 'passcode_pad.dart';

/// Asks for the current passcode before it can be changed or removed, with
/// the same persistent throttle as the lock screen.
///
/// Pops with `true` once the passcode was entered correctly.
class PasscodeVerifySheet extends StatefulWidget {
  const PasscodeVerifySheet({super.key});

  static Future<bool> confirm(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PasscodeVerifySheet(),
    );
    return ok ?? false;
  }

  @override
  State<PasscodeVerifySheet> createState() => _PasscodeVerifySheetState();
}

class _PasscodeVerifySheetState extends State<PasscodeVerifySheet> {
  final PasscodeService _passcodes = PasscodeService.secure();
  final PasscodeAttempts _attempts =
      PasscodeAttempts(store: const SecureStoragePasscodeStore());
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _attempts.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit(String pin) async {
    if (_busy || _attempts.isLocked()) return;
    final wrong = AppLocalizations.of(context).t('lock.pin.wrong');
    setState(() => _busy = true);
    final ok = await _passcodes.verify(pin);
    if (!mounted) return;
    if (ok) {
      await _attempts.recordSuccess();
      if (mounted) Navigator.pop(context, true);
      return;
    }
    await _attempts.recordFailure();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = wrong;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t('settings.lock.verifyTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else
              PasscodePad(
                onSubmit: _submit,
                locked: _attempts.isLocked(),
                remainingSeconds: _attempts.remainingSeconds(),
              ),
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
