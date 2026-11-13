import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {easeInOut, easeOut, rand} from '../kit/theme';
import {Camera, Dust, Vignette, PulseRing, Bloom, FadeBlack, LightShaft} from '../kit/Stage';
import {Phone, PhoneLight} from '../kit/Phone';
import {fontFamily} from '../kit/Fonts';

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  brand  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
const F = {
  ink: '#04070E',
  navy: '#071022',
  navy2: '#0B1B36',
  blue: '#2E7BFF',
  blueSoft: '#7FB2FF',
  gold: '#F2C14E',
  goldSoft: '#FFE1A3',
  cream: '#F7F1E3',
  steel: '#8FA0BF',
  red: '#FF5A48',
};

const cap: React.CSSProperties = {
  position: 'absolute',
  left: 70,
  right: 70,
  textAlign: 'center',
  fontFamily,
  fontWeight: 900,
  color: F.cream,
  direction: 'rtl',
  lineHeight: 1.22,
  textShadow: '0 6px 26px rgba(0,0,0,0.85), 0 2px 8px rgba(0,0,0,0.9)',
};

/** Arabic caption that rises and settles, with a gold rule that draws under it. */
const Caption: React.FC<{text: string; sub?: string; from: number; to: number; y?: number; size?: number}> = ({
  text,
  sub,
  from,
  to,
  y = 1318,
  size = 74,
}) => {
  const f = useCurrentFrame();
  const t = f - from;
  if (t < 0 || f > to) return null;
  const enter = easeOut(Math.min(1, t / 14));
  const out = interpolate(f, [to - 8, to], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const rule = easeInOut(Math.min(1, t / 22));
  return (
    <div style={{opacity: enter * out}}>
      <div style={{...cap, top: y, fontSize: size, transform: `translateY(${(1 - enter) * 26}px)`}}>{text}</div>
      {sub ? (
        <div
          style={{
            ...cap,
            top: y + size + 18,
            fontSize: size * 0.56,
            fontWeight: 700,
            color: F.goldSoft,
            transform: `translateY(${(1 - enter) * 26}px)`,
          }}
        >
          {sub}
        </div>
      ) : null}
      <div
        style={{
          position: 'absolute',
          top: y + size + (sub ? size * 0.62 + 32 : 18),
          left: 540 - 130 * rule,
          width: 260 * rule,
          height: 4,
          borderRadius: 2,
          background: `linear-gradient(90deg, rgba(242,193,78,0) 0%, ${F.gold} 50%, rgba(242,193,78,0) 100%)`,
          boxShadow: `0 0 22px ${F.gold}88`,
        }}
      />
    </div>
  );
};

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  night city  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
const City: React.FC<{snow?: number; lamp?: number}> = ({snow = 1, lamp = 1}) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg, #02050C 0%, ${F.navy} 46%, #0A1526 74%, #060C16 100%)`}}>
      {/* moon haze */}
      <div
        style={{
          position: 'absolute',
          left: 640,
          top: 120,
          width: 620,
          height: 620,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(150,180,235,0.20) 0%, rgba(150,180,235,0.05) 42%, transparent 68%)',
        }}
      />
      {/* far skyline */}
      <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
        {Array.from({length: 26}).map((_, i) => {
          const w = 60 + rand(i * 3.1) * 110;
          const x = -40 + i * 44 + rand(i * 5.3) * 20;
          const h = 130 + rand(i * 7.7) * 300;
          return (
            <g key={i} opacity={0.85}>
              <rect x={x} y={1040 - h} width={w} height={h + 40} fill="#050A14" />
              {Array.from({length: Math.floor(h / 46)}).map((__, j) => {
                const lit = rand(i * 13.3 + j * 2.7) > 0.55;
                return (
                  <rect
                    key={j}
                    x={x + 12 + (j % 2) * 26}
                    y={1040 - h + 18 + Math.floor(j / 2) * 40}
                    width={14}
                    height={18}
                    fill={lit ? 'rgba(255,203,120,0.42)' : 'rgba(120,150,210,0.05)'}
                  />
                );
              })}
            </g>
          );
        })}
      </svg>

      {/* street lamp */}
      <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
        <rect x={842} y={560} width={12} height={900} fill="#0A111E" />
        <path d="M 848 566 q 60 -6 96 34" stroke="#0A111E" strokeWidth={11} fill="none" strokeLinecap="round" />
        <ellipse cx={952} cy={604} rx={38} ry={15} fill="#0A111E" />
      </svg>
      <div
        style={{
          position: 'absolute',
          left: 952 - 44,
          top: 604,
          width: 88,
          height: 30,
          borderRadius: 16,
          background: `rgba(255,214,150,${0.55 * lamp})`,
          boxShadow: `0 0 60px 20px rgba(255,198,120,${0.22 * lamp})`,
        }}
      />
      <LightShaft x={952} y={620} angle={4} length={1050} spread={330} color="#FFC98A" opacity={0.16 * lamp} blur={44} />

      {/* wet ground reflection */}
      <div style={{position: 'absolute', left: 0, right: 0, top: 1420, height: 500, background: 'linear-gradient(180deg, #070D16 0%, #03060C 100%)'}} />
      <div style={{position: 'absolute', left: 700, top: 1430, width: 520, height: 320, background: `radial-gradient(ellipse at 50% 0%, rgba(255,198,120,${0.10 * lamp}), transparent 70%)`}} />

      {/* snow, three depths */}
      <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
        {Array.from({length: 110}).map((_, i) => {
          const depth = i % 3;
          const speed = [0.5, 1.1, 2.1][depth];
          const r = [1.2, 2.2, 3.6][depth];
          const bx = rand(i * 2.7) * 1180 - 50;
          const y = (rand(i * 5.9) * 1920 + f * speed * 1.7) % 1920;
          const x = bx + Math.sin((f + i * 30) * 0.013) * (8 + depth * 12);
          return <circle key={i} cx={x} cy={y} r={r} fill="#DCE8FF" opacity={(0.18 + depth * 0.16) * snow} />;
        })}
      </svg>
      <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(2,5,12,0.55) 0%, rgba(2,5,12,0) 34%)'}} />
    </AbsoluteFill>
  );
};

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  people  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
const Thief: React.FC<{x: number; y: number; scale?: number; reach?: number; walk?: number; flip?: boolean; opacity?: number}> = ({
  x,
  y,
  scale = 1,
  reach = 0,
  walk = 0,
  flip = false,
  opacity = 1,
}) => {
  const f = useCurrentFrame();
  const swing = Math.sin(f * 0.16) * 10 * walk;
  const body = '#03060C';
  return (
    <svg style={{position: 'absolute', inset: 0, opacity}} width={1080} height={1920}>
      <g transform={`translate(${x} ${y}) scale(${flip ? -scale : scale} ${scale})`}>
        {/* legs */}
        <path d={`M -18 0 L ${-30 + swing} 150`} stroke={body} strokeWidth={46} strokeLinecap="round" fill="none" />
        <path d={`M 18 0 L ${30 - swing} 150`} stroke={body} strokeWidth={46} strokeLinecap="round" fill="none" />
        {/* torso in a long coat */}
        <path d="M -56 -150 Q -70 -40 -52 30 L 52 30 Q 70 -40 56 -150 Z" fill={body} />
        {/* shoulders */}
        <path d="M -62 -160 Q 0 -196 62 -160 L 56 -118 Q 0 -150 -56 -118 Z" fill={body} />
        {/* hood */}
        <path d="M -46 -238 Q -52 -318 0 -326 Q 52 -318 46 -238 Q 30 -262 0 -262 Q -30 -262 -46 -238 Z" fill={body} />
        <ellipse cx={0} cy={-268} rx={34} ry={38} fill={body} />
        {/* rim light from the street lamp */}
        <path d="M 40 -300 Q 52 -258 44 -212" stroke="rgba(180,205,255,0.30)" strokeWidth={3} fill="none" />
        <path d="M 58 -168 Q 66 -90 56 -20" stroke="rgba(180,205,255,0.18)" strokeWidth={2.6} fill="none" />
        <path d="M 20 -322 Q 44 -312 46 -288" stroke="rgba(180,205,255,0.35)" strokeWidth={3} fill="none" />
        {/* right arm: idle â†’ reaching */}
        <g transform={`rotate(${-14 + reach * 96} 62 -150)`}>
          <path d="M 62 -150 L 118 -60 L 172 16" stroke={body} strokeWidth={30} strokeLinecap="round" fill="none" />
          {/* glove */}
          <path d="M 164 6 q 26 4 34 22 q -18 16 -40 8 z" fill={body} />
          <path d="M 170 12 q 22 2 30 14" stroke="rgba(180,205,255,0.22)" strokeWidth={2.4} fill="none" />
        </g>
      </g>
    </svg>
  );
};

