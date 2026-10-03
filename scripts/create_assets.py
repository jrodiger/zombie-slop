"""Run in Blender: blender --background --python scripts/create_assets.py -- --assets PATH --out PATH.
Original low-poly source assets; outputs MUST stay outside the public repository.
"""
import bpy,math,random,sys,argparse,json,wave,struct
from pathlib import Path
from mathutils import Vector
p=argparse.ArgumentParser();p.add_argument('--assets',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
source=Path(__file__).resolve().parents[1]
for root in [a.assets.resolve(),a.out.resolve()]:
 if root==source or source in root.parents:raise SystemExit('Assets must remain outside public source.')
a.assets.mkdir(parents=True,exist_ok=True);a.out.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.filepaths.use_auto_save_temporary_files=True
bpy.context.preferences.filepaths.auto_save_time=2
bpy.context.preferences.filepaths.save_version=2
palette={'wood':(0.34,0.23,0.13,1),'timber':(0.54,0.39,0.22,1),'cream':(0.69,0.67,0.49,1),'blue':(0.19,0.31,0.34,1),'green':(0.18,0.31,0.18,1),'leaf':(0.27,0.43,0.21,1),'leaf2':(0.35,0.47,0.21,1),'metal':(0.18,0.23,0.24,1),'dark':(0.065,0.09,0.095,1),'rust':(0.53,0.23,0.12,1),'skin':(0.63,0.43,0.3,1),'zskin':(0.43,0.53,0.31,1),'denim':(0.17,0.22,0.26,1),'red':(0.64,0.27,0.15,1),'glass':(0.3,0.46,0.48,1),'gold':(0.9,0.65,0.28,1)}
materials={}
def xyz(v):return (v[0],-v[2],v[1])
def mat(name):
 if name not in materials:
  m=bpy.data.materials.new(name);m.diffuse_color=palette[name];m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=palette[name];m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=0.85;materials[name]=m
 return materials[name]
def cube(name,pos,size,color='wood',angle=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(pos));o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1]);o.rotation_euler.z=-angle;o.data.materials.append(mat(color));bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return o
def sphere(name,pos,size,color='leaf'):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=xyz(pos));o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1]);o.data.materials.append(mat(color));bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return o
def cylinder(name,pos,radius,depth,color='wood',vertices=8):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=xyz(pos));o=bpy.context.object;o.name=name;o.data.materials.append(mat(color));return o
def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def export(name):
 # Keep the .blend editable; join meshes by material into fewer draw surfaces for glTF.
 bpy.ops.wm.save_as_mainfile(filepath=str(a.assets/(name+'.blend')))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and not (name=='door' and o.name in ('DoorLeaf','Handle'))]
 if meshes:
  bpy.ops.object.select_all(action='DESELECT')
  for o in meshes:o.select_set(True)
  bpy.context.view_layer.objects.active=meshes[0]
  bpy.ops.object.join()
 bpy.ops.export_scene.gltf(filepath=str(a.out/(name+'.glb')),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_yup=True)
 print('ASSET',name,flush=True)
def plank_wall():
 for i in range(10):cube('Vertical plank',(-1.35+i*.3,1.25,0),(.27,2.5,.13),'timber')
 for y in [.35,2.1]:cube('Cross brace',(0,y,.09),(3,.12,.1))
