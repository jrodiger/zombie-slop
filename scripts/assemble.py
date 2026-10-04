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
 neighborhood=exports/'neighborhood-exports.json'
 if not neighborhood.is_file():raise SystemExit('Missing neighborhood exports. Run scripts/prepare_neighborhood_assets.py --export-only.')
 for name,entry in json.loads(neighborhood.read_text())['exports'].items():
  editable=private/entry['source'];output=exports/(name+'.glb')
  if not editable.is_file() or not output.is_file() or hashlib.sha256(editable.read_bytes()).hexdigest()!=entry['source_sha256'] or hashlib.sha256(output.read_bytes()).hexdigest()!=entry['glb_sha256']:raise SystemExit('Stale neighborhood export: '+name)
  shutil.copy2(output,assets/output.name)
 missing=[]
 for name in ['survivor','zombie','plant','radio','guitar','chair','table','shelf','storage','foundation','wall','door','barricade','roof','house','tree','bush','grass','car','pistol','rifle','shotgun']:
  f=exports/(name+'.glb')
  if not f.exists():missing.append(str(f))
  else:shutil.copy2(f,assets/f.name)
 kenney=home/'downloads/suburban/extracted/Models/GLB format'
 # Discard obsolete shells and roadside crates from the disposable runtime.
 for f in list(assets.glob('kenney-*'))+[assets/'crate.glb',assets/'crate.glb.import']:
  if f.is_file():f.unlink()
 recipe=json.loads((private/'neighborhood/audio/audio_recipe.json').read_text())
 for name,entry in recipe['effects'].items():
  f=exports/(name+'.wav')
  editable=private/'neighborhood/audio'/f.name
  if not f.exists() or hashlib.sha256(f.read_bytes()).hexdigest()!=entry['sha256'] or not editable.exists() or hashlib.sha256(editable.read_bytes()).hexdigest()!=entry['sha256']:missing.append(str(f)+' — missing/stale audio checkpoint')
  else:shutil.copy2(f,assets/f.name)
 if (assets/'Textures').exists():shutil.rmtree(assets/'Textures')
 licenses=assets/'licenses';licenses.mkdir(exist_ok=True)
 for f in [home/'downloads/suburban/extracted/License.txt',home/'downloads/suburban/CC0-1.0.txt',private/'README.md',home/'downloads/zombie-apocalypse/extracted/License.txt']:
  if f.exists():shutil.copy2(f,licenses/('kenney-'+f.name if 'suburban' in str(f) else ('quaternius-'+f.name if 'zombie-apocalypse' in str(f) else f.name)))
 for pack in ['nature','survival','ithappy','audio']:
  for f in (home/'downloads'/pack).glob('*license*'):
   if f.is_file():shutil.copy2(f,licenses/(pack+'-'+f.name))
  f=home/'downloads'/pack/'extracted/License.txt'
  if f.exists():shutil.copy2(f,licenses/(pack+'-License.txt'))
 f=home/'downloads/audio/impact/License.txt'
 if f.exists():shutil.copy2(f,licenses/'kenney-impact-License.txt')
 if missing:raise SystemExit('Missing external assets; run documented Blender generation and pack setup:\n'+'\n'.join(missing))
 code=subprocess.check_output(['git','-C',str(SOURCE),'rev-parse','HEAD'],text=True).strip()
 asset=subprocess.check_output(['git','-C',str(private),'rev-parse','HEAD'],text=True).strip()
 (runtime/'assembly.json').write_text(json.dumps({'code_commit':code,'asset_commit':asset},indent=2)+'\n')
 (home/'builds').mkdir(exist_ok=True)
 print('Assembled:',runtime)
if __name__=='__main__':main()
