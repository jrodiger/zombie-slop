"""Blender working-copy adapter. Pristine pack inputs are never saved over."""
import argparse
import hashlib
import json
import sys
from pathlib import Path
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
from character_poses import right_handed
import numpy as np
from mathutils import Matrix, Vector

p = argparse.ArgumentParser()
p.add_argument('--pack', type=Path, required=True)
p.add_argument('--assets', type=Path, required=True)
p.add_argument('--out', type=Path, required=True)
p.add_argument('--update-characters', action='store_true', help='Rebuild survivor working copies with new weapons/poses; retains Blender backups.')
p.add_argument('--repair-poses', action='store_true', help='Rebake all existing survivor working copies; retains Blender backups. Requires --resume.')
mode = p.add_mutually_exclusive_group()
mode.add_argument('--export-only', action='store_true')
mode.add_argument('--resume', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
if a.update_characters and a.export_only:raise SystemExit('--update-characters cannot be combined with --export-only')
if a.repair_poses and (not a.resume or a.update_characters):raise SystemExit('--repair-poses requires --resume and cannot be combined with --update-characters')
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
    'survivor-lis': 'Characters/Blends/Characters_Lis.blend',
    'survivor-sam': 'Characters/Blends/Characters_Sam.blend',
    'survivor-shaun': 'Characters/Blends/Characters_Shaun.blend',
    'zombie': 'Characters/Blends/Zombie_Basic.blend',
    'zombie-chubby': 'Characters/Blends/Zombie_Chubby.blend',
    'zombie-arm': 'Characters/Blends/Zombie_Arm.blend',
    'zombie-ribcage': 'Characters/Blends/Zombie_Ribcage.blend',
    'pistol': 'Weapons/Blends/Pistol.blend',
    'rifle': 'Weapons/Blends/Rifle.blend',
    'shotgun': 'Weapons/Blends/Shotgun.blend',
    'car': 'Vehicles/Blends/Vehicle_Pickup.blend',
    'car-pickup-armored': 'Vehicles/Blends/Vehicle_Pickup_Armored.blend',
    'car-sports': 'Vehicles/Blends/Vehicle_Sports.blend',
    'car-sports-armored': 'Vehicles/Blends/Vehicle_Sports_Armored.blend',
    'car-truck': 'Vehicles/Blends/Vehicle_Truck.blend',
    'car-truck-armored': 'Vehicles/Blends/Vehicle_Truck_Armored.blend',
    'road-straight': 'Environment/Blends/Street_Straight.blend',
    'road-cracked': 'Environment/Blends/Street_Straight_Crack1.blend',
    'road-cross': 'Environment/Blends/Street_4Way.blend',
    'road-turn': 'Environment/Blends/Street_Turn.blend',
    'storage': 'Environment/Blends/Chest.blend',
}
exported = {}

def alias(original, name):
    """Copy an author action under a gameplay clip name without editing it."""
    action = bpy.data.actions[original].copy()
    action.name = name
    action.use_fake_user = True
    return action

def adapt_character(kind):
    """Prepare author rigs, weapon sockets and gestures in a working copy."""
    if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
    rig = bpy.data.objects['CharacterArmature']
    rig.animation_data.action = bpy.data.actions['Idle_Gun' if kind.startswith('survivor') else 'Idle']
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)
    if kind.startswith('survivor'):
        guns = ['Pistol', 'Rifle', 'Shotgun', 'SMG', 'Axe', 'Knife', 'WoodenBat_Barbed']
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
        add_survival_guns(rig)
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
        alias('Punch' if 'Punch' in bpy.data.actions else 'HitReact', 'Attack')
        # Eyelids and body share the atlas: one skin/material surface.
        bpy.ops.object.select_all(action='DESELECT')
        meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
        for obj in meshes:obj.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
    rig.scale *= 1.15
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()

