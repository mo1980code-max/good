#!/usr/bin/env python3
"""Sparkle Nail Spa — audio asset generator.

Produces the real .mp3 files shipped in `assets/audio/`:

    assets/audio/sfx/{tap,sparkle,bubble,water,brush,pop,success,gift,victory,applause}.mp3
    assets/audio/music/spa_loop.mp3

Why a generator? So every sound is auditable, reproducible and 100% original
(no third-party samples, no licensing questions) — and so the whole set can be
re-tuned per device in seconds.

Design rules for ages 3-8 (see docs/audio-report.md):
  * soft attack on every note  -> no startling "click"
  * peak normalised to <= -8 dBFS -> no clipping, no harshness
  * short SFX (<= 2.2 s), gentle music bed
  * no square/saw waves, only sine stacks -> never piercing

Usage:  python3 tools/generate_audio.py
"""

from __future__ import annotations

import os

import lameenc
import numpy as np

SR = 44_100
RNG = np.random.default_rng(20261008)

SFX_DIR = "assets/audio/sfx"
MUSIC_DIR = "assets/audio/music"


# --------------------------------------------------------------------------- #
# Building blocks
# --------------------------------------------------------------------------- #
def t_axis(duration: float) -> np.ndarray:
    return np.arange(int(duration * SR)) / SR


def attack_decay(duration: float, attack: float, decay: float) -> np.ndarray:
    """Click-free envelope: fast-but-smooth attack, exponential decay."""
    t = t_axis(duration)
    rise = 1.0 - np.exp(-t / max(attack, 1e-4))
    fall = np.exp(-t * decay)
    return rise * fall


def bell(
    freq: float,
    duration: float,
    decay: float = 8.0,
    attack: float = 0.006,
    harmonics: tuple[float, ...] = (1.0, 0.30, 0.10, 0.04),
) -> np.ndarray:
    """A soft bell / music-box note: sine stack with a quick smooth attack."""
    t = t_axis(duration)
    tone = np.zeros_like(t)
    for index, amount in enumerate(harmonics):
        tone += amount * np.sin(2 * np.pi * freq * (index + 1) * t)
    return tone * attack_decay(duration, attack, decay)


def sweep(f0: float, f1: float, duration: float, decay: float = 40.0) -> np.ndarray:
    """Exponential frequency sweep (the 'blup' of a soap bubble)."""
    t = t_axis(duration)
    k = np.log(f1 / f0) / duration
    phase = 2 * np.pi * f0 * (np.exp(k * t) - 1) / k
    return np.sin(phase) * attack_decay(duration, 0.004, decay)


def noise(duration: float) -> np.ndarray:
    return RNG.normal(0.0, 1.0, int(duration * SR))


def bandpass(signal: np.ndarray, low: float, high: float, taper: float = 0.35):
    """FFT brick-wall band-pass with a soft tapered edge (no ringing)."""
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(len(signal), 1 / SR)

    low_edge = max(low * (1 - taper), 1.0)
    high_edge = high * (1 + taper)

    mask = np.zeros_like(freqs)
    mask[(freqs >= low) & (freqs <= high)] = 1.0

    rising = (freqs > low_edge) & (freqs < low)
    mask[rising] = 0.5 * (1 - np.cos(np.pi * (freqs[rising] - low_edge) / (low - low_edge)))
    falling = (freqs > high) & (freqs < high_edge)
    mask[falling] = 0.5 * (1 + np.cos(np.pi * (freqs[falling] - high) / (high_edge - high)))

    return np.fft.irfft(spectrum * mask, n=len(signal))


def tremolo(signal: np.ndarray, rate: float, depth: float) -> np.ndarray:
    t = t_axis(len(signal) / SR)
    return signal * (1 - depth + depth * (0.5 + 0.5 * np.sin(2 * np.pi * rate * t)))


def fade(signal: np.ndarray, fade_in: float = 0.005, fade_out: float = 0.02) -> np.ndarray:
    out = signal.copy()
    n_in = min(int(fade_in * SR), len(out))
    n_out = min(int(fade_out * SR), len(out))
    if n_in:
        out[:n_in] *= np.linspace(0, 1, n_in)
    if n_out:
        out[-n_out:] *= np.linspace(1, 0, n_out)
    return out


def place(track: np.ndarray, signal: np.ndarray, at: float, gain: float = 1.0) -> None:
    start = int(at * SR)
    end = min(start + len(signal), len(track))
    if end <= start:
        return
    track[start:end] += signal[: end - start] * gain


def normalise(signal: np.ndarray, peak_db: float) -> np.ndarray:
    peak = float(np.max(np.abs(signal))) or 1.0
    target = 10 ** (peak_db / 20)
    return signal * (target / peak)


