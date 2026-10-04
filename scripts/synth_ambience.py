#!/usr/bin/env python3
"""Synthesises every ambient and cue sound Nabd ships, so the whole sound
set is original, license-free and reproducible (the launch cue and moment
sounds live in synth_sounds.py). Run from the repository root:

    python3 scripts/synth_ambience.py           # needs numpy, scipy, ffmpeg
    python3 scripts/synth_ambience.py rain_soft # one sound only

Ambient beds are seamless loops (the end is cross-faded into the start),
so LoopMode.one never clicks. Output is AAC (.m4a) in assets/sounds/.
"""

import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter, sosfilt

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


# ── building blocks ─────────────────────────────────────────────────────────

def secs(n):
    return int(round(n * RATE))


def bandpass(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], 'bandpass', fs=RATE, output='sos'), x)


def lowpass(x, hz, order=2):
    return sosfilt(butter(order, hz, 'lowpass', fs=RATE, output='sos'), x)


def highpass(x, hz, order=2):
    return sosfilt(butter(order, hz, 'highpass', fs=RATE, output='sos'), x)


def smooth_noise(rng, n, hz):
    """A slow random curve in [-1, 1]: white noise low-passed far below 1 Hz."""
    curve = lowpass(rng.standard_normal(n), hz, order=2)
    return curve / (np.abs(curve).max() + 1e-12)


def periodic_curve(rng, n, period_s, harmonics=4):
    """A slow random curve that repeats every period_s, for loopable swells."""
    t = np.arange(n) / RATE
    curve = np.zeros(n)
    for k in range(1, harmonics + 1):
        curve += rng.uniform(0.3, 1) / k * np.sin(
            2 * np.pi * k * t / period_s + rng.uniform(0, 2 * np.pi))
    return curve / np.abs(curve).max()


def room(rng, seconds, damp_hz=5000):
    """An impulse response: decaying, darkening noise. Convolution with it is
    a fast, smooth reverb without metallic comb ringing."""
    n = secs(seconds)
    t = np.arange(n) / RATE
    ir = rng.standard_normal(n) * np.exp(-t * 6.9 / seconds)
    ir = lowpass(ir, damp_hz)
    ir[0] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def reverb(rng, x, mix, seconds=2.2, damp_hz=5000):
    wet = fftconvolve(x, room(rng, seconds, damp_hz))[: len(x)]
    return (1 - mix) * x + mix * wet


def env_adsr(n, attack, release):
    env = np.ones(n)
    a, r = secs(attack), secs(release)
    env[:a] = np.linspace(0, 1, a) ** 2
    if r:
        env[-r:] *= np.linspace(1, 0, r) ** 2
    return env


def place(track, sound, at):
    start = secs(at)
    end = min(len(track), start + len(sound))
    if end > start:
        track[start:end] += sound[: end - start]


def loop(x, crossfade):
    """Fold the material after the loop point over the start: a seamless loop.

    The loop length is a whole number of 1024-sample AAC frames. AAC pads the
    last frame with silence, and a padded loop would click or gap on every
    repeat; a frame-aligned one decodes to exactly its own length."""
    c = secs(crossfade)
    m = (len(x) - c) // 1024 * 1024
    body = x[:m].copy()
    fade = np.sin(np.linspace(0, np.pi / 2, c)) ** 2
    body[:c] = body[:c] * fade + x[m:m + c] * (1 - fade)
    return body


def pluck(freq, seconds, rng, decay=0.996, brightness=0.5):
    """Karplus-Strong string, run by lfilter: y[n] = x[n] + g(y[n-N]+y[n-N-1])/2."""
    period = max(2, int(round(RATE / freq)))
    n = secs(seconds)
    burst = rng.uniform(-1, 1, period)
    burst = lowpass(burst, 1500 + 9000 * brightness, order=1)
    x = np.zeros(n)
    x[:period] = burst
    a = np.zeros(period + 2)
    a[0] = 1
    a[period] = a[period + 1] = -decay / 2
    y = lfilter([1.0], a, x)
    return y / (np.abs(y).max() + 1e-12)


