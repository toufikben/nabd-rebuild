import React from 'react';
import {S_W, S_H} from './screens';

/**
 * A phone drawn from scratch: bezel, glass sheen, dynamic island, and a real
 * screen whose content is laid out at 472x996 and scaled to fit.
 */
export const Phone: React.FC<{
  x: number;
  y: number;
  w?: number;
  rotate?: number;
  scale?: number;
  glow?: number;
  glowColor?: string;
  dim?: number;
  children: React.ReactNode;
}> = ({x, y, w = 500, rotate = 0, scale = 1, glow = 1, glowColor = '#FAF8F5', dim = 0, children}) => {
  const h = w * 2.048;
  const inset = 16;
  const screenW = w - inset * 2;
  const screenH = h - inset * 2;
  const contentScale = screenW / S_W;

  return (
    <div
      style={{
        position: 'absolute',
        left: x - w / 2,
        top: y - h / 2,
        width: w,
        height: h,
        transform: `rotate(${rotate}deg) scale(${scale})`,
        pointerEvents: 'none',
      }}
    >
      {glow > 0.01 && (
        <div
          style={{
            position: 'absolute',
            left: -w * 0.95,
            top: -w * 0.95,
            width: w * 2.9,
            height: w * 2.9,
            borderRadius: '50%',
            background: `radial-gradient(circle, ${glowColor} 0%, transparent 62%)`,
            opacity: glow * 0.5,
            filter: 'blur(10px)',
          }}
        />
      )}

      {/* side buttons */}
      <div style={{position: 'absolute', right: -3, top: h * 0.22, width: 4, height: 62, borderRadius: 3, background: '#22222E'}} />
      <div style={{position: 'absolute', right: -3, top: h * 0.31, width: 4, height: 96, borderRadius: 3, background: '#22222E'}} />
      <div style={{position: 'absolute', left: -3, top: h * 0.26, width: 4, height: 44, borderRadius: 3, background: '#22222E'}} />

      {/* bezel */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: w * 0.115,
          background: 'linear-gradient(150deg, #2A2B38 0%, #0A0B12 42%, #191A24 100%)',
          boxShadow: '0 40px 90px rgba(0,0,0,0.55)',
        }}
      >
        {/* screen */}
        <div
          style={{
            position: 'absolute',
            inset,
            borderRadius: w * 0.098,
            overflow: 'hidden',
            background: '#FAF8F5',
          }}
        >
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: S_W,
              height: S_H,
              transform: `scale(${contentScale})`,
              transformOrigin: 'top left',
            }}
          >
            {children}
          </div>

          {/* dynamic island */}
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: 10,
              width: w * 0.22,
              height: 22,
              marginLeft: -(w * 0.22) / 2,
              borderRadius: 14,
              background: '#05060B',
            }}
          />

          {/* glass sheen */}
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: 'linear-gradient(122deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0) 34%, rgba(255,255,255,0) 70%, rgba(255,255,255,0.07) 100%)',
              pointerEvents: 'none',
            }}
          />

          {dim > 0.001 && (
            <div style={{position: 'absolute', inset: 0, background: '#000', opacity: dim, pointerEvents: 'none'}} />
          )}
        </div>
      </div>
    </div>
  );
};

/** Soft light the phone throws on the room around it. */
export const PhoneLight: React.FC<{
  x: number;
  y: number;
  w?: number;
  color?: string;
  intensity?: number;
  spread?: number;
}> = ({x, y, w = 500, color = '#FAF8F5', intensity = 0.35, spread = 2.6}) => (
  <div
    style={{
      position: 'absolute',
      left: x - (w * spread) / 2,
      top: y - (w * spread * 2.048) / 2,
      width: w * spread,
      height: w * spread * 2.048,
      background: `radial-gradient(ellipse at center, ${color} 0%, transparent 66%)`,
      opacity: intensity,
      filter: 'blur(30px)',
      mixBlendMode: 'screen',
      pointerEvents: 'none',
    }}
  ></div>
);
