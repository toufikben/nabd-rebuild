import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/journal_templates.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../core/text_direction.dart';
import '../../core/writing_prompts.dart';
import '../../features/garden/bloom_celebration.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../models/tag.dart';
import '../../services/database_service.dart';
import '../../services/garden_service.dart';
import '../../services/home_widget_service.dart';
import '../../services/media_vault.dart';
import '../../services/motivation_service.dart';
import '../../services/review_prompt.dart';
import '../../services/ui_sounds.dart';
import '../../services/voice_to_text_service.dart';
import '../../widgets/audio_note_player.dart';
import '../../widgets/mood_picker.dart';
import '../../widgets/vault_image.dart';

enum _LeaveAction { save, discard, stay }

/// Writing and editing one journal entry.
///
/// Saving rules:
///  • Autosave keeps the draft safe while typing; it never opens the paywall
///    and never rewards the garden or achievements.
///  • Every save of one editor session writes the same entry id, so an
///    autosave racing a manual save can never create a duplicate.
///  • "Discard" really discards: a new entry is deleted, an edited entry is
///    put back exactly as it was opened, and media added meanwhile is removed.
class EditorScreen extends ConsumerStatefulWidget {
  final String? entryId;

  /// A mood chosen before writing, from the check-in on the Today tab.
  final String? initialMood;

  const EditorScreen({super.key, this.entryId, this.initialMood});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final DatabaseService _db = DatabaseService();
  final MediaVault _media = MediaVault();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();
  /// Created on first use: the plugin opens a native recorder on creation,
  /// which an editor that never records does not need.
  AudioRecorder? _recorderInstance;
  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();
  final VoiceToTextService _voice = VoiceToTextService();

  /// The entry as it was when the editor opened; null for a new entry.
  JournalEntry? _original;

  /// The version last written to storage; null until the first save.
  JournalEntry? _saved;

  late final String _entryId;
  bool _missing = false;
  DateTime _createdAt = DateTime.now();
  String? _moodId;
  List<String> _tags = const [];
  List<String> _imagePaths = const [];
  String? _audioPath;

  /// Media files created in this session, removed on leave unless an entry
  /// still points at them.
  final Set<String> _sessionMedia = {};

  bool _isRecording = false;
  String? _recordingPath;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  bool _isDictating = false;
  String _dictationBase = '';

  bool _isSaving = false;
  Future<void>? _inFlight;
  bool _rewarded = false;
  bool _leaving = false;
  Timer? _autosaveTimer;

  bool get _isNewEntry => _original == null;

  @override
  void initState() {
    super.initState();
    final id = widget.entryId;
    if (id == null) {
      _entryId = const Uuid().v4();
      final mood = widget.initialMood;
      if (mood != null && Mood.getById(mood) != null) _moodId = mood;
    } else {
      _entryId = id;
      final entry = _db.findEntry(id);
      if (entry == null) {
        _missing = true;
      } else {
        _original = entry;
        _saved = entry;
        _titleController.text = entry.title;
        _contentController.text = entry.content;
        _createdAt = entry.createdAt;
        _moodId = entry.mood.isEmpty ? null : entry.mood;
        _tags = List.of(entry.tags);
        _imagePaths = List.of(entry.imagePaths);
        _audioPath = entry.audioPath;
      }
    }
    _titleController.addListener(_onDraftChanged);
    _contentController.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _recordTimer?.cancel();
    if (_isDictating) unawaited(_voice.stopListening());
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    final recorder = _recorderInstance;
    if (recorder != null) unawaited(recorder.dispose());
    super.dispose();
  }

  // ─── Draft state ──────────────────────────────────────────────────────