def write_m4a(name, stereo, bitrate='96k', fade_edges=False):
    if fade_edges:  # one-shots only; loops must not dip at the seam
        e = secs(0.004)
        stereo[:e] *= np.linspace(0, 1, e)[:, None]
        stereo[-e:] *= np.linspace(1, 0, e)[:, None]
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        path = tmp.name
    with wave.open(path, 'wb') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes((np.clip(stereo, -1, 1) * 32767).astype('<i2').tobytes())
    target = os.path.join(OUT, name + '.m4a')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', path, '-c:a', 'aac',
                    '-b:a', bitrate, '-movflags', '+faststart', target], check=True)
    os.remove(path)
    print(f'{name}.m4a: {stereo.shape[0] / RATE:.1f}s, '
          f'{os.path.getsize(target) // 1024} KB')


def normalise(stereo, rms_db, ceiling_db=-3.0):
    """Set the loudness by RMS, so a sparse sound (crackles, bubbles) is as
    present as a dense one, then round off any peak above the ceiling."""
    rms = np.sqrt(np.mean(stereo ** 2)) + 1e-12
    stereo = stereo * (10 ** (rms_db / 20) / rms)
    ceiling = 10 ** (ceiling_db / 20)
    over = np.abs(stereo) > ceiling * 0.7
    knee = ceiling * 0.7
    soft = np.sign(stereo) * (knee + (ceiling - knee) * np.tanh(
        (np.abs(stereo) - knee) / (ceiling - knee)))
    return np.where(over, soft, stereo)


# ── ambient beds (seamless loops) ───────────────────────────────────────────

def rain_soft():
    rng = np.random.default_rng(11)
    length, xf = 40, 4
    n = secs(length + xf)
    shared = rng.standard_normal(n)
    channels = []
    for side in range(2):
        own = rng.standard_normal(n)
        bed = bandpass(0.6 * shared + 0.8 * own, 350, 7000)
        bed = lowpass(bed, 3500, order=1)  # pink-ish tilt: soft, not hissy
        bed *= 0.85 + 0.15 * smooth_noise(rng, n, 0.15)
        # Individual drops: impulses through a handful of short "tick" shapes.
        drops = np.zeros(n)
        kernels = []
        for _ in range(8):
            k = secs(0.006)
            t = np.arange(k) / RATE
            kernels.append(np.sin(2 * np.pi * rng.uniform(1800, 5500) * t)
                           * np.exp(-t / 0.0012))
        count = int(70 * (length + xf))
        for k in rng.integers(0, len(kernels), count):
            at = rng.integers(0, n - 300)
            amp = rng.pareto(3) * 0.15
            ker = kernels[k]
            drops[at:at + len(ker)] += amp * ker
        channels.append(bed / np.abs(bed).max() * 0.8 + drops * 0.35)
    left, right = (reverb(rng, c, 0.18, 1.2, 4000) for c in channels)
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -22)


def ocean_soft():
    rng = np.random.default_rng(12)
    waves = [7.5, 8.5, 9.0, 7.0, 8.5, 7.5]  # one loop = 48 s of six waves
    length, xf = sum(waves), 3
    n = secs(length + xf)
    t = np.arange(n) / RATE
    # A wave: a slow rise to the break, then a long fizzing wash back.
    env = np.zeros(n)
    start = 0.0
    for w in waves + waves[:1]:
        local = (t - start)
        rise = 0.38 * w
        shape = np.where(local < rise,
                         np.sin(np.pi / 2 * np.clip(local / rise, 0, 1)) ** 2,
                         np.exp(-(local - rise) / (0.35 * w)))
        env = np.maximum(env, np.where((local >= 0) & (local < 1.6 * w), shape, 0))
        start += w
    channels = []
    for side, lag in ((0, 0.0), (1, 0.35)):
        e = np.interp(t - lag, t, env)
        brown = np.cumsum(rng.standard_normal(n))
        brown = highpass(brown, 25)
        brown = lowpass(brown, 500) / (np.abs(brown).max() + 1e-12)
        foam = bandpass(rng.standard_normal(n), 900, 6000)
        foam /= np.abs(foam).max()
        sea = brown * (0.35 + 0.65 * e) + foam * 0.45 * e ** 2.2
        channels.append(sea)
    left, right = (reverb(rng, c, 0.2, 2.5, 3000) for c in channels)
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -22)


