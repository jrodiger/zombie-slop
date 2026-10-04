extends Node3D
const LootTables=preload("res://game/loot_tables.gd")
const Vehicle=preload("res://game/vehicle.gd")
const Buildings=preload("res://game/buildings.gd")
const Zombie=preload("res://game/zombie.gd")
var game
var navigation:AStarGrid2D
var static_blocks:Array=[]
var loot:Array=[]
var safe_center=Vector3(-24,0,30)
var rng=RandomNumberGenerator.new()
var sun:DirectionalLight3D
var box_batches:Dictionary={}
var regions:Dictionary={}
const LIMIT=164
const POPULATION=18
const CAMPS=[Vector3(-98,0,48),Vector3(110,0,-58)]
const HOUSES=[
 {"at":Vector3(-24,0,30),"asset":"house","address":"14 Cedar Lane","home":true},
 {"at":Vector3(25,0,-32),"asset":"house-ochre","address":"8 Cedar Lane","home":false},
 {"at":Vector3(-25,0,-52),"asset":"house-red","address":"3 Cedar Lane","home":false},
 {"at":Vector3(25,0,-55),"asset":"house-blue","address":"4 Cedar Lane","home":false},
 {"at":Vector3(-26,0,-29),"asset":"house","address":"7 Cedar Lane","home":false},
 {"at":Vector3(25,0,7),"asset":"house-red","address":"11 Cedar Lane","home":false},
 {"at":Vector3(-25,0,7),"asset":"house-blue","address":"12 Cedar Lane","home":false},
 {"at":Vector3(25,0,33),"asset":"house-blue","address":"13 Cedar Lane","home":false},
 {"at":Vector3(-68,0,-42),"asset":"house-ochre","address":"2 Orchard Way","home":false},
 {"at":Vector3(68,0,-42),"asset":"house","address":"3 Orchard Way","home":false},
 {"at":Vector3(-68,0,23),"asset":"house-red","address":"8 Orchard Way","home":false},
 {"at":Vector3(68,0,23),"asset":"house-ochre","address":"9 Orchard Way","home":false},
 {"at":Vector3(-34,0,91),"asset":"house-blue","address":"2 Mill Road","home":false},
 {"at":Vector3(34,0,91),"asset":"house-red","address":"3 Mill Road","home":false},
]
var properties:Array=[]
var furnishings:Array=[]
var paths:Array=[]
var buildings
var containers:Array=[]
var roofs:Array=[]
var vehicles:Array=[]
var respawn_left:float=25
func configure(owner_game):
 game=owner_game;rng.seed=4815
 navigation=AStarGrid2D.new();navigation.region=Rect2i(-166,-166,332,332);navigation.cell_size=Vector2.ONE;navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 environment()
 terrain()
 road_tiles()
 buildings=Buildings.new();buildings.configure(self)
 for i in range(HOUSES.size()):
  var house=HOUSES[i]
  if house.home:
   interior_house(house.at,house.address,true,house.asset);home_yard(house.at)
   properties.append({"at":house.at,"basis":Basis.IDENTITY,"width":12,"depth":10,"address":house.address,"plan":"home"})
  else:
   var plan=["cottage","townhouse","cottage","townhouse","cottage","farmhouse","cottage","townhouse","farmhouse","cottage","cottage","farmhouse","townhouse","farmhouse"][i]
   var street=Vector3((6.6 if house.at.x>0 else -6.6) if absf(house.at.x)<40 else (58 if house.at.x>0 else -58),0,house.at.z)
   var yaw=PI/2 if house.at.x>0 else -PI/2
   if house.address.contains("Mill"):street=Vector3(house.at.x,0,70);yaw=0
   buildings.create(house.at,house.address,plan,yaw,street)
 for shop in [{"at":Vector3(27,0,-106),"address":"CEDAR AUTO & FUEL","plan":"garage","yaw":PI/2},{"at":Vector3(-28,0,-108),"address":"CEDAR MARKET","plan":"grocery","yaw":-PI/2},{"at":Vector3(-69,0,-88),"address":"ORCHARD MART","plan":"convenience","yaw":-PI/2}]:
  buildings.create(shop.at,shop.address,shop.plan,shop.yaw,Vector3(0,0,shop.at.z))
 for plot in [{"at":Vector3(-116,0,-68),"address":"1 Meadow Farm"},{"at":Vector3(-116,0,48),"address":"2 Meadow Farm"}]:
  plot.at.y=ground_height(plot.at.x,plot.at.z)
  buildings.create(plot.at,plot.address,"farmhouse",-PI/2,Vector3(-107,plot.at.y,plot.at.z))
  for z in range(5):box(plot.at+Vector3(-20,.04,-8+z*3),Vector3(15,.08,1.2),Color("635441"),false)
 var pines:Array[Transform3D]=[];var willows:Array[Transform3D]=[];var flowers:Array[Transform3D]=[];var logs:Array[Transform3D]=[];var shrubs:Array[Transform3D]=[]
 var trees:Array[Transform3D]=[];var birches:Array[Transform3D]=[];var dead:Array[Transform3D]=[]
 var bushes:Array[Transform3D]=[];var grasses:Array[Transform3D]=[];var rocks:Array[Transform3D]=[]
 for i in range(1650):
  var x=rng.randf_range(-158,158);var z=rng.randf_range(-158,158);var at=Vector3(x,ground_height(x,z),z)
  if (x>4.5 and x<22.5 and z> -115.5 and z< -96.5) or (x>76 and minf(absf(z+75),absf(z-55))<5) or river_distance(x,z)<8 or absf(x)<10 or absf(z+17)<8 or absf(z-65)<8 or absf(absf(x)-54)<6 or (absf(x+105)<4 and absf(z)<135) or near_house(at,12) or near_landmark(at,7):continue
  var scale=rng.randf_range(.8,1.25);var t=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),at)
  if i%11==0:willows.append(t)
  elif i%4==0:pines.append(t)
  elif i%7==0:dead.append(t)
  elif i%3==0:birches.append(t)
  else:trees.append(t)
  collider(at+Vector3.UP,Vector3(.55,2,.55),true)
 for i in range(5700):
  var x=rng.randf_range(-160,160);var z=rng.randf_range(-160,160);var at=Vector3(x,ground_height(x,z)+.035,z)
  if (x>4.5 and x<22.5 and z> -115.5 and z< -96.5) or near_house(at,9) or near_landmark(at,4.5) or river_distance(x,z)<4 or (x>76 and minf(absf(z+75),absf(z-55))<3):continue
  # Leave a worn strip on active routes; clumps grow along edges and cracks.
  if absf(x)<5.8 or absf(z+17)<4.8 or absf(z-65)<4.8 or absf(absf(x)-54)<4.2 or (absf(x+105)<2.3 and absf(z)<135):continue
  var scale=rng.randf_range(.7,1.4);var t=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),at)
  if i%37==0:logs.append(t)
  elif i%17==0:flowers.append(t)
  elif i%9==0:shrubs.append(t)
  elif i%16==0:rocks.append(t)
  elif i%6==0:bushes.append(t)
  else:grasses.append(t)
 make_multimesh("tree-pine",pines);make_multimesh("tree-willow",willows);make_multimesh("flowers",flowers);make_multimesh("woodlog",logs);make_multimesh("bush-berries",shrubs)
 make_multimesh("tree",trees);make_multimesh("tree-birch",birches);make_multimesh("tree-dead",dead)
 make_multimesh("bush",bushes);make_multimesh("grass",grasses);make_multimesh("rock",rocks)
 var models=["car","car","car-sports","car-sports","car-truck","car-truck"]
 for i in range(models.size()):
  var car=Vehicle.new();add_child(car);car.configure(game,"parked-"+str(i),models[i],Vector3(3.1 if i%2 else -3.1,.05,-55+i*22),.1 if i%2 else PI);vehicles.append(car)
 prop("wreck",Vector3(58,0,58),.2,100);collider(Vector3(58,.925,58),Vector3(2.3,1.85,4.8),true)
 for z in [-75,55]:
  box(Vector3(river_x(z),.08,z),Vector3(19,.16,3),Color("69563c"),true,false)
  for side in [-1,1]:box(Vector3(river_x(z),.65,z+side*1.6),Vector3(19,1.1,.12),Color("6b664e"),true)
 for at in CAMPS:
  at.y=ground_height(at.x,at.z);buildings.furnishing("tent",at,.5,true,"camp");prop("campfire",at+Vector3(2,0,2),0,65);prop("woodlog",at+Vector3(-2,0,2),.2,65)
  var flame=MeshInstance3D.new();var fire=CylinderMesh.new();fire.top_radius=.025;fire.bottom_radius=.20;fire.height=.5;fire.radial_segments=5;flame.mesh=fire;flame.position=at+Vector3(2,.40,2);add_child(flame)
  var glow=StandardMaterial3D.new();glow.albedo_color=Color(1,.40,.05,.85);glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glow.emission_enabled=true;glow.emission=Color(1,.28,.01);glow.emission_energy_multiplier=1.4;flame.material_override=glow
 var raft_at=Vector3(river_x(26)-4.8,-.27,26)
 buildings.furnishing("raft",raft_at,.25,true,"riverbank");prop("raft-paddle",Vector3(river_x(26)-7.0,ground_height(river_x(26)-7,26)+.05,26),.55,65);prop("raft-paddle",Vector3(river_x(26)-7.6,ground_height(river_x(26)-7.6,27)+.05,27),.55,65)
 for x in [-2,2]:
  for z in [-2,2]:box(Vector3(-48+x,6,-8+z),Vector3(.25,12,.25),Color("5e746b"),true)
 box(Vector3(-48,12.5,-8),Vector3(5.5,3,5.5),Color("778b7b"),true)
 for x in [-8,8]:street_sign(Vector3(x,0,-22),"CEDAR LANE")
 for x in [-8.7,8.7]:
  for z in [-62,-8,42,95]:
   prop("hydrant",Vector3(x,0,z),0,65);collider(Vector3(x,.425,z),Vector3(.3,.85,.3),true)
 for at in [Vector3(-4.6,0,-18),Vector3(5,0,-14),Vector3(53,0,65)]:
  prop("road-barrier",at,0,100);collider(at+Vector3.UP*.6,Vector3(2.5,1.2,.48),true)
 # Boundaries extend above the highest new hillside, including the corners.
 for boundary in [[Vector3(-164,8,0),Vector3(1,16,328)],[Vector3(164,8,0),Vector3(1,16,328)],[Vector3(0,8,-164),Vector3(328,16,1)],[Vector3(0,8,164),Vector3(328,16,1)]]:collider(boundary[0],boundary[1],true)
 build_box_batches();build_regions();seed_loot()
 for i in range(POPULATION):
  var spawn=Vector3(rng.randf_range(-9,12),.2,rng.randf_range(-65,-5))
  if i>=12:spawn=Vector3(25+rng.randf_range(-8,8),.2,-32+rng.randf_range(-8,8))
  if i==0:spawn=Vector3(0,.2,7)
  for attempt in range(32):
   if not navigation.is_point_solid(Vector2i(roundi(spawn.x),roundi(spawn.z))):break
   spawn=Vector3(rng.randf_range(-9,12),.2,rng.randf_range(-65,-5))
  spawn_zombie(spawn,i)
