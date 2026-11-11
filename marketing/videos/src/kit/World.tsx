import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {C, rand} from './theme';

/* Rooms are painted with gradients, light and grain — never a stock photo. */

export const Window: React.FC<{
  x: number;
  y: number;
  w: number;
  h: number;
  sky?: [string, string];
  warm?: number;
  rain?: number;
  moon?: boolean;
  stars?: number;
}> = ({x, y, w, h, sky = ['#0B1030', '#1B2250'], warm = 0, rain = 0, moon = true, stars = 40}) => {
  const frame = useCurrentFrame();
  const top = sky[0];
  const bottom = sky[1];
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, height: h}}>
      <div style={{position: 'absolute', inset: 0, borderRadius: 8, overflow: 'hidden', background: `linear-gradient(180deg, ${top} 0%, ${bottom} 100%)`}}>
        {/* dawn: a gradient sun, not a flat orange card */}
        {warm > 0.01 && (
          <div
            style={{
              position: 'absolute',
              inset: 0,
              opacity: warm,
              background: 'radial-gradient(circle at 64% 26%, #FFF8E8 0%, #FFE3B6 10%, #F7B173 30%, #C9773F 58%, #6A3A29 82%, #33201C 100%)',
            }}
          />
        )}
        {Array.from({length: stars}).map((_, i) => (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: rand(i * 2.1) * w,
              top: rand(i * 5.7) * h * 0.7,
              width: 2.4,
              height: 2.4,
              borderRadius: '50%',
              background: '#E8E4FF',
              opacity: (0.25 + rand(i * 3.3) * 0.6) * (1 - warm),
            }}
          />
        ))}
        {moon && (
          <div style={{position: 'absolute', left: w * 0.6, top: h * 0.2, width: w * 0.16, height: w * 0.16, borderRadius: '50%', background: '#EFEAD8', boxShadow: '0 0 40px rgba(239,234,216,0.55)', opacity: Math.max(0.25, 1 - warm * 1.4)}} />
        )}
        {/* rain streaks */}
        {rain > 0.01 &&
          Array.from({length: 46}).map((_, i) => {
            const sx = rand(i * 1.9) * w;
            const speed = 240 + rand(i * 4.4) * 180;
            const yy = (rand(i * 6.1) * h + frame * speed * 0.09) % (h + 60) - 30;
            return (
              <div
                key={`r${i}`}
                style={{
                  position: 'absolute',
                  left: sx,
                  top: yy,
                  width: 1.6,
                  height: 26 + rand(i * 2.7) * 26,
                  background: 'linear-gradient(180deg, rgba(200,210,255,0), rgba(200,210,255,0.5))',
                  transform: 'rotate(9deg)',
                  opacity: rain * 0.8,
                }}
              />
            );
          })}
        {warm > 0.01 && <div style={{position: 'absolute', inset: 0, background: `radial-gradient(circle at 50% 70%, rgba(255,190,120,${0.5 * warm}), transparent 70%)`}} />}
      </div>
      {/* frame */}
      <div style={{position: 'absolute', inset: 0, border: `10px solid #14151F`, borderRadius: 10, boxSizing: 'border-box'}} />
      <div style={{position: 'absolute', left: '50%', top: 0, bottom: 0, width: 8, marginLeft: -4, background: '#14151F'}} />
      <div style={{position: 'absolute', top: '46%', left: 0, right: 0, height: 8, background: '#14151F'}} />
    </div>
  );
};

