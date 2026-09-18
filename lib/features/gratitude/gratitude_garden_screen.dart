import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';

/// GratitudeGardenScreen — كل امتنان يزرع زهرة.
///
/// الفكرة النفسية: الرؤية البصرية للامتنان تُقوّي السلوك الإيجابي.
class GratitudeGardenScreen extends StatefulWidget {
  const GratitudeGardenScreen({super.key});

  @override
  State<GratitudeGardenScreen> createState() => _GratitudeGardenScreenState();
}

class _GratitudeGardenScreenState extends State<GratitudeGardenScreen> {
  final Box _box = Hive.box('settings');
  final TextEditingController _controller = TextEditingController();

  List<GratitudeItem> get _items {
    final raw = _box.get('gratitude_items', defaultValue: <dynamic>[]) as List;
    return raw
        .map((e) => GratitudeItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _addGratitude() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final item = GratitudeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
      flowerIndex: _items.length % 8,
    );

    final list = [..._items.map((e) => e.toMap()), item.toMap()];
    await _box.put('gratitude_items', list);
    _controller.clear();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌻 A new flower grew in your garden!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gratitude Garden'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌻', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Garden visualization ───
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🌱', style: TextStyle(fontSize: 60)),
                          SizedBox(height: 12),
                          Text(
                            'Your garden is empty',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Add something you\'re grateful for',
                            style: TextStyle(color: Colors.black38),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // Ground
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8D6E63),
                                  Color(0xFF5D4037),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        // Flowers
                        ...items.asMap().entries.map((e) {
                          final item = e.value;
                          final row = e.key ~/ 8;
                          final col = e.key % 8;
                          return Positioned(
                            left: 30 + col * 40.0,
                            bottom: 20 + row * 50.0,
                            child: _FlowerWidget(
                              emoji: _flowerFor(item.flowerIndex),
                              delay: e.key * 100,
                              onTap: () => _showDetail(item),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ),

          // ─── Add form ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'I\'m grateful for...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _addGratitude(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addGratitude,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            Color(0xFF00A075),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _flowerFor(int index) {
    const flowers = ['🌻', '🌷', '🌹', '🌺', '🌸', '💐', '🏵️', '🌼'];
    return flowers[index % flowers.length];
  }

  void _showDetail(GratitudeItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(_flowerFor(item.flowerIndex),
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            const Text('Gratitude'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.text, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              'Planted: ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FlowerWidget extends StatelessWidget {
  final String emoji;
  final int delay;
  final VoidCallback onTap;

  const _FlowerWidget({
    required this.emoji,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 32),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .scale(curve: Curves.easeOutBack),
    );
  }
}

class GratitudeItem {
  final String id;
  final String text;
  final DateTime createdAt;
  final int flowerIndex;

  const GratitudeItem({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.flowerIndex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'flowerIndex': flowerIndex,
      };

  factory GratitudeItem.fromMap(Map<dynamic, dynamic> m) => GratitudeItem(
        id: m['id']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        flowerIndex: (m['flowerIndex'] as num?)?.toInt() ?? 0,
      );
}
