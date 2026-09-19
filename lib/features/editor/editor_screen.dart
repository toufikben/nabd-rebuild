import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../services/garden_service.dart';
import '../../services/motivation_service.dart';
import '../../services/monetization_service.dart';
import '../../widgets/mood_picker.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const EditorScreen({super.key, this.entryId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();

  JournalEntry? _existing;
  String? _moodId;
  List<String> _tags = [];
  List<String> _imagePaths = [];
  String? _audioPath;
  bool _isRecording = false;
  bool _isSaving = false;
  bool _draftReady = false;
  bool _isNewEntry = false;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    _isNewEntry = widget.entryId == null;
    _titleController.addListener(_onDraftChanged);
    _contentController.addListener(_onDraftChanged);
    _loadEntry();
  }

  void _loadEntry() {
    if (widget.entryId == null) {
      _draftReady = true;
      return;
    }
    try {
      final entries = _db.getAllEntries();
      final entry = entries.firstWhere((e) => e.id == widget.entryId);
      setState(() {
        _existing = entry;
        _titleController.text = entry.title;
        _contentController.text = entry.content;
        _moodId = entry.mood.isEmpty ? null : entry.mood;
        _tags = List<String>.from(entry.tags);
        _imagePaths = List<String>.from(entry.imagePaths);
        _audioPath = entry.audioPath;
        _draftReady = true;
      });
    } catch (error) {
      debugPrint('Unable to load journal entry: $error');
    }
  }

  void _onDraftChanged() {
    if (!_draftReady || !mounted) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _hasUnsavedChanges) {
        unawaited(_saveEntry(closeAfterSave: false));
      }
    });
    setState(() {});
  }

  bool get _hasUnsavedChanges {
    final existing = _existing;
    if (existing == null) {
      return _titleController.text.trim().isNotEmpty ||
          _contentController.text.trim().isNotEmpty ||
          _moodId != null ||
          _tags.isNotEmpty ||
          _imagePaths.isNotEmpty ||
          _audioPath != null;
    }
    return _titleController.text.trim() != existing.title ||
        _contentController.text.trim() != existing.content ||
        (_moodId ?? '') != existing.mood ||
        !_sameList(_tags, existing.tags) ||
        !_sameList(_imagePaths, existing.imagePaths) ||
        _audioPath != existing.audioPath;
  }

  bool _sameList(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _saveEntry({bool closeAfterSave = true}) async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save empty entry')),
      );
      return;
    }

    final monetization = ref.read(monetizationProvider.notifier);
    if (_existing == null &&
        !monetization.isProActive &&
        !_db.canCreateFreeEntry()) {
      if (mounted) context.push('/paywall');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final entry = _existing != null
          ? _existing!.copyWith(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              mood: _moodId ?? '',
              tags: _tags,
              imagePaths: _imagePaths,
              audioPath: _audioPath,
              updatedAt: now,
            )
          : JournalEntry(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              createdAt: now,
              updatedAt: now,
              mood: _moodId ?? '',
              tags: _tags,
              imagePaths: _imagePaths,
              audioPath: _audioPath,
            );

      if (_existing != null) {
        await _db.updateEntry(entry);
      } else {
        await _db.addEntry(entry,
            isPro: ref.read(monetizationProvider.notifier).isProActive);
        _existing = entry;
        await _processPostSave(entry);
      }

      if (mounted) {
        setState(() {});
        if (closeAfterSave) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry saved')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleBack() async {
    _autosaveTimer?.cancel();
    if (!_hasUnsavedChanges) {
      if (mounted) context.pop();
      return;
    }

    final length = _titleController.text.trim().length +
        _contentController.text.trim().length;
    if (length < 20) {
      if (_isNewEntry && _existing != null) {
        await _db.deleteEntry(_existing!.id);
      }
      if (mounted) context.pop();
      return;
    }

    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save this entry before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'save') {
      await _saveEntry();
    } else if (action == 'discard') {
      if (_isNewEntry && _existing != null) {
        await _db.deleteEntry(_existing!.id);
      }
      if (mounted) context.pop();
    }
  }

  Future<void> _processPostSave(JournalEntry entry) async {
    try {
      await ref.read(gardenProvider.notifier).water(entry);
    } catch (error) {
      debugPrint('Garden update failed after journal save: $error');
    }

    try {
      final entries = _db.getAllEntries();
      final dates = entries
          .map((item) => DateTime(
              item.createdAt.year, item.createdAt.month, item.createdAt.day))
          .toSet();
      var streak = 0;
      var day = DateTime.now();
      while (dates.contains(DateTime(day.year, day.month, day.day))) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      final service = AchievementService();
      final newAchievements = service.checkNew(
        entries: entries.length,
        streak: streak,
        words: _db.getWordCount(),
        moods: entries
            .map((item) => item.mood)
            .where((mood) => mood.isNotEmpty)
            .toSet()
            .length,
        gratitudeDays: 0,
      );
      for (final achievement in newAchievements) {
        await service.unlock(achievement);
      }
    } catch (error) {
      debugPrint('Achievement evaluation failed after journal save: $error');
    }
  }

  Future<void> _toggleFavorite() async {
    final entry = _existing;
    if (entry == null) return;
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);
    await _db.updateEntry(updated);
    if (mounted) setState(() => _existing = updated);
  }

  Future<void> _togglePinned() async {
    final entry = _existing;
    if (entry == null) return;
    final updated = entry.copyWith(isPinned: !entry.isPinned);
    await _db.updateEntry(updated);
    if (mounted) setState(() => _existing = updated);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    final docs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docs.path}/images');
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    final newPaths = <String>[];
    for (final img in images) {
      final newPath =
          '${imagesDir.path}/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
      await File(img.path).copy(newPath);
      newPaths.add(newPath);
    }

    if (mounted) setState(() => _imagePaths = [..._imagePaths, ...newPaths]);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final docs = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${docs.path}/audio');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);

    final path =
        '${audioDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    if (!mounted) return;
    await _recorder.start(const RecordConfig(), path: path);
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _pickMood() async {
    final moodId = await MoodPicker.show(
      context,
      currentMoodId: _moodId,
      langCode: 'en',
      moods: Mood.journalMoods,
    );
    if (mounted) setState(() => _moodId = moodId);
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tag name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (mounted && tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags = [..._tags, tag]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodId == null ? null : Mood.getById(_moodId!);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_existing == null ? 'New Entry' : 'Edit Entry'),
          actions: [
            if (_existing != null)
              IconButton(
                tooltip:
                    _existing!.isFavorite ? 'Remove favorite' : 'Add favorite',
                icon: Icon(_existing!.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border),
                onPressed: _toggleFavorite,
              ),
            if (_existing != null)
              IconButton(
                tooltip: _existing!.isPinned ? 'Unpin' : 'Pin',
                icon: Icon(_existing!.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined),
                onPressed: _togglePinned,
              ),
            if (_existing != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _confirmDelete(),
              ),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveEntry,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ─── Mood + Tags bar ───
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Mood
                    GestureDetector(
                      onTap: _pickMood,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: mood != null
                              ? mood.color.withValues(alpha: 0.15)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: mood != null
                                ? mood.color.withValues(alpha: 0.5)
                                : AppColors.textTertiary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mood?.emoji ?? '😐',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              mood?.label('en') ?? 'Mood',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: mood?.color ?? AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add tag button
                    IconButton(
                      onPressed: _addTag,
                      icon: const Icon(Icons.label_outline, size: 20),
                      tooltip: 'Add tag',
                    ),
                    const Spacer(),
                    // Audio recorder
                    IconButton(
                      onPressed: _toggleRecording,
                      icon: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording ? AppColors.danger : null,
                      ),
                      tooltip: _isRecording ? 'Stop recording' : 'Record audio',
                    ),
                    // Image picker
                    IconButton(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image_outlined),
                      tooltip: 'Add images',
                    ),
                  ],
                ),
              ),

              // ─── Tags chips ───
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 8),

              // ─── Title ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),

              // ─── Divider ───
              const Divider(indent: 16, endIndent: 16),

              // ─── Content ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Images preview ───
              if (_imagePaths.isNotEmpty)
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _imagePaths.length,
                    itemBuilder: (_, i) {
                      final path = _imagePaths[i];
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _imagePaths.removeAt(i));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // ─── Audio indicator ───
              if (_audioPath != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.audiotrack,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Audio recording attached',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          onPressed: () => setState(() => _audioPath = null),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && _existing != null) {
      await _db.deleteEntry(_existing!.id);
      if (mounted) context.pop();
    }
  }
}
