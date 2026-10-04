#!/usr/bin/env python3
"""Synchronize source and selected external assets into a disposable runnable workspace."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
SOURCE=Path(__file__).resolve().parents[1]
def outside(path,checkouts):
 """Reject output folders located within either protected checkout."""
 for base in checkouts:
  if path==base or base in path.parents:raise ValueError('Runtime and outputs must be outside both checkouts.')
def main():
 """Validate external inputs and assemble a disposable Godot workspace."""
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
 report=exports/'quaternius-exports.json'
 if not report.is_file():raise SystemExit('Missing Quaternius exports. Run scripts/adapt_quaternius.py --export-only as documented in docs/SETUP.md.')
 recorded=json.loads(report.read_text()).get('exports',{})
 for name in ['survivor','zombie','pistol','rifle','shotgun','car','storage']:
  editable=private/'quaternius'/(name+'.blend');output=exports/(name+'.glb');entry=recorded.get(name,{})
  if not editable.is_file() or not output.is_file() or hashlib.sha256(editable.read_bytes()).hexdigest()!=entry.get('source_sha256') or hashlib.sha256(output.read_bytes()).hexdigest()!=entry.get('glb_sha256'):
   raise SystemExit('Missing/stale Quaternius export: '+name+'. Re-export the matching private checkpoint with scripts/adapt_quaternius.py --export-only.')
 missing=[]
 for name in ['survivor','zombie','plant','radio','guitar','chair','table','shelf','storage','foundation','wall','door','barricade','roof','house','tree','bush','grass','car','pistol','rifle','shotgun','crate']:
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
 for f in [home/'downloads/suburban/extracted/License.txt',home/'downloads/suburban/CC0-1.0.txt',private/'README.md',home/'downloads/zombie-apocalypse/extracted/License.txt']:
  if f.exists():shutil.copy2(f,licenses/('kenney-'+f.name if 'suburban' in str(f) else ('quaternius-'+f.name if 'zombie-apocalypse' in str(f) else f.name)))
 if missing:raise SystemExit('Missing external assets; run documented Blender generation and pack setup:\n'+'\n'.join(missing))
 code=subprocess.check_output(['git','-C',str(SOURCE),'rev-parse','HEAD'],text=True).strip()
 asset=subprocess.check_output(['git','-C',str(private),'rev-parse','HEAD'],text=True).strip()
 (runtime/'assembly.json').write_text(json.dumps({'code_commit':code,'asset_commit':asset},indent=2)+'\n')
 (home/'builds').mkdir(exist_ok=True)
 print('Assembled:',runtime)
if __name__=='__main__':main()
