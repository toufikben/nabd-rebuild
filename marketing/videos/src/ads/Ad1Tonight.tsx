import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {C, easeInOut, clamp01} from '../kit/theme';
import {Camera, Dust, Grain, Vignette, PulseRing, Bloom, FadeBlack, LightShaft} from '../kit/Stage';
import {Silhouette, Hand} from '../kit/Silhouette';
import {Phone, PhoneLight} from '../kit/Phone';
import {TodayScreen, WorryScreen, BreathScreen, LockScreen} from '../kit/screens';
import {Bedroom, Bed, Nightstand} from '../kit/World';
import {EndCard} from '../kit/EndCard';

const Tangle: React.FC<{x: number; y: number; w: number; h: number; opacity: number; phase?: number}> = ({
  x,
  y,
  w,
  h,
  opacity,
  phase = 0,
}) => {
  const f = useCurrentFrame();
  return (
    <svg style={{position: 'absolute', left: x, top: y, width: w, height: h, opacity}} viewBox="0 0 400 300">
      {Array.from({length: 7}).map((_, i) => {
        const yy = 40 + i * 34;
        const a = 22 + (i % 3) * 10;
        const s = Math.sin(f * 0.035 + i + phase) * 10;
        return (
          <path
            key={i}
            d={`M -20 ${yy} C 90 ${yy - a + s}, 180 ${yy + a - s}, 290 ${yy - a * 0.4} S 380 ${yy + a}, 430 ${yy}`}
            stroke="#1A1C30"
            strokeWidth={2.4}
            fill="none"
            opacity={0.9}
            strokeLinecap="round"
          />
        );
      })}
    </svg>
  );
};