export const Bedroom: React.FC<{warm?: number; night?: number}> = ({warm = 0, night = 1}) => {
  const wallTop = `rgb(${Math.round(12 + warm * 34)}, ${Math.round(14 + warm * 22)}, ${Math.round(32 + warm * 10)})`;
  const wallBot = `rgb(${Math.round(6 + warm * 26)}, ${Math.round(7 + warm * 16)}, ${Math.round(16 + warm * 6)})`;
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg, ${wallTop} 0%, ${wallBot} 78%)`, opacity: night}}>
      <Window x={96} y={330} w={330} h={470} warm={warm} moon rain={0} stars={34} />
      {/* the window throws its light across the wall and down onto the floor */}
      <div
        style={{
          position: 'absolute',
          left: 150,
          top: 700,
          width: 620,
          height: 900,
          background: `linear-gradient(200deg, rgba(150,165,255,${0.10 - warm * 0.07}) 0%, rgba(150,165,255,0) 62%)`,
          transform: 'rotate(6deg)',
          filter: 'blur(18px)',
        }}
      />
      {/* plaster, mottled — the wall is a surface, not a colour */}
      <svg style={{position: 'absolute', inset: 0}} width={1080} height={1460} opacity={0.5}>
        {Array.from({length: 26}).map((_, i) => (
          <ellipse
            key={i}
            cx={rand(i * 2.7) * 1080}
            cy={rand(i * 5.1) * 1400}
            rx={90 + rand(i * 3.9) * 220}
            ry={50 + rand(i * 7.3) * 140}
            fill={i % 2 === 0 ? 'rgba(90,100,170,0.03)' : 'rgba(0,0,0,0.06)'}
          />
        ))}
      </svg>
      {/* floor line + rug */}
      <div style={{position: 'absolute', left: 0, right: 0, top: 1400, height: 520, background: `linear-gradient(180deg, ${warm > 0.3 ? '#241C22' : '#0B0C16'} 0%, #05060C 100%)`}} />
      <div style={{position: 'absolute', left: 0, right: 0, top: 1400, height: 3, background: 'rgba(255,255,255,0.05)'}} />
      {/* moonlight pool on the floor */}
      <div style={{position: 'absolute', left: 60, top: 1410, width: 620, height: 300, background: `radial-gradient(ellipse at 30% 0%, rgba(170,180,255,${0.13 - warm * 0.1}), transparent 70%)`}} />
    </AbsoluteFill>
  );
};

export const Bed: React.FC<{warm?: number}> = ({warm = 0}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
    {/* headboard */}
    <rect x={150} y={1080} width={54} height={330} rx={16} fill="#1B1D2B" />
    {/* base */}
    <rect x={190} y={1300} width={700} height={190} rx={22} fill="#181A27" />
    {/* legs and the shadow under the frame */}
    <rect x={214} y={1470} width={26} height={56} rx={6} fill="#12131C" />
    <rect x={840} y={1470} width={26} height={56} rx={6} fill="#12131C" />
    <ellipse cx={540} cy={1530} rx={380} ry={34} fill="rgba(0,0,0,0.55)" />
    {/* mattress */}
    <rect x={186} y={1206} width={708} height={110} rx={26} fill="#242634" />
    {/* sheet highlight */}
    <rect x={186} y={1206} width={708} height={16} rx={8} fill="rgba(210,215,255,0.13)" />
    <rect x={186} y={1276} width={708} height={8} rx={4} fill="rgba(8,9,16,0.55)" />
    {/* pillow */}
    <ellipse cx={286} cy={1206} rx={104} ry={34} fill="#282A3C" />
    <ellipse cx={286} cy={1198} rx={96} ry={26} fill="#323447" />
    <ellipse cx={286} cy={1192} rx={70} ry={14} fill="rgba(220,225,255,0.06)" />
    {/* blanket */}
    <path d="M 400 1214 L 900 1214 L 900 1300 Q 640 1318 400 1300 Z" fill="#1F2130" />
    <path d="M 400 1214 L 900 1214 L 900 1240 Q 640 1252 400 1240 Z" fill="#292B3D" />
    <path d="M 400 1214 L 900 1214 L 900 1226 Q 640 1236 400 1226 Z" fill="rgba(215,220,255,0.09)" />
    <path d="M 470 1200 Q 500 1250 486 1300" stroke="rgba(210,215,255,0.06)" strokeWidth={4} fill="none" />
    <path d="M 620 1204 Q 648 1254 632 1306" stroke="rgba(210,215,255,0.05)" strokeWidth={4} fill="none" />
    {warm > 0.2 && <rect x={186} y={1206} width={708} height={110} rx={26} fill="rgba(255,180,110,0.06)" />}
  </svg>
);

export const Nightstand: React.FC<{x: number; y: number; warm?: number}> = ({x, y, warm = 0}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
    <g transform={`translate(${x} ${y})`}>
      <rect x={-110} y={0} width={220} height={26} rx={8} fill="#1B1C28" />
      <rect x={-96} y={26} width={192} height={200} rx={10} fill="#12131D" />
      <rect x={-80} y={70} width={160} height={4} rx={2} fill="rgba(255,255,255,0.06)" />
      <circle cx={0} cy={120} r={5} fill="rgba(255,255,255,0.12)" />
      {warm > 0.2 && <rect x={-96} y={26} width={192} height={200} rx={10} fill="rgba(255,180,110,0.05)" />}
    </g>
  </svg>
);

