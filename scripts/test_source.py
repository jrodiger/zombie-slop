#!/usr/bin/env python3
import argparse,os,shutil,subprocess,tempfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT','godot'));a=p.parse_args()
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='zombie-slop-tests-') as folder:
 root=Path(folder)
 for name in ['game','tests']:shutil.copytree(source/name,root/name)
 (root/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Zombie Slop CI"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
 for script in ['game/game.gd','tests/integration.gd','tests/benchmark.gd','tests/inspection.gd','tests/expansion.gd','tests/district.gd','tests/polish.gd','tests/devices.gd']:
  result=subprocess.run([a.godot,'--headless','--path',folder,'--check-only','--script','res://'+script],check=False,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
  print(result.stdout,end='')
  # Godot can return zero even when --check-only reports a parse error.
  if result.returncode!=0 or 'SCRIPT ERROR:' in result.stdout or 'ERROR:' in result.stdout:raise SystemExit('Godot script check failed: '+script)
 subprocess.run([a.godot,'--headless','--path',folder,'--script','res://tests/state_test.gd'],check=True)
subprocess.run(['python3',str(source/'scripts/check_source.py')],check=True)
subprocess.run(['python3',str(source/'tests/audio_preflight.py')],check=True)