func _physics_process(delta):
 if game==null or game.player==null or not game.running or game.overlay:return
 for entry in roofs:
  var offset=entry.get("basis",Basis.IDENTITY).inverse()*(game.player.global_position-entry.at)
  var inside=absf(offset.x)<float(entry.get("width",12))*.5-.1 and absf(offset.z)<float(entry.get("depth",10))*.5-.1 and offset.y<float(entry.get("height",3.2))
  entry.node.visible=not (inside and game.player.camera.global_position.y>entry.at.y+float(entry.get("height",3.2))-.05)
 respawn_left-=delta
 if respawn_left<=0:respawn_left=15;try_respawn()
func spawn_zombie(at:Vector3,index:int):
 var enemy=Zombie.new();add_child(enemy);enemy.configure(game,at,index);return enemy
func try_respawn() -> bool:
 var alive=get_tree().get_nodes_in_group("zombies").filter(func(enemy):return enemy.alive)
 if alive.size()>=POPULATION:return false
 for attempt in range(32):
  var at=Vector3(rng.randf_range(-110,110),.2,rng.randf_range(-110,110))
  if at.distance_to(game.player.global_position)<32 or at.distance_to(safe_center)<26:continue
  if (at-game.player.global_position).normalized().dot(-game.player.camera.global_basis.z)>.2:continue
  var cell=Vector2i(roundi(at.x),roundi(at.z))
  if navigation.is_point_solid(cell):continue
  var player_cell=Vector2i(roundi(game.player.global_position.x),roundi(game.player.global_position.z))
  if regions.get(cell,-1)!=regions.get(player_cell,-2) or river_distance(at.x,at.z)<4:continue
  at.y=ground_height(at.x,at.z)+.2
  var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.36;capsule.height=1.75;q.shape=capsule;q.transform=Transform3D(Basis(),at+Vector3.UP*.9);q.collision_mask=7
  if not get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():continue
  spawn_zombie(at,rng.randi_range(0,99));return true
 return false