def encode_mp3(path: str, signal: np.ndarray, bitrate: int) -> int:
    samples = np.int16(np.clip(signal, -1.0, 1.0) * 32_767)
    encoder = lameenc.Encoder()
    encoder.set_bit_rate(bitrate)
    encoder.set_in_sample_rate(SR)
    encoder.set_channels(1)
    encoder.set_quality(2)
    payload = encoder.encode(samples.tobytes()) + encoder.flush()

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(payload)
    return len(payload)


# --------------------------------------------------------------------------- #
# Individual sounds
# --------------------------------------------------------------------------- #
def sfx_tap() -> np.ndarray:
    """A quiet wooden 'tok' — feels like a soft toy button."""
    return normalise(fade(bell(1046.5, 0.16, decay=30, harmonics=(1.0, 0.20, 0.05)), 0.004, 0.06), -12)


def sfx_sparkle() -> np.ndarray:
    """Three tiny ascending star chimes."""
    track = np.zeros(int(0.75 * SR))
    for offset, freq in ((0.00, 1318.5), (0.07, 1568.0), (0.14, 2093.0)):
        place(track, bell(freq, 0.55, decay=9, harmonics=(1.0, 0.22, 0.08)), offset, 1.0)
    shimmer = bandpass(noise(0.5), 5000, 9000) * 0.035 * attack_decay(0.5, 0.02, 8)
    place(track, shimmer, 0.10)
    return normalise(fade(track, 0.004, 0.05), -10)


def sfx_bubble() -> np.ndarray:
    """Three soap bubbles rising — playful but rounded."""
    track = np.zeros(int(0.55 * SR))
    for index, offset in enumerate((0.00, 0.11, 0.22)):
        base = 240 + index * 40
        place(track, sweep(base, base * 2.3, 0.10, decay=38), offset, 1.0)
    return normalise(fade(track, 0.004, 0.06), -11)


def sfx_water() -> np.ndarray:
    """Calm running water: filtered noise with a slow swell."""
    duration = 1.25
    bed = bandpass(noise(duration), 500, 2600)
    bed = tremolo(bed, 2.6, 0.35)
    bed *= attack_decay(duration, 0.09, 1.4)
    return normalise(fade(bed, 0.06, 0.28), -14)


def sfx_brush() -> np.ndarray:
    """A soft brushing stroke — high, dry, never sharp."""
    duration = 0.65
    stroke = bandpass(noise(duration), 1300, 4200)
    stroke = tremolo(stroke, 13.0, 0.55)
    stroke *= attack_decay(duration, 0.05, 2.2)
    return normalise(fade(stroke, 0.03, 0.12), -15)


def sfx_pop() -> np.ndarray:
    """A cheerful little 'pop' for stickers."""
    click = bandpass(noise(0.008), 1500, 7000) * 0.5
    body = bell(1400, 0.10, decay=55, harmonics=(1.0, 0.12))
    track = np.zeros(int(0.12 * SR))
    place(track, body, 0.0)
    place(track, click, 0.0, 0.6)
    return normalise(fade(track, 0.002, 0.03), -10)


def sfx_success() -> np.ndarray:
    """Two-note 'well done' chime for finishing a step."""
    track = np.zeros(int(0.70 * SR))
    place(track, bell(784.0, 0.24, decay=14), 0.00)
    place(track, bell(1046.5, 0.50, decay=7), 0.10)
    return normalise(fade(track, 0.004, 0.06), -9)


def sfx_gift() -> np.ndarray:
    """A magical rising arpeggio with a sparkle tail — opening a present."""
    track = np.zeros(int(1.10 * SR))
    for index, freq in enumerate((523.25, 659.25, 784.0, 1046.5)):
        place(track, bell(freq, 0.85, decay=6, harmonics=(1.0, 0.28, 0.10)), index * 0.09)
    tail = bandpass(noise(0.6), 4500, 9500) * 0.06 * attack_decay(0.6, 0.05, 5)
    place(track, tail, 0.30)
    return normalise(fade(track, 0.004, 0.10), -9)


def sfx_victory() -> np.ndarray:
    """A short warm fanfare (+ a soft shimmer) for the reveal."""
    track = np.zeros(int(1.90 * SR))
    for index, freq in enumerate((523.25, 659.25, 784.0, 1046.5)):
        place(track, bell(freq, 0.70, decay=6, harmonics=(1.0, 0.26, 0.09)), index * 0.10)

    t = t_axis(1.40)
    chord = (
        np.sin(2 * np.pi * 1046.5 * t)
        + np.sin(2 * np.pi * 1318.5 * t)
        + np.sin(2 * np.pi * 1568.0 * t)
    ) / 3
    chord *= attack_decay(1.40, 0.14, 1.9)
    place(track, chord, 0.42, 0.55)

    swell = bandpass(noise(1.1), 3000, 8000) * 0.05 * attack_decay(1.1, 0.2, 2.4)
    place(track, swell, 0.40)
    return normalise(fade(track, 0.005, 0.25), -8)


