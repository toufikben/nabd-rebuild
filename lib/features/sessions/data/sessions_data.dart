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
      emotionLabel: 'غضب',
      emoji: '😤',
      isFree: false,
      colorKey: 'red',
      breathingPattern: _breathingAnger,
      activity: SessionActivity.anger,
      voiceOpening: '[مقدمة الراوي — غضب]',
      voiceTransition: '[انتقال الراوي إلى النشاط — غضب]',
      voiceClosing: '[ختام الراوي — غضب]',
      ambientSound: null,
    ),
    Session(
      id: 'sadness',
      emotionLabel: 'حزن',
      emoji: '😢',
      isFree: false,
      colorKey: 'blue',
      breathingPattern: _breathingSadness,
      activity: SessionActivity.sadness,
      voiceOpening: '[مقدمة الراوي — حزن]',
      voiceTransition: '[انتقال الراوي إلى النشاط — حزن]',
      voiceClosing: '[ختام الراوي — حزن]',
      ambientSound: null,
    ),
    Session(
      id: 'anxiety',
      emotionLabel: 'قلق',
      emoji: '😰',
      isFree: true,
      colorKey: 'amber',
      breathingPattern: _breathingAnxiety,
      activity: SessionActivity.anxiety,
      voiceOpening: '[مقدمة الراوي — قلق]',
      voiceTransition: '[انتقال الراوي إلى النشاط — قلق]',
      voiceClosing: '[ختام الراوي — قلق]',
      ambientSound: null,
    ),
    Session(
      id: 'emptiness',
      emotionLabel: 'فراغ',
      emoji: '😐',
      isFree: true,
      colorKey: 'gray',
      breathingPattern: _breathingEmptiness,
      activity: SessionActivity.emptiness,
      voiceOpening: '[مقدمة الراوي — فراغ]',
      voiceTransition: '[انتقال الراوي إلى النشاط — فراغ]',
      voiceClosing: '[ختام الراوي — فراغ]',
      ambientSound: null,
    ),
    Session(
      id: 'disappointment',
      emotionLabel: 'خذلان',
      emoji: '💔',
      isFree: false,
      colorKey: 'purple',
      breathingPattern: _breathingDisappointment,
      activity: SessionActivity.disappointment,
      voiceOpening: '[مقدمة الراوي — خذلان]',
      voiceTransition: '[انتقال الراوي إلى النشاط — خذلان]',
      voiceClosing: '[ختام الراوي — خذلان]',
      ambientSound: null,
    ),
    Session(
      id: 'sleep',
      emotionLabel: 'قبل النوم',
      emoji: '😴',
      isFree: false,
      colorKey: 'indigo',
      breathingPattern: _breathingSleep,
      activity: SessionActivity.sleep,
      voiceOpening: '[مقدمة الراوي — نوم]',
      voiceTransition: '[انتقال الراوي إلى النشاط — نوم]',
      voiceClosing: '[ختام الراوي — نوم]',
      ambientSound: null,
    ),
    Session(
      id: 'gratitude',
      emotionLabel: 'امتنان',
      emoji: '🙏',
      isFree: true,
      colorKey: 'gold',
      breathingPattern: _breathingGratitude,
      activity: SessionActivity.gratitude,
      voiceOpening: '[مقدمة الراوي — امتنان]',
      voiceTransition: '[انتقال الراوي إلى النشاط — امتنان]',
      voiceClosing: '[ختام الراوي — امتنان]',
      ambientSound: null,
    ),
    Session(
      id: 'decision',
      emotionLabel: 'قبل قرار',
      emoji: '🎯',
      isFree: false,
      colorKey: 'teal',
      breathingPattern: _breathingDecision,
      activity: SessionActivity.decision,
      voiceOpening: '[مقدمة الراوي — قرار]',
      voiceTransition: '[انتقال الراوي إلى النشاط — قرار]',
      voiceClosing: '[ختام الراوي — قرار]',
      ambientSound: null,
    ),
  ];
}