/** Rain-lit study: desk, empty chair opposite, a window that will stop raining. */
export const Study: React.FC<{rain?: number; warm?: number; lamp?: number}> = ({rain = 1, warm = 0, lamp = 0}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg, rgb(${10 + warm * 30},${11 + warm * 20},${24 + warm * 8}) 0%, rgb(${5 + warm * 20},${6 + warm * 12},${13 + warm * 5}) 80%)`}}>
      <Window x={110} y={300} w={400} h={520} rain={rain} warm={warm * 0.85} moon stars={18} />
      {/* desk */}
      <div style={{position: 'absolute', left: 0, right: 0, top: 1180, height: 34, background: 'linear-gradient(180deg, #2A2330, #191520)'}} />
      <div style={{position: 'absolute', left: 0, right: 0, top: 1180, height: 3, background: 'rgba(255,255,255,0.07)'}} />
      {/* warm lamp pool, off at first */}
      <div style={{position: 'absolute', left: 520, top: 860, width: 620, height: 620, background: `radial-gradient(ellipse at center, rgba(255,180,110,${0.22 * lamp}), transparent 66%)`}} />
      {/* rain light on the desk */}
      <div style={{position: 'absolute', left: 60, top: 1180, width: 700, height: 300, background: `radial-gradient(ellipse at 30% 0%, rgba(140,160,255,${0.1 * rain}), transparent 70%)`}} />
      {/* slow curtain movement */}
      <div
        style={{
          position: 'absolute',
          left: 30,
          top: 280,
          width: 110,
          height: 900,
          background: 'linear-gradient(180deg, rgba(40,36,60,0.55), rgba(20,18,30,0.2))',
          transform: `skewX(${Math.sin(frame * 0.02) * 2}deg)`,
        }}
      />
    </AbsoluteFill>
  );
};

export const Chair: React.FC<{x: number; y: number; scale?: number; dim?: number}> = ({x, y, scale = 1, dim = 1}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920} opacity={dim}>
    <g transform={`translate(${x} ${y}) scale(${scale})`}>
      <path d="M -90 0 L -90 -210 Q -90 -240 -60 -240 L 60 -240 Q 90 -240 90 -210 L 90 0" stroke="#0A0B12" strokeWidth={22} fill="none" strokeLinecap="round" />
      <path d="M -86 0 L -96 150 M 86 0 L 96 150" stroke="#0A0B12" strokeWidth={16} strokeLinecap="round" />
      <rect x={-96} y={-20} width={192} height={20} rx={8} fill="#0A0B12" />
    </g>
  </svg>
);

/** Macro soil: dense, layered, lit from one side — never a flat brown wash. */
export const Soil: React.FC<{warm?: number; wet?: number}> = ({warm = 0, wet = 0}) => (
  <AbsoluteFill style={{background: `radial-gradient(ellipse at 38% 34%, rgb(${58 + warm * 26},${43 + warm * 18},${32 + warm * 6}) 0%, rgb(${26},${19},${15}) 58%, #080604 100%)`}}>
    <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920} viewBox="0 0 1080 1920">
      {/* furrows: soft ridges catching light from the left */}
      {Array.from({length: 9}).map((_, i) => {
        const yy = 120 + i * 210 + rand(i * 3.3) * 60;
        return (
          <path
            key={`f${i}`}
            d={`M -60 ${yy} C 240 ${yy - 26 - rand(i * 2.1) * 30}, 620 ${yy + 34}, 1140 ${yy - 18}`}
            stroke={`rgba(${120 + warm * 40},${92 + warm * 24},${68},0.13)`}
            strokeWidth={26 + rand(i * 5.5) * 22}
            fill="none"
            strokeLinecap="round"
          />
        );
      })}
      {/* cracks */}
      {Array.from({length: 34}).map((_, i) => {
        const x = rand(i * 3.1) * 1080;
        const y = rand(i * 7.3) * 1920;
        const len = 120 + rand(i * 2.2) * 340;
        const a0 = rand(i * 5.5) * Math.PI * 2;
        let d = `M ${x.toFixed(0)} ${y.toFixed(0)}`;
        let px = x;
        let py = y;
        let ang = a0;
        for (let s = 0; s < 4; s++) {
          ang += (rand(i * 11 + s) - 0.5) * 0.7;
          px += Math.cos(ang) * (len / 4);
          py += Math.sin(ang) * (len / 4);
          d += ` L ${px.toFixed(0)} ${py.toFixed(0)}`;
        }
        return <path key={`c${i}`} d={d} stroke="rgba(8,5,4,0.85)" strokeWidth={2 + rand(i * 9.9) * 4} fill="none" strokeLinecap="round" />;
      })}
      {/* pebbles: hundreds of them, each with a lit edge */}
      {Array.from({length: 240}).map((_, i) => {
        const cx = rand(i * 1.37) * 1080;
        const cy = rand(i * 4.19) * 1920;
        const r = 3 + rand(i * 6.61) * 16;
        const lit = 0.10 + rand(i * 8.3) * 0.12;
        return (
          <g key={`p${i}`}>
            <ellipse cx={cx} cy={cy} rx={r} ry={r * (0.55 + rand(i * 2.9) * 0.3)} fill={`rgba(${34 + rand(i * 3.1) * 26},${25 + rand(i * 4.3) * 18},${19 + rand(i * 5.7) * 12},1)`} transform={`rotate(${rand(i * 7.1) * 180} ${cx} ${cy})`} />
            <ellipse cx={cx - r * 0.25} cy={cy - r * 0.25} rx={r * 0.55} ry={r * 0.3} fill={`rgba(255,214,170,${lit})`} transform={`rotate(${rand(i * 7.1) * 180} ${cx} ${cy})`} />
          </g>
        );
      })}
      {/* wet patch where the drop fell */}
      {wet > 0.01 && (
        <ellipse cx={620} cy={1240} rx={130 + wet * 90} ry={40 + wet * 26} fill="rgba(10,12,22,0.55)" opacity={wet} />
      )}
      {/* tiny grass, only after growth */}
      {wet > 0.4 &&
        Array.from({length: 40}).map((_, i) => {
          const gx = rand(i * 2.7) * 1080;
          const gy = 1200 + rand(i * 9.4) * 500;
          const h = 14 + rand(i * 3.9) * 34;
          return (
            <path
              key={`g${i}`}
              d={`M ${gx} ${gy} q ${(rand(i * 5.3) - 0.5) * 12} ${-h * 0.6} ${(rand(i * 6.7) - 0.5) * 20} ${-h}`}
              stroke={`rgba(70,120,70,${wet * 0.5})`}
              strokeWidth={2.2}
              fill="none"
              strokeLinecap="round"
            />
          );
        })}
    </svg>
    <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 46% 42%, rgba(0,0,0,0) 18%, rgba(0,0,0,0.82) 76%)'}} />
  </AbsoluteFill>
);