def wind_gentle():
    rng = np.random.default_rng(13)
    length, xf = 40, 5
    n = secs(length + xf)
    channels = []
    for side in range(2):
        noise = rng.standard_normal(n)
        out = np.zeros(n)
        for lo, hi, level in ((180, 450, 1.0), (450, 1100, 0.6), (1100, 2600, 0.25)):
            band = bandpass(noise, lo, hi)
            band /= np.abs(band).max()
            out += level * band * (0.55 + 0.45 * smooth_noise(rng, n, 0.12))
        gust = 0.5 + 0.5 * smooth_noise(rng, n, 0.06)
        # A faint whistle that glides with the gusts, as wind does past a gap.
        t = np.arange(n) / RATE
        f = 620 + 160 * smooth_noise(rng, n, 0.05)
        whistle = np.sin(2 * np.pi * np.cumsum(f) / RATE) * gust ** 3 * 0.05
        channels.append(out * (0.4 + 0.6 * gust) + whistle)
    left, right = (reverb(rng, c, 0.25, 2.0, 3000) for c in channels)
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -24)


def silent_river_water():
    rng = np.random.default_rng(14)
    length, xf = 40, 3
    n = secs(length + xf)
    channels = []
    for side in range(2):
        bed = bandpass(rng.standard_normal(n), 250, 2500)
        bed /= np.abs(bed).max()
        bed *= 0.6 + 0.4 * smooth_noise(rng, n, 4.0)
        bubbles = np.zeros(n)
        for _ in range(int(28 * (length + xf))):
            dur = rng.uniform(0.012, 0.04)
            m = secs(dur)
            tt = np.arange(m) / RATE
            f0 = rng.uniform(450, 1600)
            # A bubble rings and rises in pitch as it surfaces.
            phase = 2 * np.pi * np.cumsum(f0 * (1 + 2.5 * tt / dur)) / RATE
            b = np.sin(phase) * np.exp(-tt / (dur / 3)) * rng.pareto(2.5) * 0.25
            place(bubbles, b, rng.uniform(0, length + xf - 0.05))
        channels.append(bed * 0.45 + bubbles)
    left, right = (reverb(rng, c, 0.2, 1.4, 4500) for c in channels)
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -26)


def fireplace_crackle():
    rng = np.random.default_rng(15)
    length, xf = 40, 2
    n = secs(length + xf)
    rumble = lowpass(np.cumsum(rng.standard_normal(n)), 220)
    rumble = highpass(rumble, 30)
    rumble /= np.abs(rumble).max()
    rumble *= 0.7 + 0.3 * smooth_noise(rng, n, 0.8)
    hiss = bandpass(rng.standard_normal(n), 2000, 6000)
    hiss /= np.abs(hiss).max()
    channels = []
    for side in range(2):
        crackle = np.zeros(n)
        for _ in range(int(9 * (length + xf))):  # small dry crackles
            m = secs(0.003)
            tt = np.arange(m) / RATE
            c = rng.standard_normal(m) * np.exp(-tt / 0.0006) * rng.pareto(2) * 0.2
            place(crackle, c, rng.uniform(0, length + xf - 0.01))
        for _ in range(int(0.6 * (length + xf))):  # the odd louder pop
            m = secs(0.02)
            tt = np.arange(m) / RATE
            p = bandpass(rng.standard_normal(m), 700, 3500) * np.exp(-tt / 0.004)
            place(crackle, p * rng.uniform(0.5, 1.2), rng.uniform(0, length + xf - 0.03))
        crackle = highpass(crackle, 600)
        channels.append(rumble * 0.55 + hiss * 0.04 + crackle)
    left, right = (reverb(rng, c, 0.12, 0.9, 5000) for c in channels)
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -26)


