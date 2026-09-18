import 'package:uuid/uuid.dart';

/// A journal entry persisted in the local database.
class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String mood;
  final List<String> tags;
  final List<String> imagePaths;
  final String? audioPath;
  final bool isFavorite;
  final bool isPinned;
  final String? location;

  JournalEntry({
    String? id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.mood = '',
    this.tags = const [],
    this.imagePaths = const [],
    this.audioPath,
    this.isFavorite = false,
    this.isPinned = false,
    this.location,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'mood': mood,
        'tags': List<String>.from(tags),
        'imagePaths': List<String>.from(imagePaths),
        'audioPath': audioPath,
        'isFavorite': isFavorite,
        'isPinned': isPinned,
        'location': location,
      };

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) => JournalEntry(
        id: map['id']?.toString(),
        title: map['title']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        mood: map['mood']?.toString() ?? '',
        tags: _stringList(map['tags']),
        imagePaths: _stringList(map['imagePaths']),
        audioPath: map['audioPath']?.toString(),
        isFavorite: map['isFavorite'] == true,
        isPinned: map['isPinned'] == true,
        location: map['location']?.toString(),
      );

  static List<String> _stringList(dynamic value) => value is Iterable
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];

  /// Uses a sentinel so nullable values can be intentionally cleared.
  JournalEntry copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    String? mood,
    List<String>? tags,
    List<String>? imagePaths,
    Object? audioPath = _unset,
    bool? isFavorite,
    bool? isPinned,
    Object? location = _unset,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPath:
          identical(audioPath, _unset) ? this.audioPath : audioPath as String?,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      location:
          identical(location, _unset) ? this.location : location as String?,
    );
  }
}

const Object _unset = Object();
