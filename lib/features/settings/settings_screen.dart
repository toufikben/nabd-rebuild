import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/gender_themes.dart';
import '../../services/database_service.dart';
import '../../services/biometric_service.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../../services/privacy_service.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final PrivacyService _privacy = PrivacyService();
  final BiometricService _biometric = BiometricService();
  final BackupService _backup = BackupService();

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
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final genderTheme = ref.watch(genderThemeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ─── Appearance ───
          _section('Appearance'),

          // Theme
          _tile(
            icon: Icons.brightness_6,
            title: 'Theme',
            subtitle: _themeName(themeMode),
            onTap: () => _pickTheme(themeMode),
          ),

          // Gender Theme
          _tile(
            icon: Icons.person_outline,
            title: 'Theme Style',
            subtitle: _genderThemeName(genderTheme),
            onTap: () => _pickGenderTheme(genderTheme),
          ),

          // Language
          _tile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _languageName(locale.languageCode),
            onTap: () => _pickLanguage(locale.languageCode),
          ),

          // ─── Lock ───
          _section('Lock'),

          SwitchListTile(
            secondary: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: const Text('App Lock'),
            subtitle: const Text('Require authentication when returning later'),
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
              title: 'Lock after background',
              subtitle: _lockTimeoutLabel(_lockTimeoutMinutes),
              onTap: _pickLockTimeout,
            ),

          // ─── Notifications ───
          _section('Notifications'),

          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Daily Reminder'),
            subtitle: const Text('Get reminded to write'),
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
              title: 'Reminder Time',
              subtitle:
                  '$_reminderHour:${_reminderMinute.toString().padLeft(2, '0')}',
              onTap: _pickReminderTime,
            ),

          // ─── Data ───
          _section('Data'),

          _tile(
            icon: Icons.backup_outlined,
            title: 'Backup Database',
            subtitle: 'Save entries and settings in an encrypted .nabd file',
            onTap: _createEncryptedBackup,
          ),

          _tile(
            icon: Icons.restore_outlined,
            title: 'Restore Database',
            subtitle: 'Import an encrypted .nabd file using its password',
            onTap: _restoreEncryptedBackup,
          ),

          _tile(
            icon: Icons.delete_outline,
            title: 'Delete All Data',
            subtitle: 'Remove all entries',
            danger: true,
            onTap: _confirmDeleteAll,
          ),

          // ─── About ───
          _section('About'),

          _tile(
            icon: Icons.share_outlined,
            title: 'Share App',
            subtitle: 'Tell your friends',
            onTap: () {
              Share.share('Check out My Journal — a private journaling app!');
            },
          ),

          _tile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),

          const SizedBox(height: 40),
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
          style: const TextStyle(
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
          ? const Icon(Icons.chevron_right, color: AppColors.textTertiary)
          : null,
      onTap: onTap,
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  String _genderThemeName(GenderTheme theme) {
    switch (theme) {
      case GenderTheme.feminine:
        return 'Feminine';
      case GenderTheme.masculine:
        return 'Masculine';
      default:
        return 'Neutral';
    }
  }

  String _languageName(String code) {
    const names = {
      'ar': 'العربية',
      'en': 'English',
      'fr': 'Français',
      'es': 'Español',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'tr': 'Türkçe',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'hi': 'हिन्दी',
      'id': 'Bahasa Indonesia',
      'fa': 'فارسی',
      'ur': 'اردو',
    };
    return names[code] ?? code;
  }

  String _lockTimeoutLabel(int minutes) {
    switch (minutes) {
      case 1:
        return '1 minute';
      case 5:
        return '5 minutes';
      case 15:
        return '15 minutes';
      case 30:
        return '30 minutes';
      default:
        return 'Never';
    }
  }

  Future<void> _pickLockTimeout() async {
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
                title: Text(_lockTimeoutLabel(minutes)),
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

  Future<void> _pickTheme(ThemeMode current) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('System'),
            trailing: current == ThemeMode.system
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'system'),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('Light'),
            trailing: current == ThemeMode.light
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'light'),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark'),
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

  Future<void> _pickGenderTheme(GenderTheme current) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Neutral'),
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
            title: const Text('Feminine'),
            subtitle: const Text('Softer, pink palette'),
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
            title: const Text('Masculine'),
            subtitle: const Text('Bold, dark palette'),
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
      {'code': 'fr', 'name': 'Français'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'tr', 'name': 'Türkçe'},
      {'code': 'zh', 'name': '中文'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
      {'code': 'hi', 'name': 'हिन्दी'},
      {'code': 'id', 'name': 'Bahasa Indonesia'},
      {'code': 'fa', 'name': 'فارسی'},
      {'code': 'ur', 'name': 'اردو'},
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

  Future<String?> _askForBackupPassword({required String title}) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Database password',
            hintText: 'Use at least 8 characters',
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return password;
  }

  Future<RestoreMode?> _pickRestoreMode() {
    return showDialog<RestoreMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore mode'),
        content: const Text(
          'Merge keeps current data and adds the backup. Replace clears current data first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, RestoreMode.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, RestoreMode.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmReplaceRestore() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Replace current data?'),
            content: const Text(
              'Replace will remove current entries and settings before restoring the backup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Replace'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDataMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createEncryptedBackup() async {
    final password = await _askForBackupPassword(
      title: 'Create encrypted backup',
    );
    if (!mounted || password == null || password.isEmpty) return;

    try {
      final temporaryFile = await _backup.createBackup(password: password);
      final bytes = await temporaryFile.readAsBytes();
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save encrypted database backup',
        fileName: temporaryFile.uri.pathSegments.last,
        type: FileType.custom,
        allowedExtensions: ['nabd'],
        bytes: bytes,
      );
      if (savedPath == null || savedPath.isEmpty) {
        _showDataMessage('Backup canceled');
      } else {
        _showDataMessage('Encrypted database backup saved');
      }
      if (await temporaryFile.exists()) await temporaryFile.delete();
    } catch (error) {
      _showDataMessage('Backup failed: $error');
    }
  }

  Future<void> _restoreEncryptedBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (!mounted || picked == null || picked.files.single.path == null) return;

    final selectedPath = picked.files.single.path!;
    if (!selectedPath.toLowerCase().endsWith('.nabd')) {
      _showDataMessage('Please select an encrypted .nabd backup file');
      return;
    }

    final mode = await _pickRestoreMode();
    if (!mounted || mode == null) return;
    if (mode == RestoreMode.replace && !await _confirmReplaceRestore()) {
      return;
    }

    final password = await _askForBackupPassword(
      title: 'Unlock encrypted backup',
    );
    if (!mounted || password == null || password.isEmpty) return;

    final result = await _backup.restoreBackup(
      selectedPath,
      password: password,
      mode: mode,
    );
    if (!mounted) return;
    if (result.ok) {
      _showDataMessage(
        'Restore completed: ${result.entriesImported} entries imported',
      );
    } else {
      _showDataMessage('Restore failed: ${result.error ?? 'Unknown error'}');
    }
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will permanently remove ALL entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _privacy.deleteEverything();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('All data deleted')));
      }
    }
  }
}
