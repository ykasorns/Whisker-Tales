"""Synthesises the game's music and sound effects (T-024, D-034).

Everything is generated from code — no samples, no third-party audio — so
there is no licence to track. Soft, rounded tones for young players: no
harsh square waves, no loud transients, peaks normalised to -3 dBFS.

    python3 -I tools/audio/make_sounds.py   # needs numpy + ffmpeg

Writes Ogg Vorbis files to app/assets/audio/ (loops are whole bars, so
they repeat without a gap).
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = f'{ROOT}/app/assets/audio'
SR = 32000


def note_hz(n: int) -> float:
    """MIDI note → Hz."""
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n: int, a=0.005, d=0.08, s=0.6, r=0.1) -> np.ndarray:
    """ADSR envelope over n samples (times in seconds)."""
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    e = np.full(n, s, dtype=np.float64)
    a = min(a, n)
    e[:a] = np.linspace(0, 1, a, endpoint=False)
    dd = min(d, n - a)
    e[a:a + dd] = np.linspace(1, s, dd, endpoint=False)
    rr = min(r, n)
    e[n - rr:] *= np.linspace(1, 0, rr)
    return e


def tone(hz, dur, kind='tri', vol=0.5, **kw) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * hz * t
    if kind == 'sine':
        w = np.sin(ph)
    elif kind == 'tri':
        w = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == 'soft':  # sine + a little 2nd/3rd harmonic: a marimba-ish pluck
        w = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    else:
        raise ValueError(kind)
    return w * env(n, **kw) * vol


def noise(dur, vol=0.3, lp=0.2, **kw) -> np.ndarray:
    n = int(dur * SR)
    x = np.random.default_rng(7).standard_normal(n)
    # one-pole low-pass: lp near 0 = dull, 1 = bright
    y = np.empty(n)
    acc = 0.0
    for i in range(n):
        acc += lp * (x[i] - acc)
        y[i] = acc
    return y / (np.abs(y).max() + 1e-9) * env(n, **kw) * vol


def place(buf: np.ndarray, x: np.ndarray, at: float, wrap=False):
    i = int(at * SR)
    end = i + len(x)
    if end <= len(buf):
        buf[i:end] += x
    elif wrap:  # loops: the tail rings into the start of the next repeat
        k = len(buf) - i
        buf[i:] += x[:k]
        buf[:len(x) - k] += x[k:]
    else:
        buf[i:] += x[:len(buf) - i]


def norm(x: np.ndarray, peak_db=-3.0) -> np.ndarray:
    return x / (np.abs(x).max() + 1e-9) * 10 ** (peak_db / 20)


def save(name: str, x: np.ndarray, q: int = 3):
    os.makedirs(OUT, exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    stereo = np.repeat(pcm[:, None], 2, axis=1)  # ffmpeg's vorbis wants 2 ch
    with tempfile.TemporaryDirectory() as tmp:
        w = f'{tmp}/{name}.wav'
        with wave.open(w, 'wb') as f:
            f.setnchannels(2)
            f.setsampwidth(2)
            f.setframerate(SR)
            f.writeframes(stereo.tobytes())
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', w, '-c:a', 'vorbis',
                        '-strict', '-2', '-q:a', str(q), f'{OUT}/{name}.ogg'],
                       check=True)
    print(f'{name}.ogg  {len(x) / SR:.2f}s  {os.path.getsize(f"{OUT}/{name}.ogg") // 1024} KB')


# ---------------------------------------------------------------- music

def song(bpm, bars, melody, chords, bass_oct=36, lead='soft', drums=True):
    """melody: list of (beat, midi, beats) · chords: one root per bar
    (major/minor triad by name 'C', 'Am' …)."""
    beat = 60 / bpm
    n = int(bars * 4 * beat * SR)
    buf = np.zeros(n)
    names = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    for bar, ch in enumerate(chords):
        root = names[ch[0]]
        minor = ch.endswith('m')
        third = 3 if minor else 4
        t0 = bar * 4 * beat
        # bass: root on 1 and 3, fifth on 2 and 4
        for b, iv in enumerate([0, 7, 0, 7]):
            place(buf, tone(note_hz(bass_oct + root + iv), beat * 0.9, 'sine',
                            0.32, d=0.15, s=0.5, r=0.08), t0 + b * beat, wrap=True)
        # soft pad: the triad, quiet, whole bar
        for iv in (0, third, 7):
            place(buf, tone(note_hz(60 + root + iv), 4 * beat, 'sine', 0.06,
                            a=0.08, d=0.3, s=0.7, r=0.3), t0, wrap=True)
        if drums:
            for b in range(4):
                place(buf, noise(0.05, 0.10, 0.9, a=0.001, d=0.03, s=0.0, r=0.02),
                      t0 + b * beat + beat / 2, wrap=True)  # off-beat shaker
                if b % 2 == 0:  # soft kick
                    k = tone(70, 0.18, 'sine', 0.35, a=0.002, d=0.12, s=0.0, r=0.05)
                    place(buf, k, t0 + b * beat, wrap=True)
    for at, m, dur in melody:
        place(buf, tone(note_hz(m), dur * beat * 0.95, lead, 0.30,
                        d=0.12, s=0.45, r=0.12), at * beat, wrap=True)
    return norm(buf, -4)


def farm():
    # C major pentatonic, bouncy 8-bar phrase played twice with a variation
    C, D, E, G, A = 72, 74, 76, 79, 81
    a = [(0, E, 1), (1, G, 1), (2, A, 1), (3, G, 1),
         (4, E, 1), (5, D, 1), (6, C, 2),
         (8, D, 1), (9, E, 1), (10, G, 1), (11, E, 1),
         (12, D, 2), (14, G - 12, 2),
         (16, E, 1), (17, G, 1), (18, A, 1), (19, C + 12, 1),
         (20, A, 1), (21, G, 1), (22, E, 2),
         (24, D, 1), (25, E, 1), (26, D, 1), (27, C, 1),
         (28, C, 3)]
    mel = a + [(b + 32, m, d) for b, m, d in a[:-1]] + [(60, D, 1), (61, E, 1), (62, D, 1), (63, C, 1)]
    chords = ['C', 'Am', 'F', 'G', 'C', 'Am', 'F', 'C'] * 2
    return song(112, 16, mel, chords)


def boss():
    # A minor-ish but playful, quicker, a busier bass
    A, B, C, D, E, G = 69, 71, 72, 74, 76, 79
    a = [(0, A, 0.5), (0.5, C, 0.5), (1, E, 1), (2, D, 0.5), (2.5, C, 0.5), (3, B, 1),
         (4, C, 0.5), (4.5, D, 0.5), (5, E, 1), (6, G, 1), (7, E, 1),
         (8, A, 0.5), (8.5, C, 0.5), (9, E, 1), (10, D, 0.5), (10.5, E, 0.5), (11, G, 1),
         (12, E, 1), (13, D, 1), (14, A, 2)]
    mel = a + [(b + 16, m, d) for b, m, d in a]
    chords = ['Am', 'F', 'G', 'Am'] * 2
    return song(136, 8, mel, chords, bass_oct=33)


# ---------------------------------------------------------------- effects

def fx_hit():
    return norm(noise(0.07, 0.6, 0.35, a=0.001, d=0.05, s=0.0, r=0.02)
                + np.pad(tone(180, 0.07, 'sine', 0.8, a=0.001, d=0.05, s=0, r=0.02), (0, 0)), -8)


def fx_crit():
    x = np.zeros(int(0.22 * SR))
    place(x, fx_hit() * 1.3, 0)
    for i, m in enumerate([88, 93]):
        place(x, tone(note_hz(m), 0.12, 'sine', 0.35, a=0.002, d=0.08, s=0.1, r=0.04), 0.03 + i * 0.05)
    return norm(x, -6)


def fx_pop():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    f = 700 * np.exp(-t * 9) + 180  # quick downward "boing"
    w = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, a=0.002, d=0.15, s=0.2, r=0.08)
    return norm(w, -6)


def fx_coin():
    x = np.zeros(int(0.3 * SR))
    place(x, tone(note_hz(88), 0.09, 'sine', 0.5, a=0.001, d=0.06, s=0.3, r=0.03), 0)
    place(x, tone(note_hz(93), 0.2, 'sine', 0.5, a=0.001, d=0.1, s=0.3, r=0.1), 0.07)
    return norm(x, -8)


def fx_knit():
    x = np.zeros(int(0.35 * SR))
    place(x, noise(0.18, 0.4, 0.08, a=0.04, d=0.1, s=0.3, r=0.05), 0)  # soft whoosh
    place(x, tone(note_hz(79), 0.15, 'soft', 0.5, a=0.002, d=0.1, s=0.1, r=0.05), 0.15)
    return norm(x, -6)


def fx_hatch():
    x = np.zeros(int(0.9 * SR))
    for i in range(3):  # three little cracks
        place(x, noise(0.04, 0.6, 0.6, a=0.001, d=0.03, s=0, r=0.01), i * 0.09)
    for i, m in enumerate([72, 76, 79, 84, 88]):
        place(x, tone(note_hz(m), 0.3, 'soft', 0.4, d=0.1, s=0.3, r=0.15), 0.3 + i * 0.08)
    return norm(x, -4)


def fx_win():
    x = np.zeros(int(1.2 * SR))
    for at, m, d in [(0, 72, 0.15), (0.15, 76, 0.15), (0.3, 79, 0.15), (0.45, 84, 0.6)]:
        place(x, tone(note_hz(m), d, 'soft', 0.45, d=0.1, s=0.5, r=0.15), at)
        place(x, tone(note_hz(m - 12), d, 'sine', 0.2, d=0.1, s=0.5, r=0.15), at)
    return norm(x, -4)


def fx_level():
    x = np.zeros(int(0.7 * SR))
    for i, m in enumerate([67, 71, 74, 79, 83]):
        place(x, tone(note_hz(m + 5), 0.2, 'sine', 0.4, d=0.08, s=0.3, r=0.1), i * 0.06)
    return norm(x, -5)


def fx_tap():
    return norm(tone(note_hz(84), 0.06, 'sine', 0.5, a=0.001, d=0.04, s=0, r=0.02), -12)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        sys.exit('no arguments')
    save('bgm_farm', farm(), q=2)
    save('bgm_boss', boss(), q=2)
    for name, f in [('sfx_hit', fx_hit), ('sfx_crit', fx_crit), ('sfx_pop', fx_pop),
                    ('sfx_coin', fx_coin), ('sfx_knit', fx_knit), ('sfx_hatch', fx_hatch),
                    ('sfx_win', fx_win), ('sfx_level', fx_level), ('sfx_tap', fx_tap)]:
        save(name, f())
