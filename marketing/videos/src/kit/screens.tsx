import React from 'react';
import {C} from './theme';

/* ══════════════════════════════════════════════════════════════════════════
   Wordless UI system.
   Nothing in these screens is readable text: copy is drawn as rounded bars,
   meaning is carried by icons, colour and motion. The only glyphs allowed are
   numerals (a clock, a count), which every language reads the same way.
   ══════════════════════════════════════════════════════════════════════════ */

export const S_W = 472;
export const S_H = 996;

export const clamp = (v: number) => (v < 0 ? 0 : v > 1 ? 1 : v);

/* ─────────────────────────────── icons ─────────────────────────────── */

export type IconName = 'flame' | 'sprout' | 'sun' | 'lock' | 'page' | 'wave' | 'pen' | 'bird' | 'drawer' | 'bell' | 'moon' | 'camera' | 'mic';

export const Icon: React.FC<{name: IconName; size?: number; color?: string; stroke?: number}> = ({
  name,
  size = 24,
  color = C.text2,
  stroke = 2,
}) => {
  const s = size;
  const common = {stroke: color, strokeWidth: stroke, fill: 'none', strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const};
  return (
    <svg width={s} height={s} viewBox="0 0 24 24">
      {name === 'flame' && (
        <path d="M12 3c3.4 3.2 5.2 5.8 5.2 8.6A5.2 5.2 0 0 1 12 21a5.2 5.2 0 0 1-5.2-5.4c0-2 1-3.6 2.6-5.2.4 1.6 1.2 2.6 2.2 2.6.6 0 1-.6.9-1.6-.2-2.3.4-5.4 1.5-8.4Z" {...common} fill={color} fillOpacity={0.18} />
      )}
      {name === 'sprout' && (
        <>
          <path d="M12 21v-7" {...common} />
          <path d="M12 14c0-3 2-5 5-5 0 3-2 5-5 5Z" {...common} />
          <path d="M12 16c0-2.4-1.6-4-4-4 0 2.4 1.6 4 4 4Z" {...common} />
        </>
      )}
      {name === 'sun' && (
        <>
          <circle cx="12" cy="12" r="4.2" {...common} fill={color} fillOpacity={0.2} />
          {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
            const a = (i / 8) * Math.PI * 2;
            return <line key={i} x1={12 + Math.cos(a) * 6.6} y1={12 + Math.sin(a) * 6.6} x2={12 + Math.cos(a) * 9} y2={12 + Math.sin(a) * 9} {...common} />;
          })}
        </>
      )}
      {name === 'lock' && (
        <>
          <rect x="5" y="10.5" width="14" height="10" rx="3" {...common} />
          <path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5" {...common} />
          <circle cx="12" cy="15.5" r="1.4" fill={color} stroke="none" />
        </>
      )}
      {name === 'page' && (
        <>
          <path d="M6 3.5h8l4.5 4.5V20a1.5 1.5 0 0 1-1.5 1.5H6A1.5 1.5 0 0 1 4.5 20V5A1.5 1.5 0 0 1 6 3.5Z" {...common} />
          <path d="M14 3.5V8h4.5" {...common} />
        </>
      )}
      {name === 'wave' && <path d="M2 13h4l2-6 3 12 3-9 2 3h6" {...common} />}
      {name === 'pen' && (
        <>
          <path d="M4 20l4-1 10-10-3-3L5 16l-1 4Z" {...common} />
          <path d="M14.5 6.5l3 3" {...common} />
        </>
      )}
      {name === 'bird' && (
        <>
          <path d="M3 16l7-4 5-6 3 2-1 4 4 2-7 3-4 4-2-3-5-2Z" {...common} fill={color} fillOpacity={0.14} />
        </>
      )}
      {name === 'drawer' && (
        <>
          <rect x="3.5" y="6" width="17" height="6" rx="2" {...common} />
          <rect x="3.5" y="13" width="17" height="6" rx="2" {...common} />
          <path d="M10 9h4M10 16h4" {...common} />
        </>
      )}
      {name === 'bell' && (
        <>
          <path d="M6.5 17c1-1 1.5-2.4 1.5-4.5a4 4 0 0 1 8 0c0 2.1.5 3.5 1.5 4.5H6.5Z" {...common} />
          <path d="M10.5 19.5a2 2 0 0 0 3 0" {...common} />
        </>
      )}
      {name === 'moon' && <path d="M20 15.5A8 8 0 0 1 9 4.6a8.4 8.4 0 1 0 11 10.9Z" {...common} fill={color} fillOpacity={0.15} />}
      {name === 'camera' && (
        <>
          <rect x="3" y="6.5" width="18" height="13" rx="3" {...common} />
          <circle cx="12" cy="13" r="3.6" {...common} />
        </>
      )}
      {name === 'mic' && (
        <>
          <rect x="9.5" y="3" width="5" height="10" rx="2.5" {...common} />
          <path d="M6 11.5a6 6 0 0 0 12 0M12 17.5V21" {...common} />
        </>
      )}
    </svg>
  );
};

