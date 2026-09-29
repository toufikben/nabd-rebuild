import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/biometric_service.dart';
import '../../services/passcode_service.dart';
import 'passcode_pad.dart';
import 'passcode_setup_sheet.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final BiometricService _bio = BiometricService();
  final PasscodeService _passcodes = PasscodeService.secure();
  final PasscodeAttempts _attempts = PasscodeAttempts();

  String? _error;
  bool _busy = false;
  bool? _hasPasscode;
  int _remaining = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// The lock opens with a biometric prompt when one is enrolled, and leaves
  /// the pad on screen for every other case.
  Future<void> _open() async {
    final hasPasscode = await _passcodes.hasPasscode();
    final available = await _bio.isAvailable();
    if (!mounted) return;
    setState(() => _hasPasscode = hasPasscode);
    if (hasPasscode && available) await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final reason = l10n.t('lock.subtitle');
    final failed = l10n.t('lock.failed');
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _bio.authenticate(reason: reason);
    if (!mounted) return;
    if (ok) {
      await _enter();
      return;
    }
    setState(() {
      _busy = false;
      _error = failed;
    });
  }

  Future<void> _submitPin(String pin) async {
    if (_busy || _attempts.isLocked()) return;
    final wrong = AppLocalizations.of(context).t('lock.pin.wrong');
    setState(() => _busy = true);
    final ok = await _passcodes.verify(pin);
    if (!mounted) return;
    if (ok) {
      setState(() => _busy = false);
      await _enter();
      return;
    }
    _attempts.recordFailure();
    setState(() {
      _busy = false;
      _error = wrong;
      _remaining = _attempts.remainingSeconds();
    });
    if (_remaining > 0) _startCooldownTick();
  }

  /// "Forgot" is not a back door: the device credential that protects the phone
  /// proves ownership, and then a new passcode is chosen.
  Future<void> _recover() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final reason = l10n.t('lock.recover');
    final failed = l10n.t('lock.failed');
    setState(() => _busy = true);
    final ok = await _bio.authenticate(reason: reason);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = failed;
      });
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const PasscodeSetupSheet(),
    );
    if (saved != true || !mounted) return;
    await _enter();
  }

  Future<void> _enter() async {
    _attempts.recordSuccess();
    await _bio.updateLastActivity();
    if (!mounted) return;
    context.go('/home');
  }

  void _startCooldownTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _attempts.remainingSeconds();
      setState(() => _remaining = left);
      if (left <= 0) {
        _tick?.cancel();
        _tick = null;
      }
    });
  }

  bool get _locked => _attempts.isLocked();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPasscode = _hasPasscode;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B7BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('lock.title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('lock.subtitle'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_busy)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    else if (hasPasscode == true)
                      PasscodePad(
                        onSubmit: _submitPin,
                        locked: _locked,
                        remainingSeconds: _remaining,
                        onForgotTap: _recover,
                        dark: true,
                      )
                    else
                      FilledButton.icon(
                        onPressed: _recover,
                        icon: const Icon(Icons.pin),
                        label: Text(l10n.t('lock.pin.setup')),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (hasPasscode == true) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _locked ? null : _authenticate,
                        icon: const Icon(Icons.fingerprint, size: 20),
                        label: Text(l10n.t('lock.pin.biometric')),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