func prop(kind:String,at:Vector3,yaw:float=0,distance:float=45):
 var model=game.assets.model(kind);add_child(model);model.position=at;model.rotation.y=yaw;visibility_distance(model,distance);return model
func nearest_vehicle(at:Vector3):
 var closest=null;var distance=3.4
 for car in vehicles:
  var d=at.distance_to(car.global_position)
  if d>=distance:continue
  var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP,car.global_position+Vector3.UP,1))
  if not hit.is_empty() and hit.collider!=car:continue
  closest=car;distance=d
 return closest
static func river_x(z:float) -> float:
 return 91+sin(z*.035)*4
static func river_distance(x:float,z:float) -> float:
 return absf(x-river_x(z))
static func ground_height(x:float,z:float) -> float:
 var hill=smoothstep(76,115,absf(x))*(3.5+sin(z*.035)*1.4)+smoothstep(138,162,absf(z))*3.0
 var bridge=minf(absf(z+75),absf(z-55))
 # Taper the flattened bridge approaches back into the hillside. A hard
 # x-boundary would create a cliff at the eastern end of the crossing.
 if bridge<12 and x>74:
  var approach=smoothstep(74,80,x)*(1-smoothstep(104,115,x))
  hill*=lerpf(1,smoothstep(4,12,bridge),approach)
 # Flatten the two rural farm plots, with gently blended shoulders.
 for center in [Vector2(-116,-68),Vector2(-116,48)]:
  var d=maxf(absf(x-center.x)/13,absf(z-center.y)/11);hill=lerpf(4.0,hill,smoothstep(1,1.6,d))
 if x>70:hill=lerpf(hill,-1.6,1-smoothstep(3,9,river_distance(x,z)))
 return hill
