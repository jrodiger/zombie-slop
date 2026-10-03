"""Blender exporter for existing private sources; never saves over editable files."""
import argparse
import hashlib
import runpy
import sys
from pathlib import Path
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--assets', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
source = Path(__file__).resolve().parents[1]
assets = args.assets.expanduser().resolve()
output = args.out.expanduser().resolve()
for target in (assets, output):
    if target == source or source in target.parents:
        raise SystemExit('Assets and outputs must stay outside public source.')
if output == assets or assets in output.parents:
    raise SystemExit('Reproducible exports must stay outside the private checkout.')
names = ['survivor', 'zombie', 'plant', 'radio', 'guitar', 'chair', 'table',
         'shelf', 'storage', 'foundation', 'wall', 'door', 'barricade', 'roof',
         'house', 'tree', 'bush', 'grass', 'car', 'pistol', 'crate']
missing = [str(assets / (name + '.blend')) for name in names
           if not (assets / (name + '.blend')).is_file()]
if missing:
    raise SystemExit('Missing editable sources; check out the matching asset revision:\n' + '\n'.join(missing))
output.mkdir(parents=True, exist_ok=True)
for name in names:
    original = assets / (name + '.blend')
    before = hashlib.sha256(original.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(original))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH'
              and not (name == 'door' and obj.name in ('DoorLeaf', 'Handle'))]
    if meshes:
        bpy.ops.object.select_all(action='DESELECT')
        for obj in meshes:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
    bpy.ops.export_scene.gltf(filepath=str(output / (name + '.glb')),
                             export_format='GLB', export_animations=True,
                             export_animation_mode='ACTIONS', export_yup=True)
    if hashlib.sha256(original.read_bytes()).hexdigest() != before:
        raise RuntimeError('Editable source changed during export: ' + str(original))
    print('EXPORTED', name, flush=True)
# Use the same deterministic synthesis without generating or saving any models.
sys.argv = ['create_assets.py', '--', '--assets', str(assets), '--out', str(output), '--only', 'audio']
runpy.run_path(str(source / 'scripts/create_assets.py'), run_name='__main__')
print('All editable source files preserved; GLB and audio exports complete.')
