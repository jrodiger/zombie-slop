"""Blender working-copy adapter. Pristine pack inputs are never saved over."""
import argparse
import hashlib
import json
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector

p = argparse.ArgumentParser()
p.add_argument('--pack', type=Path, required=True)
p.add_argument('--assets', type=Path, required=True)
p.add_argument('--out', type=Path, required=True)
p.add_argument('--export-only', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
source = Path(__file__).resolve().parents[1]
pack, private, out = (x.expanduser().resolve() for x in (a.pack, a.assets, a.out))
for path in (pack, private, out):
    if path == source or source in path.parents:
        raise SystemExit('Asset files must stay outside public source.')
if out == private or private in out.parents:
    raise SystemExit('Reproducible exports must stay outside private source.')
working = private / 'quaternius'
working.mkdir(parents=True, exist_ok=True)
out.mkdir(parents=True, exist_ok=True)
mapping = {
    'survivor': 'Characters/Blends/Characters_Matt.blend',
    'zombie': 'Characters/Blends/Zombie_Basic.blend',
    'pistol': 'Weapons/Blends/Pistol.blend',
    'rifle': 'Weapons/Blends/Rifle.blend',
    'shotgun': 'Weapons/Blends/Shotgun.blend',
    'car': 'Vehicles/Blends/Vehicle_Pickup.blend',
    'storage': 'Environment/Blends/Chest.blend',
}
exported = {}

def alias(original, name):
    action = bpy.data.actions[original].copy()
    action.name = name
    action.use_fake_user = True
    return action

def adapt_character(kind):
    rig = bpy.data.objects['CharacterArmature']
    rig.animation_data.action = bpy.data.actions['Idle_Gun' if kind == 'survivor' else 'Idle']
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)
    if kind == 'survivor':
        guns = ['Pistol', 'Rifle', 'Shotgun']
        for obj in list(bpy.data.objects):
            if obj.type == 'MESH' and obj.parent_type == 'BONE' and obj.name not in guns:
                bpy.data.objects.remove(obj, do_unlink=True)
        # Preserve the author's bone attachments and geometry alignment. Find a
        # barrel endpoint by fitting the standalone weapon to its attached mesh.
        for name in guns:
            weapon = bpy.data.objects[name]
            # Corresponding standalone glTF bounds are insufficient to recover
            # the attached gun's rotated vertices; read its mesh in isolation.
            with bpy.data.libraries.load(str(pack / ('Weapons/Blends/' + name + '.blend'))) as (available, data):
                data.meshes = available.meshes[:1]
            standalone = data.meshes[0]
            original = np.array([list(v.co) + [1] for v in standalone.vertices])
            attached = np.array([list(v.co) for v in weapon.data.vertices])
            if original.shape[0] != attached.shape[0]:
                raise RuntimeError('Weapon topology differs: ' + name)
            fit, _, _, _ = np.linalg.lstsq(original, attached, rcond=None)
            if np.max(np.abs(original @ fit - attached)) > .001:
                raise RuntimeError('Cannot recover muzzle alignment: ' + name)
            # Pack weapons point along Blender -Y, which exports as Godot +Z.
            muzzle = bpy.data.objects.new(name + 'Muzzle', None)
            bpy.context.collection.objects.link(muzzle)
            muzzle.parent = weapon
            tip = np.array([0, original[:, 1].min(), original[:, 2].max() * .72, 1]) @ fit
            muzzle.location = Vector(tip)
            grip = bpy.data.objects.new(name + 'Grip', None)
            bpy.context.collection.objects.link(grip)
            grip.parent = weapon
            grip.location = Vector(np.array([0, 0, 0, 1]) @ fit)
            bpy.data.meshes.remove(standalone)
        alias('Idle_Gun', 'Aim')
        for name, length, amplitude in [('Shoot', 6, .08), ('Reload', 48, .45)]:
            action = alias('Idle_Gun', name)
            # Short upper-arm recoil and a lowered forearm reload gesture on the
            # same rig. Ammo timing is owned by gameplay, interrupted on switch.
            bone = 'UpperArm.L' if name == 'Shoot' else 'LowerArm.L'
            path = 'pose.bones["' + bone + '"].rotation_quaternion'
            curve = next(c for c in action.fcurves if c.data_path == path and c.array_index == 1)
            base = curve.evaluate(0)
            curve.keyframe_points.clear()
            for frame, value in [(0, base), (length * .35, base + amplitude), (length, base)]:
                curve.keyframe_points.insert(frame, value)
            for fc in action.fcurves:
                for key in fc.keyframe_points:
                    if key.co.x > length:key.co.x = length
    else:
        alias('Punch', 'Attack')
        # Eyelids and body share the atlas: one skin/material surface.
        bpy.ops.object.select_all(action='DESELECT')
        meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
        for obj in meshes:obj.select_set(True)
        bpy.context.view_layer.objects.active = bpy.data.objects['Zombie']
        bpy.ops.object.join()
    rig.scale *= 1.15
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()

