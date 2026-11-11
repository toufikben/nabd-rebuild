import React from 'react';
import {useCurrentFrame} from 'remotion';

type Variant = 'lying' | 'desk' | 'floor' | 'standing' | 'profile' | 'backClose';

const RIM = 'rgba(200,190,255,0.55)';

/**
 * People are drawn as silhouettes on purpose: no faces to fall into the
 * uncanny valley, and it mirrors the product's promise — nothing of you leaks
 * out. Motion is breathing + weight shifts, never puppet joints.
 */
export const Silhouette: React.FC<{
  variant: Variant;
  x: number;
  y: number;
  scale?: number;
  breathing?: number;
  fill?: string;
  rim?: boolean;
  flip?: boolean;
  phase?: number;
}> = ({variant, x, y, scale = 1, breathing = 1, fill = '#04050A', rim = true, flip = false, phase = 0}) => {
  const frame = useCurrentFrame();
  const b = Math.sin(frame * 0.055 * breathing + phase) * 1.6;
  const g = (
    <g transform={`translate(${x} ${y}) scale(${flip ? -scale : scale} ${scale})`}>
      {variant === 'lying' && (
        <g transform={`translate(0 ${b * 0.4})`}>
          {/* head */}
          <ellipse cx={62} cy={64} rx={33} ry={30} fill={fill} />
          <path d="M 34 58 Q 30 30 62 26 Q 92 26 96 52" fill={fill} />
          {/* torso + legs as thick strokes: organic shoulders, no boxy joints */}
          <path d="M 92 74 Q 170 66 250 78" stroke={fill} strokeWidth={62} strokeLinecap="round" fill="none" />
          <path d="M 246 80 Q 300 66 340 58" stroke={fill} strokeWidth={50} strokeLinecap="round" fill="none" />
          <path d="M 336 60 Q 372 68 396 96" stroke={fill} strokeWidth={40} strokeLinecap="round" fill="none" />
          <path d="M 392 92 Q 404 100 404 108" stroke={fill} strokeWidth={30} strokeLinecap="round" fill="none" />
          {/* arm resting on chest */}
          <path d="M 104 78 Q 140 104 186 96" stroke={fill} strokeWidth={26} strokeLinecap="round" fill="none" />
          {/* blanket over the body, rim-lit along the top edge */}
          <path d="M 120 34 Q 240 10 400 44 L 400 122 Q 250 140 120 112 Z" fill="#1A1B29" />
          <path d="M 122 38 Q 240 14 398 46" stroke="rgba(190,190,235,0.22)" strokeWidth={3} fill="none" />
          <path d="M 200 44 Q 210 80 196 120" stroke="rgba(190,190,235,0.07)" strokeWidth={3} fill="none" />
          <path d="M 280 40 Q 292 82 278 124" stroke="rgba(190,190,235,0.07)" strokeWidth={3} fill="none" />
          {rim && (
            <>
              <path d="M 100 44 Q 130 34 160 36" stroke={RIM} strokeWidth={3} fill="none" opacity={0.5} />
              <path d="M 120 52 Q 200 46 268 58" stroke={RIM} strokeWidth={2.4} fill="none" opacity={0.32} />
            </>
          )}
        </g>
      )}

      {variant === 'desk' && (
        <g transform={`translate(0 ${b})`}>
          {/* head + hair */}
          <ellipse cx={152} cy={118} rx={35} ry={38} fill={fill} />
          <path d="M 118 116 Q 112 66 154 62 Q 192 64 188 112 Q 176 92 150 92 Q 126 94 118 116 Z" fill={fill} />
          {/* neck */}
          <path d="M 152 152 L 152 172" stroke={fill} strokeWidth={26} strokeLinecap="round" />
          {/* torso, leaning slightly forward */}
          <path d="M 158 176 Q 150 240 168 304" stroke={fill} strokeWidth={58} strokeLinecap="round" fill="none" />
          {/* upper arm + forearm reaching to the desk */}
          <path d="M 162 200 Q 224 226 268 248" stroke={fill} strokeWidth={28} strokeLinecap="round" fill="none" />
          <path d="M 264 248 Q 292 256 316 252" stroke={fill} strokeWidth={22} strokeLinecap="round" fill="none" />
          {/* thigh + shin */}
          <path d="M 170 304 Q 262 306 330 300" stroke={fill} strokeWidth={48} strokeLinecap="round" fill="none" />
          <path d="M 330 300 Q 348 348 344 396" stroke={fill} strokeWidth={38} strokeLinecap="round" fill="none" />
          <path d="M 344 394 Q 362 400 372 396" stroke={fill} strokeWidth={26} strokeLinecap="round" fill="none" />
          {rim && (
            <>
              <path d="M 122 108 Q 120 78 150 70" stroke={RIM} strokeWidth={3.2} fill="none" opacity={0.55} />
              <path d="M 140 186 Q 132 240 148 296" stroke={RIM} strokeWidth={2.6} fill="none" opacity={0.3} />
              <path d="M 196 224 Q 236 240 268 246" stroke={RIM} strokeWidth={2.2} fill="none" opacity={0.22} />
            </>
          )}
        </g>
      )}

      {variant === 'floor' && (
        <g transform={`translate(0 ${b})`}>
          {/* seated from behind, knees up, head low — the smallest shape in the room */}
          <ellipse cx={200} cy={336} rx={104} ry={18} fill={fill} />
          {/* feet just visible either side */}
          <ellipse cx={144} cy={330} rx={34} ry={15} fill={fill} />
          <ellipse cx={256} cy={330} rx={34} ry={15} fill={fill} />
          {/* knees poking past the back */}
          <ellipse cx={86} cy={292} rx={40} ry={36} fill={fill} />
          <ellipse cx={314} cy={292} rx={40} ry={36} fill={fill} />
          {/* hands resting on the knees */}
          <ellipse cx={92} cy={262} rx={22} ry={17} fill={fill} />
          <ellipse cx={308} cy={262} rx={22} ry={17} fill={fill} />
          {/* the back, hunched */}
          <path d="M 118 322 Q 106 214 146 166 Q 174 138 200 138 Q 226 138 254 166 Q 294 214 282 322 Z" fill={fill} />
          {/* neck + head, sunk into the shoulders */}
          <path d="M 178 160 L 222 160 L 226 182 L 174 182 Z" fill={fill} />
          <ellipse cx={200} cy={114} rx={38} ry={42} fill={fill} />
          {/* hair, gathered */}
          <circle cx={200} cy={68} r={18} fill={fill} />
          {rim && (
            <>
              <path d="M 168 94 Q 200 72 232 94" stroke={RIM} strokeWidth={3.2} fill="none" opacity={0.55} />
              <path d="M 158 168 Q 138 204 130 250" stroke={RIM} strokeWidth={3} fill="none" opacity={0.4} />
              <path d="M 242 168 Q 262 204 270 250" stroke={RIM} strokeWidth={3} fill="none" opacity={0.4} />
              <path d="M 200 186 L 200 300" stroke="rgba(190,185,225,0.09)" strokeWidth={3} fill="none" />
              <path d="M 118 286 Q 112 250 122 226" stroke={RIM} strokeWidth={2.4} fill="none" opacity={0.28} />
              <path d="M 282 286 Q 288 250 278 226" stroke={RIM} strokeWidth={2.4} fill="none" opacity={0.28} />
            </>
          )}
        </g>
      )}

      {variant === 'backClose' && (
        <g transform={`translate(0 ${b})`}>
          {/* head and shoulders from behind, cropped by the desk edge */}
          <path d="M 60 420 Q 66 300 128 256 Q 160 232 200 230 Q 240 232 272 256 Q 334 300 340 420 Z" fill={fill} />
          <ellipse cx={200} cy={186} rx={54} ry={58} fill={fill} />
          <path d="M 148 176 Q 146 116 200 112 Q 254 116 252 176 Q 236 146 200 146 Q 164 146 148 176 Z" fill={fill} />
          <circle cx={200} cy={106} r={22} fill={fill} />
          <path d="M 96 330 Q 84 380 92 424" stroke="rgba(190,185,225,0.10)" strokeWidth={3} fill="none" />
          {rim && (
            <>
              <path d="M 152 158 Q 168 120 200 116" stroke={RIM} strokeWidth={3.2} fill="none" opacity={0.6} />
              <path d="M 254 162 Q 240 122 206 116" stroke={RIM} strokeWidth={2.2} fill="none" opacity={0.3} />
              <path d="M 76 360 Q 72 320 100 286" stroke={RIM} strokeWidth={2.4} fill="none" opacity={0.28} />
            </>
          )}
        </g>
      )}

      {variant === 'standing' && (
        <g transform={`translate(0 ${b})`}>
          <ellipse cx={200} cy={90} rx={34} ry={38} fill={fill} />
          <path d="M 166 86 Q 160 40 200 36 Q 240 40 234 86 Q 222 60 200 60 Q 178 60 166 86 Z" fill={fill} />
          <path d="M 200 130 L 200 300" stroke={fill} strokeWidth={72} strokeLinecap="round" />
          <path d="M 200 300 L 188 400" stroke={fill} strokeWidth={40} strokeLinecap="round" />
          <path d="M 200 300 L 216 400" stroke={fill} strokeWidth={40} strokeLinecap="round" />
          <path d="M 176 150 L 150 230" stroke={fill} strokeWidth={30} strokeLinecap="round" />
          <path d="M 224 150 L 250 230" stroke={fill} strokeWidth={30} strokeLinecap="round" />
          {rim && <path d="M 168 78 Q 176 50 200 48" stroke={RIM} strokeWidth={3} fill="none" opacity={0.45} />}
        </g>
      )}

      {variant === 'profile' && (
        <g>
          {/* large profile, close-up: forehead → nose → lips → chin → neck */}
          <path
            d="M 120 260
               Q 112 150 168 108
               Q 214 74 262 96
               Q 302 116 296 160
               Q 294 178 288 190
               Q 306 202 300 214
               Q 296 224 284 226
               Q 292 236 286 246
               Q 280 256 268 254
               Q 272 276 258 294
               Q 246 310 220 314
               L 214 420 L 60 420 L 60 300 Z"
            fill={fill}
          />
          <path d="M 262 96 Q 300 112 300 150" stroke={RIM} strokeWidth={3.4} fill="none" opacity={0.6} />
          <path d="M 172 112 Q 210 82 250 98" stroke={RIM} strokeWidth={2.6} fill="none" opacity={0.4} />
        </g>
      )}
    </g>
  );
  return <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>{g}</svg>;
};