def add_survival_guns(rig):
    """Fit the inspected +X Survival guns onto this rig's authored pistol socket."""
    template = bpy.data.objects['Pistol']
    with bpy.data.libraries.load(str(pack / 'Weapons/Blends/Pistol.blend')) as (available, data):
        data.meshes = available.meshes[:1]
    original = np.array([list(v.co) + [1] for v in data.meshes[0].vertices])
    attached = np.array([list(v.co) for v in template.data.vertices])
    fit, _, _, _ = np.linalg.lstsq(original, attached, rcond=None)
    bpy.data.meshes.remove(data.meshes[0])
    folder = pack.parents[1] / 'survival/extracted/Blends'
    for name, file, scale in [('Revolver', 'Revolver_1', .25), ('CompactShotgun', 'Shotgun_SawedOff', .23)]:
        with bpy.data.libraries.load(str(folder / (file + '.blend'))) as (available, data):
            data.meshes = available.meshes[:1]
        mesh = data.meshes[0]
        for v in mesh.vertices:
            co = Vector((v.co.y * scale, -v.co.x * scale, v.co.z * scale))
            v.co = Vector(np.array([*co, 1]) @ fit)
        gun = template.copy();gun.data = mesh;gun.name = name;bpy.context.collection.objects.link(gun)
        grip = bpy.data.objects.new(name + 'Grip', None);bpy.context.collection.objects.link(grip);grip.parent = gun;grip.location = Vector(np.array([0,0,0,1]) @ fit)
        tip = bpy.data.objects.new(name + 'Muzzle', None);bpy.context.collection.objects.link(tip);tip.parent = gun
        # The fitted mesh extends along the same local barrel axis as the authored pistol.
        pts = [v.co for v in mesh.vertices];forward = (bpy.data.objects['PistolMuzzle'].location - bpy.data.objects['PistolGrip'].location).normalized()
        tip.location = grip.location + forward * max((v - grip.location).dot(forward) for v in pts)


def normalize_prop(kind):
    """Fit complete prop geometry to the runtime footprint and ground plane."""
    # Match the existing collision footprint, center XY and put the base at Z=0.
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    points = [mesh.matrix_world @ Vector(corner) for mesh in meshes for corner in mesh.bound_box]
    low = Vector([min(v[i] for v in points) for i in range(3)])
    high = Vector([max(v[i] for v in points) for i in range(3)])
    if kind == 'storage':scale = Vector([size / (high[i] - low[i]) for i, size in enumerate((1.1, .7, .65))])
    elif kind.startswith('car'):scale = Vector([size / (high[i] - low[i]) for i, size in enumerate((2.4, 5.5, 2.5) if 'truck' in kind else (2, 4.2, 1.55))])
    elif kind.startswith('road'):scale = Vector((1, 1, 1))
    else:scale = Vector((.65, .65, .65))
    transform = Matrix.Diagonal((*scale, 1)) @ Matrix.Translation(Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z)))
    for mesh in meshes:
        if mesh.parent is None:mesh.matrix_world = transform @ mesh.matrix_world
    if kind.startswith('car'):
        bpy.ops.object.select_all(action='DESELECT')
        for mesh in meshes:mesh.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()

for kind, relative in mapping.items():
    original = pack / relative
    before = hashlib.sha256(original.read_bytes()).hexdigest()
    editable = working / (kind + '.blend')
    rebuilding = a.update_characters and kind.startswith('survivor')
    if editable.exists() and not a.export_only and not a.resume and not rebuilding:
        raise SystemExit('Working source already exists: ' + str(editable))
    if a.export_only or (a.resume and editable.exists() and not rebuilding):
        bpy.ops.wm.open_mainfile(filepath=str(editable))
        if a.repair_poses and kind.startswith('survivor'):right_handed(editable, repair=True)
    else:
        bpy.ops.wm.open_mainfile(filepath=str(original))
        if kind.startswith(('survivor', 'zombie')):adapt_character(kind)
        else:normalize_prop(kind)
        # Embed the atlas so the working source is independent of download paths.
        for image in bpy.data.images:
            if image.source == 'FILE' and not image.packed_file:
                image.filepath = str(pack / 'Zombie_Atlas.png');image.reload();image.pack()
        bpy.context.preferences.filepaths.save_version = 2
        bpy.context.preferences.filepaths.use_auto_save_temporary_files = True
        bpy.ops.wm.save_as_mainfile(filepath=str(editable))
        if kind.startswith('survivor'):right_handed(editable)
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