export const Ad1Tonight: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();

  /* ── shot A: the bedroom at 3am ─────────────────────────────────────── */
  const pushA = interpolate(f, [0, 70], [1.06, 1.16], {extrapolateRight: 'clamp'});
  const handIn = interpolate(f, [58, 76], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const screenWake = interpolate(f, [46, 66], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  /* ── shot B: the lock screen clock ─────────────────────────────────── */
  const clockIn = interpolate(f, [72, 84], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  /* ── shot C: the worry box ─────────────────────────────────────────── */
  const drag = clamp01((f - 168) / 62);
  const lid = clamp01((f - 226) / 22);
  const tapPress = spring({frame: f - 226, fps, config: {damping: 12, stiffness: 200}});
  const fingerY = 1420 - easeInOut(clamp01((f - 166) / 58)) * 300;
  const fingerX = 700 - easeInOut(clamp01((f - 166) / 58)) * 300;

  /* ── shot D: the room exhales ──────────────────────────────────────── */
  const ringR = interpolate(f, [280, 330], [0, 1500], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const calm = interpolate(f, [300, 400], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const breathRate = 1 - calm * 0.55;

  /* ── shot E: dawn ──────────────────────────────────────────────────── */
  const dawn = interpolate(f, [430, 500], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  return (
    <AbsoluteFill style={{backgroundColor: C.ink}}>
      {/* ══════════════ A · the room, awake at 3 ══════════════ */}
      {f < 72 && (
        <AbsoluteFill>
          <Camera scale={pushA} x={-10} y={70}>
            <Bedroom warm={0} />
            <Bed />
            <Nightstand x={900} y={1240} />
            <Silhouette variant="lying" x={190} y={1120} scale={1.15} breathing={1.15} />
            <Tangle x={200} y={880} w={560} h={300} opacity={0.32 + screenWake * 0.1} phase={1} />
            <Tangle x={520} y={760} w={420} h={240} opacity={0.18} phase={3.4} />
            <Phone x={900} y={1120} w={118} glow={0.15 + screenWake * 0.85} glowColor="#9C93D8" dim={0.9 - screenWake * 0.9}>
              <TodayScreen clock="3:12" />
            </Phone>
            <PhoneLight x={900} y={1120} w={118} color="#8C82F0" intensity={0.1 + screenWake * 0.5} spread={5} />
            {/* moonlight on the duvet */}
            <div style={{position: 'absolute', left: 120, top: 1080, width: 760, height: 320, background: 'radial-gradient(ellipse at 30% 20%, rgba(150,165,255,0.10), transparent 70%)'}} />
          </Camera>
          <Dust count={30} opacity={0.3} tint="#9C93D8" />
          <Vignette strength={0.55} />
          <Grain opacity={0.14} />
          <FadeBlack opacity={1 - interpolate(f, [0, 22], [0, 1], {extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════════ B · 3:12, right in front of the face ══════════════ */}
      {f >= 72 && f < 150 && (
        <AbsoluteFill style={{backgroundColor: '#05060B'}}>
          <Camera scale={1.0 + clockIn * 0.03}>
            <Phone x={540} y={980} w={860} glow={0.9} glowColor="#8C82F0">
              <LockScreen clock="3:12" />
            </Phone>
          </Camera>
          <Bloom cx={540} cy={980} r={700} color="rgba(91,79,207,0.28)" />
          <Vignette strength={0.5} />
          <Grain opacity={0.12} />
          <Hand x={980} y={1500} scale={0.9} rotate={-18} points={1} />
          <FadeBlack opacity={1 - interpolate(f, [72, 80], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════════ C · writing it down, closing the box ══════════════ */}
      {f >= 150 && f < 290 && (
        <AbsoluteFill style={{backgroundColor: '#0A0A12'}}>
          <Camera scale={1.0}>
            <Phone x={540} y={980} w={900} glow={0.75} glowColor="#FAF8F5">
              <WorryScreen tangle={1 - drag * 0.85} lid={lid} dragging={drag} />
            </Phone>
          </Camera>
          {/* fingertip */}
          {f > 160 && f < 250 && (
            <div
              style={{
                position: 'absolute',
                left: fingerX - 26,
                top: fingerY - 26,
                width: 52,
                height: 62,
                borderRadius: '50% 50% 46% 46%',
                background: '#0B0A10',
                opacity: 0.55,
                filter: 'blur(6px)',
                transform: `scale(${1 - tapPress * 0.12})`,
              }}
            />
          )}
          <Vignette strength={0.4} />
          <Grain opacity={0.1} />
          <PulseRing cx={540} cy={980} r={ringR} color={C.coral} width={4} opacity={ringR > 0 ? 0.9 * (1 - ringR / 1500) : 0} glow={1.4} />
        </AbsoluteFill>
      )}

      {/* ══════════════ D · the room exhales ══════════════ */}
      {f >= 290 && f < 432 && (
        <AbsoluteFill>
          <Camera scale={interpolate(f, [290, 430], [1.14, 1.0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} y={interpolate(f, [290, 430], [-30, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}>
            <Bedroom warm={calm * 0.12} />
            <Bed />
            <Nightstand x={900} y={1240} />
            <Silhouette variant="lying" x={190} y={1120} scale={1.15} breathing={breathRate} />
            <Phone x={900} y={1120} w={118} glow={0.5 + calm * 0.2} glowColor="#E8746A" dim={0.15}>
              <BreathScreen phase={0.5 + Math.sin(f * 0.045) * 0.45} glow={1} />
            </Phone>
            <PhoneLight x={900} y={1120} w={118} color="#E8746A" intensity={0.28 + calm * 0.12} spread={5} />
          </Camera>
          <PulseRing cx={900} cy={1120} r={interpolate(f, [290, 340], [0, 1700], {extrapolateRight: 'clamp'})} color={C.coral} width={3} opacity={interpolate(f, [290, 345], [0.55, 0], {extrapolateRight: 'clamp'})} />
          <Dust count={40} opacity={0.34} tint="#E8E4FF" speed={0.5} />
          <Vignette strength={0.5} />
          <Grain opacity={0.13} />
        </AbsoluteFill>
      )}

      {/* ══════════════ E · morning ══════════════ */}
      {f >= 432 && f < 500 && (
        <AbsoluteFill>
          <Camera scale={1.02}>
            <Bedroom warm={1} night={1} />
            <Bed warm={1} />
            <div style={{position: 'absolute', inset: 0, background: `rgba(255,170,90,${0.16 * dawn})`}} />
            {/* the windowsill, one small green thing */}
            <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
              <g transform="translate(300 800)">
                <path d="M -30 0 L -30 -40" stroke="#2E6B44" strokeWidth={6} strokeLinecap="round" />
                <path d="M -30 -40 q -22 -12 -26 -34" stroke="#2E6B44" strokeWidth={5} fill="none" strokeLinecap="round" />
                <path d="M -30 -34 q 20 -10 26 -30" stroke="#3F8155" strokeWidth={5} fill="none" strokeLinecap="round" />
                <ellipse cx={-58} cy={-76} rx={13} ry={8} fill="#3F8155" transform="rotate(-28 -58 -76)" />
                <ellipse cx={-2} cy={-66} rx={13} ry={8} fill="#4C9263" transform="rotate(24 -2 -66)" />
                <rect x={-44} y={-6} width={28} height={26} rx={6} fill="#3A2B22" />
              </g>
            </svg>
            <ChairMorning />
          </Camera>
          <LightShaft x={260} y={360} angle={-14} length={1200} spread={380} color="#FFC98A" opacity={0.2 * dawn} blur={40} />
          <Vignette strength={0.4} />
          <Grain opacity={0.1} />
          <FadeBlack opacity={interpolate(f, [490, 500], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════════ signature ══════════════ */}
      {f >= 495 && (
        <AbsoluteFill style={{backgroundColor: '#05060B'}}>
          <EndCard start={498} />
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};

const ChairMorning: React.FC = () => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
    <g opacity={0.9}>
      <rect x={700} y={1180} width={120} height={16} rx={6} fill="#2A2436" />
    </g>
  </svg>
);

