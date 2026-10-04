"""Missing pack recordings must not leave a protected partial checkpoint."""
import subprocess
import sys
import tempfile
from pathlib import Path

script = Path(__file__).resolve().parents[1] / 'scripts/prepare_zombie_audio.py'
for missing in [(16,), (21,), (17, 21)]:
    with tempfile.TemporaryDirectory(prefix='zombie-audio-preflight-') as folder:
        root = Path(folder)
        home, assets = root / 'home', root / 'assets'
        sources = home / 'downloads/zombie-audio/extracted/zombies'
        sources.mkdir(parents=True)
        # Preflight must precede decoding as well as derivative creation.
        for number in (16, 17, 21):
            if number not in missing:
                (sources / f'zombie-{number}.wav').write_bytes(b'not decoded')
        result = subprocess.run([sys.executable, str(script), '--home', str(home),
                                 '--assets', str(assets)], capture_output=True, text=True)
        assert result.returncode != 0
        assert 'Missing zombie source recordings:' in result.stderr, result.stderr
        for number in missing:
            assert str(sources / f'zombie-{number}.wav') in result.stderr
        assert not list(assets.rglob('*.wav')), 'Partial audio checkpoint created'
        assert not list(assets.rglob('*.json')), 'Partial manifest created'
        assert not (home / 'generated').exists(), 'Partial runtime export created'
print('PASS: 3 missing-recording CLI cases leave no partial checkpoint or export')
