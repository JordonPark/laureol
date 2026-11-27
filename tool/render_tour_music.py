"""Render the tour's original 120 BPM arrangements as offline MP3 assets.

Install NumPy and either FFmpeg with libmp3lame or the imageio-ffmpeg wheel.
Run from the repository root with python tool/render_tour_music.py.
"""

import argparse
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import shutil
import subprocess

import numpy as np

from tour_music_scores import SCORES


RATE = 44100
STEP = RATE * 60 / (120 * 4)
END = 92.5
CHORUS_BARS = (12, 26, 40)
SCALES = {
    "major": (0, 2, 4, 5, 7, 9, 11),
    "minor": (0, 2, 3, 5, 7, 8, 10),
    "dorian": (0, 2, 3, 5, 7, 9, 10),
    "mixolydian": (0, 2, 4, 5, 7, 9, 10),
}


@dataclass(frozen=True)
class Style:
    chords: str
    bass: str
    kicks: tuple[int, ...]
    backbeat: tuple[int, ...]
    hats: tuple[int, ...]
    snare: str
    swing: float
    air: str


STYLES = {
    "alley": Style("keys", "round", (0, 6, 10), (4, 12), (2, 6, 10, 14), "rim", .018, "wood"),
    "coast": Style("guitar", "round", (0, 5, 8, 11), (4, 12), (2, 4, 6, 10, 14), "rim", .011, "surf"),
    "forest": Style("guitar", "round", (0, 8), (4, 12), (3, 7, 11, 15), "wood", .021, "leaves"),
    "metro": Style("pad", "synthBass", (0, 4, 8, 12), (4, 12), (2, 6, 10, 14), "snap", 0, "glint"),
    "hall": Style("keys", "picked", (0, 3, 8, 10), (4, 12), (0, 4, 7, 8, 12, 15), "snap", .012, "wood"),
    "festival": Style("brass", "picked", (0, 4, 7, 8, 12, 15), (4, 12, 14), (2, 5, 6, 10, 13, 14), "tom", .009, "glint"),
    "river": Style("keys", "round", (0, 8, 13), (4, 12), (2, 6, 9, 14), "rim", .019, "surf"),
    "winter": Style("pad", "round", (0, 6, 8), (4, 12), (2, 6, 10, 13, 14), "snap", .006, "frost"),
}
VOICINGS = (
    ((0, 0, 1.8), (7, 2, 1.2), (10, 0, 1.3), (14, 4, .8)),
    ((0, 0, 1.4), (4, 0, .8), (8, 2, 1.2), (11, 4, .7), (14, 0, .7)),
    ((0, 0, 2.2), (9, 2, 1.2), (13, 0, 1.0)),
)
LEAD_RHYTHMS = (
    ((0, .85), (4, .50), (7, .75), (12, .94)),
    ((0, .58), (3, .78), (8, .60), (11, 1.06)),
    ((0, 1.05), (6, .47), (9, .44), (12, .90)),
)


def pitch(song, degree):
    octave, scale_step = divmod(degree, 7)
    return song.key + 12 * octave + SCALES[song.mode][scale_step]


def oscillator(phase, partials, frequency):
    result = np.zeros_like(phase)
    for harmonic, strength in partials:
        if frequency * harmonic < RATE * .46:
            result += strength * np.sin(phase * harmonic)
    return result


@lru_cache(maxsize=192)
def note(voice, midi, length_ms):
    duration = length_ms / 1000
    release = .15 if voice in ("pad", "bell", "keys", "reed") else .07
    t = np.arange(int((duration + release) * RATE), dtype=np.float32) / RATE
    frequency = 440 * 2 ** ((midi - 69) / 12)
    phase = 2 * np.pi * frequency * t
    attack = .010
    match voice:
        case "marimba":
            x = .84 * np.sin(phase) * np.exp(-t * 4.1) + .15 * np.sin(phase * 3.99) * np.exp(-t * 20)
            attack = .002
        case "bell":
            x = oscillator(phase, ((1, .68), (2.01, .22), (2.72, .09), (4.07, .035)), frequency)
            x *= np.exp(-t * 2.4)
            attack = .002
        case "guitar" | "picked":
            x = oscillator(phase, ((1, .66), (2, .25), (3, .16), (4, .10), (6, .045)), frequency)
            x *= np.exp(-t * (3.8 if voice == "guitar" else 2.1))
            x += .10 * np.sin(phase * .997) * np.exp(-t * 5)
            attack = .004
        case "keys":
            x = .75 * np.sin(phase + np.exp(-t * 6) * .85 * np.sin(phase * 2)) + .15 * np.sin(phase * 2.003)
            x *= np.exp(-t * 2.2)
            attack = .004
        case "reed":
            phase += .18 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 5, 0, 1)
            x = oscillator(phase, ((1, .76), (2, .21), (3, .13), (5, .035)), frequency)
            attack = .034
        case "brass":
            x = oscillator(phase, ((1, .62), (2, .27), (3, .16), (4, .08), (5, .04)), frequency)
            x *= .76 + .24 * np.exp(-t * 5)
            attack = .019
        case "chip":
            x = oscillator(phase, ((1, .70), (3, .25), (5, .11), (7, .060), (9, .027)), frequency)
            x *= 1 - .12 * (1 - np.exp(-t * 6))
            attack = .003
        case "pad" | "synth" | "synthBass":
            x = oscillator(phase, ((1, .62), (2, .18), (3, .10), (4, .069), (5, .043)), frequency)
            x += .27 * np.sin(phase * 1.003) + .09 * np.sin(phase * .997 * 3)
            attack = .070 if voice == "pad" else .007
        case "round":
            x = .91 * np.sin(phase) + .28 * np.sin(phase * 2) + .085 * np.sin(phase * 3)
        case _:
            raise ValueError(voice)
    x *= np.minimum(t / attack, 1)
    x *= np.clip((duration + release - t) / release, 0, 1) ** 2
    return x.astype(np.float32, copy=False)


