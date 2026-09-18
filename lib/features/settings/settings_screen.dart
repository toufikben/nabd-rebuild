import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/gender_themes.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/privacy_service.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final PrivacyService _privacy = PrivacyService();

  bool _notificationsEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 0;

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

          // ─── Notifications ───
          _section('Notifications'),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
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
              subtitle: '$_reminderHour:${_reminderMinute.toString().padLeft(2, '0')}',
              onTap: _pickReminderTime,
            ),

          // ─── Data ───
          _section('Data'),

          _tile(
            icon: Icons.download_outlined,
            title: 'Export Data',
            subtitle: 'Save all entries as JSON',
            onTap: _exportData,
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
              Share.share(
                'Check out My Journal — a private journaling app!',
              );
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
      leading: Icon(
        icon,
        color: danger ? AppColors.danger : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? AppColors.danger : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right,
              color: AppColors.textTertiary)
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
            leading: const Icon(Icons.favorite, color: AppColors.femininePrimary),
            title: const Text('Feminine'),
            subtitle: const Text('Softer, pink palette'),
            trailing: current == GenderTheme.feminine
                ? const Icon(Icons.check, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, 'feminine'),
          ),
          ListTile(
            leading: const Icon(Icons.shield, color: AppColors.masculinePrimary),
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

  Future<void> _exportData() async {
    try {
      final entries = _db.getAllEntries();
      final json = entries.map((e) => e.toMap()).toList();

      final text = json.toString();
      await Share.share(text, subject: 'My Journal Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
      }
    }
  }
}