const Owner: React.FC<{x: number; y: number; scale?: number; warm?: number}> = ({x, y, scale = 1, warm = 0}) => {
  const f = useCurrentFrame();
  const b = Math.sin(f * 0.05) * 2;
  const body = '#03060C';
  return (
    <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
      <g transform={`translate(${x} ${y + b}) scale(${scale})`}>
        <path d="M -70 -120 Q -84 10 -66 120 L 66 120 Q 84 10 70 -120 Z" fill={body} />
        <path d="M -74 -132 Q 0 -168 74 -132 L 68 -88 Q 0 -122 -68 -88 Z" fill={body} />
        <ellipse cx={0} cy={-186} rx={40} ry={44} fill={body} />
        <path d="M -40 -196 Q -46 -244 0 -248 Q 46 -244 40 -196 Q 26 -224 0 -224 Q -26 -224 -40 -196 Z" fill={body} />
        <path d="M 44 -232 Q 52 -206 44 -186" stroke={`rgba(255,210,150,${0.18 + warm * 0.35})`} strokeWidth={3} fill="none" />
        <path d="M 60 -120 Q 70 0 60 110" stroke={`rgba(255,210,150,${0.10 + warm * 0.22})`} strokeWidth={2.6} fill="none" />
        {/* forearm resting on the table */}
        <path d="M -40 -60 L -128 32" stroke={body} strokeWidth={30} strokeLinecap="round" fill="none" />
      </g>
    </svg>
  );
};

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  table  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
const CafeTable: React.FC<{tilt?: number}> = ({tilt = 0}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
    <g transform={`translate(0 ${tilt})`}>
      <ellipse cx={540} cy={1580} rx={470} ry={128} fill="#101A2B" />
      <ellipse cx={540} cy={1566} rx={470} ry={122} fill="#182740" />
      <ellipse cx={540} cy={1566} rx={470} ry={122} fill="url(#tbl)" />
      <defs>
        <radialGradient id="tbl" cx="42%" cy="26%" r="72%">
          <stop offset="0%" stopColor="rgba(150,185,240,0.20)" />
          <stop offset="55%" stopColor="rgba(60,90,140,0.10)" />
          <stop offset="100%" stopColor="rgba(0,0,0,0)" />
        </radialGradient>
      </defs>
      <path d="M 540 1688 L 516 1900 L 564 1900 Z" fill="#0A111C" />
      <ellipse cx={540} cy={1900} rx={150} ry={22} fill="#070C14" />
      {/* cup */}
      <g transform="translate(300 1520)">
        <ellipse cx={0} cy={26} rx={44} ry={14} fill="#0A111C" />
        <path d="M -34 -6 L 34 -6 L 28 22 L -28 22 Z" fill="#1B2A42" />
        <ellipse cx={0} cy={-6} rx={34} ry={11} fill="#26374F" />
        <ellipse cx={0} cy={-6} rx={26} ry={8} fill="#0C1522" />
      </g>
    </g>
  </svg>
);

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  screens  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
const ShieldGlyph: React.FC<{size: number; color?: string; glow?: number}> = ({size, color = F.gold, glow = 1}) => (
  <svg width={size} height={size * 1.14} viewBox="0 0 100 114" style={{filter: glow > 0 ? `drop-shadow(0 0 ${18 * glow}px ${color}90)` : undefined}}>
    <path d="M 50 4 L 94 22 L 94 58 Q 94 92 50 110 Q 6 92 6 58 L 6 22 Z" fill="none" stroke={color} strokeWidth={5} />
    <path d="M 50 18 L 80 30 L 80 58 Q 80 82 50 95 Q 20 82 20 58 L 20 30 Z" fill={`${color}14`} stroke={`${color}55`} strokeWidth={2} />
  </svg>
);

