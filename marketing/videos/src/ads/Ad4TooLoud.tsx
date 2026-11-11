import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {C, clamp01, easeInOut} from '../kit/theme';
import {Camera, Grain, Vignette, PulseRing, Bloom, FadeBlack, Dust} from '../kit/Stage';
import {Silhouette, Hand} from '../kit/Silhouette';
import {Phone} from '../kit/Phone';
import {BreathScreen, MoodScreen, LockScreen} from '../kit/screens';
import {NoisePanels} from '../kit/World';
import {EndCard} from '../kit/EndCard';

export const Ad4TooLoud: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();

  /* A — the world too close */
  const shake = Math.sin(f * 1.7) * 0.6 + Math.sin(f * 0.63) * 0.5;
  const pushA = interpolate(f, [0, 80], [1.08, 1.16], {extrapolateRight: 'clamp'});
  const desat = 1 - clamp01((f - 60) / 60) * 0.3;

  /* B — one tap */
  const tap = f >= 108;
  const tapPush = spring({frame: f - 104, fps, config: {damping: 18, stiffness: 140}});

  /* C — the breath */
  const bt = clamp01((f - 138) / 150);
  const phase = Math.sin(bt * Math.PI * 2 - Math.PI / 2) * 0.5 + 0.5;
  const pull = clamp01((f - 138) / 70);
  const noiseOut = 1 - clamp01((f - 140) / 60);

  /* D — the mood */
  const bloom = clamp01((f - 344) / 40);
  const faceX = 540;

  return (
    <AbsoluteFill style={{backgroundColor: '#07080F'}}>
      {/* ══════════ A · too loud ══════════ */}
      {f < 134 && (
        <AbsoluteFill>
          <Camera scale={pushA} x={shake} y={-shake * 0.6} rotate={shake * 0.12}>
            <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 62% 34%, #1A1B28 0%, #0A0A12 62%, #05060B 100%)'}} />
            <div style={{position: 'absolute', left: 120, top: 720, width: 900, height: 900, background: `radial-gradient(circle, rgba(214,74,66,${0.16 + Math.sin(f * 0.42) * 0.06}), transparent 66%)`}} />
            <Silhouette variant="backClose" x={20} y={620} scale={2.6} fill="#04050A" rim={false} breathing={1.4} />
            <NoisePanels density={1.25} freeze={tap ? 1 : 0} opacity={0.95} />
            {/* a lamp far behind, the only warmth */}
            <div style={{position: 'absolute', left: 760, top: 240, width: 420, height: 420, borderRadius: '50%', background: 'radial-gradient(circle, rgba(232,116,106,0.22), transparent 66%)', filter: 'blur(20px)'}} />
          </Camera>
          {/* heartbeat vignette */}
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: 'radial-gradient(ellipse 70% 56% at 50% 48%, rgba(0,0,0,0) 40%, rgba(90,20,24,0.55) 100%)',
              opacity: 0.55 + Math.sin(f * 0.42) * 0.25,
            }}
          />
          <Grain opacity={0.2} />
          <FadeBlack opacity={1 - interpolate(f, [0, 20], [0, 1], {extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ B · the tap ══════════ */}
      {f >= 80 && f < 140 && (
        <AbsoluteFill style={{backgroundColor: '#07080F'}}>
          <Camera scale={1.0 + tapPush * 0.04}>
            <Phone x={540} y={1180} w={880} glow={0.8} glowColor="#8C82F0" dim={tap ? 0 : 0.25} rotate={-4}>
              <LockScreen clock="3:12" />
            </Phone>
          </Camera>
          <Hand x={980} y={1560} scale={1.05} rotate={-26} points={1} />
          <Bloom cx={540} cy={1100} r={620} color="rgba(140,130,240,0.24)" />
          <Vignette strength={0.55} />
          <Grain opacity={0.14} />
        </AbsoluteFill>
      )}

      {/* ══════════ C · breathe ══════════ */}
      {f >= 134 && f < 300 && (
        <AbsoluteFill style={{backgroundColor: '#04050A'}}>
          {/* the noise gets pulled into the ring and dissolves */}
          <NoisePanels density={1.25} freeze={1} pull={pull} opacity={noiseOut * 0.9} />
          <Camera scale={1.0 + (1 - bt) * 0.02}>
            <Phone x={540} y={980} w={900} glow={0.7} glowColor="#E8746A">
              <BreathScreen phase={phase} glow={1 + phase * 1.4} count={Math.max(1, Math.round(4 - phase * 3))} showCount={bt > 0.2} />
            </Phone>
          </Camera>
          <div style={{position: 'absolute', inset: 0, background: `radial-gradient(circle at 50% 48%, rgba(232,116,106,${0.06 + phase * 0.06}), transparent 62%)`}} />
          <Grain opacity={0.1} />
          <FadeBlack opacity={interpolate(f, [134, 140], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {/* ══════════ D · one honest answer ══════════ */}
      {f >= 300 && f < 404 && (
        <AbsoluteFill style={{backgroundColor: '#0B0A10'}}>
          <Camera scale={1.0}>
            <Phone x={540} y={980} w={900} glow={0.6 + bloom * 0.3} glowColor={bloom > 0.2 ? '#2F9E8F' : '#FAF8F5'}>
              <MoodScreen active={f > 330 ? 1 : -1} bloom={bloom} />
            </Phone>
          </Camera>
          {/* fingertip on the calm face */}
          {f > 318 && f < 352 && (
            <div
              style={{
                position: 'absolute',
                left: faceX - 30,
                top: 720 - 22,
                width: 58,
                height: 70,
                borderRadius: '50% 50% 46% 46%',
                background: '#0B0A10',
                opacity: 0.5,
                filter: 'blur(6px)',
                transform: `scale(${1 - clamp01((f - 318) / 14) * 0.1})`,
              }}
            />
          )}
          <Bloom cx={540} cy={760} r={540} color={`rgba(111,211,196,${bloom * 0.3})`} />
          <Vignette strength={0.4} />
          <Grain opacity={0.1} />
          <FadeBlack opacity={1 - interpolate(f, [300, 308], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
        </AbsoluteFill>
      )}

      {f >= 400 && (
        <AbsoluteFill style={{backgroundColor: '#05060B'}}>
          <EndCard start={403} duration={47} />
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};



