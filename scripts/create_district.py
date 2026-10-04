"""Create original editable district buildings/props from the shared runtime plans."""
import argparse,hashlib,json,math,sys
from pathlib import Path
import bpy
from mathutils import Vector
p=argparse.ArgumentParser();p.add_argument('--assets',type=Path,required=True);p.add_argument('--home',type=Path,required=True);p.add_argument('--export-only',action='store_true');p.add_argument('--update-buildings',action='store_true');a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
if a.export_only and a.update_buildings:p.error('--update-buildings changes working sources; cannot use --export-only')
public=Path(__file__).resolve().parents[1];private=a.assets.resolve();home=a.home.resolve()
for folder in (private,home):
    if folder==public or public in folder.parents:raise SystemExit('Assets must stay outside public source.')
if home==private or private in home.parents:raise SystemExit('Runtime exports must stay outside private source.')
working=private/'district';working.mkdir(parents=True,exist_ok=True);out=home/'generated';out.mkdir(parents=True,exist_ok=True)
plans=json.loads((public/'game/building_plans.json').read_text());records={};materials={}
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True);materials.clear()
def material(color,name=''):
    key=tuple(color)
    if key not in materials:
        m=bpy.data.materials.new(name or 'Weathered material');m.use_nodes=True
        linear=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in color);node=m.node_tree.nodes.get('Principled BSDF');node.inputs['Base Color'].default_value=(*linear,1);node.inputs['Roughness'].default_value=.86
        if key==(.3,.46,.49):node.inputs['Alpha'].default_value=.28
        materials[key]=m
    return materials[key]
def box(name,at,size,color):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(at[0],-at[2],at[1]));obj=bpy.context.object;obj.name=name;obj.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);obj.data.materials.append(material(color));return obj
def join():
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name!='Roof'];bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    if objects:
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
def save(name):
    path=working/(name+'.blend')
    if path.exists() and not (a.update_buildings and name.startswith('district-')):raise SystemExit('Existing district source protected: '+str(path))
    bpy.context.preferences.filepaths.save_version=2;bpy.ops.wm.save_as_mainfile(filepath=str(path))