const GuardLock: React.FC<{attempts: number; shake: number; tapDigit?: number}> = ({attempts, shake, tapDigit}) => {
  const f = useCurrentFrame();
  const press = tapDigit === undefined ? 0 : 1;
  return (
    <div style={{position: 'absolute', inset: 0, background: `linear-gradient(180deg, ${F.navy} 0%, #04070E 62%)`, direction: 'rtl'}}>
      <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 300, background: 'radial-gradient(ellipse at 50% 0%, rgba(46,123,255,0.30), transparent 70%)'}} />
      <div style={{position: 'absolute', left: 0, right: 0, top: 44, textAlign: 'center', fontFamily, fontSize: 20, color: 'rgba(190,210,240,0.55)', letterSpacing: 2}}>
        03:17
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 86, display: 'flex', justifyContent: 'center'}}>
        <ShieldGlyph size={86} color={attempts > 0 ? F.red : F.gold} glow={1} />
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 210, textAlign: 'center', fontFamily, fontWeight: 900, fontSize: 30, color: F.cream}}>
        Ø±Ù…Ø² Ø§Ù„Ø¯Ø®ÙˆÙ„
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 252, textAlign: 'center', fontFamily, fontSize: 18, color: 'rgba(160,180,212,0.85)'}}>
        Ù…Ø­Ø§ÙˆÙ„Ø© {attempts} Ù…Ù† 3
      </div>
      {/* dots */}
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 300,
          display: 'flex',
          justifyContent: 'center',
          gap: 22,
          transform: `translateX(${Math.sin(f * 1.9) * 10 * shake}px)`,
        }}
      >
        {[0, 1, 2, 3].map((i) => (
          <div
            key={i}
            style={{
              width: 22,
              height: 22,
              borderRadius: '50%',
              background: attempts > i ? F.red : 'rgba(255,255,255,0.10)',
              border: `2px solid ${attempts > i ? F.red : 'rgba(150,175,215,0.5)'}`,
              boxShadow: attempts > i ? `0 0 16px ${F.red}aa` : undefined,
            }}
          />
        ))}
      </div>
      {/* keypad */}
      <div style={{position: 'absolute', left: 58, right: 58, top: 372, display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: 16}}>
        {['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'âŒ«'].map((d, i) => {
          const active = tapDigit !== undefined && String(i) === String(tapDigit);
          return (
            <div
              key={i}
              style={{
                width: 100,
                height: 92,
                borderRadius: 46,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily,
                fontSize: 34,
                fontWeight: 700,
                color: d ? F.cream : 'transparent',
                background: active ? 'rgba(46,123,255,0.42)' : 'rgba(255,255,255,0.055)',
                border: `1px solid ${active ? 'rgba(127,178,255,0.75)' : 'rgba(255,255,255,0.06)'}`,
                transform: `scale(${active ? 0.93 : 1})`,
              }}
            >
              {d}
            </div>
          );
        })}
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 40, textAlign: 'center', fontFamily, fontSize: 16, color: `rgba(255,90,72,${0.35 + shake * 0.65})`}}>
        Ø¯Ø®ÙˆÙ„ ØºÙŠØ± Ù…ØµØ±Ù‘Ø­ Ø¨Ù‡
      </div>
    </div>
  );
};

/** The captured intruder frame: a hooded face in a scan-grid, cold and grainy. */
const IntruderShot: React.FC<{scan?: number}> = ({scan = 1}) => {
  const f = useCurrentFrame();
  return (
    <div style={{position: 'absolute', inset: 0, background: '#05090F', overflow: 'hidden'}}>
      <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 38%, #14243C 0%, #070C15 62%, #03060B 100%)'}} />
      <svg style={{position: 'absolute', inset: 0}} width={472} height={996}>
        {/* hooded head, cold fill */}
        <path d="M 236 250 Q 300 250 312 330 Q 322 404 296 436 L 296 470 L 176 470 L 176 436 Q 150 404 160 330 Q 172 250 236 250 Z" fill="#0B1524" />
        <path d="M 236 262 Q 296 262 306 336 Q 314 400 292 430" stroke="rgba(127,178,255,0.28)" strokeWidth={3} fill="none" />
        <ellipse cx={236} cy={356} rx={54} ry={64} fill="#060C16" />
        {/* eyes catch the flash */}
        <ellipse cx={214} cy={344} rx={9} ry={5} fill="rgba(220,235,255,0.55)" />
        <ellipse cx={258} cy={344} rx={9} ry={5} fill="rgba(220,235,255,0.55)" />
        <path d="M 218 388 Q 236 396 254 388" stroke="rgba(200,220,255,0.28)" strokeWidth={3} fill="none" />
        {/* shoulders */}
        <path d="M 120 996 L 140 560 Q 236 510 332 560 L 352 996 Z" fill="#080F1B" />
        <path d="M 150 566 Q 236 522 322 566" stroke="rgba(127,178,255,0.22)" strokeWidth={3} fill="none" />
        {/* scan lines */}
        {Array.from({length: 62}).map((_, i) => (
          <line key={i} x1={0} x2={472} y1={i * 16} y2={i * 16} stroke="rgba(140,180,255,0.055)" strokeWidth={1} />
        ))}
        <rect x={0} y={(f * 7) % 996} width={472} height={22} fill="rgba(127,178,255,0.07)" opacity={scan} />
      </svg>
      {/* HUD brackets */}
      {[
        [26, 300],
        [446, 300],
        [26, 700],
        [446, 700],
      ].map(([x, y], i) => (
        <div
          key={i}
          style={{
            position: 'absolute',
            left: x - 18,
            top: y - 18,
            width: 36,
            height: 36,
            borderTop: `3px solid ${i < 2 ? F.gold : F.gold}`,
            borderLeft: i % 2 === 0 ? `3px solid ${F.gold}` : undefined,
            borderRight: i % 2 === 1 ? `3px solid ${F.gold}` : undefined,
            borderBottom: i > 1 ? `3px solid ${F.gold}` : undefined,
          }}
        />
      ))}
      <div style={{position: 'absolute', left: 0, right: 0, top: 250, textAlign: 'center', fontFamily, fontSize: 13, color: F.gold, letterSpacing: 3, fontWeight: 700}}>
        CAM Â· FRONT
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 210, textAlign: 'center', fontFamily, fontWeight: 900, fontSize: 26, color: F.cream, direction: 'rtl'}}>
        ØªÙ… Ø§Ù„ØªÙ‚Ø§Ø· Ø§Ù„ØµÙˆØ±Ø©
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 170, textAlign: 'center', fontFamily, fontSize: 15, color: 'rgba(190,210,240,0.7)'}}>
        03:17:46 Â· Ø¨Ø¯ÙˆÙ† ØµÙˆØª Â· Ø¨Ø¯ÙˆÙ† Ø¥Ø´Ø¹Ø§Ø±
      </div>
    </div>
  );
};