/** The room of the last film: bare floor, one window, a person and a phone. */
export const DarkRoom: React.FC<{glow?: number; warm?: number}> = ({glow = 0, warm = 0}) => (
  <AbsoluteFill style={{background: `linear-gradient(180deg, rgb(${9 + warm * 26},${10 + warm * 18},${22 + warm * 8}) 0%, #05060B 78%)`}}>
    <Window x={760} y={260} w={250} h={360} warm={warm} moon stars={26} />
    <div style={{position: 'absolute', left: 0, right: 0, top: 1290, height: 630, background: 'linear-gradient(180deg, #0B0C15, #04050A)'}} />
    <div style={{position: 'absolute', left: 0, right: 0, top: 1290, height: 2, background: 'rgba(255,255,255,0.05)'}} />
    <div style={{position: 'absolute', left: 420, top: 500, width: 900, height: 900, background: `radial-gradient(circle, rgba(140,130,240,${0.14 * glow}), transparent 68%)`}} />
  </AbsoluteFill>
);

/** Panels of undifferentiated noise, used for the overwhelm film. */
export const NoisePanels: React.FC<{density?: number; freeze?: number; pull?: number; opacity?: number}> = ({
  density = 1,
  freeze = 0,
  pull = 0,
  opacity = 1,
}) => {
  const frame = useCurrentFrame();
  const t = frame * (1 - freeze);
  return (
    <div style={{position: 'absolute', inset: 0, overflow: 'hidden', opacity}}>
      {Array.from({length: Math.round(16 * density)}).map((_, i) => {
        const w = 180 + rand(i * 2.3) * 420;
        const h = 90 + rand(i * 5.1) * 260;
        const x = ((rand(i * 1.7) * 1300 - 200 + t * (0.6 + rand(i * 3.3) * 1.6)) % 1400) - 160;
        const y = rand(i * 7.9) * 1700 - 100 + Math.sin(t * 0.02 + i) * 40;
        const r = rand(i * 9.1) * 8 - 4;
        const targetX = 540;
        const targetY = 900;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x + (targetX - x) * pull,
              top: y + (targetY - y) * pull,
              width: w * (1 - pull * 0.8),
              height: h * (1 - pull * 0.8),
              borderRadius: 18,
              background: i % 3 === 0 ? 'rgba(158,168,210,0.14)' : i % 3 === 1 ? 'rgba(124,134,176,0.10)' : 'rgba(96,106,148,0.12)',
              border: '1px solid rgba(190,200,240,0.14)',
              transform: `rotate(${r}deg)`,
              opacity: 1 - pull,
            }}
          />
        );
      })}
    </div>
  );
};

