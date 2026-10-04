import '../models/breathing_pattern.dart';
import '../models/session.dart';
import '../models/session_activity.dart';

// Initial design data only.
// These breathing values are NOT medical or therapeutic rules.

const _breathingAnger = BreathingPattern(
  inhaleSec: 3,
  holdInSec: 0,
  exhaleSec: 3,
  holdOutSec: 0,
  recommendedCycles: 12,
);

const _breathingSadness = BreathingPattern(
  inhaleSec: 4,
  holdInSec: 0,
  exhaleSec: 6,
  holdOutSec: 0,
  recommendedCycles: 8,
);

const _breathingAnxiety = BreathingPattern(
  inhaleSec: 4,
  holdInSec: 7,
  exhaleSec: 8,
  holdOutSec: 0,
  recommendedCycles: 4,
);

const _breathingEmptiness = BreathingPattern(
  inhaleSec: 4,
  holdInSec: 4,
  exhaleSec: 4,
  holdOutSec: 4,
  recommendedCycles: 6,
);

const _breathingDisappointment = BreathingPattern(
  inhaleSec: 4,
  holdInSec: 0,
  exhaleSec: 6,
  holdOutSec: 0,
  recommendedCycles: 8,
);

const _breathingSleep = BreathingPattern(
  inhaleSec: 4,
  holdInSec: 7,
  exhaleSec: 8,
  holdOutSec: 0,
  recommendedCycles: 6,
);

const _breathingGratitude = BreathingPattern(
  inhaleSec: 5,
  holdInSec: 2,
  exhaleSec: 5,
  holdOutSec: 0,
  recommendedCycles: 6,
);

const _breathingDecision = BreathingPattern(
  inhaleSec: 4,
  holdInSec: 4,
  exhaleSec: 4,
  holdOutSec: 4,
  recommendedCycles: 6,
);

class SessionsData {
  const SessionsData._();

  static const List<Session> all = <Session>[
    Session(
      id: 'anger',
      emoji: '😤',
      isFree: false,
      colorKey: 'red',
      breathingPattern: _breathingAnger,
      activity: SessionActivity.anger,
      ambientSound: 'assets/sounds/ocean_soft.m4a',
    ),
    Session(
      id: 'sadness',
      emoji: '😢',
      isFree: false,
      colorKey: 'blue',
      breathingPattern: _breathingSadness,
      activity: SessionActivity.sadness,
      ambientSound: 'assets/sounds/rain_soft.m4a',
    ),
    Session(
      id: 'anxiety',
      emoji: '😰',
      isFree: true,
      colorKey: 'amber',
      breathingPattern: _breathingAnxiety,
      activity: SessionActivity.anxiety,
      ambientSound: 'assets/sounds/silent_river_water.m4a',
    ),
    Session(
      id: 'emptiness',
      emoji: '😐',
      isFree: true,
      colorKey: 'gray',
      breathingPattern: _breathingEmptiness,
      activity: SessionActivity.emptiness,
      ambientSound: 'assets/sounds/harp_soft.m4a',
    ),
    Session(
      id: 'disappointment',
      emoji: '💔',
      isFree: false,
      colorKey: 'purple',
      breathingPattern: _breathingDisappointment,
      activity: SessionActivity.disappointment,
      ambientSound: 'assets/sounds/oud_soft.m4a',
    ),
    Session(
      id: 'sleep',
      emoji: '😴',
      isFree: false,
      colorKey: 'indigo',
      breathingPattern: _breathingSleep,
      activity: SessionActivity.sleep,
      ambientSound: 'assets/sounds/rain_soft.m4a',
    ),
    Session(
      id: 'gratitude',
      emoji: '🙏',
      isFree: true,
      colorKey: 'gold',
      breathingPattern: _breathingGratitude,
      activity: SessionActivity.gratitude,
      ambientSound: 'assets/sounds/birds_distant.m4a',
    ),
    Session(
      id: 'decision',
      emoji: '🎯',
      isFree: false,
      colorKey: 'teal',
      breathingPattern: _breathingDecision,
      activity: SessionActivity.decision,
      ambientSound: 'assets/sounds/wind_gentle.m4a',
    ),
  ];

  static Session? byId(String id) {
    for (final session in all) {
      if (session.id == id) return session;
    }
    return null;
  }
}