func terrain():
 var mesh=ArrayMesh.new();var vertices=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array();var n=133
 for z in range(n):
  for x in range(n):
   var px=-165+x*2.5;var pz=-165+z*2.5;var h=ground_height(px,pz);vertices.append(Vector3(px,h,pz));colors.append((Color("675f45") if river_distance(px,pz)<9 else Color("586044")).srgb_to_linear())
 for z in range(n-1):
  for x in range(n-1):
   var a=z*n+x;indices.append_array(PackedInt32Array([a,a+1,a+n,a+1,a+n+1,a+n]))
 var normals=PackedVector3Array();normals.resize(vertices.size());normals.fill(Vector3.ZERO)
 for i in range(0,indices.size(),3):
  var a=indices[i];var b=indices[i+1];var c=indices[i+2];var normal=(vertices[c]-vertices[a]).cross(vertices[b]-vertices[a]).normalized();normals[a]+=normal;normals[b]+=normal;normals[c]+=normal
 for i in range(normals.size()):normals[i]=normals[i].normalized()
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=1
 var noise=FastNoiseLite.new();noise.seed=4815;noise.frequency=.018
 var texture=NoiseTexture2D.new();texture.width=256;texture.height=256;texture.seamless=true;texture.noise=noise
 var gradient=Gradient.new();gradient.set_color(0,Color(.72,.72,.72));gradient.set_color(1,Color.WHITE);texture.color_ramp=gradient
 material.albedo_texture=texture;material.uv1_triplanar=true;material.uv1_world_triplanar=true;material.uv1_scale=Vector3.ONE*.05
 mesh.surface_set_material(0,material)
 var node=MeshInstance3D.new();node.mesh=mesh;add_child(node);var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;node.add_child(body);var shape=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();body.add_child(shape)
 # One narrow winding river with shallow banks and two footbridges.
 for z in range(-164,164,4):
  var water=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(6.8,4.2);water.mesh=plane;water.position=Vector3(river_x(z),-.35,z+2);add_child(water)
  var wet=StandardMaterial3D.new();wet.albedo_color=Color(.15,.31,.33,.82);wet.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;wet.roughness=.25;water.material_override=wet
func sidewalk(side:int):
 # A flat walking strip with sloped outer edges, rather than a vertical curb.
 var mesh=ArrayMesh.new();var points=PackedVector3Array();var indices=PackedInt32Array()
 for z in [-161,161]:
  for xy in [Vector2(-1.3,0),Vector2(-.85,.14),Vector2(.85,.14),Vector2(1.3,0)]:points.append(Vector3(xy.x,xy.y,z))
 for i in range(3):indices.append_array(PackedInt32Array([i,i+1,i+4,i+1,i+5,i+4]))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_INDEX]=indices
 var normals=PackedVector3Array();normals.resize(8);normals.fill(Vector3.UP);arrays[Mesh.ARRAY_NORMAL]=normals;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var node=MeshInstance3D.new();node.mesh=mesh;node.position=Vector3(side*6.6,0,0);add_child(node)
 var material=StandardMaterial3D.new();material.albedo_color=Color("959986");material.roughness=1;node.material_override=material
 var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;node.add_child(body);var shape=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();body.add_child(shape)
func road_tiles():
 # One coherent custom asphalt material; cracks never displace walking geometry.
 var vertices=PackedVector3Array();var normals=PackedVector3Array();var indices=PackedInt32Array()
 var intervals=[-164,-135,-22,-12,60,70,135,164]
 for row in range(intervals.size()-1):
  var lo=float(intervals[row]);var hi=float(intervals[row+1]);var cross=(lo==-22 or lo==60)
  var spans=[Vector2(-164,164)] if cross else ([Vector2(-107,-103),Vector2(-58,-50),Vector2(-5.5,5.5),Vector2(50,58)] if lo>=-135 and hi<=135 else [Vector2(-5.5,5.5)])
  for span in spans:
   var nx=ceili((span.y-span.x)/2);var nz=ceili((hi-lo)/2)
   for z in range(nz):
    for x in range(nx):
     var xl=lerpf(span.x,span.y,float(x)/nx);var xr=lerpf(span.x,span.y,float(x+1)/nx);var zl=lerpf(lo,hi,float(z)/nz);var zr=lerpf(lo,hi,float(z+1)/nz);var base=vertices.size()
     for point in [Vector2(xl,zl),Vector2(xr,zl),Vector2(xr,zr),Vector2(xl,zr)]:vertices.append(Vector3(point.x,ground_height(point.x,point.y)+.04,point.y));normals.append(Vector3.UP)
     indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
 # The fuel forecourt joins the street with the same surface and collision.
 for z in range(17):
  for x in range(16):
   var base=vertices.size()
   for point in [Vector2(5.5+x,-114.5+z),Vector2(6.5+x,-114.5+z),Vector2(6.5+x,-113.5+z),Vector2(5.5+x,-113.5+z)]:vertices.append(Vector3(point.x,ground_height(point.x,point.y)+.04,point.y));normals.append(Vector3.UP)
   indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);var material=ShaderMaterial.new();material.shader=load("res://game/road.gdshader");mesh.surface_set_material(0,material)
 var node=MeshInstance3D.new();node.mesh=mesh;node.name="ContinuousRoad";add_child(node)
 var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;node.add_child(body);var shape=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();body.add_child(shape)
 for z in range(-160,161,8):
  if absf(z+17)<7 or absf(z-65)<7:continue
  box(Vector3(0,ground_height(0,z)+.043,z),Vector3(.13,.004,3.4),Color("c5c2a5"),false)
