#!/usr/bin/env python3
"""Prepare recorded CC0 effects and a quiet wind bed in the private asset checkout."""
import argparse
import array
import hashlib
import json
import math
import random
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

RATE = 44100


def read_clip(path):
    """Decode a source through macOS AudioConverter without changing the source."""
    if path.suffix == '.ogg':
        import aud
        return aud.Sound(str(path)).rechannel(1).resample(RATE, 1).data().reshape(-1).tolist()
    with tempfile.TemporaryDirectory(prefix='zombie-audio-') as tmp:
        output = Path(tmp) / 'decoded.wav'
        subprocess.run(['/usr/bin/afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '1',
                        str(path), str(output)], check=True)
        with wave.open(str(output)) as f:
            assert f.getnchannels() == 1 and f.getsampwidth() == 2 and f.getframerate() == RATE
            return [v / 32768 for v in array.array('h', f.readframes(f.getnframes()))]


def write_clip(path, values, peak=.65):
    """Remove DC, normalize below clipping, and fade the cut edges."""
    mean = sum(values) / len(values)
    values = [v - mean for v in values]
    gain = peak / max(.0001, max(abs(v) for v in values))
    fade = min(220, len(values) // 4)
    pcm = array.array('h')
    for i, v in enumerate(values):
        envelope = min(1, i / fade, (len(values) - 1 - i) / fade)
        pcm.append(round(max(-.99, min(.99, v * gain * envelope)) * 32767))
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())


def main():
    """Create private derivatives once, or copy an unchanged audio checkpoint."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--home', type=Path, default=Path.home() / 'Documents/ZombieSlop')
    parser.add_argument('--assets', type=Path, required=True)
    parser.add_argument('--export-only', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else None)
    home, private = args.home.resolve(), args.assets.resolve()
    public = Path(__file__).resolve().parents[1]
    for folder in (home, private):
        if folder == public or public in folder.parents:
            raise SystemExit('Audio must remain outside public source.')
    if home == private or private in home.parents:
        raise SystemExit('Exports must remain outside the private checkout.')
    target = private / 'neighborhood/audio'
    exports = home / 'generated'
    sources = home / 'downloads/audio'
    target.mkdir(parents=True, exist_ok=True)
    records = {}
    if not args.export_only:
        if (target / 'audio_recipe.json').exists():
            raise SystemExit('Existing audio checkpoint protected; use --export-only.')
        for gun, length in [('pistol', .65), ('rifle', .75), ('shotgun', .85)]:
            source = sources / (gun + '-original.wav')
            values = read_clip(source)
            threshold = max(abs(v) for v in values) * .30
            onset = next(i for i, v in enumerate(values) if abs(v) > threshold)
            start = max(0, onset - int(RATE * .015))
            write_clip(target / ('shot-' + gun + '.wav'), values[start:start + int(RATE * length)])
            name = 'reload-' + gun
            reload_source = sources / (gun + '-reload.wav')
            write_clip(target / (name + '.wav'), read_clip(reload_source), .38)
            records['shot-' + gun] = {'source': source.name, 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'onset_frame': onset, 'length_seconds': length}
            records[name] = {'source': reload_source.name, 'source_sha256': hashlib.sha256(reload_source.read_bytes()).hexdigest()}
        effects = {'pickup': 'impactSoft_medium_000', 'hurt': 'impactSoft_heavy_000',
                   'build': 'impactWood_medium_000', 'search': 'impactWood_light_002',
                   'door': 'impactWood_heavy_000', 'ui': 'impactGeneric_light_000'}
        for ground, filename in [('grass', 'grass'), ('wood', 'wood'), ('road', 'concrete')]:
            for index in range(3):
                effects['step-' + ground + ('' if index == 0 else '-' + str(index))] = 'footstep_' + filename + '_00' + str(index)
        for name, stem in effects.items():
            source = sources / 'impact/Audio' / (stem + '.ogg')
            write_clip(target / (name + '.wav'), read_clip(source), .32 if name.startswith('step') else .42)
            records[name] = {'source': str(source.relative_to(sources)), 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
        # Low, slowly varying noise rather than the former audible pitched hum.
        rng = random.Random(4815)
        count = RATE * 24
        values, wind = [], 0.0
        for i in range(count):
            wind = .996 * wind + rng.uniform(-1, 1) * .004
            values.append(wind * (.7 + .15 * math.sin(i / RATE * .21)))
        crossfade = RATE
        for i in range(crossfade):
            amount = i / crossfade
            values[i] = values[i] * amount + values[-crossfade + i] * (1 - amount)
        write_clip(target / 'ambient.wav', values, .045)
        records['ambient'] = {'source': 'original filtered noise', 'seed': 4815}
        for alias, name in [('shot', 'shot-pistol'), ('reload', 'reload-pistol'), ('step', 'step-grass')]:
            shutil.copy2(target / (name + '.wav'), target / (alias + '.wav'))
            records[alias] = {'alias': name}
        for name in records:
            records[name]['sha256'] = hashlib.sha256((target / (name + '.wav')).read_bytes()).hexdigest()
        (target / 'audio_recipe.json').write_text(json.dumps({'rate': RATE, 'channels': 1, 'effects': records}, indent=2) + '\n')
    recipe = json.loads((target / 'audio_recipe.json').read_text())
    exports.mkdir(parents=True, exist_ok=True)
    for name, entry in recipe['effects'].items():
        source = target / (name + '.wav')
        if hashlib.sha256(source.read_bytes()).hexdigest() != entry['sha256']:
            raise SystemExit('Audio checkpoint hash mismatch: ' + name)
        shutil.copy2(source, exports / source.name)
    shutil.copy2(target / 'audio_recipe.json', exports / 'audio_recipe.json')
    print('Exported', len(recipe['effects']), 'private audio clips.')


if __name__ == '__main__':
    main()
