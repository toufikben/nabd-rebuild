import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../services/soundscape_service.dart';

/// SoundscapeBar — شريط الأصوات المحيطة.
class SoundscapeBar extends ConsumerWidget {
  const SoundscapeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(soundscapeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Toggle button
          GestureDetector(
            onTap: () => ref.read(soundscapeProvider.notifier).toggle(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: state.enabled
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                state.enabled ? Icons.volume_up : Icons.volume_off,
                size: 18,
                color: state.enabled
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Soundscape selection
          if (state.enabled)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: SoundscapeOption.all.map((option) {
                    final selected = state.type == option.id;
                    return GestureDetector(
                      onTap: () => ref
                          .read(soundscapeProvider.notifier)
                          .setType(option.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              option.labelEn,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            const Expanded(
              child: Text(
                'Ambient sounds',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