  void _onDraftChanged() {
    if (_missing || !mounted) return;
    _scheduleAutosave();
    setState(() {});
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_leaving && _hasUnsavedChanges) {
        unawaited(_persist(explicit: false));
      }
    });
  }

  /// Any change outside the two text fields goes through here so it is both
  /// redrawn and autosaved.
  void _update(VoidCallback change) {
    setState(change);
    _scheduleAutosave();
  }

  String get _title => _titleController.text.trim();
  String get _content => _contentController.text.trim();
  bool get _isEmpty => _title.isEmpty && _content.isEmpty;

  JournalEntry _buildEntry() {
    final base = _saved ?? _original;
    final now = DateTime.now();
    if (base == null) {
      return JournalEntry(
        id: _entryId,
        title: _title,
        content: _content,
        createdAt: _createdAt,
        updatedAt: now,
        mood: _moodId ?? '',
        tags: List.of(_tags),
        imagePaths: List.of(_imagePaths),
        audioPath: _audioPath,
      );
    }
    return base.copyWith(
      title: _title,
      content: _content,
      createdAt: _createdAt,
      updatedAt: now,
      mood: _moodId ?? '',
      tags: List.of(_tags),
      imagePaths: List.of(_imagePaths),
      audioPath: _audioPath,
    );
  }

  bool get _hasUnsavedChanges {
    final saved = _saved;
    if (saved == null) {
      return !_isEmpty ||
          _moodId != null ||
          _tags.isNotEmpty ||
          _imagePaths.isNotEmpty ||
          _audioPath != null;
    }
    return _title != saved.title ||
        _content != saved.content ||
        (_moodId ?? '') != saved.mood ||
        _createdAt != saved.createdAt ||
        !_sameList(_tags, saved.tags) ||
        !_sameList(_imagePaths, saved.imagePaths) ||
        _audioPath != saved.audioPath;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ─── Saving ───────────────────────────────────────────────────────────

  /// Saves one at a time: a save that arrives while another runs waits for
  /// it, then writes the newest text under the same id.
  Future<bool> _persist({required bool explicit}) async {
    while (_inFlight != null) {
      await _inFlight;
    }
    final done = Completer<void>();
    _inFlight = done.future;
    try {
      return await _persistNow(explicit: explicit);
    } finally {
      _inFlight = null;
      done.complete();
    }
  }

  Future<bool> _persistNow({required bool explicit}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_isEmpty) {
      if (explicit) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.t('editor.empty'))));
      }
      return false;
    }

    if (mounted) setState(() => _isSaving = true);
    try {
      final entry = _buildEntry();
      if (_saved == null) {
        await _db.addEntry(entry);
      } else {
        await _db.updateEntry(entry);
      }
      _saved = entry;
      if (explicit) {
        unawaited(UiSounds.play(UiSound.save));
        await _rewardIfNew();
      }
      return true;
    } catch (error) {
      if (explicit) {
        messenger.showSnackBar(
          SnackBar(content: Text('${l10n.t('common.error')}: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// A new entry waters the garden and is checked for achievements once,
  /// when the writer is done with it, not on every autosave.
  Future<void> _rewardIfNew() async {
    final saved = _saved;
    if (_rewarded || !_isNewEntry || saved == null) return;
    _rewarded = true;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final result = await ref.read(gardenProvider.notifier).water(saved);
      if (result.ok) {
        unawaited(UiSounds.play(
          result.isComplete ? UiSound.bloom : UiSound.water,
          delay: const Duration(milliseconds: 450),
        ));
        if (result.isComplete && result.seed != null) {
          if (mounted) {
            await showBloomCelebration(context, result.seed!);
          }
        } else if (result.messageKey == 'garden.water.noTargets') {
          // Writing is already saved. Point at the next step without blocking
          // the writer with another dialog.
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.t(result.messageKey)),
                action: SnackBarAction(
                  label: l10n.t('garden.title'),
                  onPressed: () => router.push('/garden'),
                ),
              ),
            );
        } else {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.t(result.messageKey))),
            );
        }
      }
    } catch (error) {
      debugPrint('Garden update failed after journal save: $error');
    }
    try {
      final fresh = await AchievementService().unlockFromJournal(
        _db.getAllEntries(),
        contentBox(),
      );
      if (fresh.isNotEmpty) {
        unawaited(UiSounds.play(
          UiSound.bloom,
          delay: const Duration(milliseconds: 1200),
        ));
      }
    } catch (error) {
      debugPrint('Achievement evaluation failed after journal save: $error');
    }
    unawaited(ReviewPrompt().recordWin());
  }

  Future<void> _saveAndClose() async {
    _autosaveTimer?.cancel();
    await _stopCapture();
    final ok = await _persist(explicit: true);
    if (!ok || !mounted) return;
    await _leave();
  }

  // ─── Leaving ──────────────────────────────────────────────────────────

  Future<void> _handleBack() async {
    if (_leaving) return;
    _autosaveTimer?.cancel();
    await _stopCapture();
    if (_missing) return _leave();

    // A new entry with only a few characters may be a stray draft that
    // autosave already stored: it is never kept without asking. An empty
    // one simply goes.
    final length = _title.trim().length + _content.trim().length;
    final bare = _isNewEntry && _imagePaths.isEmpty && _audioPath == null;
    if (bare && length == 0) {
      await _discard();
      return;
    }
    final doubtful = bare && length < 20;

    if (!_hasUnsavedChanges && !doubtful) {
      // Autosave already holds everything; finishing still counts.
      await _rewardIfNew();
      return _leave();
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('editor.unsaved.title')),
        content: Text(l10n.t('editor.unsaved.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveAction.discard),
            child: Text(l10n.t('editor.unsaved.discard')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveAction.stay),
            child: Text(l10n.t('editor.unsaved.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveAction.save),
            child: Text(l10n.t('editor.unsaved.save')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _LeaveAction.save:
        await _saveAndClose();
      case _LeaveAction.discard:
        await _discard();
      case _LeaveAction.stay:
      case null:
        break;
    }
  }

  /// Puts storage back as it was before this editor opened.
  Future<void> _discard() async {
    final original = _original;
    final saved = _saved;
    if (original == null) {
      if (saved != null) await _db.deleteEntry(saved.id);
    } else if (saved != null && !identical(saved, original)) {
      await _db.updateEntry(original);
    }
    await _leave();
  }

  Future<void> _leave() async {
    _leaving = true;
    await _db.discardDraftMedia(_sessionMedia.toList());
    if (!mounted) return;
    unawaited(HomeWidgetService.refresh(AppLocalizations.of(context)));
    // Opened from a link or the widget, the editor is the only page: there
    // is nothing to pop back to, so it hands over to Today.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  // ─── Entry actions ────────────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    final entry = _saved;
    if (entry == null) return;
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);
    await _db.updateEntry(updated);
    if (!mounted) return;
    setState(() {
      _saved = updated;
      if (_original != null) {
        _original = _original!.copyWith(isFavorite: updated.isFavorite);
      }
    });
  }

  Future<void> _togglePinned() async {
    final entry = _saved;
    if (entry == null) return;
    final updated = entry.copyWith(isPinned: !entry.isPinned);
    await _db.updateEntry(updated);
    if (!mounted) return;
    setState(() {
      _saved = updated;
      if (_original != null) {
        _original = _original!.copyWith(isPinned: updated.isPinned);
      }
    });
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('editor.delete.title')),
        content: Text(l10n.t('editor.delete.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.t('editor.delete.action')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _autosaveTimer?.cancel();
    final saved = _saved;
    if (saved != null) await _db.deleteEntry(saved.id);
    await _leave();
  }

  // ─── Details: date, mood, tags ────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _createdAt.isAfter(now) ? now : _createdAt,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: AppLocalizations.of(context).t('editor.date'),
    );
    if (picked == null || !mounted) return;
    // Keep the time of day; only the calendar day moves.
    _update(() => _createdAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _createdAt.hour,
          _createdAt.minute,
        ));
  }

  Future<void> _pickMood() async {
    final l10n = AppLocalizations.of(context);
    final moodId = await MoodPicker.show(
      context,
      currentMoodId: _moodId,
      langCode: l10n.locale.languageCode,
      moods: Mood.journalMoods,
    );
    if (mounted && moodId != null) _update(() => _moodId = moodId);
  }

  Future<void> _addTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => const _AddTagDialog(),
    );
    // "#work" and "Work" are the same tag; the leading # is display only.
    final name = tag?.trim().replaceFirst(RegExp(r'^#+'), '').trim() ?? '';
    if (mounted &&
        name.isNotEmpty &&
        !_tags.any((t) => Tag.keyOf(t) == Tag.keyOf(name))) {
      _update(() => _tags = [..._tags, name]);
    }
  }

  // ─── Media ────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final room = AppConstants.maxImagesPerEntry - _imagePaths.length;
    if (room <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('editor.images.limit'))),
      );
      return;
    }
    // Downscaled and recompressed at pick time: a journal photo does not
    // need 12 megapixels, and backups stay small.
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    if (picked.length > room) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('editor.images.limit'))),
      );
    }
    final added = <String>[];
    for (final image in picked.take(room)) {
      try {
        final stored = await _media.importFile(
          File(image.path),
          folder: MediaVault.imagesDir,
          deleteSource: true,
        );
        added.add(stored);
        _sessionMedia.add(stored);
      } catch (error) {
        debugPrint('Image import failed: $error');
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('editor.media.failed'))),
        );
      }
    }
    if (mounted && added.isNotEmpty) {
      _update(() => _imagePaths = [..._imagePaths, ...added]);
    }
  }

  void _removeImage(String path) {
    _update(() => _imagePaths = _imagePaths.where((p) => p != path).toList());
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await _recorder.hasPermission()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('editor.audio.denied'))),
      );
      return;
    }
    if (_isDictating) await _stopDictation();
    // Recorded in the temp directory and moved into the vault on stop, so a
    // plain copy never sits in the documents directory.
    final temp = await getTemporaryDirectory();
    final path =
        '${temp.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= AppConstants.maxAudioSeconds) {
        unawaited(_stopRecording());
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final path = await _recorder.stop() ?? _recordingPath;
    if (mounted) setState(() => _isRecording = false);
    if (path == null) return;
    try {
      final stored = await _media.importFile(
        File(path),
        folder: MediaVault.audioDir,
        deleteSource: true,
      );
      _sessionMedia.add(stored);
      if (mounted) _update(() => _audioPath = stored);
    } catch (error) {
      debugPrint('Recording import failed: $error');
    }
  }

  Future<void> _toggleDictation() async {
    if (_isDictating) {
      await _stopDictation();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_isRecording) await _stopRecording();
    if (!await _voice.initialize()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('editor.dictation.unavailable'))),
      );
      return;
    }
    await _startDictation(l10n);
  }

  /// Offline first: the phone's on-device recogniser keeps speech on the
  /// phone. Online is used only after the user agreed to it once.
  Future<void> _startDictation(AppLocalizations l10n) async {
    final offline = !VoiceToTextService.onlineAllowed;
    _dictationBase = _contentController.text.trimRight();
    setState(() => _isDictating = true);
    await _voice.startListening(
      localeId: l10n.language.speechLocale,
      offline: offline,
      onResult: (words) {
        if (!mounted) return;
        final joiner = _dictationBase.isEmpty ? '' : ' ';
        _contentController.value = TextEditingValue(
          text: '$_dictationBase$joiner$words',
          selection: TextSelection.collapsed(
            offset: _dictationBase.length + joiner.length + words.length,
          ),
        );
      },
      onDone: () {
        if (mounted && _isDictating) setState(() => _isDictating = false);
      },
      onProblem: (problem) => _onDictationProblem(problem, l10n),
    );
  }

  Future<void> _onDictationProblem(
    DictationProblem problem,
    AppLocalizations l10n,
  ) async {
    if (!mounted) return;
    setState(() => _isDictating = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (problem) {
      case DictationProblem.silence:
        return;
      case DictationProblem.network:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('editor.dictation.network'))),
        );
      case DictationProblem.other:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('editor.dictation.unavailable'))),
        );
      case DictationProblem.noOfflinePack:
        if (await _allowOnlineDictation(l10n) && mounted) {
          await _startDictation(l10n);
        }
    }
  }

  /// Asked only when the offline voice pack is missing: install it, or let
  /// the phone's online speech service do the work from now on.
  Future<bool> _allowOnlineDictation(AppLocalizations l10n) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('editor.dictation.noPackTitle')),
        content: Text(
          '${l10n.t('editor.dictation.noPackBody').replaceAll('{language}', l10n.language.nativeName)}'
          '\n\n${l10n.t('editor.dictation.noticeBody')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.t('editor.dictation.useOnline')),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    await VoiceToTextService.setOnlineAllowed(true);
    return true;
  }

  Future<void> _chooseTemplate() async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<JournalTemplate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.t('editor.templates'),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final template in JournalTemplate.all)
              ListTile(
                leading: Icon(template.icon),
                title: Text(l10n.t(template.titleKey)),
                subtitle: Text(l10n.t(template.hintKey)),
                onTap: () => Navigator.of(sheetContext).pop(template),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final (text, cursor) =
        JournalTemplate.insert(_contentController.text, l10n.t(chosen.bodyKey));
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = l10n.t(chosen.titleKey);
    }
    _contentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _contentFocus.requestFocus();
  }

  Future<void> _stopDictation() async {
    if (!_isDictating) return;
    await _voice.stopListening();
    if (mounted) setState(() => _isDictating = false);
  }

  Future<void> _stopCapture() async {
    await _stopRecording();
    await _stopDictation();
  }

  // ─── UI ───────────────────────────────────────────────────────────────

  int get _wordCount =>
      _content.isEmpty ? 0 : _content.split(RegExp(r'\s+')).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saved = _saved;

    if (_missing) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.t('editor.notFound'))),
      );
    }

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isNewEntry ? l10n.t('editor.title.new') : l10n.t('editor.title.edit'),
          ),
          actions: [
            if (saved != null) ...[
              IconButton(
                tooltip: saved.isFavorite
                    ? l10n.t('editor.favorite.remove')
                    : l10n.t('editor.favorite.add'),
                icon: Icon(
                  saved.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: saved.isFavorite ? scheme.error : null,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                tooltip: saved.isPinned
                    ? l10n.t('editor.pin.unpin')
                    : l10n.t('editor.pin'),
                icon: Icon(
                  saved.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                onPressed: _togglePinned,
              ),
              IconButton(
                tooltip: l10n.t('editor.delete.action'),
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: _confirmDelete,
              ),
            ],
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: IconButton.filledTonal(
                tooltip: l10n.t('editor.unsaved.save'),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                onPressed: _isSaving ? null : _saveAndClose,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _DetailsBar(
                date: _createdAt,
                locale: l10n.locale.languageCode,
                mood: _moodId == null ? null : Mood.getById(_moodId!),
                tags: _tags,
                onDate: _pickDate,
                onMood: _pickMood,
                onAddTag: _addTag,
                onRemoveTag: (tag) =>
                    _update(() => _tags = _tags.where((t) => t != tag).toList()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _titleController,
                  textDirection: textDirectionOf(
                    _titleController.text,
                    Directionality.of(context),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: l10n.t('editor.title.hint'),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocus,
                    textDirection: textDirectionOf(
                      _contentController.text,
                      Directionality.of(context),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                    decoration: InputDecoration(
                      hintText: _isNewEntry
                          ? WritingPrompts.today(l10n)
                          : l10n.t('editor.body.hint'),
                      hintMaxLines: 3,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ),
              if (_imagePaths.isNotEmpty)
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _Thumbnail(
                      path: _imagePaths[i],
                      onOpen: () =>
                          VaultGalleryScreen.open(context, _imagePaths, i),
                      onRemove: () => _removeImage(_imagePaths[i]),
                    ),
                  ),
                ),
              if (_audioPath != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AudioNotePlayer(
                    key: ValueKey(_audioPath),
                    storedPath: _audioPath!,
                    onRemove: () => _update(() => _audioPath = null),
                  ),
                ),
              _Toolbar(
                isRecording: _isRecording,
                recordSeconds: _recordSeconds,
                isDictating: _isDictating,
                wordCount: _wordCount,
                onDictate: _toggleDictation,
                onRecord: _toggleRecording,
                onPhoto: _pickImages,
                onTemplate: _chooseTemplate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsBar extends StatelessWidget {
  const _DetailsBar({
    required this.date,
    required this.locale,
    required this.mood,
    required this.tags,
    required this.onDate,
    required this.onMood,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final DateTime date;
  final String locale;
  final Mood? mood;
  final List<String> tags;
  final VoidCallback onDate;
  final VoidCallback onMood;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final mood = this.mood;
    // Wraps instead of scrolling sideways: with a tag or two a scrolling row
    // pushed "Add tag" past the edge, out of sight and out of TalkBack.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.event_outlined, size: 18),
            label: Text(DateFormat.MMMEd(locale).format(date)),
            tooltip: l10n.t('editor.date'),
            onPressed: onDate,
          ),
          ActionChip(
            avatar: Text(mood?.emoji ?? '🙂',
                style: const TextStyle(fontSize: 16)),
            label: Text(mood?.label(locale) ?? l10n.t('editor.mood')),
            backgroundColor: mood?.color.withValues(alpha: 0.14),
            side: mood == null
                ? null
                : BorderSide(color: mood.color.withValues(alpha: 0.4)),
            onPressed: onMood,
          ),
          for (final tag in tags)
            InputChip(
              label: Text('#${localizedTagName(l10n, tag)}'),
              onDeleted: () => onRemoveTag(tag),
              backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.6),
            ),
          ActionChip(
            avatar: const Icon(Icons.sell_outlined, size: 18),
            label: Text(l10n.t('editor.tag.add')),
            onPressed: onAddTag,
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.path,
    required this.onOpen,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 88,
      child: Stack(
        children: [
          Positioned.fill(
            top: 6,
            child: GestureDetector(
              onTap: onOpen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: VaultImage(path),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Material(
              color: scheme.inverseSurface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 14, color: scheme.onInverseSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.isRecording,
    required this.recordSeconds,
    required this.isDictating,
    required this.wordCount,
    required this.onDictate,
    required this.onRecord,
    required this.onPhoto,
    required this.onTemplate,
  });

  final bool isRecording;
  final int recordSeconds;
  final bool isDictating;
  final int wordCount;
  final VoidCallback onDictate;
  final VoidCallback onRecord;
  final VoidCallback onPhoto;
  final VoidCallback onTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minutes = (recordSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordSeconds % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.t(isDictating ? 'editor.dictate.stop' : 'editor.dictate'),
            onPressed: onDictate,
            icon: Icon(
              isDictating
                  ? Icons.record_voice_over
                  : Icons.record_voice_over_outlined,
              color: isDictating ? scheme.primary : null,
            ),
          ),
          IconButton(
            tooltip: l10n.t(isRecording ? 'editor.audio.stop' : 'editor.audio.record'),
            onPressed: onRecord,
            icon: Icon(
              isRecording ? Icons.stop_circle : Icons.mic_none_rounded,
              color: isRecording ? scheme.error : null,
            ),
          ),
          IconButton(
            tooltip: l10n.t('editor.images.add'),
            onPressed: onPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          IconButton(
            tooltip: l10n.t('editor.templates'),
            onPressed: onTemplate,
            icon: const Icon(Icons.article_outlined),
          ),
          const Spacer(),
          if (isRecording)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, size: 12, color: scheme.error),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${l10n.t('editor.recording')} $minutes:$seconds',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: Text(
                '$wordCount ${l10n.t('editor.words')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Owns its [TextEditingController] so the controller is only released once
/// the dialog route has finished animating out and its `TextField` is gone.
class _AddTagDialog extends StatefulWidget {
  const _AddTagDialog();

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.t('editor.tag.add')),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: l10n.t('editor.tag.name')),
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('dialog.cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.t('dialog.add')),
        ),
      ],
    );
  }
}
