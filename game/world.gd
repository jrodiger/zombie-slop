extends Node3D
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
const LIMIT=124
const POPULATION=18
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
var containers:Array=[]
var roofs:Array=[]
var respawn_left:float=25
func configure(owner_game):
 game=owner_game;rng.seed=4815
 navigation=AStarGrid2D.new();navigation.region=Rect2i(-126,-126,252,252);navigation.cell_size=Vector2.ONE;navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 environment()
 box(Vector3(0,-.3,0),Vector3(248,.6,248),Color("586044"),true)
 box(Vector3(0,.015,0),Vector3(11,.03,246),Color("343d3c"),false)
 for z in [-17,65]:box(Vector3(0,.018,z),Vector3(246,.035,10),Color("343d3c"),false)
 for x in [-54,54]:box(Vector3(x,.018,0),Vector3(8,.035,190),Color("39413d"),false)
 for z in range(-118,120,8):box(Vector3(0,.04,z),Vector3(.13,.015,2.5),Color("b0aa84"),false)
 for side in [-1,1]:
  box(Vector3(side*6.6,.09,0),Vector3(1.7,.18,242),Color("959986"),true,false)
  for z in [-54,-34,7,33,90]:box(Vector3(side*14,.05,z),Vector3(14,.1,3),Color("8a8e7d"),true,false)
 for house in HOUSES:interior_house(house.at,house.address,house.home,house.asset)
 for house in HOUSES:
  var street=(8 if house.at.x>0 else -8) if absf(house.at.x)<40 else (54 if house.at.x>0 else -54)
  box(house.at+Vector3(0,.035,-6),Vector3(1.4,.07,4),Color("959986"),true,false)
  box(Vector3((house.at.x+street)/2,.035,house.at.z-8),Vector3(absf(house.at.x-street),.07,1.4),Color("959986"),true,false)
 for side in [-1,1]:
  for z in [-57,-35,5,33]:
   for offset in [-7,7]:box(Vector3(side*24+offset,.7,z),Vector3(.12,1.4,12),Color("6b664e"),true)
 var trees:Array[Transform3D]=[];var birches:Array[Transform3D]=[];var dead:Array[Transform3D]=[]
 var bushes:Array[Transform3D]=[];var grasses:Array[Transform3D]=[];var rocks:Array[Transform3D]=[]
 for i in range(350):
  var x=rng.randf_range(-118,118);var z=rng.randf_range(-118,118);var at=Vector3(x,0,z)
  if absf(x)<10 or absf(z+17)<8 or absf(z-65)<8 or absf(absf(x)-54)<6 or near_house(at,12):continue
  var scale=rng.randf_range(.8,1.25);var t=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),at)
  if i%7==0:dead.append(t)
  elif i%3==0:birches.append(t)
  else:trees.append(t)
  collider(at+Vector3.UP,Vector3(.55,2,.55),true)
 for i in range(1700):
  var x=rng.randf_range(-120,120);var z=rng.randf_range(-120,120);var at=Vector3(x,.035,z)
  if near_house(at,7):continue
  # Leave a worn strip on active routes; clumps grow along edges and cracks.
  if absf(x)<5.8 or absf(z+17)<4.8 or absf(z-65)<4.8 or absf(absf(x)-54)<4.2:continue
  var scale=rng.randf_range(.7,1.4);var t=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),at)
  if i%16==0:rocks.append(t)
  elif i%6==0:bushes.append(t)
  else:grasses.append(t)
 make_multimesh("tree",trees);make_multimesh("tree-birch",birches);make_multimesh("tree-dead",dead)
 make_multimesh("bush",bushes);make_multimesh("grass",grasses);make_multimesh("rock",rocks)
 for i in range(9):
  var at=Vector3(3.2 if i%2 else -3.1,0,-55+i*17 if i<7 else (-101 if i==7 else 107))
  var kind="wreck" if i%3==0 else "car";var car=prop(kind,at,0,180);car.rotation.y=.15 if i%2 else -.22
  var body=collider(at+Vector3(0,.775,0),Vector3(2,1.55,4.2),true);body.rotation.y=car.rotation.y
 for x in [-2,2]:
  for z in [-2,2]:box(Vector3(-48+x,6,-8+z),Vector3(.25,12,.25),Color("5e746b"),true)
 box(Vector3(-48,12.5,-8),Vector3(5.5,3,5.5),Color("778b7b"),true)
 for x in [-8,8]:prop("road-sign",Vector3(x,0,-22),.7,100)
 for x in [-8.7,8.7]:
  for z in [-62,-8,42,95]:
   prop("hydrant",Vector3(x,0,z),0,65);collider(Vector3(x,.425,z),Vector3(.3,.85,.3),true)
 for at in [Vector3(-4.6,0,-18),Vector3(5,0,-14),Vector3(53,0,65)]:
  prop("road-barrier",at,0,100);collider(at+Vector3.UP*.6,Vector3(2.5,1.2,.48),true)
 for boundary in [[Vector3(-124,3,0),Vector3(1,6,248)],[Vector3(124,3,0),Vector3(1,6,248)],[Vector3(0,3,-124),Vector3(248,6,1)],[Vector3(0,3,124),Vector3(248,6,1)]]:collider(boundary[0],boundary[1],true)
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
  var offset=game.player.global_position-entry.at
  entry.node.visible=not (absf(offset.x)<5.9 and absf(offset.z)<4.9 and offset.y<3)
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
  if regions.get(cell,-1)!=regions.get(player_cell,-2):continue
  var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.36;capsule.height=1.75;q.shape=capsule;q.transform=Transform3D(Basis(),at+Vector3.UP*.9);q.collision_mask=7
  if not get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():continue
  spawn_zombie(at,alive.size());return true
 return false
