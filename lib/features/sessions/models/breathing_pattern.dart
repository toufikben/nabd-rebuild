// R1.1 — BreathingPattern Value Object.
// Initial design data only; no medical or therapeutic claims.

class BreathingPattern {
  const BreathingPattern({
    required this.inhaleSec,
    required this.holdInSec,
    required this.exhaleSec,
    required this.holdOutSec,
    required this.recommendedCycles,
  });

  final int inhaleSec;
  final int holdInSec;
  final int exhaleSec;
  final int holdOutSec;
  final int recommendedCycles;

  int get cycleSec =>
      inhaleSec + holdInSec + exhaleSec + holdOutSec;

  int get totalSec => cycleSec * recommendedCycles;

  String get label {
    final parts = <int>[
      inhaleSec,
      holdInSec,
      exhaleSec,
    ];

    if (holdOutSec > 0) {
      parts.add(holdOutSec);
    }

    return parts.join('-');
  }
}
