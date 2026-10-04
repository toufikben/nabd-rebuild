import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/r_personal_service.dart';
import '../../widgets/nabd_ui.dart';

/// Letters, one place for both kinds: letters you will never send, and
/// letters to your future self that stay sealed until the day they open
/// (time capsules became the latter).
class LettersScreen extends StatefulWidget {
  const LettersScreen({super.key});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  final _service = RPersonalService();
  List<PersonalLetter> _letters = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _letters = _service.getLetters());

  Future<void> _createLetter() async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<_LetterDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LetterComposer(),
    );
    if (result == null || result.content.trim().isEmpty) return;
    final now = DateTime.now();
    final letter = PersonalLetter(
      id: const Uuid().v4(),
      kind: result.kind,
      address: result.address.trim().isEmpty
          ? l10n.t('letters.futureSelf')
          : result.address.trim(),
      content: result.content.trim(),
      createdAt: now,
      unlockDate: result.kind == PersonalLetterKind.future
          ? result.unlockDate ?? now.add(const Duration(days: 365))
          : null,
    );
    await _service.saveLetter(letter);
    if (letter.isFuture && letter.unlockDate != null) {
      await NotificationService.scheduleLetterUnlock(
        letterId: letter.id,
        opensAt: letter.unlockDate!,
        title: l10n.t('notify.letter.title'),
        body: l10n.t('notify.letter.body'),
      );
    }
    if (mounted) _reload();
  }

  Future<void> _delete(PersonalLetter letter) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('letters.delete.title')),
        content: Text(l10n.t('letters.delete.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('dialog.delete.action')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteLetter(letter);
    try {
      await NotificationService.cancelLetterUnlock(letter.id);
    } catch (_) {}
    if (mounted) _reload();
  }

  void _read(PersonalLetter letter) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.locale.languageCode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(
              '${l10n.t('letters.to')} ${letter.address}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.t('letters.writtenOn')} '
              '${DateFormat.yMMMMd(locale).format(letter.createdAt)}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SelectableText(letter.content, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('letters.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createLetter,
        icon: const Icon(Icons.edit_rounded),
        label: Text(l10n.t('letters.new')),
      ),
      body: _letters.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                emoji: '💌',
                title: l10n.t('letters.privacyNote'),
                body: l10n.t('letters.subtitle'),
              ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _letters.length,
              itemBuilder: (_, index) {
                final letter = _letters[index];
                return _LetterCard(
                  letter: letter,
                  onOpen: () => _read(letter),
                  onDelete: () => _delete(letter),
                );
              },
            ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.letter,
    required this.onOpen,
    required this.onDelete,
  });

  final PersonalLetter letter;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = l10n.locale.languageCode;
    final future = letter.isFuture;
    final opensAt = letter.unlockDate;
    final sealed = future &&
        opensAt != null &&
        opensAt.isAfter(DateTime.now());
    final daysLeft =
        sealed ? opensAt.difference(DateTime.now()).inDays + 1 : 0;
    final accent = future ? AppColors.pulse : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NabdCard(
        onTap: sealed ? null : onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    sealed
                        ? Icons.lock_clock_outlined
                        : future
                            ? Icons.drafts_outlined
                            : Icons.mail_outline_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t(future
                            ? 'letters.kindFuture'
                            : 'letters.kindUnsent'),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        future && opensAt != null
                            ? '${l10n.t(sealed ? 'letters.opensOn' : 'letters.opened')} '
                                '${DateFormat.yMMMd(locale).format(opensAt)}'
                            : '${l10n.t('letters.to')} ${letter.address}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: l10n.t('dialog.delete.action'),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sealed)
              Row(
                children: [
                  Icon(Icons.hourglass_bottom_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.t('letters.sealed')} · $daysLeft ${l10n.t('letters.daysLeft')}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              )
            else
              Text(
                letter.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _LetterDraft {
  const _LetterDraft({
    required this.kind,
    required this.address,
    required this.content,
    this.unlockDate,
  });

  final PersonalLetterKind kind;
  final String address;
  final String content;
  final DateTime? unlockDate;
}

class _LetterComposer extends StatefulWidget {
  const _LetterComposer();

  @override
  State<_LetterComposer> createState() => _LetterComposerState();
}

class _LetterComposerState extends State<_LetterComposer> {
  final _address = TextEditingController();
  final _content = TextEditingController();
  PersonalLetterKind _kind = PersonalLetterKind.unsent;
  DateTime _unlockDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _address.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.locale.languageCode;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.t('letters.write'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            SegmentedButton<PersonalLetterKind>(
              segments: [
                ButtonSegment(
                  value: PersonalLetterKind.unsent,
                  label: Text(l10n.t('letters.tabUnsent')),
                  icon: const Icon(Icons.mail_outline_rounded),
                ),
                ButtonSegment(
                  value: PersonalLetterKind.future,
                  label: Text(l10n.t('letters.tabFuture')),
                  icon: const Icon(Icons.schedule_rounded),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.first),
            ),
            const SizedBox(height: 14),
            if (_kind == PersonalLetterKind.unsent)
              TextField(
                controller: _address,
                decoration:
                    InputDecoration(labelText: l10n.t('letters.toOptional')),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    initialDate: _unlockDate,
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _unlockDate = date);
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  '${l10n.t('letters.opensOn')} '
                  '${DateFormat.yMMMMd(locale).format(_unlockDate)}',
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 8,
              minLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.t('letters.bodyHint')),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                _LetterDraft(
                  kind: _kind,
                  address: _address.text,
                  content: _content.text,
                  unlockDate: _unlockDate,
                ),
              ),
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(l10n.t('letters.saveLocal')),
            ),
          ],
        ),
      ),
    );
  }
}