def character(zombie=False):
 bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='SurvivorRig' if not zombie else 'ZombieRig';bpy.ops.object.mode_set(mode='EDIT');bones=rig.data.edit_bones;bones.remove(bones[0])
 definitions=[('root',(0,0,0),(0,.2,0),None),('hips',(0,.82,0),(0,1.03,0),'root'),('spine',(0,1.03,0),(0,1.4,0),'hips'),('head',(0,1.4,0),(0,1.76,0),'spine'),('upper_arm.R',(-.27,1.4,0),(-.36,1.12,.16),'spine'),('forearm.R',(-.36,1.12,.16),(-.27,1.13,.42),'upper_arm.R'),('hand.R',(-.27,1.13,.42),(-.27,1.13,.55),'forearm.R'),('upper_arm.L',(.27,1.4,0),(.36,1.12,.16),'spine'),('forearm.L',(.36,1.12,.16),(.05,1.13,.44),'upper_arm.L'),('hand.L',(.05,1.13,.44),(.05,1.13,.54),'forearm.L'),('thigh.R',(-.15,.88,0),(-.15,.47,0),'hips'),('shin.R',(-.15,.47,0),(-.15,.1,0),'thigh.R'),('thigh.L',(.15,.88,0),(.15,.47,0),'hips'),('shin.L',(.15,.47,0),(.15,.1,0),'thigh.L')]
 for name,head,tail,parent in definitions:
  b=bones.new(name);b.head=xyz(head);b.tail=xyz(tail)
  if parent:b.parent=bones[parent]
 bpy.ops.object.mode_set(mode='OBJECT')
 skin='zskin' if zombie else 'skin';shirt='cream' if zombie else 'blue'
 pieces=[('hips',(0,.91,0),(.42,.22,.24),'denim','hips'),('shirt',(0,1.2,0),(.54,.5,.27),shirt,'spine'),('head',(0,1.62,0),(.31,.34,.29),skin,'head'),('hair',(0,1.8,-.03),(.33,.1,.28),'dark','head'),('backpack',(0,1.18,-.23),(.42,.4,.18),'wood','spine')]
 for side,x in [('R',-.15),('L',.15)]:
  pieces += [('pants'+side,(x,.66,0),(.18,.41,.2),'denim','thigh.'+side),('leg'+side,(x,.3,0),(.15,.37,.18),'denim','shin.'+side),('boot'+side,(x,.08,.065),(.19,.14,.34),'dark','shin.'+side)]
 for side,x in [('R',-.31),('L',.31)]:
  pieces += [('sleeve'+side,(x,1.28,.07),(.17,.3,.22),shirt,'upper_arm.'+side),('arm'+side,(x*.7,1.12,.31),(.16,.15,.29),skin,'forearm.'+side),('hand'+side,(-.27 if side=='R' else .05,1.13,.48),(.14,.14,.15),skin,'hand.'+side)]
 for name,pos,size,color,bone in pieces:
  o=cube(name,pos,size,color);g=o.vertex_groups.new(name=bone);g.add(list(range(len(o.data.vertices))),1.0,'REPLACE');mod=o.modifiers.new('Skeleton','ARMATURE');mod.object=rig;o.parent=rig
 # Dark eyes oriented +Z in game.
 for x in [-.085,.085]:
  o=cube('Eye',(x,1.65,.149),(.045,.04,.014),'dark');g=o.vertex_groups.new(name='head');g.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Skeleton','ARMATURE');mod.object=rig;o.parent=rig
 rig.animation_data_create()
 for clip in ['Idle','Walk','Run','Aim','Shoot','Reload','Attack','Death']:
  action=bpy.data.actions.new(clip);rig.animation_data.action=action
  length=30 if clip not in ('Death','Reload') else 60
  for frame in range(1,length+1,3):
   phase=(frame-1)/length*math.tau
   for pb in rig.pose.bones:pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
   if clip in ('Walk','Run'):
    strength=.5 if clip=='Walk' else .8
    for side,sign in [('R',1),('L',-1)]:
     rig.pose.bones['thigh.'+side].rotation_euler.x=math.sin(phase)*strength*sign
     rig.pose.bones['shin.'+side].rotation_euler.x=max(0,-math.sin(phase)*sign)*.5
    rig.pose.bones['hips'].location.z=abs(math.sin(phase))*.04
   if clip=='Idle':rig.pose.bones['spine'].rotation_euler.x=math.sin(phase)*.018
   if clip=='Shoot':rig.pose.bones['spine'].rotation_euler.x=-max(0,1-(frame-1)/12)*.09
   if clip=='Reload':
    rig.pose.bones['forearm.L'].rotation_euler.y=math.sin((frame-1)/length*math.pi)*1.1
    rig.pose.bones['spine'].rotation_euler.x=.12*math.sin((frame-1)/length*math.pi)
   if clip=='Attack':
    for side in ['R','L']:rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.5+math.sin(phase)*.45
   if clip=='Death':rig.pose.bones['root'].rotation_euler.x=min(1,(frame-1)/35)*1.55
   for pb in rig.pose.bones:
    pb.keyframe_insert('rotation_euler',frame=frame,group=pb.name);pb.keyframe_insert('location',frame=frame,group=pb.name)
  # Keep each action on a separate NLA track for explicit export.
  track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action)
 rig.animation_data.action=None
 for track in rig.animation_data.nla_tracks:track.mute=True
 bpy.context.scene.frame_set(1)
