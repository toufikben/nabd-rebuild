import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../services/r_personal_service.dart';

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
    final result = await showModalBottomSheet<_LetterDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _LetterComposer(),
    );
    if (result == null || result.content.trim().isEmpty) return;
    final now = DateTime.now();
    await _service.saveLetter(
      PersonalLetter(
        id: const Uuid().v4(),
        kind: result.kind,
        address:
            result.address.trim().isEmpty
                ? 'My future self'
                : result.address.trim(),
        content: result.content.trim(),
        createdAt: now,
        unlockDate:
            result.kind == PersonalLetterKind.future
                ? result.unlockDate ?? now.add(const Duration(days: 365))
                : null,
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _delete(PersonalLetter letter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete letter?'),
            content: const Text('This removes the letter from local storage.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await _service.deleteLetter(letter);
      if (mounted) _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters'),
        actions: [
          IconButton(
            onPressed: _createLetter,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createLetter,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New letter'),
      ),
      body:
          _letters.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _letters.length,
                itemBuilder: (_, index) {
                  final letter = _letters[index];
                  return _LetterCard(
                    letter: letter,
                    onDelete: () => _delete(letter),
                  );
                },
              ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.letter, required this.onDelete});
  final PersonalLetter letter;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final future = letter.kind == PersonalLetterKind.future;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  future ? Icons.schedule_rounded : Icons.mail_outline_rounded,
                  color: future ? AppColors.primary : AppColors.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    future ? 'Future letter' : 'Unsent letter',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            if (!future && letter.address.isNotEmpty)
              Text(
                'To: ${letter.address}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            if (future && letter.unlockDate != null)
              Text(
                'Opens: ${_date(letter.unlockDate!)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 10),
            Text(
              letter.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.55),
            ),
            const SizedBox(height: 10),
            Text(
              _date(letter.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a letter',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            SegmentedButton<PersonalLetterKind>(
              segments: const [
                ButtonSegment(
                  value: PersonalLetterKind.unsent,
                  label: Text('Unsent'),
                  icon: Icon(Icons.lock_outline_rounded),
                ),
                ButtonSegment(
                  value: PersonalLetterKind.future,
                  label: Text('Future'),
                  icon: Icon(Icons.schedule_rounded),
                ),
              ],
              selected: {_kind},
              onSelectionChanged:
                  (value) => setState(() => _kind = value.first),
            ),
            const SizedBox(height: 14),
            if (_kind == PersonalLetterKind.unsent)
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'To (optional)'),
              ),
            if (_kind == PersonalLetterKind.future) ...[
              Text(
                'Unlock date: ${_unlockDate.day}/${_unlockDate.month}/${_unlockDate.year}',
              ),
              TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    initialDate: _unlockDate,
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _unlockDate = date);
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Choose date'),
              ),
            ],
            TextField(
              controller: _content,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Write what you want to keep...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    () => Navigator.pop(
                      context,
                      _LetterDraft(
                        kind: _kind,
                        address: _address.text,
                        content: _content.text,
                        unlockDate: _unlockDate,
                      ),
                    ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save locally'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.mail_outline_rounded, size: 56, color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Your letters stay on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Write to your future self or keep words safely unsent.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