const Evidence: React.FC<{reveal: number; send: number}> = ({reveal, send}) => {
  const f = useCurrentFrame();
  return (
    <div style={{position: 'absolute', inset: 0, background: `linear-gradient(180deg, ${F.navy} 0%, #04070E 70%)`, direction: 'rtl'}}>
      <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 240, background: 'radial-gradient(ellipse at 50% 0%, rgba(46,123,255,0.26), transparent 70%)'}} />
      <div style={{position: 'absolute', left: 0, right: 0, top: 40, textAlign: 'center', fontFamily, fontWeight: 900, fontSize: 24, color: F.gold}}>
        ØªÙ‚Ø±ÙŠØ± Ø§Ù„Ø­Ù…Ø§ÙŠØ©
      </div>
      {/* photo */}
      <div
        style={{
          position: 'absolute',
          left: 34,
          top: 96,
          width: 150,
          height: 190,
          borderRadius: 14,
          overflow: 'hidden',
          border: `2px solid ${F.gold}88`,
          opacity: reveal,
          transform: `scale(${0.86 + reveal * 0.14}) rotate(${-2 + reveal * 2}deg)`,
        }}
      >
        <div style={{position: 'absolute', inset: 0, transform: 'scale(0.62)', transformOrigin: 'top left'}}>
          <IntruderShot />
        </div>
      </div>
      {/* map */}
      <div style={{position: 'absolute', right: 34, top: 96, width: 214, height: 190, borderRadius: 14, overflow: 'hidden', border: '2px solid rgba(127,178,255,0.35)', opacity: reveal}}>
        <div style={{position: 'absolute', inset: 0, background: '#061020'}} />
        <svg width={214} height={190} style={{position: 'absolute', inset: 0}}>
          {Array.from({length: 9}).map((_, i) => (
            <line key={`h${i}`} x1={0} x2={214} y1={i * 24} y2={i * 24} stroke="rgba(127,178,255,0.14)" strokeWidth={1} />
          ))}
          {Array.from({length: 10}).map((_, i) => (
            <line key={`v${i}`} x1={i * 24} x2={i * 24} y1={0} y2={190} stroke="rgba(127,178,255,0.14)" strokeWidth={1} />
          ))}
          <path d="M -10 130 Q 60 96 106 118 Q 160 142 224 108" stroke="rgba(255,255,255,0.16)" strokeWidth={12} fill="none" />
          <path d="M 62 190 L 78 96 L 130 96 L 146 190" stroke="rgba(127,178,255,0.10)" strokeWidth={7} fill="none" />
        </svg>
        {[0, 1, 2].map((i) => {
          const t = ((f * 1.4 + i * 26) % 78) / 78;
          return (
            <div
              key={i}
              style={{
                position: 'absolute',
                left: 140 - 70 * t,
                top: 104 - 70 * t,
                width: 140 * t,
                height: 140 * t,
                borderRadius: '50%',
                border: `2px solid ${F.blue}`,
                opacity: (1 - t) * 0.8 * reveal,
              }}
            />
          );
        })}
        <div style={{position: 'absolute', left: 133, top: 92, width: 16, height: 16, borderRadius: '50%', background: F.gold, boxShadow: `0 0 18px ${F.gold}`}} />
        <div style={{position: 'absolute', left: 0, right: 0, bottom: 8, textAlign: 'center', fontFamily, fontSize: 11, color: 'rgba(190,215,255,0.85)'}}>
          24.7136Â° N Â· 46.6753Â° E
        </div>
      </div>
      {/* rows */}
      <div style={{position: 'absolute', left: 34, right: 34, top: 306, display: 'flex', flexDirection: 'column', gap: 12}}>
        {[
          ['Ø§Ù„Ù…ÙˆÙ‚Ø¹', 'Ø­ÙŠ Ø§Ù„Ù…Ù„Ø² â€” Ø§Ù„Ø±ÙŠØ§Ø¶'],
          ['Ø§Ù„ÙˆÙ‚Øª', '03:17:46 ÙØ¬Ø±Ø§Ù‹'],
          ['Ø§Ù„Ø­Ø¯Ø«', 'Ø«Ù„Ø§Ø« Ù…Ø­Ø§ÙˆÙ„Ø§Øª ÙØªØ­ ÙØ§Ø´Ù„Ø©'],
        ].map(([k, v], i) => {
          const o = interpolate(reveal, [i * 0.2, 1], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
          return (
            <div
              key={k}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '14px 18px',
                borderRadius: 12,
                background: 'rgba(255,255,255,0.045)',
                border: '1px solid rgba(127,178,255,0.14)',
                opacity: o,
                transform: `translateX(${(1 - o) * 18}px)`,
              }}
            >
              <span style={{fontFamily, fontSize: 15, color: 'rgba(170,195,230,0.85)'}}>{k}</span>
              <span style={{fontFamily, fontSize: 17, fontWeight: 700, color: F.cream}}>{v}</span>
            </div>
          );
        })}
      </div>
      {/* send */}
      <div
        style={{
          position: 'absolute',
          left: 34,
          right: 34,
          top: 436,
          height: 62,
          borderRadius: 14,
          background: `linear-gradient(90deg, rgba(46,123,255,0.9), rgba(46,123,255,0.55))`,
          boxShadow: `0 0 ${34 * send}px rgba(46,123,255,${0.5 * send})`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 10,
          opacity: 0.35 + send * 0.65,
        }}
      >
        <svg width={22} height={22} viewBox="0 0 24 24">
          <path d="M2 5 L22 5 L22 19 L2 19 Z" fill="none" stroke="#fff" strokeWidth={2} />
          <path d="M2 6 L12 13 L22 6" fill="none" stroke="#fff" strokeWidth={2} />
        </svg>
        <span style={{fontFamily, fontSize: 19, fontWeight: 800, color: '#fff'}}>Ø£ÙØ±Ø³Ù„ Ø¥Ù„Ù‰ Ø¨Ø±ÙŠØ¯Ùƒ</span>
      </div>

      {/* guard log */}
      <div style={{position: 'absolute', left: 34, right: 34, top: 524, opacity: Math.min(1, Math.max(0, (reveal - 0.35) / 0.5))}}>
        <div style={{fontFamily, fontSize: 13, color: 'rgba(150,178,215,0.8)', marginBottom: 8}}>Ø³Ø¬Ù„ Ø§Ù„Ø­Ù…Ø§ÙŠØ©</div>
        {[
          ['03:17:21', 'Ø¬Ù‡Ø§Ø² Ù…Ù‚ÙÙ„ â€” Ø­Ù…Ø§ÙŠØ© Ù…ÙØ¹Ù‘Ù„Ø©', F.blueSoft],
          ['03:17:38', 'Ù…Ø­Ø§ÙˆÙ„Ø© ÙØªØ­ Ø®Ø§Ø·Ø¦Ø©', F.gold],
          ['03:17:46', 'ØµÙˆØ±Ø© + Ù…ÙˆÙ‚Ø¹ + ØªÙ†Ø¨ÙŠÙ‡', F.red],
        ].map(([t, label, c], i) => (
          <div key={i} style={{display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10}}>
            <div style={{width: 8, height: 8, borderRadius: 4, background: c as string, boxShadow: `0 0 10px ${c}`}} />
            <div style={{fontFamily, fontSize: 12, color: 'rgba(170,195,230,0.75)', width: 64}}>{t}</div>
            <div style={{fontFamily, fontSize: 13, color: F.cream}}>{label}</div>
          </div>
        ))}
      </div>

      {/* footer state */}
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 70, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, opacity: Math.min(1, Math.max(0, (reveal - 0.6) / 0.4))}}>
        <ShieldGlyph size={44} color={F.blueSoft} glow={0.6} />
        <div style={{fontFamily, fontSize: 12, color: 'rgba(160,190,230,0.85)'}}>Ø§Ù„Ø­Ù…Ø§ÙŠØ© Ù…ÙØ¹Ù‘Ù„Ø© Â· Ø¨Ø¯ÙˆÙ† Ø¥Ø´Ø¹Ø§Ø±</div>
      </div>
    </div>
  );
};

