import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/seed.dart';

/// Shows the moment a seed reaches full bloom and lets the writer keep or
/// share the certificate that was stored with the seed.
Future<void> showBloomCelebration(
  BuildContext context,
  PlantedSeed seed,
) async {
  final l10n = AppLocalizations.of(context);
  final language = l10n.locale.languageCode;
  final plant = seed.seed;
  if (plant == null) return;

  final completedAt = seed.completedAt ?? DateTime.now();
  final date = MaterialLocalizations.of(context).formatMediumDate(completedAt);
  final shareText = '${plant.nameFor(language)}\n'
      '${l10n.t('garden.watering.bloom')}\n'
      '$date';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              plant.flowerEmoji,
              style: const TextStyle(fontSize: 76),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.t('garden.watering.congrats'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plant.nameFor(language),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: plant.colors.last,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('garden.watering.bloom'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.t('dialog.done')),
              ),
            ),
            TextButton.icon(
              onPressed: () => Share.share(shareText),
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(l10n.t('garden.certificate.share')),
            ),
          ],
        ),
      ),
    ),
  );
}
