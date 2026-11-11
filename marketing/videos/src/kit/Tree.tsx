import React from 'react';
import {useCurrentFrame} from 'remotion';
import {rand} from './theme';

type Seg = {x1: number; y1: number; x2: number; y2: number; w: number; t: number; depth: number};
type Leaf = {x: number; y: number; r: number; t: number; a: number};

const MAX_DEPTH = 6;

function build(seed: number) {
  const segs: Seg[] = [];
  const leaves: Leaf[] = [];
  let k = 0;
  const grow = (x: number, y: number, ang: number, len: number, w: number, depth: number) => {
    if (depth <= 0) return;
    k += 1;
    const bend = (rand(seed + k * 3.7) - 0.5) * 0.5;
    const x2 = x + Math.cos(ang + bend * 0.4) * len;
    const y2 = y + Math.sin(ang + bend * 0.4) * len;
    const t = 1 - depth / MAX_DEPTH;
    segs.push({x1: x, y1: y, x2, y2, w, t, depth});
    if (depth <= 2) {
      // leaf cluster at the tip
      const n = 3 + Math.floor(rand(seed + k * 11.3) * 3);
      for (let i = 0; i < n; i++) {
        leaves.push({
          x: x2 + (rand(seed + k * 5 + i) - 0.5) * len * 1.5,
          y: y2 + (rand(seed + k * 9 + i) - 0.5) * len * 1.5,
          r: len * (0.28 + rand(seed + k * 13 + i) * 0.26),
          t,
          a: rand(seed + k * 17 + i) * Math.PI,
        });
      }
    }
    const branches = depth > 4 ? 2 : rand(seed + k * 2.1) > 0.35 ? 3 : 2;
    for (let i = 0; i < branches; i++) {
      const spread = 0.42 + rand(seed + k * 7.7 + i) * 0.34;
      const na = ang + (i - (branches - 1) / 2) * spread + (rand(seed + k * 4.4 + i) - 0.5) * 0.2;
      grow(x2, y2, na, len * (0.62 + rand(seed + k * 6.1 + i) * 0.16), w * 0.66, depth - 1);
    }
  };
  grow(0, 0, -Math.PI / 2, 0.3, 0.055, MAX_DEPTH);
  return {segs, leaves};
}

const A = build(7);
const B_ = build(23);

/**
 * A tree that grows from the soil: wood appears branch by branch, leaves flush
 * in behind it. Two authored variants so no two films look alike.
 */
export const Tree: React.FC<{
  x: number;
  y: number;
  g: number;
  scale?: number;
  sway?: number;
  variant?: 0 | 1;
  leafColor?: [string, string];
}> = ({x, y, g, scale = 700, sway = 0, variant = 0, leafColor = ['#3F8155', '#63A772']}) => {
  const f = useCurrentFrame();
  const {segs, leaves} = variant === 0 ? A : B_;
  return (
    <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
      <g transform={`translate(${x} ${y}) scale(${scale})`}>
        {segs.map((s, i) => {
          if (g < s.t * 0.94) return null;
          const swayAmt = sway * (1 + s.t * 2.2) * 0.006;
          const wob = Math.sin(f * 0.02 + i * 0.3) * swayAmt;
          return (
            <line
              key={i}
              x1={s.x1 + wob}
              y1={s.y1}
              x2={s.x2 + wob * 1.6}
              y2={s.y2}
              stroke={s.depth > 4 ? '#4A3524' : s.depth > 2 ? '#553E2A' : '#634A32'}
              strokeWidth={s.w}
              strokeLinecap="round"
            />
          );
        })}
        {leaves.map((l, i) => {
          const on = (g - l.t - 0.06) / 0.18;
          if (on <= 0) return null;
          const s = Math.min(1, on);
          const wob = Math.sin(f * 0.03 + i) * 0.004;
          return (
            <g key={`l${i}`} transform={`translate(${l.x + wob} ${l.y}) rotate(${(l.a * 180) / Math.PI}) scale(${s})`}>
              <ellipse cx={0} cy={0} rx={l.r} ry={l.r * 0.62} fill={i % 4 === 0 ? leafColor[1] : leafColor[0]} />
              <ellipse cx={-l.r * 0.2} cy={-l.r * 0.16} rx={l.r * 0.5} ry={l.r * 0.3} fill={leafColor[1]} opacity={0.55} />
            </g>
          );
        })}
      </g>
    </svg>
  );
};