if not a.export_only:
    if (working/'building-plans.json').exists() and not a.update_buildings:raise SystemExit('Existing district checkpoint protected; use --export-only.')
    for name,plan in plans.items():
        reset()
        for element in plan['boxes']:box(element['name'],element['at'],element['size'],element['color'])
        w=plan['width']/2+.4;d=plan['depth']/2+.4;y=plan['roof_height']-.015
        if plan['style']=='commercial':box('Roof',[0,y+.10,0],[w*2,.20,d*2],[.24,.27,.27])
        else:
            vertices=[(-w,-d,y),(w,-d,y),(0,-d,y+1.6),(-w,d,y),(w,d,y),(0,d,y+1.6)]
            mesh=bpy.data.meshes.new('Joined pitched roof');mesh.from_pydata([(x,-z,h) for x,z,h in vertices],[],[(3,5,2,0),(5,4,1,2),(2,1,0),(4,5,3),(0,1,4,3)]);mesh.materials.append(material([.24,.27,.27]));obj=bpy.data.objects.new('Roof',mesh);bpy.context.collection.objects.link(obj)
        join();save('district-'+name)
    wood=[.42,.31,.22];pale=[.70,.71,.66];steel=[.23,.29,.29];red=[.62,.37,.27]
    props={
        'coffee-table':[('Top',[0,.42,0],[1.05,.09,.65],wood),('Base',[0,.20,0],[.72,.40,.45],steel)],
        'nightstand':[('Oak cabinet',[0,.30,0],[.65,.60,.50],wood),('Drawer',[0,.40,-.27],[.58,.22,.04],pale),('Lamp base',[0,.64,0],[.16,.04,.16],steel),('Lamp shade',[0,.85,0],[.28,.24,.28],pale)],
        'wardrobe':[('Cabinet',[0,1.0,0],[1.3,2,.55],wood),('Door one',[-.32,1,-.29],[.60,1.88,.05],pale),('Door two',[.32,1,-.29],[.60,1.88,.05],pale)],
        'tvstand':[('Low cabinet',[0,.36,0],[1.3,.72,.45],wood)],
        'tv':[('Screen',[0,.30,0],[.9,.60,.07],steel),('Stand',[0,.025,0],[.40,.05,.22],steel)],
        'rug':[('Faded rug',[0,.006,0],[2.0,.012,1.7],[.52,.42,.33])],
        'bath-sink':[('Pedestal',[0,.38,0],[.32,.76,.30],pale),('Basin',[0,.80,0],[.60,.10,.45],pale),('Faucet',[0,.91,.16],[.04,.16,.04],steel)],
        'toilet':[('Pedestal',[0,.20,0],[.30,.40,.42],pale),('Bowl',[0,.43,0],[.44,.16,.54],pale),('Tank',[0,.63,.30],[.46,.50,.15],pale),('Seat',[0,.52,-.02],[.42,.04,.48],steel)],
        'market-shelf':[('Back',[0,.90,0],[1.3,1.8,.04],wood),('Base',[0,.1,0],[1.3,.2,.7],steel)],
        'food-tin':[('Tin',[0,.085,0],[.12,.17,.12],red),('Label',[0,.085,-.062],[.09,.10,.01],pale)],
        'ammo-box':[('Ammunition carton',[0,.08,0],[.24,.16,.15],[.39,.45,.27])],
        'scrap-parts':[('Metal offcut',[0,.025,0],[.28,.05,.13],steel),('Bracket',[.10,.05,.02],[.06,.10,.12],steel)],
        'vehicle-parts':[('Armor panel',[0,.06,0],[.5,.12,.36],steel),('Fixing',[.18,.13,.05],[.04,.05,.04],pale)],
        'fuel-pump':[('Foot',[0,.08,0],[.70,.16,.65],steel),('Pump',[0,.8,0],[.6,1.5,.5],red),('Display',[0,1.20,-.26],[.48,.25,.025],steel),('Hose',[.36,.65,.05],[.08,1.2,.08],steel)],
        'wall-picture':[('Frame',[0,.3,0],[.8,.6,.035],wood),('Landscape',[0,.3,-.025],[.7,.5,.015],[.47,.58,.44])],
        'books':[('Book one',[-.08,.09,0],[.08,.18,.13],red),('Book two',[.02,.10,0],[.08,.20,.13],[.36,.46,.52])]
    }
    for name,parts in props.items():
        if a.update_buildings and (working/(name+'.blend')).exists():continue
        reset()
        for n,at,size,color in parts:box(n,at,size,color)
        if name=='market-shelf':
            for y in [.28,.8,1.32]:
                box('Shelf',[0,y,0],[1.3,.05,.7],steel)
                for x in [-.46,-.23,0,.23,.46]:
                    for z in [-.22,.22]:box('Stocked tin',[x,y+.13,z],[.13,.22,.13],red if x<0 else pale)
        join();save(name)
    (working/'building-plans.json').write_text(json.dumps(plans,indent=2)+'\n')
    (working/'README.md').write_text('Original editable district sources for Zombie Slop. All rights reserved, separately from public MIT code. Shared building plans keep authored floors, windows, stair openings and runtime collision consistent. No exported binaries belong in Git. Sources are generated by scripts/create_district.py; restore this checkpoint and export-only without saving over the working models.\n')
if a.export_only:
    checkpoint=working/'building-plans.json'
    if not checkpoint.is_file() or json.loads(checkpoint.read_text()) != plans:
        raise SystemExit('District building plans differ; run with --update-buildings, then re-export with --export-only.')
for path in sorted(working.glob('*.blend')):
    before=hashlib.sha256(path.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(path));output=out/(path.stem+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',export_yup=True,export_animations=False)
    assert before==hashlib.sha256(path.read_bytes()).hexdigest()
    records[path.stem]={'source':str(path.relative_to(private)),'source_sha256':before,'glb_sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
(out/'district-exports.json').write_text(json.dumps({'exports':records,'plans_sha256':hashlib.sha256((working/'building-plans.json').read_bytes()).hexdigest()},indent=2)+'\n')
print('DISTRICT EXPORTED',len(records),flush=True)