const NotifScreen: React.FC<{drop: number}> = ({drop}) => (
  <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(180deg, #0A1424 0%, #060C16 70%)', direction: 'rtl'}}>
    <div style={{position: 'absolute', left: 0, right: 0, top: 60, textAlign: 'center', fontFamily, fontSize: 64, fontWeight: 300, color: 'rgba(240,246,255,0.9)'}}>
      06:59
    </div>
    <div style={{position: 'absolute', left: 0, right: 0, top: 150, textAlign: 'center', fontFamily, fontSize: 16, color: 'rgba(170,195,230,0.7)'}}>
      Ø§Ù„Ø¬Ù…Ø¹Ø© Ù¡Ù¤ Ù†ÙˆÙÙ…Ø¨Ø±
    </div>
    <div
      style={{
        position: 'absolute',
        left: 22,
        right: 22,
        top: 210 - (1 - drop) * 220,
        borderRadius: 22,
        padding: 16,
        background: 'rgba(255,255,255,0.10)',
        border: '1px solid rgba(255,255,255,0.18)',
                boxShadow: '0 18px 40px rgba(0,0,0,0.5)',
        opacity: drop,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', gap: 10}}>
        <div style={{width: 34, height: 34, borderRadius: 9, overflow: 'hidden', flexShrink: 0}}>
          <Img src={staticFile('ft/icon.png')} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
        </div>
        <div style={{fontFamily, fontSize: 14, fontWeight: 700, color: '#fff', flex: 1}}>Ø­ØµÙ† Ø§Ù„Ù‡Ø§ØªÙ</div>
        <div style={{fontFamily, fontSize: 12, color: 'rgba(255,255,255,0.6)'}}>Ø§Ù„Ø¢Ù†</div>
      </div>
      <div style={{marginTop: 10, fontFamily, fontSize: 17, fontWeight: 800, color: '#fff'}}>Ù…Ø­Ø§ÙˆÙ„Ø© ÙØªØ­ ÙØ§Ø´Ù„Ø©</div>
      <div style={{marginTop: 4, fontFamily, fontSize: 14, color: 'rgba(240,246,255,0.85)', lineHeight: 1.5}}>
        ØªÙ… ØªØµÙˆÙŠØ± Ù…Ù† Ø­Ø§ÙˆÙ„ ÙØªØ­ Ù‡Ø§ØªÙÙƒØŒ ÙˆØ¥Ø±Ø³Ø§Ù„ Ø§Ù„Ù…ÙˆÙ‚Ø¹ ÙˆØ§Ù„ÙˆÙ‚Øª Ø¥Ù„Ù‰ Ø¨Ø±ÙŠØ¯Ùƒ.
      </div>
      <div style={{marginTop: 12, display: 'flex', gap: 8}}>
        <div style={{width: 60, height: 60, borderRadius: 10, overflow: 'hidden', border: `1px solid ${F.gold}66`}}>
          <div style={{position: 'absolute', width: 472, height: 996, transform: 'scale(0.127)', transformOrigin: 'top left'}}>
            <IntruderShot />
          </div>
        </div>
        <div style={{flex: 1, borderRadius: 10, background: 'rgba(46,123,255,0.16)', border: '1px solid rgba(127,178,255,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily, fontSize: 13, color: 'rgba(220,235,255,0.9)'}}>
          Ø§Ù„Ù…ÙˆÙ‚Ø¹ Ù…Ø±ÙÙ‚ Â· 03:17
        </div>
      </div>
    </div>
    {/* lock-screen bottom affordances */}
    <div style={{position: 'absolute', left: 60, right: 60, bottom: 54, display: 'flex', justifyContent: 'space-between'}}>
      {[0, 1].map((i) => (
        <div
          key={i}
          style={{
            width: 54,
            height: 54,
            borderRadius: 27,
            background: 'rgba(255,255,255,0.10)',
            border: '1px solid rgba(255,255,255,0.14)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <div style={{width: 20, height: 20, borderRadius: i === 0 ? 6 : 10, border: '2px solid rgba(255,255,255,0.6)'}} />
        </div>
      ))}
    </div>
  </div>
);

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  endcard  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
const FtEndCard: React.FC<{start: number}> = ({start}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = f - start;
  const s = spring({frame: t, fps, config: {damping: 13, stiffness: 120, mass: 0.7}});
  const ring = interpolate(t, [0, 70], [0, 720], {extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill style={{background: `radial-gradient(ellipse at 50% 34%, #10224A 0%, ${F.navy} 48%, #02050B 100%)`}}>
      <Bloom cx={540} cy={560} r={480} color="rgba(46,123,255,0.35)" opacity={Math.min(1, t / 20)} />
      <PulseRing cx={540} cy={560} r={ring} color={F.blueSoft} width={2.5} opacity={0.55 * (1 - ring / 720)} />
      <div
        style={{
          position: 'absolute',
          left: 540 - 96,
          top: 560 - 96,
          width: 192,
          height: 192,
          borderRadius: 46,
          overflow: 'hidden',
          transform: `scale(${s})`,
          boxShadow: '0 26px 60px rgba(0,0,0,0.6), 0 0 60px rgba(46,123,255,0.35)',
        }}
      >
        <Img src={staticFile('ft/icon.png')} style={{width: '100%', height: '100%'}} />
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 700, textAlign: 'center', fontFamily, fontWeight: 900, fontSize: 84, color: F.cream, direction: 'rtl', opacity: Math.min(1, Math.max(0, (t - 6) / 14))}}>
        Ø­ØµÙ† Ø§Ù„Ù‡Ø§ØªÙ
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 800, textAlign: 'center', fontFamily, fontSize: 30, fontWeight: 700, letterSpacing: 4, color: F.blueSoft, opacity: Math.min(1, Math.max(0, (t - 14) / 14))}}>
        PHONE FORTRESS
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 880, textAlign: 'center', fontFamily, fontWeight: 800, fontSize: 36, color: F.goldSoft, direction: 'rtl', opacity: Math.min(1, Math.max(0, (t - 22) / 14))}}>
        Ù…Ù† ÙŠÙØªØ­ Ù‡Ø§ØªÙÙƒâ€¦ ÙŠØªØ±Ùƒ ØµÙˆØ±ØªÙ‡
      </div>

      <div
        style={{
          position: 'absolute',
          left: 540 - 190,
          top: 1010,
          width: 380,
          height: 380,
          borderRadius: 26,
          background: '#fff',
          padding: 18,
          boxSizing: 'border-box',
          opacity: Math.min(1, Math.max(0, (t - 30) / 14)),
          transform: `translateY(${(1 - Math.min(1, Math.max(0, (t - 30) / 14))) * 22}px)`,
          boxShadow: '0 24px 60px rgba(0,0,0,0.55)',
        }}
      >
        <Img src={staticFile('ft/qr.png')} style={{width: '100%', height: '100%', imageRendering: 'pixelated'}} />
      </div>

      <div style={{position: 'absolute', left: 0, right: 0, top: 1430, textAlign: 'center', fontFamily, fontSize: 34, fontWeight: 800, color: F.cream, direction: 'rtl', opacity: Math.min(1, Math.max(0, (t - 40) / 14))}}>
        Ù…Ø¬Ø§Ù†ÙŠ Ø¹Ù„Ù‰ Google Play
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 1492, textAlign: 'center', fontFamily, fontSize: 22, letterSpacing: 3, color: 'rgba(143,160,191,0.9)', opacity: Math.min(1, Math.max(0, (t - 46) / 14))}}>
        FREE Â· 16 LANGUAGES Â· NO ACCOUNT
      </div>
    </AbsoluteFill>
  );
};