/* ───────────────────────────── primitives ───────────────────────────── */

export const Card: React.FC<{
  x?: number;
  y: number;
  w?: number;
  h: number;
  r?: number;
  fill?: string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
  pad?: number;
}> = ({x = 20, y, w = S_W - 40, h, r = 26, fill = '#FFFFFF', children, style, pad = 18}) => (
  <div
    style={{
      position: 'absolute',
      left: x,
      top: y,
      width: w,
      height: h,
      borderRadius: r,
      background: fill,
      boxShadow: '0 10px 26px rgba(29,27,38,0.07)',
      padding: pad,
      boxSizing: 'border-box',
      ...style,
    }}
  >
    {children}
  </div>
);

export const Bar: React.FC<{
  x?: number;
  y: number;
  w: number;
  h?: number;
  fill?: string;
  opacity?: number;
  r?: number;
  align?: 'left' | 'right';
  scaleX?: number;
}> = ({x = 0, y, w, h = 9, fill = C.text3, opacity = 0.35, r = 5, align = 'right', scaleX = 1}) => (
  <div
    style={{
      position: 'absolute',
      left: x,
      top: y,
      width: w,
      height: h,
      borderRadius: r,
      background: fill,
      opacity,
      transform: `scaleX(${scaleX})`,
      transformOrigin: align === 'right' ? 'right center' : 'left center',
    }}
  />
);

export const Tile: React.FC<{x: number; y: number; size: number; fill: string; icon?: IconName; color?: string; r?: number}> = ({
  x,
  y,
  size,
  fill,
  icon,
  color,
  r,
}) => (
  <div
    style={{
      position: 'absolute',
      left: x,
      top: y,
      width: size,
      height: size,
      borderRadius: r ?? size * 0.32,
      background: fill,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    {icon && <Icon name={icon} size={size * 0.5} color={color ?? C.text2} />}
  </div>
);

/* ─────────────────────────────── faces ─────────────────────────────── */

export type FaceKind = 'calm' | 'low' | 'anxious' | 'good' | 'tired';

const faceColor: Record<FaceKind, string> = {
  calm: '#6FD3C4',
  low: '#9AA6C8',
  anxious: '#E8A24A',
  good: '#F2B25C',
  tired: '#A9A3C7',
};

export const Face: React.FC<{kind: FaceKind; size?: number; active?: boolean; scale?: number}> = ({
  kind,
  size = 52,
  active = false,
  scale = 1,
}) => {
  const c = faceColor[kind];
  const droop = kind === 'low' || kind === 'tired';
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: '50%',
        background: active ? c : `${c}22`,
        border: `2px solid ${active ? c : `${c}66`}`,
        position: 'relative',
        transform: `scale(${scale})`,
        boxShadow: active ? `0 0 24px ${c}88` : undefined,
        boxSizing: 'border-box',
      }}
    >
      <div style={{position: 'absolute', left: size * 0.27, top: size * 0.33, width: size * 0.1, height: size * 0.12, borderRadius: '50%', background: active ? '#fff' : c}} />
      <div style={{position: 'absolute', right: size * 0.27, top: size * 0.33, width: size * 0.1, height: size * 0.12, borderRadius: '50%', background: active ? '#fff' : c}} />
      <div
        style={{
          position: 'absolute',
          left: size * 0.3,
          bottom: droop ? size * 0.36 : size * 0.26,
          width: size * 0.4,
          height: size * 0.16,
          borderBottom: `2.4px solid ${active ? '#fff' : c}`,
          borderRadius: droop ? '40% 40% 0 0' : kind === 'good' ? '0 0 60% 60%' : '0 0 24% 24%',
          borderTop: droop ? `2.4px solid ${active ? '#fff' : c}` : undefined,
        }}
      />
    </div>
  );
};