def night_crickets():
    """Replaces the old café bed: a calmer evening for writing."""
    rng = np.random.default_rng(16)
    length, xf = 40, 3
    n = secs(length + xf)
    left, right = np.zeros(n), np.zeros(n)
    # (carrier Hz, chirp every s, pulses per chirp, level, pan right, distance)
    crickets = [(4400, 0.80, 3, 1.0, 0.25, 0), (4750, 1.00, 4, 0.7, 0.75, 1),
                (4100, 0.625, 3, 0.45, 0.55, 2), (3900, 1.25, 5, 0.3, 0.4, 3)]
    for carrier, every, pulses, level, pan, distance in crickets:
        chirp = np.zeros(secs(0.03 * pulses + 0.05))
        for p in range(pulses):
            m = secs(0.016)
            tt = np.arange(m) / RATE
            tone = np.sin(2 * np.pi * carrier * tt) * np.sin(np.pi * tt / tt[-1]) ** 2
            place(chirp, tone, 0.03 * p)
        track = np.zeros(n)
        at = rng.uniform(0, every)
        while at < length + xf - 0.2:
            place(track, chirp * rng.uniform(0.75, 1.0), at)
            at += every * rng.uniform(0.97, 1.03)
        if distance:
            track = lowpass(track, 9000 - 1500 * distance)
        left += track * level * (1 - pan)
        right += track * level * pan
    left, right = lowpass(left, 7000, order=4), lowpass(right, 7000, order=4)
    bed = [b * 0.25 for b in wind_gentle_bed(rng, n)]
    left, right = left + bed[0], right + bed[1]
    left, right = (reverb(rng, c, 0.3, 2.4, 6000) for c in (left, right))
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -28)


def wind_gentle_bed(rng, n):
    out = []
    for side in range(2):
        b = bandpass(rng.standard_normal(n), 150, 700)
        b /= np.abs(b).max()
        out.append(b * (0.6 + 0.4 * smooth_noise(rng, n, 0.08)))
    return out


def bird_phrase(rng, kind):
    """One short song: a few notes of one of three bird 'species'."""
    notes = []
    if kind == 0:  # descending whistle, 2-3 times
        for _ in range(rng.integers(2, 4)):
            notes.append((3600, 2500, 0.18, 0.08))
    elif kind == 1:  # quick trill
        f = rng.uniform(4200, 5200)
        for _ in range(rng.integers(5, 9)):
            notes.append((f, f * 1.15, 0.035, 0.02))
    else:  # two-note "tee-oo"
        notes += [(4200, 4300, 0.12, 0.06), (3000, 2800, 0.16, 0.1)]
    out = np.zeros(secs(sum(d + g for _, _, d, g in notes) + 0.05))
    at = 0.0
    for f0, f1, dur, gap in notes:
        m = secs(dur)
        tt = np.linspace(0, 1, m)
        f = f0 + (f1 - f0) * tt
        phase = 2 * np.pi * np.cumsum(f) / RATE
        note = (np.sin(phase) + 0.15 * np.sin(2 * phase)) * np.sin(np.pi * tt) ** 1.5
        place(out, note, at)
        at += dur + gap
    return out


def birds(seed, every, birds_count, distance_hz, rev_mix, rms_db, bed_level):
    rng = np.random.default_rng(seed)
    length, xf = 48, 3
    n = secs(length + xf)
    left, right = np.zeros(n), np.zeros(n)
    for b in range(birds_count):
        kind = b % 3
        pan = rng.uniform(0.15, 0.85)
        level = rng.uniform(0.5, 1.0)
        at = rng.uniform(0, every)
        while at < length - 1:
            phrase = bird_phrase(rng, kind) * level
            place(left, phrase * (1 - pan), at)
            place(right, phrase * pan, at)
            at += every * birds_count * rng.uniform(0.6, 1.4)
    left, right = lowpass(left, distance_hz), lowpass(right, distance_hz)
    bed = wind_gentle_bed(rng, n)
    left, right = left + bed[0] * bed_level, right + bed[1] * bed_level
    left, right = (reverb(rng, c, rev_mix, 2.0, 6000) for c in (left, right))
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, rms_db)


def birds_distant():
    return birds(17, every=4.5, birds_count=2, distance_hz=5500, rev_mix=0.45,
                 rms_db=-30, bed_level=0.12)


def garden_birds():
    return birds(18, every=1.6, birds_count=3, distance_hz=7500, rev_mix=0.25,
                 rms_db=-27, bed_level=0.08)


# ── soft music beds (seamless loops) ────────────────────────────────────────

