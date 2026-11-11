import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {C} from './theme';
import {Bloom, PulseRing} from './Stage';

/** The series signature: one coral pulse, a ring that crosses the frame, a
 *  heartbeat line. No words, no logo type — the mark is the brand. */
export const EndCard: React.FC<{start: number; duration?: number}> = ({start, duration = 70}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame - start;
  if (t < 0) return null;

  const enter = spring({frame: t, fps, config: {damping: 14, stiffness: 110, mass: 0.7}});
  const dotR = 13 * enter;
  const ring1 = interpolate(t, [0, 62], [0, 620], {extrapolateRight: 'clamp'});
  const ring2 = interpolate(t, [14, 76], [0, 620], {extrapolateRight: 'clamp'});
  const line = interpolate(t, [4, 46], [0, 1], {extrapolateRight: 'clamp'});
  const fade = interpolate(t, [duration - 12, duration], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  return (
    <AbsoluteFill style={{opacity: fade}}>
      <Bloom cx={540} cy={880} r={520} color="rgba(232,116,106,0.32)" opacity={enter} />
      <PulseRing cx={540} cy={880} r={ring1} color={C.coral} width={2} opacity={0.5 * (1 - ring1 / 620)} />
      <PulseRing cx={540} cy={880} r={ring2} color={C.coral} width={1.5} opacity={0.35 * (1 - ring2 / 620)} />
      <div
        style={{
          position: 'absolute',
          left: 540 - dotR,
          top: 880 - dotR,
          width: dotR * 2,
          height: dotR * 2,
          borderRadius: '50%',
          background: C.coral,
          boxShadow: `0 0 34px ${C.coral}, 0 0 90px ${C.coral}66`,
        }}
      />
      <svg style={{position: 'absolute', inset: 0, width: 1080, height: 1920}} viewBox="0 0 1080 1920">
        <path
          d="M 90 880 L 380 880 L 420 880 L 448 812 L 480 952 L 508 842 L 530 880 L 700 880 L 736 880 L 772 824 L 806 936 L 840 880 L 990 880"
          stroke={C.coralSoft}
          strokeWidth={3}
          fill="none"
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity={0.9}
          pathLength={1}
          strokeDasharray={1}
          strokeDashoffset={1 - line}
        />
      </svg>
    </AbsoluteFill>
  );
};
