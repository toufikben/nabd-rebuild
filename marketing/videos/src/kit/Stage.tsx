import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {C, rand} from './theme';

export const Camera: React.FC<{
  scale?: number;
  x?: number;
  y?: number;
  rotate?: number;
  blur?: number;
  children: React.ReactNode;
  origin?: string;
}> = ({scale = 1, x = 0, y = 0, rotate = 0, blur = 0, children, origin = '50% 50%'}) => (
  <AbsoluteFill
    style={{
      transform: `translate3d(${x}px, ${y}px, 0) scale(${scale}) rotate(${rotate}deg)`,
      transformOrigin: origin,
      filter: blur > 0.01 ? `blur(${blur}px)` : undefined,
      willChange: 'transform',
    }}
  >
    {children}
  </AbsoluteFill>
);

export const Grain: React.FC<{opacity?: number; seed?: number}> = ({opacity = 0.16, seed = 3}) => (
  <svg
    style={{position: 'absolute', inset: 0, width: 1080, height: 1920, pointerEvents: 'none', mixBlendMode: 'overlay'}}
    viewBox="0 0 1080 1920"
  >
    <defs>
      <filter id={`grain-${seed}`}>
        <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed={seed} />
        <feColorMatrix type="saturate" values="0" />
      </filter>
    </defs>
    <rect width={1080} height={1920} filter={`url(#grain-${seed})`} opacity={opacity} />
  </svg>
);

export const Vignette: React.FC<{strength?: number; color?: string}> = ({strength = 0.9, color = '#000000'}) => (
  <div
    style={{
      position: 'absolute',
      inset: 0,
      background: `radial-gradient(ellipse 78% 62% at 50% 46%, rgba(0,0,0,0) 42%, ${color} 100%)`,
      opacity: strength,
      pointerEvents: 'none',
    }}
  />
);

export const Dust: React.FC<{count?: number; opacity?: number; tint?: string; speed?: number}> = ({
  count = 44,
  opacity = 0.5,
  tint = '#E8E4FF',
  speed = 1,
}) => {
  const frame = useCurrentFrame();
  return (
    <svg style={{position: 'absolute', inset: 0, width: 1080, height: 1920, pointerEvents: 'none'}} viewBox="0 0 1080 1920">
      {Array.from({length: count}).map((_, i) => {
        const bx = rand(i * 3.3) * 1080;
        const by = rand(i * 7.7) * 1920;
        const r = 0.9 + rand(i * 1.7) * 2.6;
        const drift = Math.sin(frame * 0.012 * speed + i) * 26;
        const rise = (frame * 0.35 * speed + rand(i * 5.1) * 400) % 1920;
        const y = (by - rise + 1920) % 1920;
        return (
          <circle
            key={i}
            cx={bx + drift}
            cy={y}
            r={r}
            fill={tint}
            opacity={(0.15 + rand(i * 9.1) * 0.55) * opacity}
          />
        );
      })}
    </svg>
  );
};

export const PulseRing: React.FC<{
  cx: number;
  cy: number;
  r: number;
  width?: number;
  color?: string;
  opacity?: number;
  glow?: number;
}> = ({cx, cy, r, width = 3, color = C.coral, opacity = 1, glow = 1}) => {
  if (r <= 0) return null;
  return (
    <div
      style={{
        position: 'absolute',
        left: cx - r,
        top: cy - r,
        width: r * 2,
        height: r * 2,
        borderRadius: '50%',
        border: `${width}px solid ${color}`,
        boxShadow: `0 0 ${40 * glow}px ${color}, inset 0 0 ${40 * glow}px ${color}`,
        opacity,
        pointerEvents: 'none',
      }}
    />
  );
};

export const Bloom: React.FC<{
  cx: number;
  cy: number;
  r: number;
  color: string;
  opacity?: number;
}> = ({cx, cy, r, color, opacity = 0.8}) => (
  <div
    style={{
      position: 'absolute',
      left: cx - r,
      top: cy - r,
      width: r * 2,
      height: r * 2,
      borderRadius: '50%',
      background: `radial-gradient(circle, ${color} 0%, transparent 70%)`,
      opacity,
      pointerEvents: 'none',
      filter: 'blur(8px)',
    }}
  />
);

export const LightShaft: React.FC<{
  x: number;
  y: number;
  angle?: number;
  length?: number;
  spread?: number;
  color?: string;
  opacity?: number;
  blur?: number;
}> = ({x, y, angle = 0, length = 1200, spread = 260, color = '#C8BFFF', opacity = 0.18, blur = 26}) => (
  <div
    style={{
      position: 'absolute',
      left: x - spread / 2,
      top: y,
      width: spread,
      height: length,
      background: `linear-gradient(to bottom, ${color} 0%, transparent 92%)`,
      filter: `blur(${blur}px)`,
      opacity,
      transform: `rotate(${angle}deg)`,
      transformOrigin: 'top center',
      pointerEvents: 'none',
      mixBlendMode: 'screen',
    }}
  />
);

export const FadeBlack: React.FC<{opacity: number}> = ({opacity}) =>
  opacity <= 0.001 ? null : (
    <div style={{position: 'absolute', inset: 0, backgroundColor: '#000', opacity, pointerEvents: 'none'}} />
  );
