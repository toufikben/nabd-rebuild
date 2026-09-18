import 'package:flutter/material.dart';

import '../models/session.dart';

const Map<String, Color> _sessionAccentMap = <String, Color>{
  'red': Color(0xFFE74C3C),
  'blue': Color(0xFF5B7C99),
  'amber': Color(0xFFD4A017),
  'gray': Color(0xFF7F8C8D),
  'purple': Color(0xFF8E7CC3),
  'indigo': Color(0xFF2C3E50),
  'gold': Color(0xFFE8B84B),
  'teal': Color(0xFF16A085),
};

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  final Session session;
  final VoidCallback? onTap;

  Color _accentFor(BuildContext context) {
    return _sessionAccentMap[session.colorKey] ??
        Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = _accentFor(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double topAlpha = isDark ? 0.24 : 0.16;
    final double bottomAlpha = isDark ? 0.06 : 0.04;
    final double borderAlpha = isDark ? 0.38 : 0.30;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withOpacity(topAlpha),
                accent.withOpacity(bottomAlpha),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withOpacity(borderAlpha),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                session.emoji,
                style: const TextStyle(fontSize: 38),
              ),
              const SizedBox(height: 8),
              Text(
                session.emotionLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (!session.isFree) ...<Widget>[
                const SizedBox(height: 6),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
