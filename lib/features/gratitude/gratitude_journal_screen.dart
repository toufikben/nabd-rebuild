import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';

class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen> {
  final Box _box = Hive.box('settings');
  final List<TextEditingController> _controllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  String get _todayKey {
    final now = DateTime.now();
    return 'gratitude_${now.year}_${now.month}_${now.day}';
  }

  List<_GratitudeItem> get _items {
    final items = <_GratitudeItem>[];
    for (final key
        in _box.keys.where((key) => key.toString().startsWith('gratitude_'))) {
      final dateKey = key.toString();
      final raw = _box.get(key);
      if (raw is! List) continue;
      final date = _dateFromKey(dateKey);
      for (final value in raw) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          items.add(_GratitudeItem(dateKey: dateKey, date: date, text: text));
        }
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  void _loadToday() {
    final saved = _box.get(_todayKey);
    if (saved is! List) return;
    for (var i = 0; i < saved.length && i < _controllers.length; i++) {
      _controllers[i].text = saved[i]?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    final values =
        _controllers.map((controller) => controller.text.trim()).toList();
    await _box.put(_todayKey, values);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ امتنانك'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _delete(_GratitudeItem item) async {
    final raw = _box.get(item.dateKey);
    if (raw is! List) return;
    final values = raw.map((value) => value?.toString() ?? '').toList();
    final index = values.indexOf(item.text);
    if (index >= 0) values.removeAt(index);
    await _box.put(item.dateKey, values);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مذكرة الامتنان'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'حفظ',
              onPressed: _save,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF48FB1), Color(0xFFEC407A)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text('🙏', style: TextStyle(fontSize: 50)),
                  SizedBox(height: 12),
                  Text(
                    'ثلاثة أشياء تشعر بالامتنان لوجودها اليوم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(3, (index) => _input(index)),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ امتنان اليوم'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'الإدخالات السابقة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Text(
                    'لا توجد إدخالات امتنان بعد',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...items.map((item) => _itemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _input(int index) {
    const hints = [
      'شخص أقدّره...',
      'لحظة جعلتني أبتسم...',
      'شيء صغير لكنه مهم...'
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controllers[index],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hints[index],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(_GratitudeItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Text('🙏', style: TextStyle(fontSize: 22)),
        title: Text(item.text),
        subtitle: Text(_formatDate(item.date)),
        trailing: IconButton(
          onPressed: () => _delete(item),
          tooltip: 'حذف',
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  DateTime _dateFromKey(String key) {
    final parts = key.split('_');
    if (parts.length == 4) {
      return DateTime.tryParse(
              '${parts[1].padLeft(4, '0')}-${parts[2].padLeft(2, '0')}-${parts[3].padLeft(2, '0')}') ??
          DateTime(1970);
    }
    return DateTime(1970);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _GratitudeItem {
  final String dateKey;
  final DateTime date;
  final String text;

  const _GratitudeItem(
      {required this.dateKey, required this.date, required this.text});
}
