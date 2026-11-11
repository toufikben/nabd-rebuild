import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate} from 'remotion';
import {C, clamp01, easeInOut, rand} from '../kit/theme';
import {Camera, Dust, Grain, Vignette, PulseRing, Bloom, FadeBlack, LightShaft} from '../kit/Stage';
import {Silhouette} from '../kit/Silhouette';
import {Phone} from '../kit/Phone';
import {LetterScreen, GratitudeScreen} from '../kit/screens';
import {Study} from '../kit/World';
import {EndCard} from '../kit/EndCard';

/** A folded paper bird. Wings flap, the body banks — the letter that never got sent. */
const PaperBird: React.FC<{x: number; y: number; scale?: number; rot?: number; flap?: number; opacity?: number}> = ({
  x,
  y,
  scale = 1,
  rot = 0,
  flap = 0,
  opacity = 1,
}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920} opacity={opacity}>
    <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${scale})`}>
      <path d="M 0 -6 L 34 10 L 0 4 L -34 10 Z" fill="#F3EEE4" />
      <path d="M 0 -6 L 20 8 L 0 4 L -20 8 Z" fill="#FFFFFF" />
      <g transform={`rotate(${-flap * 34} 0 0)`}>
        <path d="M 0 -2 L -58 -30 L -12 6 Z" fill="#EFE9DE" />
        <path d="M 0 -2 L -44 -24 L -10 4 Z" fill="#FFFFFF" opacity={0.7} />
      </g>
      <g transform={`rotate(${flap * 34} 0 0)`}>
        <path d="M 0 -2 L 58 -30 L 12 6 Z" fill="#E7E0D4" />
        <path d="M 0 -2 L 44 -24 L 10 4 Z" fill="#FFFFFF" opacity={0.6} />
      </g>
      <path d="M 0 4 L 12 26 L 0 20 L -12 26 Z" fill="#E2DACE" />
    </g>
  </svg>
);

const Cup: React.FC<{x: number; y: number; scale?: number; steam?: number; warm?: number}> = ({x, y, scale = 1, steam = 0, warm = 0}) => {
  const f = useCurrentFrame();
  return (
    <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
      <g transform={`translate(${x} ${y}) scale(${scale})`}>
        <ellipse cx={0} cy={6} rx={26} ry={7} fill="rgba(0,0,0,0.45)" />
        <path d="M -22 -44 L 22 -44 L 17 2 L -17 2 Z" fill={warm > 0.4 ? '#3A2E28' : '#242030'} />
        <path d="M -22 -44 L 0 -44 L 0 2 L -17 2 Z" fill="rgba(255,255,255,0.05)" />
        <ellipse cx={0} cy={-44} rx={22} ry={6} fill="#2E2836" />
        <ellipse cx={0} cy={-44} rx={16} ry={4} fill={warm > 0.4 ? '#6B4A32' : '#1A1722'} />
        <path d="M 22 -36 q 16 2 14 14 q -2 12 -16 12" stroke={warm > 0.4 ? '#3A2E28' : '#242030'} strokeWidth={6} fill="none" />
        {steam > 0.01 &&
          [0, 1, 2].map((i) => {
            const p = ((f * 0.012 + i * 0.33) % 1);
            return (
              <path
                key={i}
                d={`M ${-6 + i * 6} ${-50 - p * 44} q ${Math.sin(p * 6 + i) * 8} -14 ${Math.sin(p * 6 + i + 1) * 12} -26`}
                stroke="rgba(230,230,255,0.16)"
                strokeWidth={3}
                fill="none"
                opacity={(1 - p) * steam}
              />
            );
          })}
      </g>
    </svg>
  );
};

const DeskTop: React.FC<{warm?: number}> = ({warm = 0}) => (
  <div
    style={{
      position: 'absolute',
      left: 0,
      right: 0,
      top: 1102,
      height: 78,
      background: `linear-gradient(180deg, rgb(${40 + warm * 34},${32 + warm * 22},${46 + warm * 10}) 0%, rgb(${58 + warm * 34},${46 + warm * 22},${62 + warm * 12}) 100%)`,
    }}
  >
    {/* the window lies along the desk as a cold stripe */}
    <div style={{position: 'absolute', left: 90, top: 6, width: 430, height: 30, background: 'linear-gradient(180deg, rgba(160,175,255,0.16), rgba(160,175,255,0))', filter: 'blur(6px)', transform: 'skewX(-16deg)'}} />
    <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 2, background: 'rgba(255,230,200,0.10)'}} />
  </div>
);

const DeskFront: React.FC<{warm?: number}> = ({warm = 0}) => (
  <div style={{position: 'absolute', left: 0, right: 0, top: 1180, height: 740, background: `linear-gradient(180deg, rgb(${40 + warm * 36},${32 + warm * 22},${46 + warm * 10}) 0%, rgb(${20 + warm * 18},${16 + warm * 10},${26 + warm * 5}) 46%, rgb(${8 + warm * 8},${7 + warm * 4},${12 + warm * 2}) 100%)`}}>
    {/* the lit top edge of the desk */}
    <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 6, background: 'rgba(255,225,190,0.13)'}} />
    <div style={{position: 'absolute', left: 0, right: 0, top: 6, height: 26, background: 'linear-gradient(180deg, rgba(0,0,0,0.55), rgba(0,0,0,0))'}} />
    {/* wood grain, drawn once, never animated */}
    <svg style={{position: 'absolute', inset: 0}} width={1080} height={740}>
      {Array.from({length: 22}).map((_, i) => (
        <path
          key={i}
          d={`M ${-20 + i * 54} 30 q ${8 + rand(i * 3.1) * 14} 200 ${-6 + rand(i * 5.2) * 12} 380 q ${4 + rand(i * 7.7) * 10} 180 ${rand(i * 2.3) * 8} 330`}
          stroke="rgba(255,220,180,0.05)"
          strokeWidth={1 + rand(i * 4.4) * 2.2}
          fill="none"
        />
      ))}
    </svg>
  </div>
);

/** The unsent thread: from the sternum to the cup nobody is drinking. */
const Thread: React.FC<{from: [number, number]; to: [number, number]; loosen?: number; opacity?: number}> = ({
  from,
  to,
  loosen = 0,
  opacity = 1,
}) => {
  const f = useCurrentFrame();
  const midX = (from[0] + to[0]) / 2;
  const sag = 60 + loosen * 170 + Math.sin(f * 0.03) * 8;
  const midY = (from[1] + to[1]) / 2 + sag;
  return (
    <svg style={{position: 'absolute', inset: 0, opacity}} width={1080} height={1920}>
      <path d={`M ${from[0]} ${from[1]} Q ${midX} ${midY} ${to[0]} ${to[1]}`} stroke={C.coral} strokeWidth={8} fill="none" opacity={0.15} />
      <path d={`M ${from[0]} ${from[1]} Q ${midX} ${midY} ${to[0]} ${to[1]}`} stroke={C.coralSoft} strokeWidth={2.6} fill="none" opacity={0.7} />
      <circle cx={from[0]} cy={from[1]} r={7} fill={C.coral} opacity={0.85} />
    </svg>
  );
};

export const Ad2Unsent: React.FC = () => {
  const f = useCurrentFrame();

  const pushA = interpolate(f, [0, 130], [1.0, 1.06], {extrapolateRight: 'clamp'});
  const threadIn = interpolate(f, [26, 62], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  const typedRaw = (f - 140) / 34;
  const typed = f < 205 ? 1 - Math.abs(((typedRaw % 2) + 2) % 2 - 1) : 1;
  const saved = clamp01((f - 214) / 20);

  const birdT = clamp01((f - 300) / 100);
  const birdX = 925 - easeInOut(birdT) * 620;
  const birdY = 1032 - easeInOut(birdT) * 470 - Math.sin(birdT * Math.PI) * 120;
  const loosen = clamp01((f - 320) / 90);
  const lit = clamp01((f - 366) / 46) * 3;
  const warm = clamp01((f - 344) / 96);
  const rainStop = 1 - clamp01((f - 432) / 58);

  return (
    <AbsoluteFill style={{backgroundColor: C.ink}}>
      {/* ══════════ A ══════════ */}
      {f < 134 && (
        <AbsoluteFill>
          <Camera scale={pushA} x={interpolate(f, [0, 130], [0, -12], {extrapolateRight: 'clamp'})}>
            <Study rain={1} warm={0} lamp={0} />
            <DeskTop />
            <Silhouette variant="backClose" x={131} y={560} scale={1.35} breathing={1} />
            <Cup x={700} y={1150} scale={1.15} steam={0.4} />
            <Cup x={790} y={1152} scale={1.15} steam={0} />
            <DeskFront />
            <Phone x={925} y={1032} w={150} glow={0.4} glowColor="#7b83e0" dim={0.3} rotate={7}>
              <LetterScreen typed={0} saved={0} />
            </Phone>
            {threadIn > 0 && <Thread from={[480, 940]} to={[790, 1124]} opacity={threadIn * 0.85} />}
          </Camera>
          <Dust count={26} opacity={0.26} tint="#C9D2FF" />
          <Vignette strength={0.6} />
          <Grain opacity={0.15} />
          <FadeBlack opacity={1 - interpolate(f, [0, 26], [0, 1], {extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ B ══════════ */}
      {f >= 134 && f < 300 && (
        <AbsoluteFill style={{backgroundColor: '#0A0A12'}}>
          <Camera scale={1.0}>
            <Phone x={540} y={980} w={900} glow={0.7} glowColor="#FAF8F5">
              <LetterScreen typed={typed} saved={saved} />
            </Phone>
          </Camera>
          {f > 232 && (
            <PaperBird
              x={540}
              y={980 - (f - 232) * 2.6}
              scale={1.3 + (f - 232) * 0.02}
              flap={Math.sin((f - 232) * 0.5)}
              rot={(f - 232) * 1.6}
              opacity={clamp01((f - 232) / 10)}
            />
          )}
          <Vignette strength={0.42} />
          <Grain opacity={0.1} />
          <FadeBlack opacity={1 - interpolate(f, [134, 142], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ C ══════════ */}
      {f >= 300 && f < 432 && (
        <AbsoluteFill>
          <Camera scale={1.03} y={-6}>
            <Study rain={1} warm={warm * 0.85} lamp={warm} />
            <DeskTop warm={warm} />
            <Silhouette variant="backClose" x={131} y={560} scale={1.35} breathing={1 - loosen * 0.35} />
            <Cup x={700} y={1150} scale={1.15} steam={0.4 + warm * 0.4} warm={warm} />
            <Cup x={790} y={1152} scale={1.15} steam={warm * 0.5} warm={warm} />
            <DeskFront warm={warm} />
            <Phone x={925} y={1032} w={160} glow={0.5} glowColor="#F2B25C" dim={0.05}>
              <GratitudeScreen lit={lit} />
            </Phone>
            {loosen < 0.98 && <Thread from={[480, 940]} to={[790, 1124]} loosen={loosen} opacity={1 - loosen} />}
            <PaperBird x={birdX} y={birdY} scale={1.6 - birdT * 0.95} flap={Math.sin(f * 0.4)} rot={Math.sin(birdT * Math.PI) * -18 + 8} />
          </Camera>
          <Bloom cx={902} cy={1010} r={440} color={`rgba(242,178,92,${0.1 + warm * 0.22})`} />
          <Dust count={34} opacity={0.26 + warm * 0.24} tint="#FFD9A8" speed={0.55} />
          <Vignette strength={0.52 - warm * 0.14} />
          <Grain opacity={0.12} />
          <PulseRing cx={925} cy={1032} r={interpolate(f, [300, 348], [0, 1600], {extrapolateRight: 'clamp'})} color={C.amber} width={3} opacity={interpolate(f, [300, 352], [0.45, 0], {extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ D ══════════ */}
      {f >= 432 && f < 500 && (
        <AbsoluteFill>
          <Camera scale={1.0 + (f - 432) * 0.0008}>
            <Study rain={rainStop} warm={1} lamp={1} />
            <DeskTop warm={1} />
            <Silhouette variant="backClose" x={131} y={560} scale={1.35} breathing={0.7} />
            <Cup x={700} y={1150} scale={1.15} steam={0.7} warm={1} />
            <Cup x={790} y={1152} scale={1.15} steam={0.55} warm={1} />
            <DeskFront warm={1} />
            <PaperBird x={300} y={878} scale={1.15} flap={Math.sin(f * 0.14) * 0.22} rot={-8} />
          </Camera>
          <LightShaft x={310} y={300} angle={-10} length={1250} spread={460} color="#FFC98A" opacity={0.2} blur={44} />
          <Vignette strength={0.44} />
          <Grain opacity={0.1} />
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

