"""Prepare private working sources for the third neighborhood iteration in Blender."""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
from character_poses import right_handed
from mathutils import Matrix, Vector

p = argparse.ArgumentParser()
p.add_argument('--home', type=Path, required=True)
p.add_argument('--assets', type=Path, required=True)
mode=p.add_mutually_exclusive_group()
mode.add_argument('--export-only', action='store_true')
mode.add_argument('--resume', action='store_true')
p.add_argument('--repair-poses', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
if a.repair_poses and a.export_only:
    p.error('--repair-poses changes a working source; use --resume, not --export-only')
home, private = a.home.expanduser().resolve(), a.assets.expanduser().resolve()
public = Path(__file__).resolve().parents[1]
for folder in (home, private):
    if folder == public or public in folder.parents:
        raise SystemExit('Assets and outputs must remain outside public source.')
if home == private or private in home.parents:
    raise SystemExit('Exports must remain outside the private checkout.')
working = private / 'neighborhood'
working.mkdir(parents=True, exist_ok=True)
out = home / 'generated'
out.mkdir(parents=True, exist_ok=True)
records = {}


def export(name, path):
    """Re-export an editable source without changing its hash."""
    before = hashlib.sha256(path.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(path))
    bpy.ops.export_scene.gltf(filepath=str(out / (name + '.glb')), export_format='GLB',
                             export_yup=True, export_animations=True,
                             export_animation_mode='ACTIONS', export_force_sampling=True)
    assert before == hashlib.sha256(path.read_bytes()).hexdigest()
    records[name] = {'source': str(path.relative_to(private)), 'source_sha256': before,
                     'glb_sha256': hashlib.sha256((out / (name + '.glb')).read_bytes()).hexdigest()}


def save(name):
    """Save a new private working source with Blender backup protection."""
    path = working / (name + '.blend')
    if path.exists():
        raise SystemExit('Existing source protected: ' + str(path))
    bpy.context.preferences.filepaths.save_version = 2
    bpy.context.preferences.filepaths.use_auto_save_temporary_files = True
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    return path



def isolate(names, size=None):
    """Keep selected non-character meshes, detach transforms and fit their bounds."""
    meshes = [bpy.data.objects[n] for n in names]
    for obj in meshes:
        if obj.name not in bpy.context.view_layer.objects:
            bpy.context.scene.collection.objects.link(obj)
        obj.hide_set(False)
        obj.hide_viewport = False
        obj.hide_render = False
        matrix = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = matrix
        for mod in list(obj.modifiers):
            if mod.type == 'ARMATURE':
                obj.modifiers.remove(mod)
    for obj in list(bpy.data.objects):
        if obj not in meshes:
            bpy.data.objects.remove(obj, do_unlink=True)
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    low, high = (Vector([fn(v[i] for v in points) for i in range(3)]) for fn in (min, max))
    factor = Vector([size[i] / max(.001, high[i] - low[i]) for i in range(3)]) if size else Vector((1, 1, 1))
    transform = Matrix.Diagonal((*factor, 1)) @ Matrix.Translation(Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z)))
    for obj in meshes:
        obj.matrix_world = transform @ obj.matrix_world
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()


def portable_materials():
    """Connect ITHappy's packed color atlas to glTF-compatible PBR inputs."""
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        nodes = material.node_tree.nodes
        shader = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
        atlas = next((n for n in nodes if n.type == 'TEX_IMAGE' and n.image and n.image.name == 'Color2.png'), None)
        if shader and atlas:
            material.node_tree.links.new(atlas.outputs['Color'], shader.inputs['Base Color'])
            shader.inputs['Roughness'].default_value = .85
            # Preserve the source's named UV map instead of unsupported shader mixes.
            attribute = next((n for n in nodes if n.type == 'ATTRIBUTE'), None)
            if attribute:
                uv = nodes.new('ShaderNodeUVMap')
                uv.uv_map = attribute.attribute_name
                material.node_tree.links.new(uv.outputs['UV'], atlas.inputs['Vector'])


