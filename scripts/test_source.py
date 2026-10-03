#!/usr/bin/env python3
import argparse,os,shutil,subprocess,tempfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT','godot'));a=p.parse_args()
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='zombie-slop-tests-') as folder:
 root=Path(folder)
 for name in ['game','tests']:shutil.copytree(source/name,root/name)
 (root/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Zombie Slop CI"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
 for script in ['game/game.gd','tests/integration.gd','tests/benchmark.gd']:
  subprocess.run([a.godot,'--headless','--path',folder,'--check-only','--script','res://'+script],check=True)
 subprocess.run([a.godot,'--headless','--path',folder,'--script','res://tests/state_test.gd'],check=True)
subprocess.run(['python3',str(source/'scripts/check_source.py')],check=True)