func home_yard(at:Vector3):
 # Main entrance faces Cedar Lane; the south gate serves the existing workshop.
 for side in [-1,1]:box(at+Vector3(side*8,.65,7),Vector3(.12,1.3,0.12),Color("6b664e"),true)
 box(at+Vector3(-8,.65,-.5),Vector3(.12,1.3,15),Color("6b664e"),true)
 for entry in [[-6.15,3.7],[3.15,7.7]]:box(at+Vector3(8,.65,entry[0]),Vector3(.12,1.3,entry[1]),Color("6b664e"),true)
 box(at+Vector3(0,.65,7),Vector3(16,1.3,.12),Color("6b664e"),true)
 for side in [-1,1]:box(at+Vector3(side*4.9,.65,-8),Vector3(6.2,1.3,.12),Color("6b664e"),true)
 box(at+Vector3(11.7,.035,-2.5),Vector3(11.4,.07,1.5),Color("959986"),true,false)
func footstep(at:Vector3) -> String:
 for house in HOUSES:
  if absf(at.x-house.at.x)<6 and absf(at.z-house.at.z)<5:return "step-wood"
 if absf(at.x)<8 or absf(at.z+17)<6 or absf(at.z-65)<6 or absf(absf(at.x)-54)<5:return "step-road"
 return "step-grass"
func environment():
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_SKY
 var sky=Sky.new();var material=ProceduralSkyMaterial.new();material.sky_top_color=Color("718b9b");material.sky_horizon_color=Color("c3b99b");material.ground_horizon_color=Color("b2af8d");material.ground_bottom_color=Color("454e39");material.sun_angle_max=10;sky.sky_material=material;e.sky=sky
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("d6d9c8");e.ambient_light_energy=.35;e.tonemap_mode=Environment.TONE_MAPPER_ACES
 e.fog_enabled=true;e.fog_light_color=Color("a3b2b2");e.fog_density=.0018
 env.environment=e;add_child(env)
 sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-32,-35,0);sun.light_color=Color("fff0d9");sun.light_energy=.85;sun.shadow_enabled=bool(game.state.settings.shadows);sun.directional_shadow_max_distance=50;add_child(sun)
func box(at:Vector3,size:Vector3,color:Color,solid:bool,nav:bool=true):
 if not box_batches.has(color):box_batches[color]=[]
 box_batches[color].append(Transform3D(Basis.IDENTITY.scaled(size),at))
 if solid:collider(at,size,nav)
func build_box_batches():
 # Shared unit boxes preserve authored geometry while batching by material.
 var noise=FastNoiseLite.new();noise.seed=4815;noise.frequency=.025
 var texture=NoiseTexture2D.new();texture.width=256;texture.height=256;texture.seamless=true;texture.noise=noise
 var gradient=Gradient.new();gradient.set_color(0,Color(.7,.7,.7));gradient.set_color(1,Color.WHITE);texture.color_ramp=gradient
 for color in box_batches:
  var mesh=BoxMesh.new();mesh.size=Vector3.ONE
  var material=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1;mesh.material=material
  if color in [Color("586044"),Color("343d3c"),Color("39413d")]:
   material.albedo_texture=texture;material.uv1_triplanar=true;material.uv1_world_triplanar=true;material.uv1_scale=Vector3.ONE*.06
  var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=box_batches[color].size()
  for i in range(mm.instance_count):mm.set_instance_transform(i,box_batches[color][i])
  var instance=MultiMeshInstance3D.new();instance.multimesh=mm;add_child(instance)
 box_batches.clear()
func collider(at:Vector3,size:Vector3,nav:bool):
 var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=size;c.shape=s;body.add_child(c);add_child(body);body.position=at
 var ground=ground_height(at.x,at.z)
 if nav and at.y+size.y*.5>ground+.6 and at.y-size.y*.5<ground+1.6:
  # Mark grid centers inside the inflated footprint. Rounding outward adds
  # another whole cell and seals otherwise usable two-meter doorways.
  for x in range(ceili(at.x-size.x*.5-.35),floori(at.x+size.x*.5+.35)+1):
   for z in range(ceili(at.z-size.z*.5-.35),floori(at.z+size.z*.5+.35)+1):
    var cell=Vector2i(x,z)
    if navigation.is_in_boundsv(cell):navigation.set_point_solid(cell)
 return body
func build_regions():
 # Static connected components reject impossible routes before A* scans the
 # entire neighborhood. Placed barricades still use live collision/attacks.
 regions.clear();var region_id=0
 for x in range(-166,166):
  for z in range(-166,166):
   var first=Vector2i(x,z)
   if regions.has(first) or navigation.is_point_solid(first):continue
   region_id+=1;var pending:Array[Vector2i]=[first];regions[first]=region_id
   while not pending.is_empty():
    var cell=pending.pop_back()
    for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var next=cell+offset
     if navigation.is_in_boundsv(next) and not regions.has(next) and not navigation.is_point_solid(next):regions[next]=region_id;pending.append(next)
