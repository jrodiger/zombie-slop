#!/usr/bin/env python3
"""Synchronize source and selected external assets into a disposable runnable workspace."""
import argparse,json,shutil,subprocess
from pathlib import Path
SOURCE=Path(__file__).resolve().parents[1]
def outside(path,checkouts):
 for base in checkouts:
  if path==base or base in path.parents:raise ValueError('Runtime and outputs must be outside both checkouts.')
def main():
 p=argparse.ArgumentParser();p.add_argument('--assets',type=Path,default=SOURCE.parent/'zombie-slop-assets');p.add_argument('--home',type=Path,default=Path.home()/'Documents/ZombieSlop');a=p.parse_args()
 home=a.home.expanduser().resolve();private=a.assets.expanduser().resolve();runtime=home/'workspace';outside(home,[SOURCE,private]);outside(private,[SOURCE]);runtime.mkdir(parents=True,exist_ok=True)
 for name in ['game','tests']:
  dest=runtime/name
  uids={str(f.relative_to(dest)):f.read_bytes() for f in dest.rglob("*.uid")} if dest.exists() else {}
  if dest.exists():shutil.rmtree(dest)
  shutil.copytree(SOURCE/name,dest)
  for rel,data in uids.items():
   target=dest/rel
   if target.with_suffix("").exists():target.write_bytes(data)
 for name in ['project.godot','export_presets.cfg']:
  if (SOURCE/name).exists():shutil.copy2(SOURCE/name,runtime/name)
 assets=runtime/'assets';assets.mkdir(exist_ok=True)
 exports=home/'generated'
 missing=[]
 for name in ['survivor','zombie','plant','radio','guitar','chair','table','shelf','storage','foundation','wall','door','barricade','roof','house','tree','bush','grass','car','pistol','crate']:
  f=exports/(name+'.glb')
  if not f.exists():missing.append(str(f))
  else:shutil.copy2(f,assets/f.name)
 kenney=home/'downloads/suburban/extracted/Models/GLB format'
 for name in ['building-type-a','building-type-c','building-type-e','building-type-h','building-type-k','building-type-n','fence','tree-large','planter']:
  f=kenney/(name+'.glb')
  if not f.exists():missing.append(str(f)+' — https://kenney.nl/assets/city-kit-suburban')
  else:shutil.copy2(f,assets/('kenney-'+f.name))
 for name in ['shot','reload','pickup','hurt','ambient','step','build']:
  f=exports/(name+'.wav')
  if not f.exists():missing.append(str(f))
  else:shutil.copy2(f,assets/f.name)
 textures=kenney/'Textures'
 if textures.exists():shutil.copytree(textures,assets/'Textures',dirs_exist_ok=True)
 else:missing.append(str(textures))
 licenses=assets/'licenses';licenses.mkdir(exist_ok=True)
 for f in [home/'downloads/suburban/extracted/License.txt',home/'downloads/suburban/CC0-1.0.txt',private/'README.md']:
  if f.exists():shutil.copy2(f,licenses/('kenney-'+f.name if 'suburban' in str(f) else f.name))
 if missing:raise SystemExit('Missing external assets; run documented Blender generation and pack setup:\n'+'\n'.join(missing))
 code=subprocess.check_output(['git','-C',str(SOURCE),'rev-parse','HEAD'],text=True).strip()
 asset=subprocess.check_output(['git','-C',str(private),'rev-parse','HEAD'],text=True).strip()
 (runtime/'assembly.json').write_text(json.dumps({'code_commit':code,'asset_commit':asset},indent=2)+'\n')
 (home/'builds').mkdir(exist_ok=True)
 print('Assembled:',runtime)
if __name__=='__main__':main()
