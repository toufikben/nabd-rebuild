import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/database_service.dart';

/// EmotionRadarScreen — رادار المشاعر (6 أبعاد).
class EmotionRadarScreen extends ConsumerStatefulWidget {
  const EmotionRadarScreen({super.key});

  @override
  ConsumerState<EmotionRadarScreen> createState() =>
      _EmotionRadarScreenState();
}

class _EmotionRadarScreenState extends ConsumerState<EmotionRadarScreen> {
  final DatabaseService _db = DatabaseService();
  int _period = 30;

  /// 6 أبعاد — (label, [moodIds])
  static const Map<String, List<String>> _dimensions = {
    'Joy': ['joyful', 'happy', 'excited'],
    'Love': ['loved', 'in_love', 'grateful'],
    'Peace': ['peaceful', 'calm', 'hopeful'],
    'Sadness': ['sad', 'lonely', 'depressed'],
    'Anger': ['angry', 'frustrated'],
    'Anxiety': ['anxious', 'confused', 'tired'],
  };

  Map<String, double> get _scores {
    final entries = _db.getAllEntries();
    final cutoff = DateTime.now().subtract(Duration(days: _period));
    final recent = entries.where((e) => e.createdAt.isAfter(cutoff)).toList();

    final result = <String, double>{};

    for (final entry in _dimensions.entries) {
      final label = entry.key;
      final moods = entry.value;

      final count = recent.where((e) => moods.contains(e.mood)).length;
      final percent = recent.isEmpty ? 0.0 : count / recent.length;
      result[label] = percent;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scores = _scores;
    final hasData = scores.values.any((v) => v > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Radar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [7, 30, 90, 365].map((d) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(d == 365 ? 'Year' : '$d Days'),
                    selected: _period == d,
                    onSelected: (_) => setState(() => _period = d),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: !hasData
          ? const Center(
              child: Text(
                'Not enough mood data yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: _RadarPainter(scores),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLegend(scores),
                ],
              ),
            ),
    );
  }

  Widget _buildLegend(Map<String, double> scores) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: scores.entries.map((e) {
        final percent = (e.value * 100).round();
        final color = _colorFor(e.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${e.key}: $percent%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _colorFor(String label) {
    switch (label) {
      case 'Joy':
        return const Color(0xFFFFD54F);
      case 'Love':
        return const Color(0xFFE91E63);
      case 'Peace':
        return const Color(0xFF00D2A8);
      case 'Sadness':
        return const Color(0xFF5C6BC0);
      case 'Anger':
        return const Color(0xFFD50000);
      case 'Anxiety':
        return const Color(0xFF7E57C2);
      default:
        return AppColors.primary;
    }
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> scores;
  _RadarPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 40;
    final sides = scores.length;
    final labels = scores.keys.toList();

    final gridPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Grid
    for (var r = 1; r <= 4; r++) {
      final radius = maxRadius * r / 4;
      final path = Path();
      for (var i = 0; i < sides; i++) {
        final angle = (i / sides) * 2 * math.pi - math.pi / 2;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis
    for (var i = 0; i < sides; i++) {
      final angle = (i / sides) * 2 * math.pi - math.pi / 2;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Data polygon
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < sides; i++) {
      final value = scores[labels[i]] ?? 0;
      final normalized = math.min(value * 3, 1.0);
      final angle = (i / sides) * 2 * math.pi - math.pi / 2;
      final radius = maxRadius * normalized;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Labels
    for (var i = 0; i < sides; i++) {
      final angle = (i / sides) * 2 * math.pi - math.pi / 2;
      final labelRadius = maxRadius + 20;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