@lru_cache(maxsize=24)
def percussion(kind):
    duration = .68 if kind in ("downbeat", "surf", "frost", "leaves", "glint") else .23
    t = np.arange(int(RATE * duration), dtype=np.float32) / RATE
    seed = sum(ord(char) * (index + 1) for index, char in enumerate(kind))
    noise = np.random.default_rng(seed).standard_normal(len(t), dtype=np.float32)
    low = np.convolve(noise, np.ones(27, dtype=np.float32) / 27, mode="same")
    high = noise - np.roll(noise, 2)
    match kind:
        case "kick" | "downbeat":
            frequency = 50 * t + 108 * .020 * (1 - np.exp(-t / .020))
            body = np.sin(2 * np.pi * frequency) * np.exp(-t * 14)
            strike = .13 * np.exp(-t * 155) * high + .12 * np.sin(2 * np.pi * 196 * t) * np.exp(-t * 45)
            x = body + strike
            if kind == "downbeat":
                x += .09 * high * np.exp(-t * 9)
        case "rim":
            x = (.42 * np.sin(2 * np.pi * 460 * t) + .35 * np.sin(2 * np.pi * 612 * t) + .27 * noise) * np.exp(-t * 35)
        case "snap":
            x = (.55 * noise + .22 * np.sin(2 * np.pi * 194 * t) * np.exp(-t * 24)) * np.exp(-t * 18)
        case "hat":
            x = .32 * high * np.exp(-t * 53)
        case "wood" | "tom":
            frequency = (150 if kind == "wood" else 92) * t + .8 * (1 - np.exp(-t * 28))
            x = (.72 * np.sin(2 * np.pi * frequency) + .17 * noise) * np.exp(-t * 23)
        case "surf":
            x = low * np.sin(np.pi * np.minimum(t / duration, 1)) ** 2
        case "leaves":
            x = high * .22 * np.sin(np.pi * np.minimum(t / duration, 1)) ** 2
        case "frost" | "glint":
            x = oscillator(2 * np.pi * 510 * t, ((1, .26), (2.81, .23), (3.63, .12)), 510)
            x *= np.exp(-t * 6)
        case _:
            raise ValueError(kind)
    return x.astype(np.float32, copy=False) * np.minimum(1, t * 800)


def mix(bus, sample, sound, gain, pan=0):
    index = max(0, round(sample))
    end = min(index + len(sound), len(bus))
    if end <= index:
        return
    signal = sound[: end - index] * gain
    bus[index:end, 0] += signal * np.sqrt(.5 - pan * .5)
    bus[index:end, 1] += signal * np.sqrt(.5 + pan * .5)


