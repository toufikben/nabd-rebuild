class Tag {
  final String id;
  final String name;
  final int color;
  final int usageCount;
  const Tag({required this.id, required this.name, required this.color, this.usageCount = 0});
  static const defaultTags = [Tag(id: 'personal', name: 'Personal', color: 0xFF6C5CE7), Tag(id: 'work', name: 'Work', color: 0xFF00B88A), Tag(id: 'gratitude', name: 'Gratitude', color: 0xFFF5A623), Tag(id: 'goals', name: 'Goals', color: 0xFFE84848), Tag(id: 'travel', name: 'Travel', color: 0xFF3B82F6), Tag(id: 'family', name: 'Family', color: 0xFFEC4899), Tag(id: 'health', name: 'Health', color: 0xFF10B981), Tag(id: 'ideas', name: 'Ideas', color: 0xFF8B5CF6)];
}