func prop(kind:String,at:Vector3,yaw:float=0,distance:float=45):
 var model=game.assets.model(kind);add_child(model);model.position=at;model.rotation.y=yaw;visibility_distance(model,distance);return model
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
 if nav and at.y+size.y*.5>.6 and at.y-size.y*.5<1.6:
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
 for x in range(-126,126):
  for z in range(-126,126):
   var first=Vector2i(x,z)
   if regions.has(first) or navigation.is_point_solid(first):continue
   region_id+=1;var pending:Array[Vector2i]=[first];regions[first]=region_id
   while not pending.is_empty():
    var cell=pending.pop_back()
    for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var next=cell+offset
     if navigation.is_in_boundsv(next) and not regions.has(next) and not navigation.is_point_solid(next):regions[next]=region_id;pending.append(next)
func window_collision(at:Vector3,axis:String,fixed:float,lo:float,hi:float,centers:Array):
 var cursor=lo
 for center in centers+[hi+.8]:
  var edge=float(center)-.8
  if edge>cursor:
   var offset=Vector3(fixed,1.6,(cursor+edge)*.5) if axis=="x" else Vector3((cursor+edge)*.5,1.6,fixed)
   var size=Vector3(.2,3.2,edge-cursor) if axis=="x" else Vector3(edge-cursor,3.2,.2)
   collider(at+offset,size,true)
  cursor=float(center)+.8
 for center in centers:
  var glass_at=Vector3(fixed,1.775,center) if axis=="x" else Vector3(center,1.775,fixed)
  var glass_size=Vector3(.025,1.38,1.5) if axis=="x" else Vector3(1.5,1.38,.025)
  collider(at+glass_at,glass_size,false)
 var offset=Vector3(fixed,.575,(lo+hi)*.5) if axis=="x" else Vector3((lo+hi)*.5,.575,fixed)
 var size=Vector3(.2,.95,hi-lo) if axis=="x" else Vector3(hi-lo,.95,.2)
 collider(at+offset,size,true)
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
 for x in [-6,6]:window_collision(at,"x",x,-5,5,[-2.5,2.5])
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
  prop("bed",at+Vector3(-3,.16,3));collider(at+Vector3(-3,.5,3),Vector3(1.5,.68,2.1),true)
  prop("stove",at+Vector3(-1.45,.16,-3.8));collider(at+Vector3(-1.45,.66,-3.8),Vector3(.7,1,.6),true)
 else:
  prop("table",at+Vector3(-3,.16,2.5));collider(at+Vector3(-3,.96,2.5),Vector3(1.8,.1,1),false)
  prop("shelf",at+Vector3(3,.16,3.5))
  for y in [.1,.65,1.2,1.75]:collider(at+Vector3(3,.16+y,3.5),Vector3(1.5,.09,.5),false)
 var key=address.to_lower().replace(" ","-")
 var fridge_stock=[{"id":key+"-food","kind":"food","amount":2},{"id":key+"-water","kind":"water","amount":2}]
 var drawer_stock=[{"id":key+"-scrap","kind":"scrap","amount":4},{"id":key+"-ammo","kind":"ammo","amount":12}]
 var safe_stock=[{"id":key+"-medkit","kind":"medkit","amount":1},{"id":key+"-rifle-ammo","kind":"rifle_ammo","amount":24}]
 if safe:drawer_stock=[{"id":"porch-wood","kind":"wood","amount":12},{"id":"porch-scrap","kind":"scrap","amount":4}]
 if address=="8 Cedar Lane":safe_stock=[{"id":"rifle-supply","kind":"rifle","amount":1},{"id":"rifle-rounds","kind":"rifle_ammo","amount":90},{"id":"supply-house-3","kind":"medkit","amount":2}]
 if address=="12 Cedar Lane":safe_stock=[{"id":"shotgun-porch","kind":"shotgun","amount":1},{"id":"shotgun-shells","kind":"shells","amount":18}]
 add_container(key+"-fridge","Refrigerator",address,"fridge",at+Vector3(-4.5,.16,-3.5),Vector3(.8,1.8,.7),fridge_stock)
 add_container(key+"-drawer","Kitchen drawers",address,"drawer",at+Vector3(4,.16,-3.8),Vector3(1.2,.86,.55),drawer_stock)
 add_container(key+"-safe","Bedroom safe",address,"safe",at+Vector3(4.7,.16,3.5),Vector3(.7,.8,.65),safe_stock)
 for offset in [Vector3(-7,0,-4),Vector3(7,0,-4)]:prop("trashcan",at+offset,0,60)
 prop("trashbag",at+Vector3(7.6,0,-4.3),0,50);prop("grill",at+Vector3(4,0,7),0,55)