func window_collision(at:Vector3,axis:String,fixed:float,lo:float,hi:float,centers:Array,door:float=INF):
 var cursor=lo
 for center in centers+[hi+.8]:
  var edge=float(center)-.8
  if edge>cursor:
   var offset=Vector3(fixed,1.6,(cursor+edge)*.5) if axis=="x" else Vector3((cursor+edge)*.5,1.6,fixed)
   var size=Vector3(.2,3.2,edge-cursor) if axis=="x" else Vector3(edge-cursor,3.2,.2)
   collider(at+offset,size,true)
  cursor=float(center)+.8
 for center in centers:
  if center==door:continue
  var glass_at=Vector3(fixed,1.775,center) if axis=="x" else Vector3(center,1.775,fixed)
  var glass_size=Vector3(.025,1.38,1.5) if axis=="x" else Vector3(1.5,1.38,.025)
  collider(at+glass_at,glass_size,false)
 var offset=Vector3(fixed,.575,(lo+hi)*.5) if axis=="x" else Vector3((lo+hi)*.5,.575,fixed)
 var size=Vector3(.2,.95,hi-lo) if axis=="x" else Vector3(hi-lo,.95,.2)
 if is_finite(door):
  for span in [Vector2(lo,door-.8),Vector2(door+.8,hi)]:
   offset.z=(span.x+span.y)/2;size.z=span.y-span.x;collider(at+offset,size,true)
 else:collider(at+offset,size,true)
 offset.y=2.85;size.y=.7;collider(at+offset,size,false)
func interior_house(at:Vector3,address:String,safe:bool,asset:String="house"):
 var visual=prop(asset,at,0,180);var roof=visual.find_child("Roof",true,false)
 box(at+Vector3(1.95,2.3,-5.13),Vector3(.7,.42,.04),Color("343d3c"),false)
 var number=MeshInstance3D.new();var lettering=TextMesh.new();lettering.text=address.split(" ")[0];lettering.font_size=48;lettering.pixel_size=.006;lettering.depth=.003;number.mesh=lettering
 var ink=StandardMaterial3D.new();ink.albedo_color=Color("e4dfcc");ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;number.material_override=ink;number.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(number);number.position=at+Vector3(1.95,2.3,-5.16);number.rotation.y=PI;number.visibility_range_end=30
 if roof!=null:
  roofs.append({"at":at,"node":roof})
  var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0
  var shape=CollisionShape3D.new();shape.shape=roof.mesh.create_trimesh_shape();body.add_child(shape);roof.add_child(body)
 collider(at+Vector3(0,.08,0),Vector3(12,.16,10),false)
 collider(at+Vector3(0,.06,-6),Vector3(4,.12,2),false)
 for x in [-6,6]:window_collision(at,"x",x,-5,5,[-2.5,2.5],-2.5 if x==6 else INF)
 collider(at+Vector3(7,.06,-2.5),Vector3(2,.12,2.4),false)
 window_collision(at,"z",5,-6,6,[-3.5,3.5])
 window_collision(at,"z",-5,-6,-1.3,[-4]);window_collision(at,"z",-5,1.3,6,[4])
 collider(at+Vector3(0,2.85,-5),Vector3(2.6,.7,.2),false)
 for x in [-1.8,1.8]:collider(at+Vector3(x,1.35,-6.85),Vector3(.13,2.6,.13),true)
 collider(at+Vector3(0,2.7,-6),Vector3(4.4,.15,2.3),false)
 for x in [-3.4,3.4]:collider(at+Vector3(x,1.6,1),Vector3(5.2,3.2,.16),true)
 # Furnished kitchens and separate bedrooms; home leaves the rear workshop clear.
 if not safe or furnishing_clear(at+Vector3(-3,.16,-3.8),Vector3(2,1,.65)):
  prop("counter",at+Vector3(-3,.16,-3.8));collider(at+Vector3(-3,.66,-3.8),Vector3(2,1,.65),true)
  prop("bottle",at+Vector3(-2.4,1.2,-3.8))
 if not safe or furnishing_clear(at+Vector3(3,.16,-.5),Vector3(2.1,.85,.85)):
  prop("couch",at+Vector3(3,.16,-.5),PI);collider(at+Vector3(3,.58,-.5),Vector3(2.1,.85,.85),true)
 if not safe:
  var bedroom_x=-3.0 if address.hash()%2==0 else 3.0
  prop("bed",at+Vector3(bedroom_x,.16,3.7),PI);collider(at+Vector3(bedroom_x,.5,3.7),Vector3(1.5,.68,2.1),true)
  prop("table",at+Vector3(3,.16,-2));collider(at+Vector3(3,.55,-2),Vector3(1.8,.78,1),true)
  for side in [-1,1]:
   prop("chair",at+Vector3(3+side*1.4,.16,-2),-side*PI/2);collider(at+Vector3(3+side*1.4,.6,-2),Vector3(.6,.85,.6),true)
  prop("stove",at+Vector3(-1.45,.16,-3.8));collider(at+Vector3(-1.45,.66,-3.8),Vector3(.7,1,.6),true)
 else:
  for item in [{"kind":"table","at":Vector3(-3,.16,2.5)},{"kind":"shelf","at":Vector3(3,.16,3.5)},{"kind":"coffee-table","at":Vector3(3,.16,-1.9)},{"kind":"bed","at":Vector3(-4.75,.16,4.0)},{"kind":"tvstand","at":Vector3(5.2,.16,-1.0)}]:
   var model=game.assets.model(item.kind);var bounds=model_bounds(model);model.free()
   if furnishing_clear(at+item.at,bounds.size):buildings.furnishing(item.kind,at+item.at,PI/2 if item.kind=="bed" else 0,true,address)
  prop("rug",at+Vector3(3,.165,-1.7));prop("books",at+Vector3(-3,1.1,2.5));prop("wall-picture",at+Vector3(-2.8,1.7,.85),PI)
 var key=address.to_lower().replace(" ","-")
 var fridge_stock=LootTables.stock(game.state.loot_seed,address,"fridge")
 var drawer_stock=LootTables.stock(game.state.loot_seed,address,"drawer")
 var safe_stock=LootTables.stock(game.state.loot_seed,address,"safe")
 add_container(key+"-fridge","Refrigerator",address,"fridge",at+Vector3(-4.5,.16,-3.5),Vector3(.8,1.8,.7),fridge_stock,PI)
 add_container(key+"-drawer","Kitchen drawers",address,"drawer",at+Vector3(4,.16,-3.8),Vector3(1.2,.86,.55),drawer_stock,PI)
 add_container(key+"-safe","Bedroom safe",address,"safe",at+Vector3(4.7,.16,3.5),Vector3(.7,.8,.65),safe_stock)
 for offset in [Vector3(-7,0,-4),Vector3(7,0,-4)]:prop("trashcan",at+offset,0,60)
 prop("trashbag",at+Vector3(7.6,0,-4.3),0,50);prop("grill",at+Vector3(4,0,6.3),0,55)