def midi(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def harp_soft():
    rng = np.random.default_rng(19)
    length, xf = 48, 4
    n = secs(length + xf)
    left, right = np.zeros(n), np.zeros(n)
    scale = [62, 64, 66, 69, 71, 74, 76, 78, 81, 83]  # D major pentatonic
    phrases = [[0, 2, 4, 5, 4, 2], [1, 3, 5, 7, 5, 3], [2, 4, 6, 8, 6, 4],
               [0, 3, 5, 6, 5, 3]]
    at = 0.3
    while at < length - 5:
        for step in phrases[rng.integers(len(phrases))]:
            note = scale[step]
            tone = pluck(midi(note), 4.0, rng, decay=0.998, brightness=0.2)
            tone *= env_adsr(len(tone), 0.002, 0.6) * rng.uniform(0.55, 0.8)
            pan = 0.3 + 0.4 * (step / len(scale))
            place(left, tone * (1 - pan), at)
            place(right, tone * pan, at)
            at += 0.55
        at += 1.1  # breathe between phrases
    left, right = lowpass(left, 4500), lowpass(right, 4500)
    left, right = (reverb(rng, c, 0.35, 3.0, 5000) for c in (left, right))
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -24)


def oud_soft():
    rng = np.random.default_rng(20)
    length, xf = 48, 4
    n = secs(length + xf)
    left, right = np.zeros(n), np.zeros(n)
    # Maqam Hijaz on D: D Eb F# G A Bb C D, low and warm.
    hijaz = [50, 51, 54, 55, 57, 58, 60, 62]
    figures = [[0, 1, 2, 1, 0], [2, 3, 4, 3, 2, 1], [4, 5, 4, 3, 2],
               [3, 2, 1, 0], [0, 2, 3, 4, 5, 4, 3]]
    at = 0.4
    while at < length - 5:
        for i, step in enumerate(figures[rng.integers(len(figures))]):
            note = hijaz[step]
            # The risha tremolo: a quick repeat on the phrase's long notes.
            repeats = 3 if i == 0 and rng.random() < 0.5 else 1
            for r in range(repeats):
                tone = pluck(midi(note), 2.5, rng, decay=0.996, brightness=0.3)
                tone = tone + 0.6 * bandpass(tone, 150, 450)  # wooden body
                tone *= env_adsr(len(tone), 0.001, 0.5) * rng.uniform(0.5, 0.75)
                place(left, tone * 0.55, at)
                place(right, tone * 0.45, at + 0.004)
                at += 0.11 if r < repeats - 1 else rng.choice([0.45, 0.6, 0.9])
        at += 1.4
    left, right = lowpass(left, 3200), lowpass(right, 3200)
    left, right = (reverb(rng, c, 0.3, 2.6, 4000) for c in (left, right))
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -24)


def flute_note(freq, seconds, rng):
    n = secs(seconds)
    t = np.arange(n) / RATE
    vibrato = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.35) / 0.5, 0, 1)
    phase = 2 * np.pi * np.cumsum(freq * vibrato) / RATE
    tone = (np.sin(phase) + 0.35 * np.sin(2 * phase) + 0.12 * np.sin(3 * phase)
            + 0.05 * np.sin(4 * phase))
    breath = bandpass(rng.standard_normal(n), freq * 0.8, min(freq * 4, 15000))
    breath /= np.abs(breath).max()
    env = env_adsr(n, 0.18, min(0.6, seconds / 3))
    return (tone * 0.8 + breath * 0.12) * env


def flute_dawn():
    rng = np.random.default_rng(21)
    length, xf = 48, 4
    n = secs(length + xf)
    left, right = np.zeros(n), np.zeros(n)
    scale = [74, 76, 78, 81, 83, 86]  # D5 pentatonic, an open morning sound
    melody = [(0, 2.5), (2, 1.5), (3, 3.0), (None, 1.0), (4, 1.5), (3, 1.5),
              (2, 3.0), (None, 1.5), (1, 2.0), (2, 1.5), (0, 3.5), (None, 2.0),
              (3, 1.5), (5, 2.5), (4, 1.5), (3, 3.0), (None, 1.5), (2, 2.0),
              (1, 1.5), (0, 4.0)]
    at = 0.5
    for step, dur in melody:
        if step is not None and at < length - 2:
            note = flute_note(midi(scale[step]), dur + 0.3, rng) * rng.uniform(0.7, 0.85)
            place(left, note * 0.52, at)
            place(right, note * 0.48, at + 0.006)
        at += dur
    # A low drone keeps the silence between phrases warm.
    t = np.arange(n) / RATE
    drone = (np.sin(2 * np.pi * midi(50) * t) + 0.4 * np.sin(2 * np.pi * midi(57) * t))
    drone *= 0.06 * (0.8 + 0.2 * periodic_curve(rng, n, 16))
    left, right = left + drone, right + drone
    left, right = (reverb(rng, c, 0.4, 3.2, 6000) for c in (left, right))
    stereo = np.stack([loop(left, xf), loop(right, xf)], axis=1)
    return normalise(stereo, -22)


