"""Render the offline call cue with eSpeak NG 1.52.0 and the game script."""

import argparse
from array import array
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import wave


OUTPUT_RATE = 44_100
CUE_SECONDS = 0.777
REPO = Path(__file__).resolve().parents[1]


def synthesize(executable: Path, data_path: Path | None) -> array:
    with TemporaryDirectory() as folder:
        script = Path(folder) / 'call.txt'
        script.write_text('라우럴!', encoding='utf-8')
        output = Path(folder) / 'call.wav'
        command = [str(executable)]
        if data_path is not None:
            command.append(f'--path={data_path}')
        command.extend(['-v', 'ko', '-s', '152', '-p', '61', '-a', '100',
                        '-z', '-b', '1', '-w', str(output), '-f', str(script)])
        subprocess.run(command, check=True)
        with wave.open(str(output), 'rb') as voice:
            if (voice.getnchannels(), voice.getsampwidth(), voice.getframerate()) != (1, 2, 22_050):
                raise ValueError('Expected 22.05 kHz signed 16-bit mono output from eSpeak NG')
            samples = array('h', voice.readframes(voice.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    return samples


def mix(samples: array) -> array:
    dry = []
    for previous, following in zip(samples, samples[1:]):
        dry += [previous, (previous + following) / 2]
    frames = round(OUTPUT_RATE * CUE_SECONDS)
    if not dry or len(dry) > frames:
        raise ValueError('The call must fit the existing cue duration')
    peak = max(map(abs, dry))
    if peak == 0:
        raise ValueError('eSpeak NG produced a silent cue')
    dry.extend([0] * (frames - len(dry)))
    wet = (round(OUTPUT_RATE * .033), round(OUTPUT_RATE * .049))
    gain = 32767 * .84 / (peak * 1.16)
    stereo = array('h')
    for index, direct in enumerate(dry):
        fade = min(1., index / 180, (frames - 1 - index) / 450)
        for delay in wet:
            echo = dry[index - delay] if index >= delay else 0
            stereo.append(round((direct + .16 * echo) * gain * fade))
    if sys.byteorder != 'little':
        stereo.byteswap()
    return stereo


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--espeak', type=Path, required=True)
    parser.add_argument('--data-path', type=Path, help='Folder containing espeak-ng-data')
    parser.add_argument('--output', type=Path, default=REPO / 'assets/audio/sfx/laureol-call.wav')
    args = parser.parse_args()
    samples = mix(synthesize(args.espeak, args.data_path))
    with wave.open(str(args.output), 'wb') as output:
        output.setparams((2, 2, OUTPUT_RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(samples.tobytes())


if __name__ == '__main__':
    main()
