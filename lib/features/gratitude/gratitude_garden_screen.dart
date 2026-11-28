import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/gratitude.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/storage.dart';

/// GratitudeGardenScreen — كل امتنان يزرع زهرة.
///
/// الفكرة النفسية: الرؤية البصرية للامتنان تُقوّي السلوك الإيجابي.
///
/// The garden is a view of the gratitude journal, not a second store: every
/// flower is a line written on a day, so what is planted here shows up in the
/// journal and counts towards the gratitude achievement.
class GratitudeGardenScreen extends StatefulWidget {
  const GratitudeGardenScreen({super.key});

  @override
  State<GratitudeGardenScreen> createState() => _GratitudeGardenScreenState();
}

class _GratitudeGardenScreenState extends State<GratitudeGardenScreen> {
  final Box _box = contentBox();
  final TextEditingController _controller = TextEditingController();

  List<GratitudeEntry> get _entries => gratitudeEntries(_box);

  Future<void> _addGratitude() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await addGratitude(_box, text);
    if (!mounted) return;
    _controller.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('gratitudeGarden.grew')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('gratitudeGarden.title')),
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
                      '${entries.length}',
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
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌱', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)
                                .t('gratitudeGarden.empty'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppLocalizations.of(context)
                                .t('gratitudeGarden.add'),
                            style: const TextStyle(color: Colors.black38),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // One flower per entry, laid out in rows that fit the
                        // width instead of a fixed eight per row, which used to
                        // push flowers off the right edge on a narrow phone.
                        const spacing = 44.0;
                        final perRow = (constraints.maxWidth / spacing)
                            .floor()
                            .clamp(1, 12)
                            .toInt();
                        return Stack(
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
                            // Flowers, newest last so the garden grows.
                            ...entries.asMap().entries.map((e) {
                              final entry = e.value;
                              final row = e.key ~/ perRow;
                              final col = e.key % perRow;
                              // A flower's shape comes from the line itself,
                              // not from its position in the list, so deleting
                              // one does not reshape every flower after it.
                              final shape = entry.date.day + entry.slot;
                              return Positioned(
                                left: 16 + col * spacing,
                                bottom: 18 + row * 46.0,
                                child: _FlowerWidget(
                                  emoji: _flowerFor(shape),
                                  delay: e.key * 60,
                                  onTap: () => _showDetail(entry, shape),
                                ),
                              );
                            }),
                          ],
                        );
                      },
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
                        hintText: AppLocalizations.of(context)
                            .t('gratitudeGarden.hint'),
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
                  Semantics(
                    button: true,
                    label: AppLocalizations.of(context)
                        .t('gratitudeJournal.saveTooltip'),
                    child: GestureDetector(
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

  void _showDetail(GratitudeEntry entry, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(_flowerFor(index), style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(ctx).t('gratitudeGarden.item')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.text, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(ctx).t('gratitude.plantedOn').replaceAll(
                    '{date}',
                    MaterialLocalizations.of(ctx).formatMediumDate(entry.date),
                  ),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await removeGratitude(_box, entry);
              if (mounted) setState(() {});
            },
            child: Text(
              AppLocalizations.of(ctx).t('gratitudeJournal.deleteTooltip'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).t('dialog.close')),
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