# ── one-shot cues ───────────────────────────────────────────────────────────

def tibetan_bowl():
    rng = np.random.default_rng(22)
    seconds = 7.0
    n = secs(seconds)
    t = np.arange(n) / RATE
    f0 = 196.0
    channels = []
    for side, detune in ((0, 0.0), (1, 0.4)):
        tone = np.zeros(n)
        for ratio, amp, tau, beat in ((1, 1.0, 4.5, 0.9), (2.71, 0.55, 3.0, 1.6),
                                      (5.15, 0.25, 1.8, 2.3), (8.42, 0.12, 1.0, 3.1)):
            f = f0 * ratio
            pair = (np.sin(2 * np.pi * f * t) + np.sin(2 * np.pi * (f + beat + detune) * t))
            tone += amp * pair * np.exp(-t / tau)
        strike = lowpass(rng.standard_normal(n), 2500) * np.exp(-t / 0.006) * 0.6
        channels.append(tone * env_adsr(n, 0.004, 1.2) + strike)
    left, right = (reverb(rng, c, 0.22, 2.5, 5000) for c in channels)
    return normalise(np.stack([left, right], axis=1), -18)


def paper_turn():
    rng = np.random.default_rng(23)
    seconds = 0.75
    n = secs(seconds)
    t = np.arange(n) / RATE
    swish = np.where(t < 0.16, (t / 0.16) ** 2, np.exp(-(t - 0.16) / 0.13))
    noise = bandpass(rng.standard_normal(n), 1200, 7500)
    grain = lowpass(np.abs(rng.standard_normal(n)) ** 3, 400)  # crinkle
    grain /= grain.max()
    page = noise * swish * (0.55 + 0.45 * grain)
    flap = np.sin(2 * np.pi * 130 * t) * np.exp(-np.maximum(t - 0.42, 0) / 0.03)
    flap *= (t >= 0.42) * 0.35
    mono = reverb(rng, page / np.abs(page).max() + flap, 0.15, 0.6, 6000)
    return normalise(np.stack([mono, np.roll(mono, 40)], axis=1), -24)


def breath(seconds, f_from, f_to, seed):
    rng = np.random.default_rng(seed)
    n = secs(seconds)
    t = np.linspace(0, 1, n)
    noise = rng.standard_normal(n)
    low = bandpass(noise, 300, 900)
    high = bandpass(noise, 900, 2600)
    low, high = low / np.abs(low).max(), high / np.abs(high).max()
    tilt = f_from + (f_to - f_from) * t  # 0 = dark, 1 = bright
    air = low * (1 - tilt) + high * tilt
    env = np.sin(np.pi * t) ** 1.6
    mono = reverb(rng, air * env, 0.2, 1.0, 4000)
    return normalise(np.stack([mono, mono], axis=1), -26)


def inhale():
    return breath(2.0, 0.2, 0.85, 24)  # brightens as the lungs fill


def exhale():
    return breath(3.0, 0.75, 0.1, 25)  # darkens as the air leaves


SOUNDS = {
    'rain_soft': (rain_soft, '96k', False),
    'ocean_soft': (ocean_soft, '96k', False),
    'wind_gentle': (wind_gentle, '80k', False),
    'silent_river_water': (silent_river_water, '96k', False),
    'fireplace_crackle': (fireplace_crackle, '96k', False),
    'night_crickets': (night_crickets, '80k', False),
    'birds_distant': (birds_distant, '80k', False),
    'garden_birds': (garden_birds, '96k', False),
    'harp_soft': (harp_soft, '96k', False),
    'oud_soft': (oud_soft, '96k', False),
    'flute_dawn': (flute_dawn, '96k', False),
    'tibetan_bowl': (tibetan_bowl, '128k', True),
    'paper_turn': (paper_turn, '96k', True),
    'inhale': (inhale, '80k', True),
    'exhale': (exhale, '80k', True),
}


if __name__ == '__main__':
    wanted = sys.argv[1:] or list(SOUNDS)
    for name in wanted:
        build, bitrate, one_shot = SOUNDS[name]
        write_m4a(name, build(), bitrate, fade_edges=one_shot)
