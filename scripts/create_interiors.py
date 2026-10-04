"""Create original editable house and searchable-furniture sources outside public Git."""
import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix

p = argparse.ArgumentParser()
p.add_argument('--assets', type=Path, required=True)
p.add_argument('--replace-existing', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
private = a.assets.expanduser().resolve()
public = Path(__file__).resolve().parents[1]
if private == public or public in private.parents:
    raise SystemExit('Editable assets must remain outside public source.')
working = private / 'neighborhood'
working.mkdir(parents=True, exist_ok=True)


def material(name, color, alpha=1):
    """Create an ordinary rough PBR material that survives glTF export."""
    m = bpy.data.materials.new(name)
    color = tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in color)
    m.diffuse_color = (*color, alpha)
    m.use_nodes = True
    node = m.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = (*color, alpha)
    node.inputs['Roughness'].default_value = .9
    node.inputs['Alpha'].default_value = alpha
    return m


def box(name, at, size, mat, parent=None):
    """Add a dimensioned component with applied scale and an optional pivot."""
    # Plans use X / ground Z / height; Blender +Y exports to Godot -Z.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(at[0], -at[1], at[2]))
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    if parent:
        world = o.matrix_world.copy()
        o.parent = parent
        o.matrix_world = world
    return o


def reset():
    """Start a clean source scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)


def consolidate(container=False):
    """Batch static meshes while retaining the roof or an opening furniture front."""
    if container:
        pivot = bpy.data.objects.new('ContainerDoorPivot', None)
        bpy.context.collection.objects.link(pivot)
        if container == 'fridge':
            pivot.location = (-.375, .37, 0)
        elif container == 'safe':
            pivot.location = (-.29, .34, 0)
        bpy.context.view_layer.update()
        front = [o for o in bpy.context.scene.objects if o.type == 'MESH' and any(s in o.name for s in ['Drawer front', 'Drawer handle', 'Door', 'Handle', 'Safe door', 'Cylinder'])]
        for obj in front:
            world = obj.matrix_world.copy()
            obj.parent = pivot
            obj.matrix_parent_inverse = Matrix.Identity(4)
            obj.matrix_basis = pivot.matrix_world.inverted() @ world
        bpy.context.view_layer.update()
    for parent in [None] + ([pivot] if container else []):
        meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.parent == parent and o.name != 'Roof']
        bpy.ops.object.select_all(action='DESELECT')
        for obj in meshes:
            obj.select_set(True)
        if meshes:
            bpy.context.view_layer.objects.active = meshes[0]
            if len(meshes) > 1:
                bpy.ops.object.join()


def window_wall(axis, fixed, lo, hi, windows, paint, trim, glass):
    """Build actual window openings with a sill, lintel, posts and thin glazing."""
    def part(center, level, width, height, depth, mat):
        at = (fixed, center, level) if axis == 'x' else (center, fixed, level)
        size = (depth, width, height) if axis == 'x' else (width, depth, height)
        box('Wall', at, size, mat)
    part((lo + hi) / 2, .575, hi - lo, .95, .2, paint)
    part((lo + hi) / 2, 2.85, hi - lo, .7, .2, paint)
    last = lo
    for center in windows:
        left, right = center - .8, center + .8
        if left > last:
            part((last + left) / 2, 1.775, left - last, 1.45, .2, paint)
        part(center, 1.02, 1.85, .10, .3, trim)
        part(center, 2.53, 1.85, .10, .3, trim)
        for x in [left, right]:
            part(x, 1.775, .10, 1.5, .3, trim)
        part(center, 1.775, 1.5, 1.38, .025, glass)
        part(center, 1.775, .06, 1.4, .1, trim)
        last = right
    if last < hi:
        part((last + hi) / 2, 1.775, hi - last, 1.45, .2, paint)


def cabinet(name, width, depth, height, mat):
    """Use a hollow shell so opening a door reveals an actual interior."""
    for x in [-width / 2 + .025, width / 2 - .025]:
        box(name + ' side', (x, 0, height / 2), (.05, depth, height), mat)
    for z in [.025, height - .025]:
        box(name + ' shelf', (0, 0, z), (width, depth, .05), mat)
    box(name + ' back', (0, depth / 2 - .025, height / 2), (width, .05, height), mat)


def house(color):
    """Build a pitched-roof bungalow with openings, two rooms and a porch."""
    paint = material('Weathered siding', color)
    trim = material('Timber trim', (.30, .28, .23))
    floor = material('Floor boards', (.40, .35, .27))
    roof = material('Roof shingles', (.24, .27, .27))
    glass = material('Dusty window glass', (.30, .46, .49), .28)
    box('Floor', (0, 0, .08), (12, 10, .16), floor)
    for x in [-6, 6]:
        window_wall('x', x, -5, 5, [-2.5, 2.5], paint, trim, glass)
    window_wall('y', 5, -6, 6, [-3.5, 3.5], paint, trim, glass)
    window_wall('y', -5, -6, -1.3, [-4], paint, trim, glass)
    window_wall('y', -5, 1.3, 6, [4], paint, trim, glass)
    box('Door lintel', (0, -5, 2.85), (2.6, .2, .7), paint)
    for x in [-1.3, 1.3]:
        box('Door jamb', (x, -5, 1.25), (.12, .28, 2.5), trim)
    door = box('Ajar front door', (-1.15, -4.25, 1.25), (1.65, .12, 2.25), trim)
    door.rotation_euler.z = math.radians(-70)
    for x in [-3.4, 3.4]:
        box('Room partition', (x, 1, 1.6), (5.2, .16, 3.2), paint)
    # Roof remains a distinct object; the game can hide it when indoors.
    vertices = [(-6.5, -5.5, 3.18), (6.5, -5.5, 3.18), (0, -5.5, 4.8),
                (-6.5, 5.5, 3.18), (6.5, 5.5, 3.18), (0, 5.5, 4.8)]
    mesh = bpy.data.meshes.new('Pitched roof')
    mesh.from_pydata([(x, -y, z) for x, y, z in vertices], [],
                     [(3, 5, 2, 0), (5, 4, 1, 2), (2, 1, 0), (4, 5, 3)])
    mesh.materials.append(roof)
    obj = bpy.data.objects.new('Roof', mesh)
    bpy.context.collection.objects.link(obj)
    box('Porch', (0, -6, .06), (4, 2, .12), floor)
    box('Porch awning', (0, -6, 2.7), (4.4, 2.3, .15), roof)
    for x in [-1.8, 1.8]:
        box('Porch post', (x, -6.85, 1.35), (.13, .13, 2.6), trim)
    for x in [-5.1, 5.1]:
        box('Lower siding trim', (x, -5.13, .38), (1.6, .05, .12), trim)
    for height in [.3, .6, .9, 2.65, 2.95]:
        for x in [-6.12, 6.12]:
            box('Siding seam', (x, 0, height), (.025, 9.9, .015), trim)
        box('Rear siding seam', (0, 5.12, height), (11.9, .025, .015), trim)


for name, color in [('house', (.48, .56, .45)), ('house-red', (.59, .40, .34)),
                     ('house-blue', (.42, .53, .58)), ('house-ochre', (.67, .58, .42))]:
    target = working / (name + '.blend')
    if target.exists() and not a.replace_existing:
        raise SystemExit('Existing source protected: ' + str(target))
    reset()
    house(color)
    consolidate()
    bpy.context.preferences.filepaths.save_version = 2
    bpy.context.preferences.filepaths.use_auto_save_temporary_files = True
    bpy.ops.wm.save_as_mainfile(filepath=str(target))

for name in ['drawer', 'fridge', 'safe', 'bed', 'counter']:
    target = working / (name + '.blend')
    if target.exists() and not a.replace_existing:
        raise SystemExit('Existing source protected: ' + str(target))
    reset()
    wood = material('Old oak', (.42, .31, .22))
    pale = material('Aged enamel', (.68, .71, .66))
    metal = material('Dark steel', (.23, .29, .29))
    if name == 'drawer':
        cabinet('Cabinet', 1.2, .55, .86, wood)
        for z in [.22, .52, .78]:
            box('Drawer front', (0, -.29, z), (1.12, .06, .22), pale)
            box('Drawer handle', (0, -.35, z), (.25, .04, .04), metal)
            box('Drawer front tray', (0, -.03, z-.09), (1.05, .48, .025), wood)
    elif name == 'fridge':
        cabinet('Fridge', .8, .7, 1.8, pale)
        for z in [.42, .86, 1.22]:
            box('Interior shelf', (0, 0, z), (.68, .6, .035), metal)
        food = material('Food tins', (.63, .46, .27))
        for x in [-.2, 0, .2]:
            box('Food tin', (x, 0, .55), (.13, .15, .22), food)
        for z, height in [(1.50, .52), (.62, 1.12)]:
            box('Door', (0, -.37, z), (.75, .06, height), pale)
            box('Handle', (.28, -.43, z), (.04, .06, .28), metal)
    elif name == 'safe':
        cabinet('Safe', .7, .65, .8, metal)
        box('Safe door', (0, -.34, .4), (.58, .04, .66), pale)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=.10, depth=.08, location=(0, .4, .4), rotation=(math.pi / 2, 0, 0))
        bpy.context.object.data.materials.append(metal)
    elif name == 'bed':
        box('Bed frame', (0, 0, .22), (1.5, 2.1, .35), wood)
        box('Mattress', (0, 0, .47), (1.44, 2, .22), pale)
        box('Blanket', (0, .25, .6), (1.45, 1.35, .08), metal)
        box('Pillow', (0, -.74, .64), (.7, .4, .16), pale)
        box('Headboard', (0, -1.05, .6), (1.5, .1, 1.1), wood)
    else:
        box('Counter', (0, 0, .45), (2, .6, .9), wood)
        box('Countertop', (0, 0, .94), (2.06, .65, .08), pale)
        box('Sink', (.4, 0, .99), (.7, .4, .05), metal)
    consolidate(name if name in ['drawer', 'fridge', 'safe'] else False)
    bpy.ops.wm.save_as_mainfile(filepath=str(target))
print('Created nine original editable house/interior sources.', flush=True)