func near_house(at:Vector3,radius:float) -> bool:
 for house in HOUSES:
  if at.distance_to(house.at)<radius:return true
 return false
func furnishing_clear(at:Vector3,size:Vector3) -> bool:
 var candidate=AABB(at-Vector3(size.x/2,0,size.z/2),size)
 for record in game.state.objects:
  var dimensions:Vector3=game.catalog.ITEMS[record.kind].size
  var position=Vector3(record.position[0],record.position[1],record.position[2])
  var bounds=Transform3D(Basis(Vector3.UP,float(record.yaw)),position)*AABB(Vector3(-dimensions.x/2,0,-dimensions.z/2),dimensions)
  if candidate.intersects(bounds):return false
 return true
func add_container(ident:String,title:String,address:String,kind:String,at:Vector3,size:Vector3,stock:Array):
 # Existing home arrangements take priority over newly introduced fixtures.
 if address=="14 Cedar Lane" and not furnishing_clear(at,size):return
 var visual=prop(kind,at,0,40);var body=collider(at+Vector3.UP*size.y*.5,size,true)
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
  else:tween.tween_property(door,"rotation:y",-.7,.25)
 game.sound("search",.45)
func close_containers():
 for entry in containers:
  if entry.has("tween") and entry.tween.is_valid():entry.tween.kill()
  var door=entry.door
  if door!=null:door.position=entry.rest;door.rotation.y=0
func model_bounds(node:Node3D) -> AABB:
 var result=AABB()
 for child in node.get_children():
  if child is MeshInstance3D:result=result.merge(child.transform*child.get_aabb())
  elif child is Node3D:result=result.merge(child.transform*model_bounds(child))
 return result
func add_loot(ident:String,kind:String,at:Vector3,amount:int=1):
 if ident in game.state.collected:return
 var root=prop(kind,at,0,40)
 loot.append({"id":ident,"kind":kind,"amount":amount,"node":root})
func seed_loot():
 add_loot("fern","plant",Vector3(-12,.1,13))
 add_loot("radio","radio",Vector3(21.5,1.155,3.2))
 add_loot("chair","chair",Vector3(-26,.16,5))
 add_loot("table","table",Vector3(28,.16,10))
 add_loot("guitar","guitar",Vector3(27,.2,-34))
 add_loot("shelf","shelf",Vector3(21,.16,-34))
func nearest_loot(at:Vector3):
 var best=null;var distance=2.2
 for item in loot:
  if not is_instance_valid(item.node):continue
  var d=at.distance_to(item.node.global_position)
  if d<distance:
   var ray=PhysicsRayQueryParameters3D.create(at+Vector3.UP*1.2,item.node.global_position+Vector3.UP*.35,1)
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
 for point in navigation.get_point_path(first,last,false):result.append(Vector3(point.x,.2,point.y))
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