/** A hand entering frame, reaching for the phone. */
export const Hand: React.FC<{
  x: number;
  y: number;
  scale?: number;
  rotate?: number;
  fill?: string;
  points?: number;
}> = ({x, y, scale = 1, rotate = 0, fill = '#04050A', points = 1}) => (
  <svg style={{position: 'absolute', inset: 0}} width={1080} height={1920}>
    <g transform={`translate(${x} ${y}) rotate(${rotate}) scale(${scale})`}>
      <path d="M 0 0 L 0 120 L 90 150" stroke={fill} strokeWidth={64} strokeLinecap="round" fill="none" />
      <path d="M 86 150 Q 140 158 176 146" stroke={fill} strokeWidth={46} strokeLinecap="round" fill="none" />
      {/* fingers */}
      {[0, 1, 2, 3].map((i) => (
        <path
          key={i}
          d={`M ${150 + i * 6} ${142 + i * 12} Q ${190 + i * 4} ${128 + i * 20} ${212} ${132 + i * 22}`}
          stroke={fill}
          strokeWidth={17}
          strokeLinecap="round"
          fill="none"
          opacity={0.55 + 0.45 * points}
        />
      ))}
      <path d="M 96 176 Q 132 210 176 200" stroke={fill} strokeWidth={30} strokeLinecap="round" fill="none" />
      <path d="M 30 40 L 40 130" stroke="rgba(200,190,255,0.35)" strokeWidth={3} fill="none" />
    </g>
  </svg>
);