reset();character();export('survivor')
reset();character(True);export('zombie')
for name in ['plant','radio','guitar','chair','table','shelf','storage','foundation','wall','door','barricade','roof','house','tree','bush','grass','car','pistol','crate']:
 reset()
 if name=='plant':
  cylinder('Terracotta',(0,.17,0),.2,.34,'rust');
  for i in range(7):
   ang=i*math.tau/7;sphere('Fern',(.17*math.cos(ang),.52,.17*math.sin(ang)),(.19,.28,.12),'leaf' if i%2 else 'leaf2')
 elif name=='radio':
  cube('Radio shell',(0,.15,0),(.5,.3,.25),'blue');cube('Speaker',(-.11,.15,.132),(.18,.2,.018),'dark');cube('Tuner',(.12,.2,.132),(.15,.06,.018),'gold');cube('Antenna',(.18,.48,0),(.014,.4,.014),'metal')
 elif name=='guitar':
  sphere('Body',(0,.24,0),(.21,.25,.09),'timber');sphere('Upper body',(0,.44,0),(.17,.18,.09),'timber');cube('Neck',(0,.72,0),(.08,.55,.06));cube('Headstock',(0,.99,0),(.12,.12,.06));cylinder('Sound hole',(0,.31,.082),.065,.015,'dark')
 elif name in ('chair','table'):
  if name=='table':w,d,y=1.8,1,.8
  else:w,d,y=.6,.6,.48
  cube('Top',(0,y,0),(w,.1,d),'timber')
  for x in [-w/2+.07,w/2-.07]:
   for z in [-d/2+.07,d/2-.07]:cube('Leg',(x,y/2,z),(.1,y,.1))
  if name=='chair':cube('Back',(0,.77,-.25),(.6,.46,.1),'timber')
 elif name=='shelf':
  for x in [-.7,.7]:cube('Upright',(x,.9,0),(.1,1.8,.5))
  for y in [.1,.65,1.2,1.75]:cube('Shelf',(0,y,0),(1.5,.09,.5),'timber')
 elif name in ('storage','crate'):
  size=(1.1,.65,.7) if name=='storage' else (.65,.5,.5)
  cube('Box',(0,size[1]/2,0),size,'wood');cube('Lid',(0,size[1]-.04,0),(size[0]+.02,.08,size[2]+.02),'timber')
  for x in [-size[0]*.3,size[0]*.3]:cube('Band',(x,size[1]/2,.0),(.055,size[1]+.02,size[2]+.03),'metal')
 elif name in ('foundation','roof'):
  size=3 if name=='foundation' else 3.2;thick=.2 if name=='foundation' else .16
  for i in range(10):cube('Decking',(-size/2+size/20+i*size/10,thick/2,0),(size/10-.015,thick,size),'timber')
 elif name=='wall':plank_wall()
 elif name=='door':
  for x in [-1.08,1.08]:cube('Frame side',(x,1.25,0),(.84,2.5,.18),'timber')
  cube('Lintel',(0,2.34,0),(1.3,.32,.18),'timber');leaf=cube('DoorLeaf',(0,1.08,0),(1.2,2.16,.12),'blue');handle=sphere('Handle',(.45,1.08,.08),(.05,.05,.05),'gold')
  pivot=bpy.data.objects.new('DoorPivot',None);bpy.context.collection.objects.link(pivot);pivot.location=xyz((-.6,0,0))
  for o in [leaf,handle]:
   o.parent=pivot;o.matrix_parent_inverse=pivot.matrix_world.inverted()
 elif name=='barricade':
  for x in [-1,1]:cube('Post',(x,.62,0),(.15,1.25,.5))
  for y in [.28,.63,.98]:cube('Rail',(0,y,0),(2.6,.25,.12),'timber')
 elif name=='house':
  cube('Floor',(0,.08,0),(12,.16,10),'timber')
  for x in [-6,6]:cube('Side wall',(x,1.6,0),(.22,3.2,10),'cream')
  cube('Back wall',(0,1.6,5),(12,3.2,.22),'cream')
  for x in [-3.65,3.65]:cube('Front wall',(x,1.6,-5),(4.7,3.2,.22),'cream')
  cube('Door lintel',(0,2.85,-5),(2.6,.7,.22),'cream')
  for x in [-3.4,3.4]:cube('Room divider',(x,1.6,1),(5.2,3.2,.16),'cream')
  for x in [-3.8,3.8]:
   cube('Window',(x,1.8,-5.13),(1.7,1.25,.04),'glass');cube('Window sill',(x,1.16,-5.2),(2,.12,.3),'blue')
  for x,angle in [(-3.15,-.34),(3.15,.34)]:
   o=cube('Pitched roof',(x,3.73,0),(6.8,.22,11),'blue');o.rotation_euler.y=angle
  for x in [-5.5,5.5]:cube('Porch post',(x,1.6,-6),(.15,3.2,.15),'wood')
  cube('Porch roof',(0,3.2,-5.7),(12.6,.18,2),'blue')
 elif name=='tree':
  cylinder('Trunk',(0,2.1,0),.27,4.2,'wood')
  for pos,size in [((0,5,0),(2.6,2.5,2.5)),((1.3,4.2,.5),(1.9,1.9,1.9)),((-1.2,4.5,-.5),(1.8,2,1.8))]:sphere('Canopy',pos,size,'leaf')
 elif name=='bush':
  for x in [-.45,0,.45]:sphere('Bush',(x,.5,0),(.7,.65,.65),'leaf2')
 elif name=='grass':
  for i in range(6):cube('Blade',((i%3-.8)*.15,.2,(i//3-.5)*.15),(.025,.4,.08),'leaf',i*.7)
 elif name=='car':
  cube('Chassis',(0,.6,0),(1.9,.48,4.1),'rust');cube('Cabin',(0,1.05,-.3),(1.65,.65,2.1),'blue');cube('Windshield',(0,1.14,.77),(1.5,.45,.035),'glass');cube('Bumper',(0,.47,2.1),(1.95,.16,.16),'metal')
  for x in [-.97,.97]:
   for z in [-1.3,1.3]:sphere('Tire',(x,.35,z),(.2,.35,.35),'dark')
  for x in [-.6,.6]:cube('Headlight',(x,.69,2.065),(.35,.16,.03),'gold')
 elif name=='pistol':
  cube('Slide',(0,.05,.15),(.055,.075,.3),'metal');cube('Grip',(0,-.045,.045),(.055,.15,.08),'dark');cube('Muzzle',(0,.05,.31),(.03,.03,.015),'dark')
 export(name)
# Original effects, generated from deterministic synthesis. Source parameters are editable text.
rng=random.Random(7)
for name,duration in [('shot',.19),('reload',.9),('pickup',.22),('hurt',.24),('step',.09),('build',.3),('ambient',8)]:
 samples=[];rate=22050
 for i in range(int(duration*rate)):
  t=i/rate;envelope=max(0,1-t/duration)
  if name=='shot':v=(rng.uniform(-1,1)*.65+math.sin(t*220*math.tau)*.3)*math.exp(-t*32)
  elif name=='ambient':v=(math.sin(t*57*math.tau)+math.sin(t*61*math.tau))*.012+rng.uniform(-1,1)*.015
  elif name in ('pickup','build'):v=math.sin(t*(660 if name=='pickup' else 180)*math.tau)*envelope*.25
  elif name=='reload':v=rng.uniform(-1,1)*.28*math.exp(-((t-.12)/.025)**2)+rng.uniform(-1,1)*.35*math.exp(-((t-.75)/.018)**2)
  else:v=rng.uniform(-1,1)*.22*envelope*envelope
  samples.append(struct.pack('<h',int(max(-1,min(1,v))*32767)))
 with wave.open(str(a.out/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(samples))
(a.assets/'recipe.json').write_text(json.dumps({'generator':'scripts/create_assets.py','version':1,'blender':bpy.app.version_string,'palette':palette,'audio_seed':7,'notes':'Original editable models. Selected Quaternius downloads unavailable due Drive quota; these are temporary original stand-ins, not Quaternius assets.'},indent=2)+'\n')