def render(region, song):
    style = STYLES[region]
    bus = np.zeros((round(RATE * END), 2), dtype=np.float32)
    for bar in range(46):
        chorus = next((number for number, start in enumerate(CHORUS_BARS) if start <= bar < start + 5), None)
        soundcheck = bar in (10, 11, 23, 24, 25, 37, 38, 39)
        pickup = bar in (11, 25, 39)
        outro = bar == 45
        active = chorus is not None
        first_beat = bar * 16 * STEP
        chord = 0 if outro or bar in (16, 30, 44) else song.chords[bar % 4] - 1
        velocity = .74 if soundcheck else (1.13 if active else .93)

        def beat(step, straight=False):
            offset = style.swing * RATE if step % 2 and not straight else 0
            return first_beat + step * STEP + offset

        kicks = (0, 8) if soundcheck or outro else style.kicks
        if song.groove == 1 and not soundcheck and not outro and region != "metro":
            kicks = tuple(sorted({*kicks, (10 if bar % 2 else 14)}))
        for step in kicks:
            emphasized = bar in CHORUS_BARS and step == 0
            mix(bus, beat(step, True), percussion("downbeat" if emphasized else "kick"), velocity * (.46 if emphasized else .27))
        if not outro:
            for step in style.backbeat:
                if not soundcheck or step == 12:
                    mix(bus, beat(step, True), percussion(style.snare), velocity * .24, .07)
            if not soundcheck:
                for step in style.hats:
                    mix(bus, beat(step), percussion("hat"), velocity * (.14 if step % 4 == 2 else .09), -.20 if step % 2 else .23)
        if pickup:
            for step in (12, 14, 15):
                mix(bus, beat(step), percussion("tom"), .11 + (step - 12) * .027, (step - 13) / 8)
        if bar % 4 == song.groove or bar in CHORUS_BARS:
            mix(bus, beat(0), percussion(style.air), .14 if active else .10, -.30)

        bass_part = ((0, 0, 2.0),) if soundcheck or outro else VOICINGS[song.groove]
        for step, relative, beats in bass_part:
            mix(bus, beat(step), note(style.bass, pitch(song, chord + relative - 14), round(beats * 500)), .29 * velocity)

        chord_degrees = (chord, chord + 2, chord + 4)
        if active or region in ("hall", "river", "winter"):
            chord_degrees += (chord + 6,)
        if style.chords == "pad":
            chord_steps, chord_ms = (0,), 1650
        elif region in ("coast", "forest"):
            chord_steps, chord_ms = (0, 7, 12), (620 if active else 460)
        else:
            chord_steps, chord_ms = ((2, 8, 14) if active else (0, 9)), 380
        for step in ((0,) if soundcheck or outro else chord_steps):
            for i, degree in enumerate(chord_degrees):
                pan = (-.36, .26, -.13, .40)[i]
                offset = i * .013 * RATE if style.chords == "guitar" else 0
                mix(bus, beat(step) + offset, note(style.chords, pitch(song, degree), chord_ms), velocity * (.108 if active else .082), pan)

        if outro:
            mix(bus, first_beat, note(song.lead, pitch(song, 0), 1500), .30)
            continue
        if soundcheck or (bar < 2 and region in ("forest", "river", "winter")):
            mix(bus, beat(0), note(song.lead, pitch(song, chord + 4), 330), .12, -.18)
            continue
        if not active and bar % 4 in (2, 3):
            idx = (bar + song.groove) % 8
            mix(bus, beat(8), note(song.lead, pitch(song, song.hook[idx]), 420), .18, .10)
            if bar % 4 == 3:
                mix(bus, beat(13), note(song.lead, pitch(song, song.hook[idx - 1]), 220), .13, -.20)
            continue

        local = bar - CHORUS_BARS[chorus] if active else bar % 4
        rhythm = LEAD_RHYTHMS[(song.groove + (1 if local == 3 else 0)) % 3]
        for index, (step, duration) in enumerate(rhythm):
            degree = song.hook[(local * 4 + index) % 8]
            if local == 4:
                degree = (4, 2, 1, 0)[index]
            elif local == 2 and index >= 2:
                degree += 2
            if not active and index == 2:
                continue
            position = beat(step)
            lead = note(song.lead, pitch(song, degree), round(duration * 500))
            mix(bus, position, lead, .37 if active else .25, -.13 if bar % 2 else .10)
            if active:
                mix(bus, position + .188 * RATE, lead, .075, .44)
                if chorus >= 1 and (index == 0 or index == 3):
                    mix(bus, position, note(style.chords, pitch(song, degree + (2 if chorus == 1 else 7)), 440), .12, -.33)

    last = round(90 * RATE)
    bus[last:] *= np.linspace(1, 0, len(bus) - last, dtype=np.float32)[:, None]
    rms = np.sqrt(np.mean(bus ** 2))
    bus *= .149 / rms
    bus = np.tanh(bus * 1.2) / np.tanh(1.2) * .86
    return np.rint(bus * 32767).astype("<i2", copy=False)


def encode(job):
    encoder, directory, region, song = job
    path = directory / (song.slug + ".mp3")
    pcm = render(region, song)
    temporary = path.with_suffix(".new.mp3")
    command = (
        encoder, "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
        "-f", "s16le", "-ar", str(RATE), "-ac", "2", "-i", "pipe:0",
        "-c:a", "libmp3lame", "-b:a", "96k", "-map_metadata", "-1",
        "-metadata", "title=" + song.title, "-metadata", "album=Laureol Offline Tour",
        "-id3v2_version", "3", str(temporary),
    )
    try:
        subprocess.run(command, input=pcm.tobytes(), check=True)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)
    return song.slug


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("assets/audio/map"))
    parser.add_argument("--track", action="append", help="Render only this venue slug. Repeat for more.")
    parser.add_argument("--jobs", type=int, default=4)
    options = parser.parse_args()
    encoder = shutil.which("ffmpeg")
    if encoder is None:
        from imageio_ffmpeg import get_ffmpeg_exe
        encoder = get_ffmpeg_exe()
    known = {song.slug for songs in SCORES.values() for song in songs}
    requested = set(options.track) if options.track else known
    if requested - known:
        parser.error("Unknown venue slugs: " + ", ".join(sorted(requested - known)))
    options.output.mkdir(parents=True, exist_ok=True)
    jobs = [(encoder, options.output, region, song) for region, songs in SCORES.items() for song in songs if song.slug in requested]
    with ProcessPoolExecutor(max_workers=options.jobs) as pool:
        for slug in pool.map(encode, jobs):
            print(slug, flush=True)


if __name__ == "__main__":
    main()