/* â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  film  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ */
export const AdFtWarded: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();

  /* shot A â€” the cafÃ©, 3:17 am (0-96) */
  const pushA = interpolate(f, [0, 96], [1.02, 1.14], {extrapolateRight: 'clamp'});
  const handHeld = Math.sin(f * 0.11) * 3 + Math.sin(f * 0.043) * 4;
  const thiefIn = easeOut(Math.min(1, Math.max(0, (f - 22) / 54)));
  const thiefWalk = f > 20 ? 1 : 0;
  const lampFlicker = 0.9 + Math.sin(f * 0.9) * 0.04 + (rand(Math.floor(f / 3)) > 0.86 ? -0.22 : 0);

  /* shot B â€” the reach (96-168) */
  const reach = easeInOut(Math.min(1, Math.max(0, (f - 108) / 34)));
  const grab = Math.min(1, Math.max(0, (f - 146) / 12));
  const streak = Math.min(1, Math.max(0, (f - 148) / 12));

  /* shot C â€” three wrong PINs (168-258) */
  const taps = [186, 204, 222];
  const wrong = taps.filter((t) => f >= t + 6).length;
  const shake = taps.reduce((a, t) => a + (f >= t + 4 && f < t + 18 ? 1 - (f - t - 4) / 14 : 0), 0);
  const activeDigit = taps.reduce<number | undefined>((a, t) => (f >= t && f < t + 7 ? taps.indexOf(t) : a), undefined);
  const lockPush = interpolate(f, [168, 258], [1.0, 1.06], {extrapolateRight: 'clamp'});

  /* shot D â€” the flash (258-336) */
  const flash = interpolate(f, [268, 270, 278], [0, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const recoil = Math.min(1, Math.max(0, (f - 268) / 26));
  const captureShake = f > 268 && f < 296 ? Math.sin(f * 2.2) * (1 - (f - 268) / 28) * 12 : 0;

  /* shot E â€” the evidence (336-444) */
  const evReveal = Math.min(1, Math.max(0, (f - 342) / 40));
  const send = Math.min(1, Math.max(0, (f - 402) / 26));

  /* shot F â€” morning, the owner (444-520) */
  const notifDrop = spring({frame: f - 458, fps, config: {damping: 14, stiffness: 140, mass: 0.8}});
  const warm = Math.min(1, Math.max(0, (f - 452) / 60));

  /* shot G â€” endcard (520-630) */
  const cutDark = f < 12 ? 1 - f / 12 : 0;

  return (
    <AbsoluteFill style={{backgroundColor: F.ink}}>
      {/* â•â•â•â•â• A Â· street â•â•â•â•â• */}
      {f < 100 && (
        <AbsoluteFill>
          <Camera scale={pushA} x={handHeld} y={handHeld * 1.4}>
            <City lamp={lampFlicker} />
            <Thief x={210 + thiefIn * 300} y={1500} scale={0.95} walk={thiefWalk} opacity={0.9} />
            <CafeTable />
            <Owner x={250} y={1380} scale={0.92} />
            <Phone x={700} y={1452} w={150} rotate={-8} glow={0.7} glowColor="#9FC6FF">
              <GuardLock attempts={0} shake={0} />
            </Phone>
            <PhoneLight x={700} y={1452} w={150} color="#5E9BFF" intensity={0.35} spread={4.4} />
          </Camera>
          <Dust count={26} opacity={0.22} tint="#CFE0FF" speed={0.4} />
          <Vignette strength={0.62} />
          <Caption text="Ø§Ù„Ø«Ø§Ù„Ø«Ø© ÙØ¬Ø±Ø§Ù‹." sub="Ù‡Ø§ØªÙÙƒ Ø¹Ù„Ù‰ Ø§Ù„Ø·Ø§ÙˆÙ„Ø©" from={16} to={92} y={1218} size={78} />
          <FadeBlack opacity={cutDark} />
        </AbsoluteFill>
      )}

      {/* â•â•â•â•â• B Â· the hand â•â•â•â•â• */}
      {f >= 100 && f < 170 && (
        <AbsoluteFill style={{backgroundColor: '#03060C'}}>
          <Camera scale={1.0 + Math.min(1, (f - 100) / 70) * 0.12} x={-16} y={-10}>
            {/* out-of-focus street behind the phone */}
            <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 30% 30%, #0B1626 0%, #04070E 68%)'}} />
            {Array.from({length: 14}).map((_, i) => (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: 80 + rand(i * 3.7) * 920,
                  top: 120 + rand(i * 5.1) * 900,
                  width: 220 + rand(i * 2.3) * 260,
                  height: 220 + rand(i * 4.9) * 260,
                  borderRadius: '50%',
                  background:
                    i % 3 === 0
                      ? 'radial-gradient(circle, rgba(255,196,120,0.16) 0%, rgba(255,196,120,0) 68%)'
                      : 'radial-gradient(circle, rgba(120,165,255,0.14) 0%, rgba(120,165,255,0) 68%)',
                }}
              />
            ))}
            <div
              style={{
                position: 'absolute',
                inset: 0,
                transform: `translate(${grab * 300}px, ${-grab * 140}px) rotate(${grab * 16}deg) scale(${1 - grab * 0.12})`,
                opacity: 1 - grab * 0.25,
              }}
            >
              <Phone x={480} y={960} w={560} rotate={-5} glow={0.9} glowColor="#9FC6FF">
                <GuardLock attempts={0} shake={0} />
              </Phone>
              <PhoneLight x={480} y={960} w={560} color="#5E9BFF" intensity={0.5} spread={2.4} />
            </div>
            {/* the thief's gloved hand comes in from the right edge */}
            <div style={{position: 'absolute', inset: 0, transform: `translate(${(1 - reach) * 340}px, ${(1 - reach) * 70}px)`}}>
              <Thief x={790} y={1330} scale={1.45} reach={0.8} flip opacity={1} />
            </div>
          </Camera>
          {/* snatch streak */}
          {streak > 0 && (
            <div
              style={{
                position: 'absolute',
                left: 200 - grab * 120,
                top: 1380,
                width: 760,
                height: 200,
                borderRadius: 100,
                background: 'linear-gradient(90deg, rgba(159,198,255,0) 0%, rgba(159,198,255,0.5) 60%, rgba(159,198,255,0) 100%)',
                filter: 'blur(18px)',
                opacity: streak * 0.8,
                transform: `rotate(-8deg)`,
              }}
            />
          )}
          <Vignette strength={0.55} />
          <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 420, background: 'linear-gradient(180deg, rgba(3,6,12,0) 0%, rgba(3,6,12,0.9) 62%)'}} />
          <Caption text="ÙŠØ¯ÙŒ Ù„ÙŠØ³Øª ÙŠØ¯Ùƒ." from={112} to={168} y={1560} size={76} />
        </AbsoluteFill>
      )}

      {/* â•â•â•â•â• C Â· POV, three wrong codes â•â•â•â•â• */}
      {f >= 170 && f < 260 && (
        <AbsoluteFill style={{backgroundColor: '#03060C'}}>
          <Camera scale={lockPush} rotate={Math.sin(f * 0.07) * 0.4}>
            <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 30%, #0B1A33 0%, #03060C 62%)'}} />
            <Phone x={540} y={790} w={700} rotate={-3} glow={0.95} glowColor="#5E9BFF">
              <GuardLock attempts={wrong} shake={shake} tapDigit={activeDigit} />
            </Phone>
            <PhoneLight x={540} y={790} w={700} color="#4B86FF" intensity={0.55} spread={2.4} />
          </Camera>
          {/* the room's darkness pulses red with each failure */}
          <div style={{position: 'absolute', inset: 0, background: `radial-gradient(ellipse at 50% 50%, rgba(255,90,72,${0.16 * shake}), transparent 70%)`, opacity: shake}} />
          <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 420, background: 'linear-gradient(180deg, rgba(3,6,12,0) 0%, rgba(3,6,12,0.92) 62%)'}} />
          <Vignette strength={0.5} />
          <Caption text="Ù£ Ù…Ø­Ø§ÙˆÙ„Ø§Øª." sub="ÙˆÙƒÙ„ Ù…Ø­Ø§ÙˆÙ„Ø© ØªÙØ³Ø¬ÙŽÙ‘Ù„" from={176} to={256} y={1548} size={62} />
        </AbsoluteFill>
      )}

      {/* â•â•â•â•â• D Â· the front camera â•â•â•â•â• */}
      {f >= 260 && f < 340 && (
        <AbsoluteFill style={{backgroundColor: '#03060C'}}>
          <Camera scale={1.02 + recoil * 0.05} x={captureShake} y={captureShake * 0.7} rotate={captureShake * 0.25}>
            <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 34%, #10203A 0%, #04070E 66%)'}} />
            <Phone x={540} y={790} w={720} rotate={2} glow={0.9} glowColor="#5E9BFF" scale={1 - recoil * 0.06}>
              <IntruderShot />
            </Phone>
          </Camera>
          <Bloom cx={540} cy={790} r={620} color="rgba(94,155,255,0.30)" opacity={0.7} />
          <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 420, background: 'linear-gradient(180deg, rgba(3,6,12,0) 0%, rgba(3,6,12,0.92) 62%)'}} />
          <Vignette strength={0.55} />
          <Caption text="Ø§Ù„ÙƒØ§Ù…ÙŠØ±Ø§ Ø§Ù„Ø£Ù…Ø§Ù…ÙŠØ©â€¦" sub="Ø¨ØµÙ…Øª ØªØ§Ù…" from={272} to={338} y={1548} size={62} />
          {/* shutter flash */}
          <div style={{position: 'absolute', inset: 0, background: '#fff', opacity: flash}} />
        </AbsoluteFill>
      )}

      {/* â•â•â•â•â• E Â· the evidence â•â•â•â•â• */}
      {f >= 340 && f < 446 && (
        <AbsoluteFill style={{backgroundColor: '#03060C'}}>
          <Camera scale={1.0 + Math.min(1, (f - 340) / 106) * 0.05}>
            <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 26%, #0C1D38 0%, #03060C 62%)'}} />
            <Phone x={540} y={790} w={700} rotate={0} glow={0.8} glowColor="#5E9BFF">
              <Evidence reveal={evReveal} send={send} />
            </Phone>
            <PhoneLight x={540} y={790} w={700} color="#4B86FF" intensity={0.5} spread={2.4} />
          </Camera>
          {/* a line of light travels up as the report is sent */}
          {send > 0 && (
            <div
              style={{
                position: 'absolute',
                left: 0,
                right: 0,
                top: 1200 - send * 900,
                height: 220,
                background: 'linear-gradient(180deg, rgba(127,178,255,0) 0%, rgba(127,178,255,0.28) 50%, rgba(127,178,255,0) 100%)',
                opacity: send * 0.7,
                filter: 'blur(6px)',
              }}
            />
          )}
          <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 420, background: 'linear-gradient(180deg, rgba(3,6,12,0) 0%, rgba(3,6,12,0.92) 62%)'}} />
          <Vignette strength={0.5} />
          <Caption text="ØµÙˆØ±ØªÙ‡. Ù…ÙˆÙ‚Ø¹Ù‡. Ø§Ù„Ø³Ø§Ø¹Ø©." from={348} to={444} y={1548} size={60} />
        </AbsoluteFill>
      )}

      {/* â•â•â•â•â• F Â· morning, the owner â•â•â•â•â• */}
      {f >= 446 && f < 524 && (
        <AbsoluteFill>
          <Camera scale={1.04 + Math.min(1, (f - 446) / 78) * 0.06} x={Math.sin(f * 0.04) * 3}>
            <div style={{position: 'absolute', inset: 0, background: `linear-gradient(180deg, rgb(${8 + warm * 26},${12 + warm * 20},${26 + warm * 12}) 0%, #05080F 72%)`}} />
            {/* window with dawn light */}
            <div style={{position: 'absolute', left: 660, top: 260, width: 330, height: 430, borderRadius: 10, overflow: 'hidden', border: '12px solid #0A0E18', boxSizing: 'border-box'}}>
              <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(180deg, #2A3B63 0%, #7C6A78 52%, #D89C74 78%, #F3C79B 100%)'}} />
              <div style={{position: 'absolute', left: '50%', top: 0, bottom: 0, width: 10, marginLeft: -5, background: '#0A0E18'}} />
              <div style={{position: 'absolute', left: 0, right: 0, top: '52%', height: 10, background: '#0A0E18'}} />
              <div style={{position: 'absolute', left: -40, top: 120, width: 420, height: 120, background: 'rgba(255,200,150,0.16)', filter: 'blur(20px)'}} />
            </div>
            <LightShaft x={830} y={300} angle={-16} length={1100} spread={420} color="#FFC98A" opacity={0.22 * warm} blur={46} />
            {/* warm pool on the bedside table */}
            <div style={{position: 'absolute', left: 0, right: 0, top: 1300, height: 620, background: 'linear-gradient(180deg, #0A101C 0%, #05080F 100%)'}} />
            <div style={{position: 'absolute', left: 120, top: 1290, width: 760, height: 320, background: `radial-gradient(ellipse at 50% 10%, rgba(255,190,130,${0.14 * warm}), transparent 70%)`}} />
            {/* owner's hand holding the phone */}
            <Owner x={250} y={1180} scale={1.0} warm={warm} />
            <Phone x={560} y={1180} w={420} rotate={-12} glow={0.7} glowColor="#BFD4FF">
              <NotifScreen drop={Math.max(0, Math.min(1, notifDrop))} />
            </Phone>
            <PhoneLight x={560} y={1180} w={420} color="#BFD4FF" intensity={0.32} spread={3} />
          </Camera>
          <Vignette strength={0.5} />
          <Caption text="ÙˆØ£Ù†Øª Ù†Ø§Ø¦Ù…â€¦" sub="Ù‡Ø§ØªÙÙƒ ÙƒØ§Ù† ÙŠØ­Ø±Ø³ Ù†ÙØ³Ù‡" from={456} to={522} y={1600} size={62} />
        </AbsoluteFill>
      )}

      {/* â•â•â•â•â• G Â· endcard â•â•â•â•â• */}
      {f >= 520 && (
        <AbsoluteFill>
          <FtEndCard start={522} />
          <Vignette strength={0.35} />
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};
