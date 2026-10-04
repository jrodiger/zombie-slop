#!/usr/bin/env python3
"""Keep the CC0 recordings pristine; checkpoint mono runtime derivatives privately."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path
from prepare_audio import read_clip, write_clip, RATE


def main():
    """Preflight pristine recordings, protect their checkpoint and export verified clips."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--home', type=Path, default=Path.home() / 'Documents/ZombieSlop')
    parser.add_argument('--assets', type=Path, required=True)
    parser.add_argument('--export-only', action='store_true')
    args = parser.parse_args()
    home, private = args.home.resolve(), args.assets.resolve()
    public = Path(__file__).resolve().parents[1]
    if any(path == public or public in path.parents for path in (home, private)):
        raise SystemExit('Audio must remain outside public source.')
    if home == private or private in home.parents:
        raise SystemExit('Exports must remain outside the private checkout.')
    target = private / 'neighborhood/audio'
    target.mkdir(parents=True, exist_ok=True)
    manifest = target / 'zombie-audio.json'
    if not args.export_only:
        if manifest.exists() or any(target.glob('zombie-growl-*.wav')):
            raise SystemExit('Existing zombie audio checkpoint protected; use --export-only.')
        sources = [home / 'downloads/zombie-audio/extracted/zombies' / f'zombie-{n}.wav'
                   for n in (16, 17, 21)]
        missing = [str(source) for source in sources if not source.is_file()]
        if missing:
            raise SystemExit('Missing zombie source recordings: ' + ', '.join(missing))
        # Decode every input before creating a checkpoint so a bad later source
        # cannot strand earlier derivatives without their manifest.
        clips = [(source, read_clip(source), hashlib.sha256(source.read_bytes()).hexdigest())
                 for source in sources]
        effects = {}
        for index, (source, clip, source_hash) in enumerate(clips):
            name = f'zombie-growl-{index}'
            write_clip(target / (name + '.wav'), clip, .65)
            effects[name] = {'source': source.name,
                             'source_sha256': source_hash,
                             'sha256': hashlib.sha256((target / (name + '.wav')).read_bytes()).hexdigest()}
        manifest.write_text(json.dumps({'author': 'artisticdude', 'license': 'CC0',
            'url': 'https://opengameart.org/content/zombies-sound-pack',
            'rate': RATE, 'channels': 1, 'effects': effects}, indent=2) + '\n')
    if not manifest.is_file():
        raise SystemExit('Missing zombie audio manifest; restore the matching private checkpoint before export-only.')
    recipe = json.loads(manifest.read_text())
    if set(recipe['effects']) != {f'zombie-growl-{index}' for index in range(3)}:
        raise SystemExit('Zombie audio checkpoint is incomplete; restore all three recorded effects.')
    exports = home / 'generated'
    exports.mkdir(parents=True, exist_ok=True)
    for name, entry in recipe['effects'].items():
        source = target / (name + '.wav')
        if hashlib.sha256(source.read_bytes()).hexdigest() != entry['sha256']:
            raise SystemExit('Zombie audio checkpoint hash mismatch: ' + name)
        shutil.copy2(source, exports / source.name)
    shutil.copy2(manifest, exports / manifest.name)
    print('Exported', len(recipe['effects']), 'private recorded zombie sounds.')


if __name__ == '__main__':
    main()