def sfx_applause() -> np.ndarray:
    """A small, polite crowd clap — never a stadium roar."""
    duration = 2.2
    track = np.zeros(int(duration * SR))

    # Individual claps: short band-limited noise bursts, random timing.
    for _ in range(30):
        at = float(RNG.uniform(0.05, duration - 0.35))
        length = float(RNG.uniform(0.012, 0.030))
        clap = bandpass(noise(length), 900, 5200) * attack_decay(length, 0.001, 90)
        place(track, clap, at, float(RNG.uniform(0.25, 0.9)))

    # A warm crowd bed underneath, so it reads as "many hands".
    crowd = bandpass(noise(duration), 300, 1400)
    crowd *= attack_decay(duration, 0.25, 0.9)
    track += crowd * 0.22

    return normalise(fade(track, 0.05, 0.7), -11)


def music_spa_loop() -> np.ndarray:
    """19.2 s seamless loop: soft pads, music-box melody, no percussion."""
    bpm = 100.0
    beat = 60.0 / bpm                 # 0.6 s
    bar = beat * 4                    # 2.4 s
    bars = 8
    duration = bar * bars             # 19.2 s
    track = np.zeros(int(duration * SR))

    def note(freq: float) -> float:
        return float(freq)

    # I - vi - IV - V, two bars each: gentle, endlessly loopable.
    progression = [
        (note(130.81), (261.63, 329.63, 392.00)),   # C
        (note(110.00), (261.63, 329.63, 440.00)),   # Am
        (note(87.31), (261.63, 349.23, 440.00)),    # F
        (note(98.00), (246.94, 293.66, 392.00)),    # G
    ]

    # --- Pads -----------------------------------------------------------------
    for index, (root, chord) in enumerate(progression):
        start = index * bar * 2
        for freq in chord:
            voice = bell(freq, bar * 2, decay=1.05, attack=0.55, harmonics=(1.0, 0.14, 0.05))
            place(track, voice, start, 0.30)
        # Soft bass root, one octave down, on every bar.
        for b in range(2):
            place(
                track,
                bell(root / 2, bar * 0.9, decay=2.6, attack=0.10, harmonics=(1.0, 0.18)),
                start + b * bar,
                0.22,
            )

    # --- Music-box melody (C major pentatonic, fixed seed => reproducible) -----
    pentatonic = (523.25, 587.33, 659.25, 783.99, 880.00, 1046.50)
    step = beat * 0.5
    position = 0.0
    while position < duration - 1.0:
        if RNG.random() < 0.42:
            freq = float(RNG.choice(pentatonic))
            place(
                track,
                bell(freq, 1.1, decay=4.5, attack=0.006, harmonics=(1.0, 0.20, 0.06)),
                position,
                0.16,
            )
        position += step * float(RNG.choice((1, 1, 2)))

    # --- Make the loop seam invisible -----------------------------------------
    cross = int(0.35 * SR)
    head, tail = track[:cross].copy(), track[-cross:].copy()
    ramp = np.linspace(0, 1, cross)
    track[:cross] = head * ramp + tail * (1 - ramp)
    track = track[:-cross]

    return normalise(fade(track, 0.02, 0.02), -14)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
SFX = {
    "tap": sfx_tap,
    "sparkle": sfx_sparkle,
    "bubble": sfx_bubble,
    "water": sfx_water,
    "brush": sfx_brush,
    "pop": sfx_pop,
    "success": sfx_success,
    "gift": sfx_gift,
    "victory": sfx_victory,
    "applause": sfx_applause,
}


def main() -> None:
    print(f"{'file':38s} {'seconds':>8s} {'peak dBFS':>10s} {'rms dBFS':>9s} {'KB':>7s}")
    print("-" * 78)

    total = 0
    for name, builder in SFX.items():
        signal = builder()
        path = os.path.join(SFX_DIR, f"{name}.mp3")
        size = encode_mp3(path, signal, bitrate=96)
        total += size
        peak = 20 * np.log10(max(float(np.max(np.abs(signal))), 1e-9))
        rms = 20 * np.log10(max(float(np.sqrt(np.mean(signal**2))), 1e-9))
        print(f"{path:38s} {len(signal)/SR:8.2f} {peak:10.1f} {rms:9.1f} {size/1024:7.1f}")

    music = music_spa_loop()
    music_path = os.path.join(MUSIC_DIR, "spa_loop.mp3")
    size = encode_mp3(music_path, music, bitrate=128)
    total += size
    peak = 20 * np.log10(max(float(np.max(np.abs(music))), 1e-9))
    rms = 20 * np.log10(max(float(np.sqrt(np.mean(music**2))), 1e-9))
    print(f"{music_path:38s} {len(music)/SR:8.2f} {peak:10.1f} {rms:9.1f} {size/1024:7.1f}")

    print("-" * 78)
    print(f"total: {total/1024:.0f} KB")


if __name__ == "__main__":
    main()