/* ══════════════════════════════ screens ══════════════════════════════ */

export const TodayScreen: React.FC<{clock?: string; streak?: number; moodActive?: number; write?: number}> = ({
  clock = '3:12',
  streak = 11,
  moodActive = -1,
  write = 0,
}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(circle at 70% 0%, rgba(232,116,106,0.15), transparent 55%)'}} />

    {/* status: time only — a numeral, not a word */}
    <div style={{position: 'absolute', top: 22, left: 0, right: 0, padding: '0 26px', display: 'flex', justifyContent: 'space-between'}}>
      <div style={{fontFamily: 'Cairo', fontSize: 15, fontWeight: 800, color: C.text}}>{clock}</div>
      <div style={{display: 'flex', gap: 5, alignItems: 'center'}}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{width: 4, height: 4, borderRadius: '50%', background: C.text3, opacity: 0.5}} />
        ))}
      </div>
    </div>

    {/* the daily prompt: two lines of unreadable copy + a pen */}
    <Card y={78} h={250} style={{background: `linear-gradient(150deg, ${C.indigo} 0%, ${C.indigoGlow} 100%)`}}>
      <div style={{position: 'absolute', top: 22, left: 22, width: 44, height: 44, borderRadius: 15, background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <Icon name="page" size={22} color="#FFFFFF" />
      </div>
      <Bar x={22} y={92} w={300} h={14} fill="#FFFFFF" opacity={0.92} align="left" />
      <Bar x={22} y={116} w={230} h={14} fill="#FFFFFF" opacity={0.72} align="left" />
      <Bar x={22} y={140} w={160} h={14} fill="#FFFFFF" opacity={0.4} align="left" />
      <div style={{position: 'absolute', left: 22, top: 176, display: 'flex', gap: 10}}>
        <div style={{width: 44, height: 44, borderRadius: 15, background: 'rgba(255,255,255,0.94)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <Icon name="pen" size={21} color={C.indigoDeep} />
        </div>
        <div style={{width: 44, height: 44, borderRadius: 15, background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <Icon name="mic" size={21} color="#FFFFFF" />
        </div>
        <div style={{width: 44, height: 44, borderRadius: 15, background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <Icon name="camera" size={21} color="#FFFFFF" />
        </div>
      </div>
      {write > 0 && (
        <div style={{position: 'absolute', left: 22 + Math.min(1, write) * 250, top: 92, width: 3, height: 40, background: '#FFFFFF', opacity: 0.9}} />
      )}
    </Card>

    {/* mood row */}
    <Card y={350} h={126}>
      {(['good', 'calm', 'tired', 'anxious', 'low'] as FaceKind[]).map((k, i) => (
        <div key={k} style={{position: 'absolute', left: 16 + i * 88, top: 22}}>
          <Face kind={k} size={58} active={moodActive === i} scale={moodActive === i ? 1.08 : 1} />
        </div>
      ))}
    </Card>

    {/* streak */}
    <Card y={496} h={96} fill="#FFF4F1">
      <div style={{position: 'absolute', left: 18, top: 21, width: 54, height: 54, borderRadius: 18, background: `linear-gradient(140deg, ${C.coral}, #F2A65A)`, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <Icon name="flame" size={26} color="#FFF3EE" />
      </div>
      <div style={{position: 'absolute', left: 88, top: 26, fontFamily: 'Cairo', fontSize: 26, fontWeight: 800, color: C.text}}>{streak}</div>
      <Bar x={88} y={62} w={120} h={9} fill={C.text3} opacity={0.3} align="left" />
    </Card>

    {/* recents */}
    {[0, 1, 2].map((i) => (
      <Card key={i} y={612 + i * 84} h={72} pad={12}>
        <Tile x={12} y={12} size={44} fill={i === 0 ? '#EFEBFF' : i === 1 ? '#E7F7F4' : '#FFF1EE'} icon={i === 0 ? 'page' : i === 1 ? 'sprout' : 'moon'} color={i === 0 ? C.indigo : i === 1 ? C.teal : C.coral} />
        <Bar x={68} y={20} w={200 - i * 24} h={9} fill={C.text2} opacity={0.3} align="left" />
        <Bar x={68} y={40} w={110} h={8} fill={C.text3} opacity={0.2} align="left" />
      </Card>
    ))}
  </div>
);

export const WorryScreen: React.FC<{tangle?: number; lid?: number; dragging?: number}> = ({tangle = 1, lid = 0, dragging = 0}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    {/* header: a box icon + unreadable copy */}
    <div style={{position: 'absolute', top: 34, left: 26, display: 'flex', gap: 12, alignItems: 'center'}}>
      <Tile x={0} y={0} size={46} fill="#EFEBFF" icon="lock" color={C.indigo} />
      <Bar x={58} y={10} w={170} h={12} fill={C.text} opacity={0.55} align="left" />
      <Bar x={58} y={30} w={110} h={9} fill={C.text3} opacity={0.25} align="left" />
    </div>

    {/* thoughts as tangles, drifting above the box */}
    <div style={{position: 'absolute', top: 110, left: 20, right: 20, height: 330, opacity: 1 - dragging * 0.4}}>
      <svg width={432} height={330} viewBox="0 0 432 330">
        {Array.from({length: 10}).map((_, i) => {
          const y = 34 + i * 28;
          const amp = 24 + (i % 3) * 14;
          const shrink = Math.max(0, 1 - dragging * 1.15);
          return (
            <path
              key={i}
              d={`M -20 ${y} C 90 ${y - amp * tangle}, 170 ${y + amp * tangle}, 300 ${y - amp * 0.5 * tangle} S 400 ${y + amp * 0.8}, 460 ${y}`}
              stroke={C.text3}
              strokeWidth={2.3}
              fill="none"
              opacity={0.5 * tangle * shrink}
              strokeLinecap="round"
            />
          );
        })}
      </svg>
    </div>

    {/* what was written: a single line inside the box being filled */}
    <Card y={452} h={92} fill="#F2EFEA">
      <Bar x={18} y={24} w={230} h={11} fill={C.text2} opacity={0.45} align="left" />
      <Bar x={18} y={46} w={150} h={11} fill={C.text2} opacity={0.25} align="left" />
    </Card>

    {/* input pill + lock button */}
    <div style={{position: 'absolute', left: 20, right: 20, top: 566, height: 62, borderRadius: 18, background: '#F2EFEA', display: 'flex', alignItems: 'center', padding: '0 18px'}}>
      <div style={{width: 3, height: 22, background: C.indigo, opacity: 0.6}} />
      <Bar x={14} y={22} w={150} h={10} fill={C.text3} opacity={0.28} align="left" />
    </div>
    <div
      style={{
        position: 'absolute',
        right: 20,
        top: 648,
        width: 96,
        height: 96,
        borderRadius: 32,
        background: `linear-gradient(140deg, ${C.coral}, #F2A65A)`,
        boxShadow: `0 16px 36px ${C.coral}55`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transform: `scale(${1 - lid * 0.06})`,
      }}
    >
      <Icon name="lock" size={38} color="#fff" stroke={2.1} />
    </div>

    {/* the box itself, lid closing */}
    <div style={{position: 'absolute', left: 20, right: 20, top: 788, height: 168}}>
      <div style={{position: 'absolute', inset: 0, borderRadius: 26, background: '#FFFFFF', border: `1.5px solid ${C.border}`, overflow: 'hidden'}}>
        <div style={{position: 'absolute', left: 26, right: 26, top: 40, display: 'flex', gap: 12}}>
          {[0, 1, 2].map((i) => (
            <Bar key={i} x={i * 116} y={0} w={64 + i * 12} h={9} fill={C.text3} opacity={0.2 + lid * 0.25} align="left" />
          ))}
        </div>
        <div
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            bottom: 0,
            height: 74,
            background: `linear-gradient(180deg, ${C.coral}, #D9574D)`,
            transformOrigin: 'bottom',
            transform: `scaleY(${0.18 + lid * 0.82})`,
            borderTopLeftRadius: 10,
            borderTopRightRadius: 10,
          }}
        />
      </div>
    </div>
  </div>
);

export const LetterScreen: React.FC<{typed?: number; saved?: number}> = ({typed = 0, saved = 0}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    <div style={{position: 'absolute', top: 34, left: 26, display: 'flex', gap: 12, alignItems: 'center'}}>
      <Tile x={0} y={0} size={46} fill="#EFEBFF" icon="bird" color={C.indigo} />
      <Bar x={58} y={10} w={190} h={12} fill={C.text} opacity={0.55} align="left" />
      <div style={{position: 'absolute', left: 58, top: 32, height: 26, padding: '0 12px', borderRadius: 13, background: '#EFEBFF', display: 'flex', alignItems: 'center'}}>
        <div style={{width: 46, height: 8, borderRadius: 4, background: C.indigo, opacity: 0.55}} />
      </div>
    </div>

    {/* the page */}
    <Card y={128} h={430}>
      <div style={{position: 'absolute', left: 22, top: 26, right: 22}}>
        {[0, 1, 2, 3, 4, 5, 6].map((i) => {
          const w = [330, 356, 300, 340, 240, 320, 190][i];
          const on = typed > i * 0.14;
          return (
            <div key={i} style={{position: 'relative', height: 30}}>
              <Bar x={0} y={0} w={w} h={11} fill={on ? C.text2 : C.border} opacity={on ? 0.75 : 0.7} align="left" scaleX={on ? 1 : 0.35} />
            </div>
          );
        })}
        <div style={{position: 'absolute', left: 0, top: 208, width: 3, height: 24, background: C.coral, opacity: Math.sin(typed * 22) > 0 ? 1 : 0.2}} />
      </div>
    </Card>

    {/* save-to-drawer */}
    <div
      style={{
        position: 'absolute',
        left: 20,
        right: 20,
        top: 586,
        height: 66,
        borderRadius: 20,
        background: `linear-gradient(120deg, ${C.indigo}, ${C.indigoGlow})`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 12,
        opacity: 1 - saved * 0.9,
      }}
    >
      <Icon name="drawer" size={24} color="#fff" />
      <div style={{width: 120, height: 10, borderRadius: 5, background: '#fff', opacity: 0.85}} />
    </div>

    {/* drawer with sealed letters */}
    <Card y={672} h={170} fill="#F7F4EF">
      <div style={{position: 'absolute', left: 22, top: 22}}>
        <Icon name="drawer" size={22} color={C.text2} />
      </div>
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          style={{
            position: 'absolute',
            left: 22 + i * 118,
            top: 62,
            width: 104,
            height: 78,
            borderRadius: 16,
            background: '#FFFFFF',
            border: `1.5px solid ${C.border}`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            opacity: i === 2 ? 1 : 0.45,
          }}
        >
          <Icon name="page" size={26} color={i === 2 ? C.indigo : C.text3} />
        </div>
      ))}
    </Card>
  </div>
);

export const GratitudeScreen: React.FC<{lit?: number}> = ({lit = 0}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    <div style={{position: 'absolute', top: 34, left: 26, display: 'flex', gap: 12, alignItems: 'center'}}>
      <Tile x={0} y={0} size={46} fill="#FFF3DF" icon="sun" color={C.amber} />
      <Bar x={58} y={10} w={200} h={12} fill={C.text} opacity={0.55} align="left" />
      <Bar x={58} y={32} w={120} h={9} fill={C.text3} opacity={0.25} align="left" />
    </div>
    {[0, 1, 2].map((i) => {
      const on = lit > i;
      return (
        <Card key={i} y={140 + i * 132} h={112} fill={on ? '#FFF8EC' : '#FFFFFF'}>
          <div style={{position: 'absolute', left: 18, top: 26, width: 60, height: 60, borderRadius: 20, background: on ? `linear-gradient(140deg, #F7C56B, ${C.amber})` : C.surfaceAlt, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: on ? `0 0 28px ${C.amber}66` : undefined}}>
            <Icon name="sun" size={30} color={on ? '#FFFDF6' : C.text3} />
          </div>
          <Bar x={94} y={34} w={230 - i * 26} h={11} fill={on ? C.text2 : C.text3} opacity={on ? 0.7 : 0.25} align="left" />
          <Bar x={94} y={58} w={140} h={9} fill={C.text3} opacity={0.2} align="left" />
        </Card>
      );
    })}
  </div>
);

export const GardenScreen: React.FC<{growth?: number; streak?: number; sprout?: number}> = ({
  growth = 0,
  streak = 1,
  sprout = 1,
}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    <div style={{position: 'absolute', top: 34, left: 26, display: 'flex', gap: 12, alignItems: 'center'}}>
      <Tile x={0} y={0} size={46} fill="#E7F7F4" icon="sprout" color={C.teal} />
      <div style={{position: 'absolute', left: 58, top: 4, display: 'flex', alignItems: 'center', gap: 8}}>
        <Bar x={0} y={0} w={120} h={12} fill={C.text} opacity={0.55} align="left" />
      </div>
      <div style={{position: 'absolute', right: 0, top: 6, height: 40, padding: '0 16px', borderRadius: 20, background: '#FFF0EB', display: 'flex', alignItems: 'center', gap: 8}}>
        <Icon name="flame" size={18} color={C.coral} />
        <div style={{fontFamily: 'Cairo', fontSize: 16, fontWeight: 800, color: C.coral}}>{streak}</div>
      </div>
    </div>

    <div
      style={{
        position: 'absolute',
        left: 20,
        right: 20,
        top: 110,
        height: 600,
        borderRadius: 28,
        background: 'linear-gradient(180deg, #EAF3E6 0%, #DCEBD5 42%, #7A6244 100%)',
        overflow: 'hidden',
        boxShadow: '0 14px 34px rgba(29,27,38,0.1)',
      }}
    >
      <div style={{position: 'absolute', top: 0, left: 0, right: 0, height: 280, background: 'radial-gradient(circle at 68% 8%, #FFF3D6, transparent 62%)'}} />
      {Array.from({length: 7}).map((_, i) => {
        const g = clamp(growth - i * 0.07);
        const h = 24 + g * (140 + (i % 3) * 70);
        return (
          <div key={i} style={{position: 'absolute', left: 44 + i * 54, bottom: 150, width: 4, height: h, borderRadius: 3, background: g > 0.05 ? '#4E8C55' : '#8A7A66', transform: `scaleY(${g > 0.02 ? 1 : 0.08})`, transformOrigin: 'bottom'}}>
            {g > 0.35 && (
              <>
                <div style={{position: 'absolute', top: 8, left: -15, width: 17, height: 9, borderRadius: 9, background: '#5CA064', transform: 'rotate(-24deg)'}} />
                <div style={{position: 'absolute', top: 30, right: -15, width: 17, height: 9, borderRadius: 9, background: '#5CA064', transform: 'rotate(20deg)'}} />
              </>
            )}
            {g > 0.85 && <div style={{position: 'absolute', top: -8, left: -6, width: 16, height: 16, borderRadius: '50%', background: C.coral, boxShadow: `0 0 16px ${C.coral}`}} />}
          </div>
        );
      })}
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 152, background: 'linear-gradient(180deg, #6B5438, #4A3826)'}} />
      {/* the seed just dropped */}
      {sprout < 1 && <div style={{position: 'absolute', left: 236, bottom: 168, width: 10, height: 10, borderRadius: '50%', background: '#2F6B3A', opacity: sprout}} />}
    </div>

    <Card y={742} h={134}>
      <div style={{position: 'absolute', left: 18, top: 22, display: 'flex', gap: 10, alignItems: 'center'}}>
        <Icon name="pen" size={20} color={C.indigo} />
        <Bar x={0} y={4} w={170} h={10} fill={C.text2} opacity={0.35} align="left" />
      </div>
      <div style={{position: 'absolute', left: 18, right: 18, bottom: 24, height: 10, borderRadius: 5, background: C.surfaceAlt}}>
        <div style={{width: `${Math.min(100, growth * 100)}%`, height: 10, borderRadius: 5, background: `linear-gradient(90deg, ${C.teal}, ${C.tealSoft})`}} />
      </div>
    </Card>
  </div>
);

export const BreathScreen: React.FC<{phase?: number; count?: number; glow?: number; showCount?: boolean}> = ({
  phase = 0,
  count = 4,
  glow = 1,
  showCount = false,
}) => (
  <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(180deg, #141233 0%, #0B0E1C 100%)'}}>
    <div style={{position: 'absolute', inset: 0, background: `radial-gradient(circle at 50% 46%, rgba(232,116,106,${0.1 + phase * 0.16}), transparent 58%)`}} />
    <div style={{position: 'absolute', top: 60, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 8}}>
      {[0, 1, 2, 3].map((i) => (
        <div key={i} style={{width: 6, height: 6, borderRadius: '50%', background: '#6B62B8', opacity: 0.4 + i * 0.12}} />
      ))}
    </div>
    <div style={{position: 'absolute', left: 0, right: 0, top: 430, display: 'flex', justifyContent: 'center'}}>
      <div
        style={{
          width: 250,
          height: 250,
          borderRadius: '50%',
          border: `2px solid ${C.coralSoft}`,
          boxShadow: `0 0 ${60 * glow}px ${C.coral}88, inset 0 0 ${50 * glow}px ${C.coral}44`,
          transform: `scale(${0.66 + phase * 0.46})`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: `radial-gradient(circle, rgba(232,116,106,${0.13 + phase * 0.13}), transparent 70%)`,
        }}
      >
        {showCount && <div style={{fontFamily: 'Cairo', fontSize: 58, fontWeight: 300, color: '#F4EFEA'}}>{count}</div>}
      </div>
    </div>
    <div style={{position: 'absolute', bottom: 120, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: 0.55}}>
      <Icon name="wave" size={40} color="#C9C2EE" />
    </div>
  </div>
);

export const MoodScreen: React.FC<{active?: number; bloom?: number}> = ({active = -1, bloom = 0}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    <div style={{position: 'absolute', inset: 0, opacity: bloom, background: `radial-gradient(circle at 50% 58%, ${C.tealSoft}66, transparent 62%)`}} />
    <div style={{position: 'absolute', top: 54, left: 26, display: 'flex', gap: 12, alignItems: 'center'}}>
      <Tile x={0} y={0} size={46} fill="#E7F7F4" icon="wave" color={C.teal} />
      <Bar x={58} y={12} w={210} h={12} fill={C.text} opacity={0.55} align="left" />
    </div>
    <div style={{position: 'absolute', top: 190, left: 26, right: 26, display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between'}}>
      {(['good', 'calm', 'tired', 'anxious', 'low'] as FaceKind[]).map((k, i) => (
        <div key={k} style={{width: '31%', display: 'flex', justifyContent: 'center', marginBottom: 34}}>
          <Face kind={k} size={84} active={active === i} scale={active === i ? 1.12 : 1} />
        </div>
      ))}
    </div>
    <Card y={600} h={150} style={{background: `linear-gradient(140deg, ${C.teal}, ${C.tealSoft})`, opacity: bloom}}>
      <div style={{position: 'absolute', left: 24, top: 30, display: 'flex', gap: 12, alignItems: 'center'}}>
        <Icon name="sprout" size={34} color="#EAFFFB" />
        <div style={{display: 'flex', flexDirection: 'column', gap: 10}}>
          <Bar x={0} y={0} w={180} h={12} fill="#FFFFFF" opacity={0.9} align="left" />
          <Bar x={0} y={24} w={120} h={10} fill="#FFFFFF" opacity={0.6} align="left" />
        </div>
      </div>
    </Card>
  </div>
);

export const InsightsScreen: React.FC<{reveal?: number; wave?: number}> = ({reveal = 0, wave = 0}) => (
  <div style={{position: 'absolute', inset: 0, background: C.paper}}>
    <div style={{position: 'absolute', top: 34, left: 26, display: 'flex', gap: 12, alignItems: 'center'}}>
      <Tile x={0} y={0} size={46} fill="#EFEBFF" icon="wave" color={C.indigo} />
      <div style={{position: 'absolute', left: 58, top: 8, display: 'flex', flexDirection: 'column', gap: 8}}>
        <Bar x={0} y={0} w={190} h={12} fill={C.text} opacity={0.55} align="left" />
        <Bar x={0} y={22} w={110} h={9} fill={C.text3} opacity={0.25} align="left" />
      </div>
    </div>

    <div style={{position: 'absolute', top: 122, left: 26, right: 26}}>
      <svg width={420} height={276} viewBox="0 0 420 276">
        {Array.from({length: 26 * 9}).map((_, i) => {
          const col = i % 26;
          const row = Math.floor(i / 26);
          const v = Math.abs(Math.sin(i * 0.37) * Math.cos(i * 0.11));
          const on = reveal > (i / 234) * 1.08;
          const hue = v > 0.72 ? C.coral : v > 0.45 ? C.indigoGlow : C.tealSoft;
          return <rect key={i} x={col * 16} y={row * 30} width={12.5} height={12.5} rx={3.6} fill={hue} opacity={on ? 0.22 + v * 0.72 : 0.07} />;
        })}
      </svg>
    </div>

    <div style={{position: 'absolute', top: 424, left: 20, right: 20, height: 160}}>
      <svg width={432} height={160} viewBox="0 0 432 160">
        <path
          d={`M 0 84 ${Array.from({length: 44})
            .map((_, i) => {
              const x = (i / 43) * 432;
              const y = 84 - Math.sin(i * 0.52 + wave * 6) * 40 * Math.exp(-Math.pow((i - 21) / 15, 2)) * reveal;
              return `L ${x.toFixed(1)} ${y.toFixed(1)}`;
            })
            .join(' ')}`}
          stroke={C.coral}
          strokeWidth={3.4}
          fill="none"
          strokeLinecap="round"
        />
      </svg>
    </div>

    <div style={{position: 'absolute', top: 596, left: 20, right: 20, display: 'flex', gap: 12}}>
      {['12', '64', '3'].map((n, i) => (
        <div key={n} style={{flex: 1, height: 118, borderRadius: 22, background: '#fff', boxShadow: '0 8px 22px rgba(29,27,38,0.07)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10}}>
          <div style={{fontFamily: 'Cairo', fontSize: 30, fontWeight: 800, color: i === 1 ? C.teal : C.indigo}}>{n}</div>
          <div style={{width: 46, height: 8, borderRadius: 4, background: C.text3, opacity: 0.25}} />
        </div>
      ))}
    </div>

    <Card y={742} h={132} fill="#F0EDFF">
      <div style={{position: 'absolute', left: 22, top: 26}}><Icon name="bird" size={26} color={C.indigo} /></div>
      <div style={{position: 'absolute', left: 22, top: 66, display: 'flex', flexDirection: 'column', gap: 10}}>
        <Bar x={0} y={0} w={300} h={10} fill={C.indigo} opacity={0.35} align="left" />
        <Bar x={0} y={20} w={200} h={10} fill={C.indigo} opacity={0.22} align="left" />
      </div>
    </Card>
  </div>
);

export const LockScreen: React.FC<{clock?: string; unlock?: number}> = ({clock = '3:12', unlock = 0}) => (
  <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(180deg, #1B1A23 0%, #0A0D14 100%)'}}>
    <div style={{position: 'absolute', top: 200, left: 0, right: 0, textAlign: 'center', fontFamily: 'Cairo', fontSize: 96, fontWeight: 300, color: '#F1EFF7'}}>
      {clock}
    </div>
    <div style={{position: 'absolute', top: 470, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
      <div style={{width: 96, height: 96, borderRadius: '50%', border: `2px solid ${C.indigoGlow}`, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: `0 0 40px ${C.indigo}77`, opacity: 1 - unlock, transform: `scale(${1 - unlock * 0.2})`}}>
        <Icon name="lock" size={40} color={C.indigoGlow} />
      </div>
    </div>
    <div style={{position: 'absolute', bottom: 96, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 22}}>
      {[0, 1, 2, 3].map((i) => (
        <div key={i} style={{width: 16, height: 16, borderRadius: '50%', background: unlock > (i + 1) / 5 ? C.coral : '#3A3742'}} />
      ))}
    </div>
  </div>
);
