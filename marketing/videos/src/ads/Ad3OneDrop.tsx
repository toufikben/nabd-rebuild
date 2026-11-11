import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate} from 'remotion';
import {C, clamp01, easeOut, rand} from '../kit/theme';
import {Camera, Dust, Grain, Vignette, FadeBlack, LightShaft, Bloom} from '../kit/Stage';
import {Silhouette} from '../kit/Silhouette';
import {Soil, Window} from '../kit/World';
import {Tree} from '../kit/Tree';
import {EndCard} from '../kit/EndCard';

const Pen: React.FC<{x: number; y: number; rot?: number; scale?: number}> = ({x, y, rot = 0, scale = 1}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
    <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${scale})`}>
      <path d="M -26 -420 L 26 -420 L 12 0 L 0 46 L -12 0 Z" fill="#0A0A10" />
      <path d="M -26 -420 L -6 -420 L -2 0 L 0 46 L -12 0 Z" fill="#1B1B2A" />
      <path d="M 12 0 L 0 46 L -2 0 Z" fill="#33334A" />
      <path d="M 16 -380 L 20 -60" stroke="rgba(200,205,255,0.22)" strokeWidth={3} />
    </g>
  </svg>
);

const Drop: React.FC<{x: number; y: number; s?: number; opacity?: number}> = ({x, y, s = 1, opacity = 1}) => (
  <div
    style={{
      position: 'absolute',
      left: x - 12 * s,
      top: y - 18 * s,
      width: 24 * s,
      height: 34 * s,
      borderRadius: '50% 50% 50% 50% / 62% 62% 38% 38%',
      background: 'linear-gradient(160deg, #3A3F63 0%, #101326 60%, #05060C 100%)',
      boxShadow: '0 0 22px rgba(140,150,220,0.5)',
      opacity,
    }}
  >
    <div style={{position: 'absolute', left: 6 * s, top: 6 * s, width: 5 * s, height: 7 * s, borderRadius: '50%', background: 'rgba(255,255,255,0.8)'}} />
  </div>
);

export const Ad3OneDrop: React.FC = () => {
  const f = useCurrentFrame();

  /* A — dry ground, a pen, one drop */
  const penIn = interpolate(f, [16, 42], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const dropT = clamp01((f - 58) / 24);
  const dropY = 470 + easeOut(dropT) * 730;
  const land = f >= 82;
  const ripple = clamp01((f - 82) / 34);

  /* B — it answers */
  const g = clamp01((f - 124) / 186);
  const sway = Math.sin(f * 0.03) * 0.7;

  /* C — the room */
  const camScale = interpolate(f, [300, 400], [1.32, 1.0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const camY = interpolate(f, [300, 400], [120, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const warm = clamp01((f - 330) / 90);

  return (
    <AbsoluteFill style={{backgroundColor: '#08060A'}}>
      {/* ══════════ A ══════════ */}
      {f < 128 && (
        <AbsoluteFill>
          <Camera scale={1.9} y={40}>
            <Soil />
            {/* the dead twig that was here before */}
            <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
              <path d="M 300 1560 q 70 -190 6 -320 q -32 -74 -98 -104" stroke="#2A1E16" strokeWidth={15} fill="none" strokeLinecap="round" />
              <path d="M 312 1450 q 76 -44 140 -32" stroke="#2A1E16" strokeWidth={9} fill="none" strokeLinecap="round" />
            </svg>
            <Pen x={648} y={1180 - penIn * 110} rot={16} scale={1.15} />
          </Camera>
          {!land && <Drop x={640} y={dropY} s={1.7} opacity={clamp01(dropT * 3)} />}
          {land &&
            [0, 1, 2].map((i) => {
              const t = clamp01((ripple - i * 0.14) / 0.72);
              return (
                <div
                  key={i}
                  style={{
                    position: 'absolute',
                    left: 640 - (70 + t * 200) * 1.9,
                    top: 1250 - (20 + t * 54) * 1.9,
                    width: (70 + t * 200) * 2 * 1.9,
                    height: (20 + t * 54) * 2 * 1.9,
                    borderRadius: '50%',
                    border: `3px solid rgba(160,170,240,${0.34 * (1 - t)})`,
                  }}
                />
              );
            })}
          <Dust count={36} opacity={0.34} tint="#FFDCC0" speed={0.35} />
          <Vignette strength={0.62} />
          <Grain opacity={0.16} />
          <FadeBlack opacity={1 - interpolate(f, [0, 18], [0, 1], {extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ B ══════════ */}
      {f >= 128 && f < 302 && (
        <AbsoluteFill style={{backgroundColor: '#0A0806'}}>
          <Camera scale={interpolate(f, [128, 300], [1.42, 1.12], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} y={interpolate(f, [128, 300], [120, 40], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}>
            <Soil wet={g} warm={0.15 + g * 0.25} />
            <Tree x={560} y={1290} g={g} scale={680} sway={sway} variant={0} />
            {Array.from({length: 18}).map((_, i) => {
              const px = 160 + rand(i * 2.4) * 760 + Math.sin(f * 0.02 + i) * 34;
              const py = 820 + rand(i * 5.2) * 540 - clamp01((f - 190) / 110) * 240;
              return (
                <div
                  key={i}
                  style={{
                    position: 'absolute',
                    left: px,
                    top: py,
                    width: 6,
                    height: 6,
                    borderRadius: '50%',
                    background: '#D8F26A',
                    boxShadow: '0 0 14px #D8F26A',
                    opacity: clamp01((f - 190) / 70) * (0.35 + rand(i * 7.7) * 0.65),
                  }}
                />
              );
            })}
          </Camera>
          <Bloom cx={560} cy={1000} r={520} color={`rgba(216,242,106,${0.05 + g * 0.07})`} />
          <Vignette strength={0.6} />
          <Grain opacity={0.15} />
          <FadeBlack opacity={1 - interpolate(f, [128, 140], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ C ══════════ */}
      {f >= 302 && f < 500 && (
        <AbsoluteFill>
          <Camera scale={camScale} y={camY}>
            <div style={{position: 'absolute', inset: 0, background: `linear-gradient(180deg, rgb(${16 + warm * 40},${16 + warm * 24},${30 + warm * 10}) 0%, rgb(${10 + warm * 16},${9 + warm * 9},${17 + warm * 4}) 70%)`}} />
            {/* plank wall, faint vertical seams */}
            <svg style={{position: 'absolute', inset: 0}} width={1080} height={1300}>
              {Array.from({length: 9}).map((_, i) => (
                <line key={i} x1={i * 132 + 20} y1={0} x2={i * 132 + 26} y2={1300} stroke="rgba(0,0,0,0.22)" strokeWidth={3} />
              ))}
            </svg>
            {/* dawn window, behind the person */}
            <Window x={64} y={330} w={300} h={640} warm={0.55 + warm * 0.4} moon={false} stars={0} />
            {/* floor */}
            <div style={{position: 'absolute', left: 0, right: 0, top: 1290, height: 630, background: `linear-gradient(180deg, rgb(${34 + warm * 18},${25 + warm * 10},${18}) 0%, #08060A 100%)`}} />
            <div style={{position: 'absolute', left: 0, right: 0, top: 1290, height: 3, background: 'rgba(255,220,180,0.07)'}} />
            {/* the plot: a mound of soil, broken at the edge, not a box */}
            <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
              <defs>
                <radialGradient id="mound" cx="45%" cy="8%" r="82%">
                  <stop offset="0%" stopColor="#4A3928" />
                  <stop offset="45%" stopColor="#2A1E15" />
                  <stop offset="100%" stopColor="#0D0906" />
                </radialGradient>
              </defs>
              <path d="M 200 1330 Q 240 1246 420 1238 Q 620 1230 830 1240 Q 1000 1248 1030 1330 Q 900 1382 620 1384 Q 340 1382 200 1330 Z" fill="url(#mound)" />
              {Array.from({length: 46}).map((_, i) => {
                const t = i / 45;
                const bx = 214 + t * 800;
                const by = 1300 - Math.sin(t * Math.PI) * 52 + (rand(i * 3.3) - 0.5) * 16;
                return <path key={i} d={`M ${bx} ${by} q ${(rand(i * 2.1) - 0.5) * 16} -18 ${(rand(i * 5.7) - 0.5) * 22} -34`} stroke={`rgba(${86 + rand(i * 4.4) * 50},${104 + rand(i * 6.2) * 40},${60 + rand(i * 7.1) * 30},0.55)`} strokeWidth={2.6} fill="none" strokeLinecap="round" />;
              })}
            </svg>
            <Tree x={600} y={1318} g={1} scale={760} sway={sway} variant={0} />
            {/* the near lip of the mound, in front of the trunk */}
            <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
              <defs>
                <linearGradient id="lip" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#241910" />
                  <stop offset="100%" stopColor="#080605" />
                </linearGradient>
              </defs>
              <path d="M 236 1302 Q 420 1348 640 1350 Q 860 1346 1012 1300 Q 900 1384 620 1386 Q 360 1384 236 1302 Z" fill="url(#lip)" />
            </svg>
            <Silhouette variant="floor" x={120} y={1206} scale={1.2} breathing={0.5} fill="#04050A" />
            <div style={{position: 'absolute', left: -40, top: 520, width: 900, height: 1000, background: `radial-gradient(circle, rgba(255,190,120,${0.12 + warm * 0.1}), transparent 64%)`}} />
          </Camera>
          <LightShaft x={180} y={300} angle={16} length={1400} spread={520} color="#FFC98A" opacity={0.12 + warm * 0.1} blur={54} />
          <Dust count={46} opacity={0.28 + warm * 0.2} tint="#FFDCC0" speed={0.32} />
          <Vignette strength={0.54} />
          <Grain opacity={0.12} />
          <FadeBlack opacity={interpolate(f, [490, 500], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {f >= 495 && (
        <AbsoluteFill style={{backgroundColor: '#05060B'}}>
          <EndCard start={498} />
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};