def normalize_prop(kind):
    # Match the existing collision footprint, center XY and put the base at Z=0.
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    points = [mesh.matrix_world @ Vector(corner) for mesh in meshes for corner in mesh.bound_box]
    low = Vector([min(v[i] for v in points) for i in range(3)])
    high = Vector([max(v[i] for v in points) for i in range(3)])
    if kind == 'storage':scale = Vector([size / (high[i] - low[i]) for i, size in enumerate((1.1, .7, .65))])
    elif kind == 'car':scale = Vector([size / (high[i] - low[i]) for i, size in enumerate((2, 4.2, 1.55))])
    else:scale = Vector((.65, .65, .65))
    transform = Matrix.Diagonal((*scale, 1)) @ Matrix.Translation(Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z)))
    for mesh in meshes:
        if mesh.parent is None:mesh.matrix_world = transform @ mesh.matrix_world
    if kind == 'car':
        bpy.ops.object.select_all(action='DESELECT')
        for mesh in meshes:mesh.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()

for kind, relative in mapping.items():
    original = pack / relative
    before = hashlib.sha256(original.read_bytes()).hexdigest()
    editable = working / (kind + '.blend')
    if not a.export_only:
        if editable.exists():raise SystemExit('Working source already exists: ' + str(editable))
        bpy.ops.wm.open_mainfile(filepath=str(original))
        if kind in ('survivor', 'zombie'):adapt_character(kind)
        else:normalize_prop(kind)
        # Embed the atlas so the working source is independent of download paths.
        for image in bpy.data.images:
            if image.source == 'FILE' and not image.packed_file:
                image.filepath = str(pack / 'Zombie_Atlas.png');image.reload();image.pack()
        bpy.context.preferences.filepaths.save_version = 2
        bpy.context.preferences.filepaths.use_auto_save_temporary_files = True
        bpy.ops.wm.save_as_mainfile(filepath=str(editable))
    else:
        bpy.ops.wm.open_mainfile(filepath=str(editable))
    editable_before = hashlib.sha256(editable.read_bytes()).hexdigest()
    bpy.ops.export_scene.gltf(filepath=str(out / (kind + '.glb')), export_format='GLB',
                             export_animations=True, export_animation_mode='ACTIONS',
                             export_yup=True, export_force_sampling=True)
    if hashlib.sha256(original.read_bytes()).hexdigest() != before:
        raise RuntimeError('Pristine input changed: ' + str(original))
    if hashlib.sha256(editable.read_bytes()).hexdigest() != editable_before:
        raise RuntimeError('Editable source changed during export: ' + str(editable))
    exported[kind] = {'source_sha256': editable_before,
                      'glb_sha256': hashlib.sha256((out / (kind + '.glb')).read_bytes()).hexdigest()}
    print('QUATERNIUS EXPORTED', kind, flush=True)
(out / 'quaternius-exports.json').write_text(json.dumps({'source': 'Quaternius Zombie Apocalypse Kit',
    'license': 'CC0-1.0', 'files': mapping, 'exports': exported,
    'adapter': 'scripts/adapt_quaternius.py'}, indent=2) + '\n')
