import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/data_revision.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gender_themes.dart';
import '../../services/biometric_service.dart';
import '../../services/encryption_service.dart';
import '../../services/notification_service.dart';
import '../../services/privacy_service.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final PrivacyService _privacy = PrivacyService();
  final BackupService _backup = BackupService();
  final BiometricService _biometric = BiometricService();

  // These must outlive the dialog that borrows them. `showDialog` returns as
  // soon as the route starts closing, so disposing a controller in a `finally`
  // tears down the EditableText/Focus structure while the exit animation is
  // still mounted. That trips `_dependents.isEmpty` and paints a red screen.
  // Owning them as State fields means disposal only happens in dispose(),
  // which the framework guarantees runs after teardown.
  final TextEditingController _exportPasswordController =
      TextEditingController();
  final TextEditingController _restorePasswordController =
      TextEditingController();

  bool _notificationsEnabled = true;
  bool _lockEnabled = false;
  int _lockTimeoutMinutes = 5;
  int _reminderHour = 20;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _lockEnabled = _biometric.isLockEnabled();
    _lockTimeoutMinutes = _biometric.getLockTimeout();
  }

  @override
  void dispose() {
    _exportPasswordController.dispose();
    _restorePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final genderTheme = ref.watch(genderThemeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings.title'))),
      body: ListView(
        children: [
          // ─── Appearance ───
          _section(l10n.t('settings.section.appearance')),

          // Theme
          _tile(
            icon: Icons.brightness_6,
            title: l10n.t('settings.theme'),
            subtitle: _themeName(themeMode, l10n),
            onTap: () => _pickTheme(themeMode, l10n),
          ),

          // Gender Theme
          _tile(
            icon: Icons.person_outline,
            title: l10n.t('settings.themeStyle'),
            subtitle: _genderThemeName(genderTheme, l10n),
            onTap: () => _pickGenderTheme(genderTheme, l10n),
          ),

          // Language
          _tile(
            icon: Icons.language,
            title: l10n.t('settings.language'),
            subtitle: _languageName(locale.languageCode),
            onTap: () => _pickLanguage(locale.languageCode),
          ),

          // ─── Lock ───
          _section(l10n.t('settings.section.lock')),

          SwitchListTile(
            secondary: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text(l10n.t('settings.lock.appLock')),
            subtitle: Text(l10n.t('settings.lock.appLockHint')),
            value: _lockEnabled,
            onChanged: (value) async {
              await _biometric.setLockEnabled(value);
              if (!mounted) return;
              setState(() => _lockEnabled = value);
            },
          ),

          if (_lockEnabled)
            _tile(
              icon: Icons.timer_outlined,
              title: l10n.t('settings.lock.timeout'),
              subtitle: _lockTimeoutLabel(_lockTimeoutMinutes, l10n),
              onTap: () => _pickLockTimeout(l10n),
            ),

          // ─── Notifications ───
          _section(l10n.t('settings.section.notifications')),

          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            title: Text(l10n.t('settings.notify.daily')),
            subtitle: Text(l10n.t('settings.notify.dailyHint')),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              if (v) {
                NotificationService.scheduleDailyReminder(
                  hour: _reminderHour,
                  minute: _reminderMinute,
                );
              } else {
                NotificationService.cancelAll();
              }
            },
          ),

          if (_notificationsEnabled)
            _tile(
              icon: Icons.access_time,
              title: l10n.t('settings.notify.time'),
              subtitle:
                  '$_reminderHour:${_reminderMinute.toString().padLeft(2, '0')}',
              onTap: _pickReminderTime,
            ),

          // ─── Data ───
          _section(l10n.t('settings.section.data')),

          _tile(
            icon: Icons.download_outlined,
            title: l10n.t('settings.data.export'),
            subtitle: l10n.t('settings.data.exportHint'),
            onTap: _exportData,
          ),

          _tile(
            icon: Icons.upload_outlined,
            title: l10n.t('settings.data.restore'),
            subtitle: l10n.t('settings.data.restoreHint'),
            onTap: _restoreData,
          ),

          _tile(
            icon: Icons.key_outlined,
            title: l10n.t('settings.data.rotateKey'),
            subtitle: l10n.t('settings.data.rotateKeyHint'),
            onTap: () => _confirmRotateKey(l10n),
          ),

          _tile(
            icon: Icons.delete_outline,
            title: l10n.t('settings.data.deleteAll'),
            subtitle: l10n.t('settings.data.deleteAllHint'),
            danger: true,
            onTap: () => _confirmDeleteAll(l10n),
          ),

          // ─── About ───
          _section(l10n.t('settings.section.about')),

          _tile(
            icon: Icons.share_outlined,
            title: l10n.t('settings.about.share'),
            subtitle: l10n.t('settings.about.shareHint'),
            onTap: () {
              Share.share(l10n.t('settings.about.shareBody'));
            },
          ),

          _tile(
            icon: Icons.info_outline,
            title: l10n.t('settings.about.version'),
            subtitle: '1.0.0',
            onTap: null,
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.danger : AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? AppColors.danger : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: AppColors.textTertiary)
          : null,
      onTap: onTap,
    );
  }

  String _themeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.t('settings.theme.light');
      case ThemeMode.dark:
        return l10n.t('settings.theme.dark');
      default:
        return l10n.t('settings.theme.system');
    }
  }

  String _genderThemeName(GenderTheme theme, AppLocalizations l10n) {
    switch (theme) {
      case GenderTheme.feminine:
        return l10n.t('settings.themeStyle.feminine');
      case GenderTheme.masculine:
        return l10n.t('settings.themeStyle.masculine');
      default:
        return l10n.t('settings.themeStyle.neutral');
    }
  }

  String _languageName(String code) {
    const names = {
      'ar': 'العربية',
      'en': 'English',
    };
    return names[code] ?? code;
  }

  String _lockTimeoutLabel(int minutes, AppLocalizations l10n) {
    switch (minutes) {
      case 1:
        return l10n.t('settings.lock.1m');
      case 5:
        return l10n.t('settings.lock.5m');
      case 15:
        return l10n.t('settings.lock.15m');
      case 30:
        return l10n.t('settings.lock.30m');
      default:
        return l10n.t('settings.lock.never');
    }
  }

  Future<void> _pickLockTimeout(AppLocalizations l10n) async {
    const options = <int>[1, 5, 15, 30, 0];
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final minutes in options)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(_lockTimeoutLabel(minutes, l10n)),
                trailing: _lockTimeoutMinutes == minutes
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                onTap: () => Navigator.pop(context, minutes),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (result == null) return;
    await _biometric.setLockTimeout(result);
    if (mounted) setState(() => _lockTimeoutMinutes = result);
  }

  Future<void> _pickTheme(ThemeMode current, AppLocalizations l10n) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(l10n.t('settings.theme.system')),
            trailing: current == ThemeMode.system
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'system'),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: Text(l10n.t('settings.theme.light')),
            trailing: current == ThemeMode.light
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'light'),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(l10n.t('settings.theme.dark')),
            trailing: current == ThemeMode.dark
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'dark'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (result != null) {
      await ref.read(themeModeProvider.notifier).setTheme(result);
    }
  }

  Future<void> _pickGenderTheme(GenderTheme current, AppLocalizations l10n) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.t('settings.themeStyle.neutral')),
            trailing: current == GenderTheme.neutral
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'neutral'),
          ),
          ListTile(
            leading: const Icon(
              Icons.favorite,
              color: AppColors.femininePrimary,
            ),
            title: Text(l10n.t('settings.themeStyle.feminine')),
            subtitle: Text(l10n.t('settings.themeStyle.feminineHint')),
            trailing: current == GenderTheme.feminine
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'feminine'),
          ),
          ListTile(
            leading: const Icon(
              Icons.shield,
              color: AppColors.masculinePrimary,
            ),
            title: Text(l10n.t('settings.themeStyle.masculine')),
            subtitle: Text(l10n.t('settings.themeStyle.masculineHint')),
            trailing: current == GenderTheme.masculine
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'masculine'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (result != null) {
      await ref.read(genderThemeProvider.notifier).setGenderTheme(result);
    }
  }

  Future<void> _pickLanguage(String current) async {
    const languages = [
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'en', 'name': 'English'},
    ];

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: languages.length,
          itemBuilder: (_, i) {
            final lang = languages[i];
            final isSelected = lang['code'] == current;
            return ListTile(
              title: Text(lang['name']!),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.success)
                  : null,
              onTap: () => Navigator.pop(context, lang['code']),
            );
          },
        ),
      ),
    );

    if (result != null) {
      await ref.read(localeProvider.notifier).setLanguage(result);
    }
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );

    if (time != null) {
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
      await NotificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  /// Exports an encrypted backup. The user picks where the `.nabd` file goes,
  /// so a copy survives even if the app is uninstalled.
  Future<void> _exportData() async {
    final passwordController = _exportPasswordController;
    passwordController.clear();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    String? destination;
    var saved = false;
    try {
      final password = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.t('dialog.export.title')),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.t('dialog.export.password')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.t('dialog.cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, passwordController.text),
              child: Text(l10n.t('dialog.continue')),
            ),
          ],
        ),
      );
      if (password == null || password.isEmpty || !mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('dialog.save.creating'))),
      );
      final backup = await _backup.createBackup(password: password);
      if (!mounted) return;

      // On Android and iOS the picker cannot hand back a writable path, so it
      // requires the bytes up front. Reading them here also lets us drop the
      // temp file straight after the save.
      final bytes = await File(backup.path).readAsBytes();
      destination = await FilePicker.platform.saveFile(
        dialogTitle: l10n.t('dialog.save.title'),
        fileName: p.basename(backup.path),
        type: FileType.any,
        bytes: bytes,
      );
      if (destination == null) {
        await backup.delete().catchError((_) => backup);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('dialog.save.cancelled'))),
        );
        return;
      }

      // Desktop and web return a path, so finish the write ourselves there.
      if (!kIsWeb && destination.isNotEmpty) {
        final target = File(destination);
        if (!await target.exists()) {
          await target.parent.create(recursive: true);
          await target.writeAsBytes(bytes, flush: true);
        }
      }
      await backup.delete().catchError((_) => backup);

      saved = true;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.t('dialog.save.done')}: ${p.basename(destination)}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.t('dialog.save.failed')}: $e')),
      );
      if (!saved) {
        debugPrint('Export did not complete; destination=$destination');
      }
    }
  }

  /// Restores an encrypted `.nabd` backup, letting the user merge with the
  /// current data or replace it wholesale.
  Future<void> _restoreData() async {
    final passwordController = _restorePasswordController;
    passwordController.clear();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );
      if (picked == null || !mounted) return;
      final path = picked.files.single.path;
      if (path == null) return;

      final password = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.t('dialog.restore.title')),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.t('dialog.export.password')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.t('dialog.cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, passwordController.text),
              child: Text(l10n.t('dialog.continue')),
            ),
          ],
        ),
      );
      if (password == null || password.isEmpty || !mounted) return;

      if (!mounted) return;
      final mode = await _askRestoreMode(l10n);
      if (mode == null || !mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('dialog.restore.restoring'))),
      );
      final result = await _backup.restoreBackup(
        path,
        password: password,
        mode: mode,
      );
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      if (!result.ok) {
        messenger.showSnackBar(
          SnackBar(content: Text('${l10n.t('dialog.restore.failed')}: ${result.error ?? ''}')),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            mode == RestoreMode.merge
                ? '${l10n.t('dialog.restore.merged')} ${result.entriesImported}'
                    ' ${l10n.t('dialog.restore.unit')} '
                    '(${result.imagesRestored} ${l10n.t('dialog.restore.media')}, '
                    '${result.audioRestored} ${l10n.t('dialog.restore.audio')})'
                : '${l10n.t('dialog.restore.replaced')} ${result.entriesImported}'
                    ' ${l10n.t('dialog.restore.unit')} '
                    '(${result.imagesRestored} ${l10n.t('dialog.restore.media')}, '
                    '${result.audioRestored} ${l10n.t('dialog.restore.audio')})',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      // Data changed underneath every screen, so ask listeners to refetch.
      ref.read(dataRevisionProvider.notifier).bump();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('${l10n.t('dialog.restore.failed')}: $e')));
    }
  }

  Future<RestoreMode?> _askRestoreMode(AppLocalizations l10n) {
    return showDialog<RestoreMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('dialog.mode.title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.t('dialog.mode.merge')),
              subtitle: Text(l10n.t('dialog.mode.mergeHint')),
              onTap: () => Navigator.pop(ctx, RestoreMode.merge),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(l10n.t('dialog.mode.replace')),
              subtitle: Text(l10n.t('dialog.mode.replaceHint')),
              onTap: () => Navigator.pop(ctx, RestoreMode.replace),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('dialog.cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRotateKey(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('dialog.rotate.title')),
        content: const Text(
          'Every entry will be re-encrypted with a new key. '
          'If this is interrupted the old key is restored automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('dialog.rotate')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.t('dialog.rotate.running'))),
    );
    try {
      await EncryptionService().rotateKey();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('dialog.rotate.done'))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.t('dialog.rotate.failed')}: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAll(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('dialog.delete.title')),
        content: const Text(
          'This will permanently remove ALL entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.t('settings.data.deleteAll')),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _privacy.deleteEverything();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.t('dialog.delete.done'))));
      }
    }
  }
}
