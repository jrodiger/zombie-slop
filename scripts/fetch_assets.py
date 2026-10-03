#!/usr/bin/env python3
"""Download pristine CC0 packs from their authors; never write assets into source."""
import argparse
import concurrent.futures
import hashlib
import html
import json
import re
import urllib.request
import zipfile
from pathlib import Path

PACKS = {
    'zombie': ('https://quaternius.com/packs/zombieapocalypsekit.html', '1mWP6sCHun7OUMHQeDNZLrXTteXlzWg_t'),
    'survival': ('https://quaternius.com/packs/survival.html', '1NKfC95GMWWJquy6rRzwFVkVDoZ_QP7K_'),
    'nature': ('https://quaternius.com/packs/ultimatenature.html', '1-Kl0L_Jg8awbh0S5T-z3zxh4mVlnxTpa'),
}

def read(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'}), timeout=90).read()

def entries(folder):
    page = read('https://drive.google.com/drive/folders/' + folder).decode()
    result = []
    for row in re.findall(r'<tr data-selectable.*?</tr>', page, re.S):
        ident = re.search(r'data-id="([^"]+)"', row).group(1)
        name = re.search(r'<strong[^>]*>(.*?)</strong>', row, re.S)
        if name:
            result.append((ident, html.unescape(re.sub('<[^>]+>', '', name.group(1))), 'Shared folder' in row))
    return result

def collect(folder, prefix=Path()):
    files = []
    for ident, name, is_folder in entries(folder):
        print('Inspect', prefix / name, flush=True)
        if is_folder:
            # Prefer explicit glTF; retain editable Blend and OBJ for older packs.
            if name.lower() not in ('fbx', 'textures', 'obj') or 'gltf' not in [x[1].lower() for x in entries(folder)]:
                files += collect(ident, prefix / name)
        elif Path(name).suffix.lower() in ('.glb', '.gltf', '.bin', '.blend', '.png', '.jpg', '.mtl', '.obj', '.txt', '.md', '.pdf', '.zip'):
            files.append((ident, prefix / name))
    return files

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--originals', type=Path, required=True)
    parser.add_argument('--pack', choices=list(PACKS) + ['suburban', 'all'], default='all')
    args = parser.parse_args()
    root = args.originals.expanduser().resolve()
    source = Path(__file__).resolve().parents[1]
    if root == source or source in root.parents:
        raise SystemExit('Assets must be outside the code checkout.')
    root.mkdir(parents=True, exist_ok=True)
    names = list(PACKS) + ['suburban'] if args.pack == 'all' else [args.pack]
    for pack in names:
        dest = root / pack
        dest.mkdir(exist_ok=True)
        records = []
        if pack == 'suburban':
            url = 'https://kenney.nl/media/pages/assets/city-kit-suburban/2c871b7af2-1745479373/kenney_city-kit-suburban_20.zip'
            archive = dest / 'kenney_city-kit-suburban_20.zip'
            if not archive.exists():
                archive.write_bytes(read(url))
            with zipfile.ZipFile(archive) as z:
                for info in z.infolist():
                    target = (dest / 'extracted' / info.filename).resolve()
                    if not target.is_relative_to((dest / 'extracted').resolve()):
                        raise ValueError('Unsafe archive path')
                z.extractall(dest / 'extracted')
            records.append({'file': archive.name, 'url': url, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest()})
            source_url = 'https://kenney.nl/assets/city-kit-suburban'
        else:
            source_url, folder = PACKS[pack]
            files = collect(folder)
            def download(entry):
                ident, rel = entry
                path = dest / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                url = 'https://drive.usercontent.google.com/download?id=' + ident + '&export=download&confirm=t'
                if not path.exists():
                    data = read(url)
                    if data[:100].lower().find(b'<html') >= 0 or data[:100].lower().find(b'<!doctype') >= 0:
                        raise ValueError('Download returned HTML: ' + str(rel))
                    path.write_bytes(data)
                print('Ready', pack, rel, flush=True)
                return {'file': str(rel), 'url': url, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
            with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
                records = list(pool.map(download, files))
        # Preserve full license, also alongside selected runtime files in assemble.py.
        license_url = 'https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt'
        (dest / 'CC0-1.0.txt').write_bytes(read(license_url))
        (dest / 'SOURCE.json').write_text(json.dumps({'source': source_url, 'license': license_url, 'files': records}, indent=2) + '\n')
        print('Complete', pack, len(records), flush=True)

if __name__ == '__main__':
    main()
