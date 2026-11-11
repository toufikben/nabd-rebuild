import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate} from 'remotion';
import {C, clamp01, easeInOut, rand} from '../kit/theme';
import {Camera, Dust, Grain, Vignette, Bloom, FadeBlack, PulseRing} from '../kit/Stage';
import {Silhouette} from '../kit/Silhouette';
import {Phone} from '../kit/Phone';
import {InsightsScreen} from '../kit/screens';
import {DarkRoom} from '../kit/World';
import {EndCard} from '../kit/EndCard';

const COLS = 26;
const ROWS = 9;
const CELL = 24;

const HeatGrid: React.FC<{reveal: number; opacity?: number; lift?: number}> = ({reveal, opacity = 1, lift = 0}) => {
  const f = useCurrentFrame();
  const cells = [];
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const i = r * COLS + c;
      const v = Math.abs(Math.sin(i * 0.37) * Math.cos(i * 0.11));
      const order = i / (COLS * ROWS);
      const on = clamp01((reveal - order * 0.85) / 0.12);
      const depth = 0.78 + (r / ROWS) * 0.5;
      const x = (c - (COLS - 1) / 2) * CELL * depth;
      const y = (r - (ROWS - 1) / 2) * CELL * depth * 1.45;
      const hue = v > 0.72 ? C.coral : v > 0.45 ? C.indigoGlow : C.tealSoft;
      const float = Math.sin(f * 0.03 + i * 0.5) * 3 * depth;
      cells.push(
        <rect
          key={i}
          x={x - (CELL * depth) / 2 + 2}
          y={y - (CELL * depth) / 2 + float - lift * (0.4 + depth)}
          width={CELL * depth - 4}
          height={CELL * depth - 4}
          rx={4}
          fill={hue}
          opacity={on * (0.16 + v * 0.7) * opacity}
        />,
      );
    }
  }
  return (
    <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
      <g transform="translate(566 918) rotate(-3) skewX(-5)">{cells}</g>
    </svg>
  );
};

export const Ad5Year: React.FC = () => {
  const f = useCurrentFrame();

  /* A — the floor, the phone, one dot */
  const dotRise = clamp01((f - 40) / 40);
  const firstDotY = 1400 - dotRise * 420;

  /* B — the year assembles */
  const reveal = clamp01((f - 110) / 150);
  const crane = interpolate(f, [110, 300], [1.0, 1.06], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const craneY = interpolate(f, [110, 300], [0, -90], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  /* C — the shape of it */
  const wave = clamp01((f - 300) / 70);
  const ringR = interpolate(f, [340, 420], [0, 900], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const gridFade = 1 - clamp01((f - 360) / 70) * 0.45;

  /* D — it lands on them */
  const light = clamp01((f - 400) / 60);
  const lookUp = clamp01((f - 400) / 55);

  return (
    <AbsoluteFill style={{backgroundColor: '#05060B'}}>
      {/* ══════════ A+B+C ══════════ */}
      {f < 470 && (
        <AbsoluteFill>
          <Camera scale={crane} y={craneY}>
            <DarkRoom glow={0.6 + reveal * 0.5} warm={light * 0.35} />
            {/* a pool of screen light on the floor, so the person reads against it */}
            <div style={{position: 'absolute', left: 540, top: 1130, width: 560, height: 500, background: `radial-gradient(ellipse at 50% 60%, rgba(150,140,245,${0.13 + reveal * 0.1}), transparent 66%)`}} />
            <Silhouette variant="floor" x={588} y={1206} scale={1.12} breathing={0.8} fill="#04050A" rim={false} />
            <Phone x={566} y={1496} w={152} glow={0.9} glowColor="#8C82F0" rotate={-8}>
              <InsightsScreen reveal={reveal} wave={wave} />
            </Phone>
            <div style={{position: 'absolute', left: 400, top: 1360, width: 340, height: 340, background: 'radial-gradient(circle, rgba(140,130,240,0.16), transparent 68%)'}} />
          </Camera>

          {/* the dots leave the phone and take their places */}
          <Camera scale={crane} y={craneY}>
            <HeatGrid reveal={reveal} opacity={gridFade} lift={reveal * 40} />
          </Camera>

          {/* the first dot */}
          {f < 60 && (
            <div
              style={{
                position: 'absolute',
                left: 564,
                top: firstDotY,
                width: 16,
                height: 16,
                borderRadius: '50%',
                background: C.indigoGlow,
                boxShadow: `0 0 26px ${C.indigoGlow}`,
                opacity: 0.9,
              }}
            />
          )}

          {/* risers: brief streaks from screen to grid */}
          {Array.from({length: 26}).map((_, i) => {
            const t0 = 100 + i * 5;
            const t = clamp01((f - t0) / 34);
            if (t <= 0 || t >= 1) return null;
            const sx = 528 + rand(i * 3.3) * 110;
            const sy = 1440;
            const tx = 240 + rand(i * 7.1) * 620;
            const ty = 800 + rand(i * 2.9) * 260;
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: sx + (tx - sx) * easeInOut(t),
                  top: sy + (ty - sy) * easeInOut(t),
                  width: 7,
                  height: 7,
                  borderRadius: '50%',
                  background: i % 3 === 0 ? C.coral : C.indigoGlow,
                  boxShadow: `0 0 14px ${i % 3 === 0 ? C.coral : C.indigoGlow}`,
                  opacity: Math.sin(t * Math.PI),
                }}
              />
            );
          })}

          {/* the pulse line the grid collapses into */}
          {wave > 0 && (
            <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
              <path
                d={`M 190 918 ${Array.from({length: 40})
                  .map((_, i) => {
                    const x = 190 + (i / 39) * 760;
                    const y = 918 - Math.sin(i * 0.45 + f * 0.12) * 120 * Math.exp(-Math.pow((i - 20) / 13, 2)) * wave;
                    return `L ${x.toFixed(1)} ${y.toFixed(1)}`;
                  })
                  .join(' ')}`}
                stroke={C.coral}
                strokeWidth={5}
                fill="none"
                strokeLinecap="round"
                opacity={wave * (1 - clamp01((f - 380) / 50) * 0.5)}
                pathLength={1}
                strokeDasharray={1}
                strokeDashoffset={1 - wave}
              />
            </svg>
          )}

          <PulseRing cx={566} cy={918} r={ringR} color={C.indigoGlow} width={2.5} opacity={ringR > 0 ? 0.5 * (1 - ringR / 900) : 0} />

          {/* light landing on the person */}
          <Bloom cx={790} cy={1170} r={420} color={`rgba(200,190,255,${light * 0.28})`} />
          <div
            style={{
              position: 'absolute',
              left: 430,
              top: -200,
              width: 640,
              height: 1500,
              background: `linear-gradient(180deg, rgba(200,190,255,${0.16 * light}) 0%, transparent 78%)`,
              transform: 'rotate(10deg)',
              filter: 'blur(30px)',
              mixBlendMode: 'screen',
            }}
          />

          <Dust count={50} opacity={0.25 + reveal * 0.2} tint="#C9C2EE" speed={0.3} />
          <Vignette strength={0.62 - light * 0.18} />
          <Grain opacity={0.14} />
          <FadeBlack opacity={1 - interpolate(f, [0, 24], [0, 1], {extrapolateRight: 'clamp'})} />
          <FadeBlack opacity={interpolate(f, [462, 470], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {f >= 468 && (
        <AbsoluteFill style={{backgroundColor: '#05060B'}}>
          <EndCard start={470} />
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};






