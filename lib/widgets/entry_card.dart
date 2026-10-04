import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_localizations.dart';
import '../core/text_direction.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import 'nabd_ui.dart';

/// One journal entry in a list: the day on the leading side, then the title,
/// a two-line preview, and quiet markers for mood, media, favourite and pin.
class EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = l10n.locale.languageCode;
    final mood = Mood.getById(entry.mood);
    final title = entry.title.trim();
    final preview = entry.content.trim().replaceAll(RegExp(r'\s+'), ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NabdCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: (mood?.color ?? scheme.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat.d(locale).format(entry.createdAt),
                    style: theme.textTheme.titleLarge?.copyWith(height: 1.1),
                  ),
                  Text(
                    DateFormat.MMM(locale).format(entry.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.isEmpty
                              ? DateFormat.EEEE(locale).format(entry.createdAt)
                              : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: textDirectionOf(
                              title, Directionality.of(context)),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (entry.isPinned)
                        Icon(Icons.push_pin, size: 15, color: scheme.primary),
                      if (entry.isFavorite)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4),
                          child: Icon(Icons.favorite,
                              size: 15, color: scheme.tertiary),
                        ),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      maxLines: 2,
                      textDirection: textDirectionOf(
                          preview, Directionality.of(context)),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        DateFormat.jm(locale).format(entry.createdAt),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      if (mood != null)
                        Text(
                          '${mood.emoji} ${mood.label(locale)}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: mood.color),
                        ),
                      if (entry.imagePaths.isNotEmpty)
                        _Marker(
                          icon: Icons.photo_outlined,
                          text: '${entry.imagePaths.length}',
                        ),
                      if (entry.audioPath != null)
                        const _Marker(icon: Icons.graphic_eq, text: ''),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        if (text.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(text, style: TextStyle(fontSize: 11, color: color)),
        ],
      ],
    );
  }
}
