#!/usr/bin/env python3
"""Synthesises Nabd's own sounds, so they are original, license-free and
reproducible. Run from the repository root:

    python3 scripts/synth_sounds.py          # needs numpy and ffmpeg

Writes AAC (.m4a) files into assets/sounds/:

  nabd_pulse.m4a   launch cue: two soft heartbeats ("lub-dub") that bloom
                   into a warm D-major-add9 chime over a breath of air.
                   The app is called "pulse"; the sound says so, gently.
  ui_drop.m4a      a single water drop, played when the garden is watered.
  ui_bloom.m4a     a rising three-note sparkle for growth and achievements.
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
rng = np.random.default_rng(7)  # fixed seed: the same file every run


def t_axis(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def envelope(n, attack, decay, sustain_shape='exp'):
    """Attack in seconds, then an exponential decay with time constant."""
    t = np.arange(n) / RATE
    env = np.minimum(t / max(attack, 1e-4), 1.0)
    return env * np.exp(-np.maximum(t - attack, 0) / decay)


def heartbeat(start_hz, end_hz, length, level):
    """A soft thump: a sine gliding down, with harmonics strong enough that a
    phone speaker, which cannot play the fundamental, still conveys the beat
    (the ear rebuilds the missing low note from its overtones)."""
    t = t_axis(length)
    freq = start_hz + (end_hz - start_hz) * (1 - np.exp(-t / 0.05))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    body = (np.sin(phase) + 0.7 * np.sin(2 * phase) + 0.45 * np.sin(3 * phase)
            + 0.2 * np.sin(4 * phase))
    tap = rng.standard_normal(len(t)) * np.exp(-t / 0.004) * 0.25
    tap = np.convolve(tap, np.ones(8) / 8, mode='same')
    return level * (body * envelope(len(t), 0.006, 0.09) + tap)


def bell(freq, length, level, decay=1.6):
    """A soft bell: the fundamental plus two quiet inharmonic partials."""
    t = t_axis(length)
    tone = (np.sin(2 * np.pi * freq * t)
            + 0.22 * np.sin(2 * np.pi * freq * 2.01 * t) * np.exp(-t / 0.5)
            + 0.08 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / 0.25))
    return level * tone * envelope(len(t), 0.035, decay)


def breath(length, level):
    """Air: filtered noise that swells and fades like one slow breath."""
    n = int(length * RATE)
    noise = rng.standard_normal(n)
    # Two passes of a moving average roll off the hiss; subtracting a wider
    # average removes the rumble, leaving a soft band in the middle.
    soft = np.convolve(noise, np.ones(24) / 24, mode='same')
    soft = np.convolve(soft, np.ones(24) / 24, mode='same')
    soft -= np.convolve(soft, np.ones(400) / 400, mode='same')
    shape = np.sin(np.pi * np.linspace(0, 1, n)) ** 2
    return level * soft / (np.abs(soft).max() + 1e-9) * shape


def place(track, sound, at):
    start = int(at * RATE)
    end = min(len(track), start + len(sound))
    track[start:end] += sound[: end - start]


def reverb(signal, mix=0.22):
    """A small Schroeder room: four combs, two all-passes."""
    out = np.zeros_like(signal)
    for delay_ms, gain in [(29.7, 0.77), (37.1, 0.74), (41.1, 0.72), (43.7, 0.70)]:
        d = int(delay_ms * RATE / 1000)
        buf = np.copy(signal)
        for i in range(d, len(buf)):
            buf[i] += gain * buf[i - d]
        out += buf
    out /= 4
    for delay_ms, gain in [(5.0, 0.7), (1.7, 0.7)]:
        d = int(delay_ms * RATE / 1000)
        y = np.zeros_like(out)
        for i in range(len(out)):
            x = out[i]
            delayed = y[i - d] if i >= d else 0.0
            x_d = out[i - d] if i >= d else 0.0
            y[i] = -gain * x + x_d + gain * delayed
        out = y
    return (1 - mix) * signal + mix * out


def finish(channels, fade_out=0.3, peak_db=-3.0):
    stereo = np.stack(channels, axis=1)
    fade = int(fade_out * RATE)
    stereo[-fade:] *= np.linspace(1, 0, fade)[:, None] ** 2
    stereo[: int(0.003 * RATE)] *= np.linspace(0, 1, int(0.003 * RATE))[:, None]
    peak = np.abs(stereo).max()
    return stereo * (10 ** (peak_db / 20) / peak)


def write_m4a(name, stereo, bitrate='128k'):
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        path = tmp.name
    with wave.open(path, 'wb') as wav:
        wav.setnchannels(stereo.shape[1])
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes((stereo * 32767).astype('<i2').tobytes())
    target = os.path.join(OUT, name)
    subprocess.run(
        ['ffmpeg', '-y', '-loglevel', 'error', '-i', path, '-c:a', 'aac',
         '-b:a', bitrate, '-movflags', '+faststart', target],
        check=True,
    )
    os.remove(path)
    print(f'{name}: {stereo.shape[0] / RATE:.2f}s, '
          f'{os.path.getsize(target) // 1024} KB')


def pulse():
    length = 2.6
    left = np.zeros(int(length * RATE))
    right = np.zeros_like(left)
    # Lub-dub: the second beat is lighter, as a real heartbeat is.
    for at, level in [(0.05, 0.9), (0.33, 0.6)]:
        beat = heartbeat(118, 84, 0.45, level)
        place(left, beat, at)
        place(right, beat, at)
    # The chord blooms out of the second beat, notes rolled gently and
    # spread across the stereo field.
    chord = [(293.66, 0.00, 0.55, 0.62), (440.00, 0.07, 0.45, 0.50),
             (659.25, 0.14, 0.35, 0.40), (739.99, 0.21, 0.30, 0.30)]
    for i, (freq, delay, level, pan_right) in enumerate(chord):
        tone = bell(freq, 2.1, level, decay=1.5 - i * 0.15)
        place(left, tone * (1 - pan_right), 0.52 + delay)
        place(right, tone * pan_right * 1.2, 0.52 + delay)
    air = breath(1.6, 0.10)
    place(left, air, 0.30)
    place(right, air[::-1], 0.30)
    return finish([reverb(left), reverb(right)], fade_out=0.45)


def drop():
    length = 0.55
    t = t_axis(0.25)
    freq = 650 + 1500 * (1 - np.exp(-t / 0.018))  # the drop's upward "plip"
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    plip = np.sin(phase) * envelope(len(t), 0.002, 0.045)
    ring = bell(1320, 0.4, 0.18, decay=0.12)
    mono = np.zeros(int(length * RATE))
    place(mono, plip, 0.01)
    place(mono, ring, 0.03)
    mono = reverb(mono, mix=0.3)
    return finish([mono, mono], fade_out=0.15, peak_db=-6.0)


def bloom():
    length = 1.2
    left = np.zeros(int(length * RATE))
    right = np.zeros_like(left)
    for i, freq in enumerate([659.25, 830.61, 987.77, 1318.51]):
        tone = bell(freq, 0.9, 0.5 - i * 0.07, decay=0.45)
        pan = 0.35 + i * 0.1
        place(left, tone * (1 - pan), i * 0.075)
        place(right, tone * pan, i * 0.075)
    shimmer = breath(0.5, 0.04)
    place(left, shimmer, 0.15)
    place(right, shimmer, 0.15)
    return finish([reverb(left, 0.3), reverb(right, 0.3)], fade_out=0.3,
                  peak_db=-5.0)


if __name__ == '__main__':
    write_m4a('nabd_pulse.m4a', pulse())
    write_m4a('ui_drop.m4a', drop(), bitrate='96k')
    write_m4a('ui_bloom.m4a', bloom(), bitrate='96k')
