import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/seed.dart';
import '../../services/garden_service.dart';

/// Every seed that reached full bloom, grouped by the season it finished in.
class GardenShowcaseScreen extends ConsumerStatefulWidget {
  const GardenShowcaseScreen({super.key});

  @override
  ConsumerState<GardenShowcaseScreen> createState() =>
      _GardenShowcaseScreenState();
}

class _GardenShowcaseScreenState extends ConsumerState<GardenShowcaseScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final garden = ref.read(gardenProvider.notifier);
    final current = ref
        .watch(gardenProvider)
        .seeds
        .where((seed) => seed.isComplete)
        .toList();
    final archived = garden.archivedSeeds;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('garden.showcase.title')),
        actions: [
          IconButton(
            tooltip: l10n.t('garden.showcase.share'),
            onPressed: _sharing || (current.isEmpty && archived.isEmpty)
                ? null
                : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: current.isEmpty && archived.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.t('garden.showcase.empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: _ShowcaseCard(
                  current: current,
                  archived: archived,
                  currentSeason: garden.currentSeason,
                ),
              ),
            ),
    );
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Showcase is not rendered');
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Showcase image is empty');
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'nabd_garden_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: l10n.t('garden.showcase.text'),
      );
    } catch (error) {
      debugPrint('Garden showcase could not be shared: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('garden.showcase.shareFailed'))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _ShowcaseCard extends StatelessWidget {
  final List<PlantedSeed> current;
  final List<ArchivedSeed> archived;
  final int currentSeason;

  const _ShowcaseCard({
    required this.current,
    required this.archived,
    required this.currentSeason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seasons = <int, List<PlantedSeed>>{};
    if (current.isNotEmpty) seasons[currentSeason] = current;
    for (final entry in archived) {
      seasons.putIfAbsent(entry.season, () => []).add(entry.seed);
    }
    final ordered = seasons.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🌳',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            l10n.t('garden.showcase.title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('garden.showcase.subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          for (final season in ordered) ...[
            Text(
              season == currentSeason
                  ? l10n.t('garden.showcase.current')
                  : l10n
                      .t('garden.showcase.season')
                      .replaceAll('{season}', '$season'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF33691E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: [
                for (final seed in seasons[season]!) _BloomedPlant(seed: seed),
              ],
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class _BloomedPlant extends StatelessWidget {
  final PlantedSeed seed;

  const _BloomedPlant({required this.seed});

  @override
  Widget build(BuildContext context) {
    final plant = seed.seed;
    if (plant == null) return const SizedBox.shrink();
    final language = AppLocalizations.of(context).locale.languageCode;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: plant.colors.last.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child:
                Text(plant.flowerEmoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 6),
          Text(
            plant.nameFor(language),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }
}