if not a.export_only:
    right_handed(private / "quaternius/survivor.blend", a.repair_poses)
    selections = {
        'tree-pine': ('nature', 'PineTree_3', (4.2, 4.2, 8.0)),
        'tree-willow': ('nature', 'Willow_2', (6, 6, 7)),
        'flowers': ('nature', 'Flowers', (.5, .5, .4)),
        'woodlog': ('nature', 'WoodLog_Moss', (1.8, .6, .5)),
        'bush-berries': ('nature', 'BushBerries_1', (1.3, 1.3, 1)),
        'backpack': ('survival', 'Backpack', (.4, .25, .5)),
        'campfire': ('survival', 'Bonfire', (.9, .9, .28)),
        'tent': ('survival', 'Tent', (2.8, 2.2, 1.7)),
        'tree': ('nature', 'CommonTree_1', (3.8, 3.8, 6.8)),
        'tree-birch': ('nature', 'BirchTree_2', (3, 3, 6.4)),
        'tree-dead': ('nature', 'CommonTree_Dead_3', (3.4, 3.4, 6.5)),
        'bush': ('nature', 'Bush_1', (1.6, 1.3, 1.1)),
        'grass': ('nature', 'Grass_Short', (.65, .65, .28)),
        'rock': ('nature', 'Rock_Moss_3', (1.4, 1.1, .65)),
        'radio': ('survival', 'Radio', (.5, .25, .3)),
        'medkit': ('survival', 'FirstAidKit', (.32, .23, .25)),
        'bandages': ('survival', 'Bandages', (.25, .2, .15)),
        'bottle': ('survival', 'WaterBottle_1', (.1, .1, .26)),
        'trashcan': ('survival', 'Trashcan', (.6, .6, .85)),
        'gascan': ('survival', 'GasCan', (.3, .2, .45)),
        'couch': ('zombie-apocalypse', 'Couch', (2.1, .85, .85)),
        'hydrant': ('zombie-apocalypse', 'FireHydrant', (.45, .45, .85)),
        'trashbag': ('zombie-apocalypse', 'TrashBag_1', (.55, .5, .7)),
    }
    for name, (pack, filename, size) in selections.items():
        if a.resume and (working / (name + '.blend')).exists():
            continue
        original = home / 'downloads' / pack / 'extracted' / ('Environment/Blends' if pack == 'zombie-apocalypse' else 'Blends') / (filename + '.blend')
        before = hashlib.sha256(original.read_bytes()).hexdigest()
        bpy.ops.wm.open_mainfile(filepath=str(original))
        isolate([o.name for o in bpy.context.scene.objects if o.type == 'MESH'], size)
        for image in bpy.data.images:
            if image.source == 'FILE' and not image.packed_file:
                image.filepath = str(home / 'downloads/zombie-apocalypse/extracted/Zombie_Atlas.png')
                image.reload()
                image.pack()
        save(name)
        assert hashlib.sha256(original.read_bytes()).hexdigest() == before
    original = home / 'downloads/ithappy/Apocalypse_Free.blend'
    before = hashlib.sha256(original.read_bytes()).hexdigest()
    for name, names, size in [('guitar', ['Back_Guitar'], (.45, .12, 1)),
                              ('road-barrier', ['Road_Barrier_01'], (2.5, .48, 1.2)),
                              ('grill', ['Barbecue_Grill'], (.55, .55, .8)),
                              ('stove', ['Potbelly_Stove_01'], (.7, .6, 1)),
                              ('road-sign', ['Signs_Shield'], (.7, .15, 2)),
                              ('wreck', None, (2.3, 4.8, 1.85))]:
        if a.resume and (working / (name + '.blend')).exists():
            continue
        bpy.ops.wm.open_mainfile(filepath=str(original))
        if names is None:
            names = [o.name for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith('Apocalypse_Car')]
        isolate(names, size)
        portable_materials()
        save(name)
    assert hashlib.sha256(original.read_bytes()).hexdigest() == before

for path in sorted(working.glob('*.blend')):
    export(path.stem, path)
(out / 'neighborhood-exports.json').write_text(json.dumps({'exports': records, 'adapter': 'scripts/prepare_neighborhood_assets.py'}, indent=2) + '\n')
print('NEIGHBORHOOD EXPORTS', len(records), flush=True)
if not a.export_only:
    print('Re-export the changed survivor with scripts/adapt_quaternius.py --export-only before assembly.', flush=True)