func near_house(at:Vector3,radius:float) -> bool:
 for path in paths:
  var local=path.basis.inverse()*(at-path.at)
  if absf(local.x)<1.0+maxf(0,radius-7) and local.z>=path.end-.5 and local.z<=path.gate+3:return true
 for house in properties:
  var local=house.basis.inverse()*(at-house.at);var margin=maxf(0,radius-6)
  if absf(local.x)<float(house.width)/2+margin and absf(local.z)<float(house.depth)/2+margin:return true
  if house.plan=="garage" and absf(local.x)<11 and local.z> -18 and local.z< -4:return true
 return false
func near_landmark(at:Vector3,radius:float) -> bool:
 for center in CAMPS+[Vector3(river_x(26)-6,0,26)]:
  if Vector2(at.x-center.x,at.z-center.z).length()<radius:return true
 return false
func street_sign(at:Vector3,title:String):
 box(at+Vector3.UP*1.4,Vector3(.10,2.8,.10),Color("78857d"),true)
 box(at+Vector3.UP*2.55,Vector3(2.4,.42,.075),Color("24382d"),false)
 var label=MeshInstance3D.new();var mesh=TextMesh.new();mesh.text=title;mesh.font_size=48;mesh.pixel_size=.0055;mesh.depth=.002;label.mesh=mesh;label.position=at+Vector3(0,2.55,.042);add_child(label)
 var material=StandardMaterial3D.new();material.albedo_color=Color("e4dfcc");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;label.material_override=material;label.visibility_range_end=45
func furnishing_clear(at:Vector3,size:Vector3) -> bool:
 var candidate=AABB(at-Vector3(size.x/2,0,size.z/2),size)
 for record in game.state.objects:
  var dimensions:Vector3=game.catalog.ITEMS[record.kind].size
  var position=Vector3(record.position[0],record.position[1],record.position[2])
  var bounds=Transform3D(Basis(Vector3.UP,float(record.yaw)),position)*AABB(Vector3(-dimensions.x/2,0,-dimensions.z/2),dimensions)
  if candidate.intersects(bounds):return false
 return true
func add_container(ident:String,title:String,address:String,kind:String,at:Vector3,size:Vector3,stock:Array,yaw:float=0):
 # Existing home arrangements take priority over newly introduced fixtures.
 if address=="14 Cedar Lane" and not furnishing_clear(at,size):return
 var model={"parts":"storage-special","market":"market-shelf","chest":"storage-special" if address.hash()%3==0 else "storage"}.get(kind,kind)
 var visual=prop(model,at,yaw,55);var bounds=model_bounds(visual);var basis=Basis(Vector3.UP,yaw);var center=at+basis*bounds.get_center();var dimensions=Buildings.new().dimensions(basis,bounds.size)
 var body=collider(center,Vector3(maxf(.1,dimensions.x),maxf(.1,dimensions.y),maxf(.1,dimensions.z)),true)
 var door=visual.find_child("ContainerDoorPivot",true,false)
 containers.append({"id":ident,"title":title,"address":address,"kind":kind,"node":visual,"body":body,"stock":stock,"searched":false,"door":door,"rest":door.position if door!=null else Vector3.ZERO})
func container_items(entry:Dictionary) -> Array:
 return entry.stock.filter(func(item):return item.id not in game.state.collected)
func nearest_container(at:Vector3):
 var best=null;var distance=2.4
 for entry in containers:
  var d=at.distance_to(entry.node.global_position)
  if d>=distance:continue
  var target=entry.node.global_position+Vector3.UP*.5
  var ray=PhysicsRayQueryParameters3D.create(at+Vector3.UP*1.2,target,1)
  var hit=get_world_3d().direct_space_state.intersect_ray(ray)
  if not hit.is_empty() and hit.collider!=entry.body:continue
  best=entry;distance=d
 return best
func search_container(entry:Dictionary):
 entry.searched=true
 if entry.has("tween") and entry.tween.is_valid():entry.tween.kill()
 var door=entry.door
 if door!=null:
  var tween=create_tween()
  entry.tween=tween
  if entry.kind=="drawer":tween.tween_property(door,"position:z",entry.rest.z-.20,.25)
  else:tween.tween_property(door,"rotation:y",1.15,.25)
 game.sound("search",.45)
