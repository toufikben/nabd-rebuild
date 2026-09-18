import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/mood.dart';

/// MoodPicker — منتقي المشاعر (Modal Bottom Sheet).
class MoodPicker extends StatelessWidget {
  final String? selectedMoodId;
  final ValueChanged<String?> onSelected;
  final String langCode;

  const MoodPicker({
    super.key,
    this.selectedMoodId,
    required this.onSelected,
    this.langCode = 'en',
  });

  static Future<String?> show(
    BuildContext context, {
    String? currentMoodId,
    String langCode = 'en',
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodPicker(
        selectedMoodId: currentMoodId,
        langCode: langCode,
        onSelected: (mood) => Navigator.pop(context, mood),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['positive', 'neutral', 'negative'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            langCode == 'ar' ? 'كيف تشعر؟' : 'How do you feel?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Clear option
          if (selectedMoodId != null)
            TextButton.icon(
              onPressed: () => onSelected(null),
              icon: const Icon(Icons.clear, size: 18),
              label: Text(
                langCode == 'ar' ? 'إزالة المشاعر' : 'Clear mood',
              ),
            ),

          // Moods by category
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: categories.map((cat) {
                  final moods = Mood.all
                      .where((m) => m.category == cat)
                      .toList();
                  if (moods.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Text(
                          Mood.categoryLabel(cat, langCode),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: moods.map((mood) {
                          final selected = mood.id == selectedMoodId;
                          return GestureDetector(
                            onTap: () => onSelected(mood.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? mood.color.withValues(alpha: 0.2)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? mood.color
                                      : Colors.transparent,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood.emoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    mood.label(langCode),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? mood.color
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
