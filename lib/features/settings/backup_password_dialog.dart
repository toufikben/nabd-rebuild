import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// Asks for a backup password. When [confirm] is set (creating a backup) the
/// password is typed twice and its strength is shown, because a typo here
/// makes the backup impossible to open.
///
/// Owns its controllers, so they are only released after the dialog route
/// has finished animating out.
class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({super.key, required this.confirm});

  final bool confirm;

  /// 0 = weak, 1 = fair, 2 = strong.
  static int strength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    final kinds = [
      RegExp(r'[a-z]'),
      RegExp(r'[A-Z]'),
      RegExp(r'[0-9]'),
      RegExp(r'[^a-zA-Z0-9]'),
    ].where((pattern) => pattern.hasMatch(password)).length;
    if (kinds >= 3) score++;
    if (password.length < 8) return 0;
    return score >= 3 ? 2 : (score >= 2 ? 1 : 0);
  }

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final value = _password.text;
    if (value.isEmpty) return;
    if (widget.confirm && value != _repeat.text) {
      setState(() => _error = l10n.t('backup.password.mismatch'));
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final strength = BackupPasswordDialog.strength(_password.text);
    final strengthColor = [scheme.error, Colors.orange, Colors.green][strength];
    final strengthLabel = l10n.t([
      'backup.password.weak',
      'backup.password.fair',
      'backup.password.strong',
    ][strength]);
    return AlertDialog(
      title: Text(l10n.t(widget.confirm
          ? 'dialog.export.title'
          : 'dialog.restore.title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => widget.confirm ? null : _submit(),
              decoration: InputDecoration(
                labelText: l10n.t('dialog.export.password'),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            if (widget.confirm) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _password.text.isEmpty ? 0 : (strength + 1) / 3,
                color: strengthColor,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              if (_password.text.isNotEmpty)
                Text(
                  strengthLabel,
                  style: TextStyle(color: strengthColor, fontSize: 12),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _repeat,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.t('backup.password.confirm'),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('backup.password.hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('dialog.cancel')),
        ),
        FilledButton(
          onPressed: _password.text.isEmpty ? null : _submit,
          child: Text(l10n.t('dialog.continue')),
        ),
      ],
    );
  }
}
