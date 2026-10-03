#!/usr/bin/env python3
"""Install pinned Godot and official CLI tools to an external personal tools folder."""
import argparse
import json
import os
import shutil
import subprocess
import tarfile
import urllib.request
import zipfile
from pathlib import Path

def fetch(url, path):
    """Download an official archive only when the external cache is absent."""
    if not path.exists():
        print('Downloading', path.name, flush=True)
        temporary=path.with_name(path.name+'.part')
        with urllib.request.urlopen(url, timeout=120) as r, temporary.open('wb') as out:
            shutil.copyfileobj(r, out)
        temporary.replace(path)

def main():
    """Install pinned official tools and export templates outside source."""
    p = argparse.ArgumentParser()
    p.add_argument('--root', type=Path, required=True)
    a = p.parse_args()
    root = a.root.expanduser().resolve()
    root.mkdir(parents=True, exist_ok=True)
    fetch('https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_macos.universal.zip', root / 'godot.zip')
    subprocess.run(['ditto', '-xk', str(root / 'godot.zip'), str(root)], check=True)
    godot = root / 'Godot.app/Contents/MacOS/Godot'
    godot.chmod(0o755)
    print(subprocess.check_output([str(godot), '--version'], text=True).strip())
    fetch('https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz', root / 'templates.tpz')
    templates = Path.home() / 'Library/Application Support/Godot/export_templates/4.7.2.stable'
    templates.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(root / 'templates.tpz') as z:
        for name in z.namelist():
            if name.startswith('templates/') and not name.endswith('/'):
                (templates / Path(name).name).write_bytes(z.read(name))
    for repo, match, executable in [('cli/cli', 'macOS_arm64.zip', 'gh'), ('git-lfs/git-lfs', 'darwin-arm64', 'git-lfs')]:
        request = urllib.request.Request('https://api.github.com/repos/' + repo + '/releases/latest', headers={'User-Agent':'ZombieSlop-setup'})
        data = json.load(urllib.request.urlopen(request, timeout=60))
        asset = next(x for x in data['assets'] if match in x['name'] and not 'sha256' in x['name'])
        path = root / asset['name']
        fetch(asset['browser_download_url'], path)
        unpack = root / executable
        unpack.mkdir(exist_ok=True)
        if zipfile.is_zipfile(path):
            with zipfile.ZipFile(path) as z:
                z.extractall(unpack)
        else:
            with tarfile.open(path) as t:
                # Official archives only; no shell installers.
                t.extractall(unpack)
        binary = next(x for x in unpack.rglob(executable) if x.is_file())
        binary.chmod(0o755)
        print(executable, data['tag_name'], binary, flush=True)

if __name__ == '__main__':
    main()
