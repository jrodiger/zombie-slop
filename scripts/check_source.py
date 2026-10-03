#!/usr/bin/env python3
"""Reject assets/caches/credentials in versioned public files before any push."""
import subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
forbidden={'.blend','.blend1','.glb','.gltf','.bin','.fbx','.obj','.mtl','.png','.jpg','.jpeg','.svg','.webp','.wav','.mp3','.ogg','.ttf','.otf','.zip','.tpz','.pck','.mp4','.mov','.tres','.res','.exr','.hdr','.dds','.ico','.icns'}
files=subprocess.check_output(['git','-C',str(root),'ls-files','-z'],text=True).split('\0')
errors=[]
for name in filter(None,files):
 p=Path(name)
 if p.suffix.lower() in forbidden or any(x in p.parts for x in ['assets','.godot','exports','builds','__pycache__']):errors.append(name)
 if p.name in ['.env','credentials','private_key']:errors.append(name)
if errors:raise SystemExit('Forbidden public files:\n'+'\n'.join(errors))
print('Public source audit passed: no tracked assets, caches, exports, or credential files.')