func close_containers():
 for entry in containers:
  if entry.has("tween") and entry.tween.is_valid():entry.tween.kill()
  var door=entry.door
  if door!=null:door.position=entry.rest;door.rotation.y=0
func model_bounds(node:Node3D) -> AABB:
 var result=node.get_aabb() if node is MeshInstance3D else AABB()
 var found=node is MeshInstance3D
 for child in node.get_children():
  if child is Node3D:
   var bounds=model_bounds(child)
   if bounds.size.length_squared()>0:
    bounds=child.transform*bounds;result=result.merge(bounds) if found else bounds;found=true
 return result
func add_loot(ident:String,kind:String,at:Vector3,amount:int=1,yaw:float=0):
 if ident in game.state.collected:return
 var model={"water":"bottle","food":"food-tin","vehicle_parts":"vehicle-parts","ammo":"ammo-box","rifle_ammo":"ammo-box","shells":"ammo-box","scrap":"scrap-parts"}.get(kind,kind)
 var root=prop(model,at,yaw,45)
 if kind in game.catalog.FURNITURE:
  var bounds=model_bounds(root);var basis=Basis(Vector3.UP,yaw);var center=at+basis*bounds.get_center();var size=Buildings.new().dimensions(basis,bounds.size);var body=collider(center,size,false);body.reparent(root,true)
 loot.append({"id":ident,"kind":kind,"amount":amount,"node":root})
func seed_loot():
 add_loot("fern","plant",Vector3(-12,.1,13))
 for item in [{"id":"radio","kind":"radio","address":"8 Cedar Lane","at":Vector3(-1.9,1.18,-5.0)},{"id":"chair","kind":"chair","address":"12 Cedar Lane","at":Vector3(-1.4,.16,-.2)},{"id":"table","kind":"table","address":"11 Cedar Lane","at":Vector3(2,.16,4)},{"id":"guitar","kind":"guitar","address":"8 Cedar Lane","at":Vector3(-3.6,.16,2.0)},{"id":"shelf","kind":"shelf","address":"8 Cedar Lane","at":Vector3(.9,3.36,0),"yaw":PI/2}]:
  var plot=properties.filter(func(entry):return entry.address==item.address)[0];add_loot(item.id,item.kind,plot.at+plot.basis*item.at,1,plot.basis.get_euler().y+float(item.get("yaw",0)))
 add_loot("camp-pack","backpack",Vector3(-96,ground_height(-96,50),50))
 add_loot("camp-fire","campfire",Vector3(-95,ground_height(-95,51),51))
 add_loot("camp-medkit","medkit",Vector3(-97,ground_height(-97,48),48))
func nearest_loot(at:Vector3):
 var best=null;var distance=2.2
 for item in loot:
  if not is_instance_valid(item.node):continue
  var d=at.distance_to(item.node.global_position)
  if d<distance:
   var ray=PhysicsRayQueryParameters3D.create(at+Vector3.UP*1.2,item.node.global_position+Vector3.UP*.15,1,item.node.get_children().filter(func(child):return child is StaticBody3D).map(func(body):return body.get_rid()))
   if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():best=item;distance=d
 return best
func route(from:Vector3,to:Vector3) -> PackedVector3Array:
 var first=Vector2i(roundi(from.x),roundi(from.z));var last=Vector2i(roundi(to.x),roundi(to.z));var result:PackedVector3Array=[]
 if not navigation.is_in_boundsv(first) or not navigation.is_in_boundsv(last):return result
 if navigation.is_point_solid(last):
  for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(2,0),Vector2i(-2,0)]:
   if navigation.is_in_boundsv(last+offset) and not navigation.is_point_solid(last+offset):last+=offset;break
 if navigation.is_point_solid(first):return result
 # Partial searches toward a still-solid destination can scan the whole grid.
 # Wait for a reachable target instead of repeating that work for every zombie.
 if navigation.is_point_solid(last):return result
 if regions.get(first,-1)!=regions.get(last,-2):return result
 for point in navigation.get_point_path(first,last,false):result.append(Vector3(point.x,ground_height(point.x,point.y)+.2,point.y))
 return result
func alert_zombies(at:Vector3,radius:float):
 for zombie in get_tree().get_nodes_in_group("zombies"):
  if zombie.global_position.distance_to(at)<radius:zombie.alerted=12

func visibility_distance(root:Node,distance:float):
 if root is GeometryInstance3D:root.visibility_range_end=distance
 for child in root.get_children():visibility_distance(child,distance)

func make_multimesh(kind:String,transforms:Array[Transform3D]):
 var model=game.assets.model(kind)
 multimesh_parts(model,Transform3D.IDENTITY,transforms)
 model.free()
func multimesh_parts(node:Node3D,local:Transform3D,transforms:Array[Transform3D]):
 var combined=local*node.transform
 if node is MeshInstance3D:
  var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=node.mesh;mm.instance_count=transforms.size()
  for i in range(transforms.size()):mm.set_instance_transform(i,transforms[i]*combined)
  var instance=MultiMeshInstance3D.new();instance.multimesh=mm;add_child(instance)
 for child in node.get_children():
  if child is Node3D:multimesh_parts(child,combined,transforms)
