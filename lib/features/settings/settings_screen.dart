import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/data_revision.dart';
import '../../core/backup_nudge.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/languages.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gender_themes.dart';
import '../../features/lock/passcode_setup_sheet.dart';
import '../../services/audio_service.dart';
import '../../services/biometric_service.dart';
import '../../services/encryption_service.dart';
import '../../services/notification_service.dart';
import '../../services/passcode_service.dart';
import '../../services/privacy_service.dart';
import '../../services/backup_service.dart';
import '../../services/r_personal_service.dart';
import '../../services/review_prompt.dart';
import '../../services/settings_service.dart';
import '../../services/ui_sounds.dart';
import '../../services/database_service.dart';
import '../../services/voice_to_text_service.dart';
import '../../services/garden_service.dart';
import '../../services/journal_export_service.dart';
import '../../services/monetization_service.dart';
import '../../services/splash_service.dart';
import '../lock/passcode_verify_sheet.dart';
import '../../widgets/nabd_ui.dart';
import '../../widgets/vault_image.dart';
import 'backup_password_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _autoSnapshotSecret = 'nabd_auto_restore_password_v1';
  final PrivacyService _privacy = PrivacyService();
  final BackupService _backup = BackupService();
  final BiometricService _biometric = BiometricService();

  bool _notificationsEnabled = false;
  bool _notificationsAllowed = true;
  bool _weeklyReview = false;
  bool _launchSound = true;
  bool _uiSounds = true;
  double _cueVolume = 0.8;
  bool _hasAutoSnapshot = false;
  bool _lockEnabled = false;
  int _lockTimeoutMinutes = 5;
  int _reminderHour = NotificationService.defaultHour;
  int _reminderMinute = NotificationService.defaultMinute;
  bool _smartReminder = true;
  bool _onlineDictation = false;
  bool _hasPasscode = false;
  bool _biometricsAvailable = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = NotificationService.isEnabled;
    _loadNotificationPermission();
    _weeklyReview = NotificationService.isWeeklyReviewEnabled;
    _launchSound =
        Hive.box('settings').get('splash_sound_enabled', defaultValue: true) ==
            true;
    _uiSounds = UiSounds.enabled;
    _cueVolume = AudioService.instance.cueVolume;
    _reminderHour = NotificationService.hour;
    _reminderMinute = NotificationService.minute;
    _smartReminder = NotificationService.isSmart;
    _onlineDictation = VoiceToTextService.onlineAllowed;
    _lockEnabled = _biometric.isLockEnabled();
    _lockTimeoutMinutes = _biometric.getLockTimeout();
    _loadLockState();
    _refreshAutoSnapshot();
  }

  /// A safety copy outlives the SnackBar action, so Settings offers a second
  /// way back until the next Replace overwrites it.
  Future<void> _refreshAutoSnapshot() async {
    final snapshot = await _backup.autoSnapshot();
    if (!mounted) return;
    setState(() => _hasAutoSnapshot = snapshot != null);
  }

  Future<void> _loadNotificationPermission() async {
    final allowed = await NotificationService.hasPermission();
    if (!mounted) return;
    setState(() => _notificationsAllowed = allowed);
  }

  /// The passcode lives in the OS keystore and biometric support is a platform
  /// question, so neither can be read synchronously the way the Hive flags can.
  Future<void> _loadLockState() async {
    final hasPasscode = await PasscodeService.secure().hasPasscode();
    final available = await _biometric.isAvailable();
    var version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _hasPasscode = hasPasscode;
      _biometricsAvailable = available;
      _version = version;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final genderTheme = ref.watch(genderThemeProvider);
    final isPro =
        ref.watch(monetizationProvider.select((state) => state.isPro));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings.title'))),
      body: ListView(
        children: [
          // ─── Pro ───
          _group(l10n.t('paywall.brand'), [
            _tile(
              icon: Icons.workspace_premium_outlined,
              title: isPro
                  ? l10n.t('settings.pro.active')
                  : l10n.t('paywall.title'),
              subtitle: isPro
                  ? l10n.t('settings.pro.activeHint')
                  : l10n.t('paywall.tagline'),
              onTap: () => context.push('/paywall'),
            ),
          ]),

          // ─── Appearance ───
          _group(l10n.t('settings.section.appearance'), [
            // Theme
            _tile(
              icon: Icons.brightness_6,
              title: l10n.t('settings.theme'),
              subtitle: _themeName(themeMode, l10n),
              onTap: () => _pickTheme(themeMode, l10n),
            ),

            // Gender Theme
            _tile(
              icon: Icons.palette_outlined,
              title: l10n.t('settings.themeStyle'),
              subtitle: _genderThemeName(genderTheme, l10n),
              onTap: () => _pickGenderTheme(genderTheme, l10n),
            ),
            _tile(
              icon: Icons.text_fields_rounded,
              title: l10n.t('settings.font'),
              subtitle: _fontName(ref.watch(appFontProvider), l10n),
              onTap: () => _pickFont(ref.read(appFontProvider), l10n),
            ),

            // Language
            _tile(
              icon: Icons.language,
              title: l10n.t('settings.language'),
              subtitle: _languageName(locale.languageCode),
              onTap: () => _pickLanguage(locale.languageCode),
            ),
          ]),

          // ─── Sounds ───
          _group(l10n.t('settings.section.sound'), [
            SwitchListTile(
              secondary: _iconBadge(Icons.favorite_outline, AppColors.pulse),
              title: Text(l10n.t('settings.sound.launch')),
              subtitle: Text(l10n.t('settings.sound.launchHint')),
              value: _launchSound,
              onChanged: (value) async {
                await Hive.box('settings').put('splash_sound_enabled', value);
                if (mounted) setState(() => _launchSound = value);
              },
            ),
            if (_launchSound)
              _tile(
                icon: Icons.graphic_eq_rounded,
                title: l10n.t('settings.sound.launchChoice'),
                subtitle: l10n.t('sound.${_launchSoundId()}'),
                onTap: () => _pickLaunchSound(l10n),
              ),
            SwitchListTile(
              secondary:
                  _iconBadge(Icons.music_note_outlined, AppColors.secondary),
              title: Text(l10n.t('settings.sound.ui')),
              subtitle: Text(l10n.t('settings.sound.uiHint')),
              value: _uiSounds,
              onChanged: (value) async {
                await UiSounds.setEnabled(value);
                if (mounted) setState(() => _uiSounds = value);
                if (value) unawaited(UiSounds.play(UiSound.bloom));
              },
            ),
            _tile(
              icon: Icons.hearing_outlined,
              title: l10n.t('settings.sound.cueVolume'),
              subtitle: '${(_cueVolume * 100).round()}%',
              onTap: _pickCueVolume,
            ),
          ]),

          // ─── Lock ───
          _group(l10n.t('settings.section.lock'), [
            SwitchListTile(
              secondary: _iconBadge(Icons.lock_outline, AppColors.primary),
              title: Text(l10n.t('settings.lock.appLock')),
              subtitle: Text(l10n.t('settings.lock.appLockHint')),
              value: _lockEnabled,
              onChanged: (value) => _setLockEnabled(value, l10n),
            ),
            if (_lockEnabled) ...[
              _tile(
                icon: Icons.timer_outlined,
                title: l10n.t('settings.lock.timeout'),
                subtitle: _lockTimeoutLabel(_lockTimeoutMinutes, l10n),
                onTap: () => _pickLockTimeout(l10n),
              ),
              _tile(
                icon: Icons.numbers,
                title: l10n.t('settings.lock.passcode'),
                subtitle: _hasPasscode
                    ? l10n.t('settings.lock.passcodeSet')
                    : l10n.t('settings.lock.passcodeUnset'),
                onTap: _changePasscode,
              ),
              if (_hasPasscode)
                _tile(
                  icon: Icons.lock_open_outlined,
                  title: l10n.t('settings.lock.removeTitle'),
                  subtitle: _lockRemovalNote(l10n),
                  onTap: () => _removePasscode(l10n),
                  danger: true,
                ),
            ],
          ]),

          // ─── Notifications ───
          _group(l10n.t('settings.section.notifications'), [
            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
              title: Text(l10n.t('settings.notify.daily')),
              subtitle: Text(
                _notificationsEnabled && !_notificationsAllowed
                    ? l10n.t('settings.notify.permissionMissing')
                    : l10n.t('settings.notify.dailyHint'),
              ),
              value: _notificationsEnabled,
              onChanged: (v) => _setReminderEnabled(v, l10n),
            ),
            if (_notificationsEnabled) ...[
              SwitchListTile(
                secondary:
                    _iconBadge(Icons.auto_awesome_outlined, AppColors.primary),
                title: Text(l10n.t('settings.notify.smart')),
                subtitle: Text(l10n.t('settings.notify.smartHint')),
                value: _smartReminder,
                onChanged: _setSmartReminder,
              ),
              _tile(
                icon: Icons.access_time,
                title: l10n.t('settings.notify.time'),
                subtitle: _reminderTimeLabel(l10n),
                // With smart timing the time follows the habit; picking one
                // by hand means turning it off first.
                onTap: _smartReminder ? null : _pickReminderTime,
              ),
            ],
            SwitchListTile(
              secondary: _iconBadge(
                  Icons.calendar_view_week_outlined, AppColors.secondary),
              title: Text(l10n.t('settings.notify.weekly')),
              subtitle: Text(l10n.t('settings.notify.weeklyHint')),
              value: _weeklyReview,
              onChanged: (value) => _setWeeklyReview(value, l10n),
            ),
          ]),

          // ─── Data ───
          _group(l10n.t('settings.section.data'), [
            SwitchListTile(
              secondary:
                  _iconBadge(Icons.mic_none_rounded, AppColors.secondary),
              title: Text(l10n.t('settings.dictation.online')),
              subtitle: Text(l10n.t('settings.dictation.onlineHint')),
              value: _onlineDictation,
              onChanged: (value) async {
                await VoiceToTextService.setOnlineAllowed(value);
                if (mounted) setState(() => _onlineDictation = value);
              },
            ),
            _tile(
              icon: Icons.download_outlined,
              title: l10n.t('settings.data.export'),
              subtitle: l10n.t('settings.data.exportHint'),
              onTap: _exportData,
            ),
            _tile(
              icon: Icons.auto_stories_outlined,
              title: l10n.t('legacy.title'),
              subtitle: l10n.t('legacy.subtitle'),
              onTap: () => context.push('/legacy-journal'),
            ),
            _tile(
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.t('settings.data.exportDoc'),
              subtitle: l10n.t('settings.data.exportDocHint'),
              onTap: _exportDocument,
            ),
            _tile(
              icon: Icons.upload_outlined,
              title: l10n.t('settings.data.restore'),
              subtitle: l10n.t('settings.data.restoreHint'),
              onTap: _restoreData,
            ),
            if (_hasAutoSnapshot)
              _tile(
                icon: Icons.history_rounded,
                title: l10n.t('settings.data.undoRestore'),
                subtitle: l10n.t('settings.data.undoRestoreHint'),
                onTap: () => _confirmUndoRestore(l10n),
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
          ]),

          // ─── About ───
          _group(l10n.t('settings.section.about'), [
            _tile(
              icon: Icons.share_outlined,
              title: l10n.t('settings.about.share'),
              subtitle: l10n.t('settings.about.shareHint'),
              onTap: () {
                Share.share(l10n.t('settings.about.shareBody'));
              },
            ),
            _tile(
              icon: Icons.star_outline_rounded,
              title: l10n.t('settings.about.rate'),
              subtitle: l10n.t('settings.about.rateHint'),
              onTap: ReviewPrompt.openStorePage,
            ),
            _tile(
              icon: Icons.info_outline,
              title: l10n.t('settings.about.version'),
              subtitle: _version,
              onTap: null,
            ),
          ]),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  /// A titled group of settings on one rounded card.
  Widget _group(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: NabdCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tint = danger ? scheme.error : scheme.primary;
    return ListTile(
      leading: _iconBadge(icon, tint),
      title: Text(title, style: danger ? TextStyle(color: scheme.error) : null),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }

  Widget _iconBadge(IconData icon, Color tint) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: tint, size: 20),
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

  String _genderThemeName(GenderTheme theme, AppLocalizations l10n) =>
      l10n.t('settings.themeStyle.${theme.name}');

  String _fontName(AppFont font, AppLocalizations l10n) =>
      l10n.t('settings.font.${font.name}');

  String _launchSoundId() {
    final saved = Hive.box('settings').get('splash_sound') as String?;
    return SplashService.choices.contains(saved)
        ? saved!
        : SplashService.signatureSound;
  }

  /// Lists the launch sounds; tapping one plays it and makes it the cue.
  Future<void> _pickLaunchSound(AppLocalizations l10n) async {
    final preview = SplashService();
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final id in SplashService.choices)
                  ListTile(
                    leading: Icon(
                      id == _launchSoundId()
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: AppColors.pulse,
                    ),
                    title: Text(l10n.t('sound.$id')),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () async {
                      await Hive.box('settings').put('splash_sound', id);
                      setSheetState(() {});
                      if (mounted) setState(() {});
                      await preview.stopSplashSound();
                      await preview.playSplashSound(id);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } finally {
      await preview.stopSplashSound();
      await preview.dispose();
    }
  }

  Future<void> _pickCueVolume() async {
    final l10n = AppLocalizations.of(context);
    var value = _cueVolume;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('settings.sound.cueVolume'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.volume_down_outlined),
                    Expanded(
                      child: Slider(
                        value: value,
                        divisions: 10,
                        label: '${(value * 100).round()}%',
                        onChanged: (next) {
                          setSheetState(() => value = next);
                        },
                        onChangeEnd: (next) async {
                          await AudioService.instance.setCueVolume(next);
                          if (mounted) setState(() => _cueVolume = next);
                          unawaited(AudioService.instance.playCue(
                            'assets/sounds/inhale.m4a',
                            volume: next,
                          ));
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up_outlined),
                  ],
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _languageName(String code) {
    for (final language in appLanguages) {
      if (language.code == code) return language.nativeName;
    }
    return code;
  }

  String _lockTimeoutLabel(int minutes, AppLocalizations l10n) {
    switch (minutes) {
      case lockImmediately:
        return l10n.t('settings.lock.immediately');
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

  /// The lock may only be switched on once there is a way in that does not
  /// depend on biometrics. Before the passcode existed, a phone with no
  /// enrolled fingerprint accepted this switch and then refused to open.
  Future<void> _setLockEnabled(bool value, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final needsPasscode = l10n.t('settings.lock.needsPasscode');
    if (!value) {
      if (_hasPasscode) {
        final verified = await PasscodeVerifySheet.confirm(context);
        if (!verified || !mounted) return;
      }
      await _biometric.setLockEnabled(false);
      if (!mounted) return;
      setState(() => _lockEnabled = false);
      return;
    }

    if (!_hasPasscode) {
      final saved = await _openPasscodeSetup();
      if (!saved) {
        messenger.showSnackBar(SnackBar(content: Text(needsPasscode)));
        return;
      }
      setState(() => _hasPasscode = true);
    }

    await _biometric.setLockEnabled(true);
    if (!mounted) return;
    setState(() => _lockEnabled = true);
  }

  Future<bool> _openPasscodeSetup() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      // Without this the sheet is capped at 9/16 of the screen and the last
      // row of the pad is cut off.
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const PasscodeSetupSheet(),
    );
    return saved ?? false;
  }

  Future<void> _changePasscode() async {
    if (_hasPasscode && !await PasscodeVerifySheet.confirm(context)) return;
    if (!mounted) return;
    final saved = await _openPasscodeSetup();
    if (!saved || !mounted) return;
    setState(() => _hasPasscode = true);
  }

  String _lockRemovalNote(AppLocalizations l10n) {
    if (!_biometricsAvailable) {
      return l10n.t('settings.lock.removeBlocked');
    }
    return l10n.t('settings.lock.removeBody');
  }

  Future<void> _removePasscode(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_lockEnabled && !_biometricsAvailable) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('settings.lock.removeBlocked'))),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('settings.lock.removeTitle')),
        content: Text(l10n.t('settings.lock.removeBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.t('dialog.done')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await PasscodeVerifySheet.confirm(context)) return;
    await PasscodeService.secure().removePasscode();
    if (!mounted) return;
    setState(() => _hasPasscode = false);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.t('settings.lock.removed'))),
    );
  }

  Future<void> _pickLockTimeout(AppLocalizations l10n) async {
    const options = <int>[lockImmediately, 1, 5, 15, 30, lockNever];
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
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

  Future<void> _pickGenderTheme(
      GenderTheme current, AppLocalizations l10n) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<GenderTheme>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final theme in GenderTheme.values)
                _PaletteSwatch(
                  palette: GenderThemes.palettes[theme]!,
                  dark: dark,
                  label: _genderThemeName(theme, l10n),
                  selected: theme == current,
                  onTap: () => Navigator.pop(sheetContext, theme),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await ref.read(genderThemeProvider.notifier).setGenderTheme(result.name);
    }
  }

  Future<void> _pickFont(AppFont current, AppLocalizations l10n) async {
    final language = l10n.language;
    final result = await showModalBottomSheet<AppFont>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final font in AppFontFamily.choicesFor(language))
                ListTile(
                  title: Text(_fontName(font, l10n)),
                  subtitle: Text(
                    font == AppFont.auto
                        ? l10n
                            .t('settings.font.autoHint')
                            .replaceAll('{language}', language.nativeName)
                        : l10n.t('settings.font.sample'),
                    style: TextStyle(
                      fontFamily: font.familyFor(language),
                      fontSize: 16,
                    ),
                  ),
                  trailing: font == current
                      ? const Icon(Icons.check, color: AppColors.success)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, font),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) await ref.read(appFontProvider.notifier).set(result);
  }

  Future<void> _pickLanguage(String current) async {
    final languages = [
      for (final language in appLanguages)
        {'code': language.code, 'name': language.nativeName},
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

  List<DateTime> get _writtenAt =>
      DatabaseService().getAllEntries().map((e) => e.createdAt).toList();

  String _reminderTimeLabel(AppLocalizations l10n) {
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (!_smartReminder) return time;
    final learned = NotificationService.suggestedTime(_writtenAt) != null;
    return l10n
        .t(learned ? 'settings.notify.learned' : 'settings.notify.learning')
        .replaceAll('{time}', time);
  }

  Future<void> _setSmartReminder(bool value) async {
    await NotificationService.setSmart(value, writtenAt: _writtenAt);
    if (!mounted) return;
    setState(() {
      _smartReminder = value;
      _reminderHour = NotificationService.hour;
      _reminderMinute = NotificationService.minute;
    });
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );

    if (time == null || !mounted) return;
    setState(() {
      _reminderHour = time.hour;
      _reminderMinute = time.minute;
    });
    await _scheduleReminder(AppLocalizations.of(context));
  }

  /// The reminder is only shown as on once the OS has granted permission and
  /// the schedule is stored, so the switch never claims what is not true.
  Future<void> _setReminderEnabled(bool value, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!value) {
      await NotificationService.disableDailyReminder();
      if (mounted) setState(() => _notificationsEnabled = false);
      return;
    }
    final granted = await NotificationService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _notificationsAllowed = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('settings.notify.denied'))),
      );
      return;
    }
    setState(() => _notificationsAllowed = true);
    await _scheduleReminder(l10n);
  }

  Future<void> _setWeeklyReview(bool value, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!value) {
      await NotificationService.disableWeeklyReview();
      if (mounted) setState(() => _weeklyReview = false);
      return;
    }
    if (!await NotificationService.requestPermission()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('settings.notify.denied'))),
      );
      return;
    }
    try {
      await NotificationService.enableWeeklyReview(
        title: l10n.t('notify.weekly.title'),
        body: l10n.t('notify.weekly.body'),
      );
      if (mounted) setState(() => _weeklyReview = true);
    } catch (error) {
      debugPrint('Weekly review could not be scheduled: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('settings.notify.failed'))),
      );
    }
  }

  Future<void> _scheduleReminder(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationService.enableDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        title: l10n.t('notify.title'),
        body: l10n.t('notify.body'),
        writtenAt: _writtenAt,
      );
      if (mounted) {
        setState(() {
          _notificationsEnabled = true;
          _reminderHour = NotificationService.hour;
          _reminderMinute = NotificationService.minute;
        });
      }
    } catch (error) {
      debugPrint('Daily reminder could not be scheduled: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('settings.notify.failed'))),
      );
    }
  }

  /// Exports an encrypted backup. The user picks where the `.nabd` file goes,
  /// so a copy survives even if the app is uninstalled.
  Future<void> _exportData() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const BackupPasswordDialog(confirm: true),
    );
    if (password == null || password.isEmpty || !mounted) return;

    File? backup;
    try {
      final created = await _withProgress(
        l10n.t('dialog.save.creating'),
        (onProgress) =>
            _backup.createBackup(password: password, onProgress: onProgress),
      );
      backup = created;
      if (!mounted) return;
      // On Android and iOS the picker cannot hand back a writable path, so it
      // requires the bytes up front.
      final bytes = await created.readAsBytes();
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: l10n.t('dialog.save.title'),
        fileName: p.basename(created.path),
        type: FileType.any,
        bytes: bytes,
      );
      if (destination == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('dialog.save.cancelled'))),
        );
        return;
      }
      // Desktop returns a path, so finish the write ourselves there.
      if (!kIsWeb && destination.isNotEmpty) {
        final target = File(destination);
        if (!await target.exists()) {
          await target.parent.create(recursive: true);
          await target.writeAsBytes(bytes, flush: true);
        }
      }
      await BackupNudge.recordBackup();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.t('dialog.save.done')}: ${p.basename(destination)}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (error) {
      debugPrint('Export failed: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('dialog.save.failed'))),
      );
    } finally {
      final file = backup;
      if (file != null && await file.exists()) await file.delete();
    }
  }

  /// Exports the journal as a readable PDF or Markdown file (a Pro extra).
  Future<void> _exportDocument() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(monetizationProvider.notifier);
    // Cold start: the entitlement cache is still being read. Deciding before
    // it lands would send a Pro customer to the paywall.
    await service.ensureReady();
    if (!mounted) return;
    if (!service.isProActive) {
      await context.push('/paywall');
      return;
    }
    final entries = DatabaseService().getAllEntries();
    if (entries.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('export.doc.empty'))),
      );
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('export.doc.title')),
        content: Text(l10n.t('export.doc.warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('dialog.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'md'),
            child: Text(l10n.t('export.doc.markdown')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'pdf'),
            child: Text(l10n.t('export.doc.pdf')),
          ),
        ],
      ),
    );
    if (format == null || !mounted) return;
    try {
      final exporter = JournalExportService();
      final title = l10n.t('export.doc.name');
      final language = l10n.locale.languageCode;
      final Uint8List bytes = format == 'pdf'
          ? await exporter.toPdf(entries, title: title, languageCode: language)
          : Uint8List.fromList(utf8.encode(exporter.toMarkdown(
              entries,
              title: title,
              languageCode: language,
            )));
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: l10n.t('dialog.save.title'),
        fileName: 'nabd_journal_$stamp.$format',
        type: FileType.any,
        bytes: bytes,
      );
      if (destination == null) return;
      if (!kIsWeb && destination.isNotEmpty) {
        final target = File(destination);
        if (!await target.exists()) {
          await target.writeAsBytes(bytes, flush: true);
        }
      }
      messenger.showSnackBar(SnackBar(
        content:
            Text('${l10n.t('dialog.save.done')}: ${p.basename(destination)}'),
      ));
    } catch (error) {
      debugPrint('Document export failed: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('dialog.save.failed'))),
      );
    }
  }

  /// The safety copy is encrypted with an app-owned password in the OS
  /// keystore, so Undo never asks the writer for another secret.
  Future<String> _autoSnapshotPassword() async {
    final encryption = EncryptionService();
    final existing = await encryption.readSecret(_autoSnapshotSecret);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final generated = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await encryption.writeSecret(_autoSnapshotSecret, generated);
    return generated;
  }

  /// Restores an encrypted `.nabd` backup, letting the user merge with the
  /// current data or replace it wholesale.
  Future<void> _restoreData() async {
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
        builder: (_) => const BackupPasswordDialog(confirm: false),
      );
      if (password == null || password.isEmpty || !mounted) return;

      final mode = await _askRestoreMode(l10n);
      if (mode == null || !mounted) return;

      File? safetyCopy;
      String? safetyPassword;
      if (mode == RestoreMode.replace) {
        safetyPassword = await _autoSnapshotPassword();
        safetyCopy = await _withProgress(
          l10n.t('dialog.restore.safety'),
          (onProgress) => _backup.createAutoSnapshot(
            password: safetyPassword!,
            onProgress: onProgress,
          ),
        );
        if (!mounted) return;
      }

      final result = await _withProgress(
        l10n.t('dialog.restore.restoring'),
        (onProgress) => _backup.restoreBackup(
          path,
          password: password,
          mode: mode,
          onProgress: onProgress,
        ),
      );
      if (!mounted) return;
      if (!result.ok) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.t(result.error ?? 'backup.error.failed')),
        ));
        return;
      }

      final entryUnit = result.entriesImported == 1
          ? l10n.t('calendar.entry.one')
          : l10n.t('calendar.entry.many');
      final separator = l10n.t('dialog.restore.sep');
      final counts =
          '${result.entriesImported} $entryUnit '
          '(${result.imagesRestored} ${l10n.t('dialog.restore.media')}$separator'
          '${result.audioRestored} ${l10n.t('dialog.restore.audio')}$separator'
          '${_seedCount(result.seedsRestored, l10n)})';
      // Replacing an already visible message keeps the twelve-second Undo from
      // queueing behind it and following the writer into the next screen.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.t(mode == RestoreMode.merge ? 'dialog.restore.merged' : 'dialog.restore.replaced')} $counts',
            ),
            duration: Duration(seconds: safetyCopy == null ? 5 : 12),
            action: safetyCopy == null
                ? null
                : SnackBarAction(
                    label: l10n.t('dialog.restore.undo'),
                    onPressed: () => _undoRestore(
                      safetyCopy!,
                      safetyPassword!,
                      l10n,
                    ),
                  ),
          ),
        );
      await _refreshAutoSnapshot();
      if (!mounted) return;
      VaultImage.clearCache();
      try {
        await NotificationService.syncLetterUnlocks(
          letters: [
            for (final letter in RPersonalService().getLetters())
              if (letter.isFuture) (id: letter.id, opensAt: letter.unlockDate),
          ],
          title: l10n.t('notify.letter.title'),
          body: l10n.t('notify.letter.body'),
        );
      } catch (error) {
        debugPrint('Letter announcements not synced: $error');
      }
      // Data changed underneath every screen, so ask listeners to refetch.
      ref.invalidate(gardenProvider);
      ref.read(dataRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Restore failed: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('backup.error.failed'))),
      );
    }
  }

  /// Counts the restored seeds in a form the language actually inflects:
  /// Arabic has a dual, Russian and Ukrainian change the ending with the last
  /// two digits, and most of the other shipped languages keep the noun as is.
  String _seedCount(int count, AppLocalizations l10n) {
    final code = l10n.locale.languageCode;
    final String form;
    if (code == 'ar') {
      form = switch (count) {
        1 => 'one',
        2 => 'two',
        >= 3 && <= 10 => 'few',
        _ => 'many',
      };
    } else if (code == 'ru' || code == 'uk') {
      final mod10 = count % 10;
      final mod100 = count % 100;
      if (mod10 == 1 && mod100 != 11) {
        form = 'one';
      } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
        form = 'few';
      } else {
        form = 'many';
      }
    } else {
      form = count == 1 ? 'one' : 'many';
    }
    return '$count ${l10n.t('dialog.restore.seeds.$form')}';
  }

  /// Offers the same Undo from Settings once the SnackBar is gone.
  Future<void> _confirmUndoRestore(AppLocalizations l10n) async {
    final snapshot = await _backup.autoSnapshot();
    if (!mounted) return;
    if (snapshot == null) {
      await _refreshAutoSnapshot();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('settings.data.undoRestore')),
        content: Text(l10n.t('settings.data.undoRestoreHint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('dialog.restore.undo')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final password = await _autoSnapshotPassword();
    await _undoRestore(snapshot, password, l10n);
  }

  /// Puts back the copy taken just before Replace. The password lives in the
  /// OS keystore, so Undo works even after the app is restarted.
  Future<void> _undoRestore(
    File snapshot,
    String password,
    AppLocalizations l10n,
  ) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await snapshot.exists()) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.t('dialog.restore.undoFailed'))),
          );
        return;
      }
      if (!mounted) return;
      final result = await _withProgress(
        l10n.t('dialog.restore.restoring'),
        (onProgress) => _backup.restoreBackup(
          snapshot.path,
          password: password,
          mode: RestoreMode.replace,
          onProgress: onProgress,
        ),
      );
      if (!mounted) return;
      if (!result.ok) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.t(result.error ?? 'backup.error.failed')),
          ));
        return;
      }
      try {
        await _backup.clearAutoSnapshot();
      } catch (error) {
        // A leftover copy is harmless; do not turn a good restore into a fail.
        debugPrint('Could not delete the safety copy: $error');
      }
      if (!mounted) return;
      await _refreshAutoSnapshot();
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.t('dialog.restore.undone'))),
        );
      VaultImage.clearCache();
      ref.invalidate(gardenProvider);
      ref.read(dataRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Undo restore failed: $error');
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.t('dialog.restore.undoFailed'))),
        );
    }
  }

  /// Runs [task] behind a modal progress dialog that cannot be dismissed.
  Future<T> _withProgress<T>(
    String label,
    Future<T> Function(void Function(double) onProgress) task,
  ) async {
    final progress = ValueNotifier<double>(0);
    final navigator = Navigator.of(context);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, value, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: value == 0 ? null : value),
              ],
            ),
          ),
        ),
      ),
    ));
    try {
      return await task((value) => progress.value = value);
    } finally {
      navigator.pop();
      progress.dispose();
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
        content: Text(l10n.t('dialog.rotate.body')),
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
        content: Text(l10n.t('dialog.delete.body')),
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

    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final savedLanguage = Hive.box('settings').get('language');
    try {
      await _privacy.deleteEverything();
    } catch (error) {
      debugPrint('Delete All failed: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('dialog.delete.failed'))),
      );
      return;
    }
    // Wiping the journal must not take the writer's language with it: the
    // language is an accessibility choice, not journal content.
    if (savedLanguage is String) {
      await Hive.box('settings').put('language', savedLanguage);
    }
    // Everything that lives outside the boxes goes too: the passcode and its
    // attempt record, the scheduled reminder and the in-memory caches.
    await PasscodeService.secure().removePasscode();
    await _biometric.setLockEnabled(false);
    try {
      await NotificationService.disableDailyReminder();
      await NotificationService.disableWeeklyReview();
      // Letters to the future too: their announcements outlived the letters.
      await NotificationService.cancelEverything();
    } catch (_) {}
    DatabaseService.invalidate();
    VaultImage.clearCache();
    ref.invalidate(gardenProvider);
    ref.invalidate(themeModeProvider);
    ref.invalidate(localeProvider);
    ref.invalidate(genderThemeProvider);
    ref.read(dataRevisionProvider.notifier).bump();
    messenger
        .showSnackBar(SnackBar(content: Text(l10n.t('dialog.delete.done'))));
    // A fresh start: splash, then choosing a first seed.
    router.go('/');
  }
}

/// A palette as two overlapping circles over its own background.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.dark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Palette palette;
  final bool dark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 92,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      dark ? palette.darkBackground : palette.lightBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(-8, 0),
                      child: CircleAvatar(
                          radius: 16, backgroundColor: palette.primary),
                    ),
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: CircleAvatar(
                          radius: 12, backgroundColor: palette.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ExcludeSemantics(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
