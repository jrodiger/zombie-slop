extends Node3D
const Zombie=preload("res://game/zombie.gd")
var game
var navigation:AStarGrid2D
var static_blocks:Array=[]
var loot:Array=[]
var safe_center=Vector3(-24,0,30)
var rng=RandomNumberGenerator.new()
var sun:DirectionalLight3D
func configure(owner_game):
 game=owner_game;rng.seed=4815
 navigation=AStarGrid2D.new();navigation.region=Rect2i(-76,-76,152,152);navigation.cell_size=Vector2.ONE;navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 environment()
 box(Vector3(0,-.3,0),Vector3(150,.6,150),Color("45573d"),true)
 box(Vector3(0,.015,0),Vector3(11,.03,148),Color("414a48"),false)
 box(Vector3(0,.018,-17),Vector3(148,.035,10),Color("414a48"),false)
 for z in range(-70,72,8):box(Vector3(0,.04,z),Vector3(.18,.015,3.4),Color("bab9a1"),false)
 for side in [-1,1]:
  box(Vector3(side*6.6,.09,0),Vector3(1.7,.18,148),Color("7e8775"),true,false)
  for z in [-54,-34,7,33,56]:
   box(Vector3(side*14,.05,z),Vector3(14,.1,3),Color("878b7c"),true,false)
 # Two original accessible modular houses, six external Kenney houses.
 interior_house(Vector3(-24,0,30),"01 / THE GREENHOUSE",true)
 interior_house(Vector3(25,0,-32),"08 / SUPPLY HOUSE",false)
 var houses=[Vector3(-25,0,-52),Vector3(25,0,-55),Vector3(-26,0,-29),Vector3(25,0,7),Vector3(-25,0,7),Vector3(25,0,33)]
 var names=["a","c","e","h","k","n"]
 for i in range(houses.size()):
  var visual=game.assets.model("kenney-building-type-"+names[i]);add_child(visual);visual.position=houses[i];visual.scale=Vector3.ONE*3.4
  var bounds=model_bounds(visual)
  if bounds.size.length()>0:
   # Models are decorative shells; collision uses a readable conservative footprint.
   collider(houses[i]+Vector3(0,2.3,0),Vector3(12,4.6,10),true)
  label(str(i+2).pad_zeros(2)+" / EVACUATED",houses[i]+Vector3(0,1,-7),Color("d4ceac"),28)
 for side in [-1,1]:
  for z in [-57,-35,5,33]:
   # Interrupted fence lines preserve routes and yard shortcuts.
   for offset in [-7,7]:box(Vector3(side*24+offset,.7,z),Vector3(.12,1.4,12),Color("736d4b"),true)
 var trees:Array[Transform3D]=[]
 var bushes:Array[Transform3D]=[]
 var grasses:Array[Transform3D]=[]
 for i in range(90):
  var x=rng.randf_range(-70,70);var z=rng.randf_range(-70,70)
  if absf(x)<11 or absf(z+17)<8 or near_house(Vector3(x,0,z),13):continue
  var scale=rng.randf_range(.75,1.4);trees.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),Vector3(x,0,z)))
  collider(Vector3(x,1,z),Vector3(.6,2,.6),true)
 for i in range(170):
  var x=rng.randf_range(-66,66);var z=rng.randf_range(-66,66)
  if near_house(Vector3(x,0,z),9):continue
  var transform=Transform3D(Basis(Vector3.UP,rng.randf()*TAU),Vector3(x,.03,z))
  if i%3==0:bushes.append(transform)
  else:grasses.append(transform)
 make_multimesh("tree",trees)
 make_multimesh("bush",bushes)
 make_multimesh("grass",grasses)
 for i in range(7):
  var at=Vector3(3.2 if i%2 else -3.1,0,-55+i*17)
  var car=game.assets.model("car");add_child(car);car.position=at;car.rotation.y=.15 if i%2 else -.22;collider(at+Vector3(0,.6,0),Vector3(2,1.2,4.2),true)
 # Landmark: tall water tower assembled from modular structural definitions.
 for x in [-2,2]:
  for z in [-2,2]:box(Vector3(-48+x,6,-8+z),Vector3(.25,12,.25),Color("5e746b"),true)
 box(Vector3(-48,12.5,-8),Vector3(5.5,3,5.5),Color("778b7b"),true)
 label("CEDAR / WATER",Vector3(-48,14,-11),Color("f2dfb7"),38)
 label("CEDAR END",Vector3(0,4,-68),Color("dfd1a6"),42)
 label("HOME",Vector3(-24,3.8,22),Color("c0db89"),38)
 label("SUPPLIES →",Vector3(8,2,-20),Color("efb479"),32)
 box(Vector3(0,1.7,-71),Vector3(11,3.4,.5),Color("5c6857"),true)
 for boundary in [[Vector3(-75,3,0),Vector3(1,6,150)],[Vector3(75,3,0),Vector3(1,6,150)],[Vector3(0,3,-75),Vector3(150,6,1)],[Vector3(0,3,75),Vector3(150,6,1)]]:collider(boundary[0],boundary[1],true)
 seed_loot()
 for i in range(18):
  var spawn=Vector3(rng.randf_range(-9,12),.2,rng.randf_range(-65,-5))
  if i>=12:spawn=Vector3(25+rng.randf_range(-9,9),.2,-32+rng.randf_range(-8,8))
  if i==0:spawn=Vector3(0,.2,7)
  var z=Zombie.new();add_child(z);z.configure(game,spawn,i)
func environment():
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("758b89");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("d6d5b3");e.ambient_light_energy=.25;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 e.fog_enabled=true;e.fog_light_color=Color("75877e");e.fog_density=.006;e.fog_sky_affect=.5
 env.environment=e;add_child(env)
 sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_color=Color("fff0d9");sun.light_energy=.75;sun.shadow_enabled=bool(game.state.settings.shadows);sun.directional_shadow_max_distance=55;add_child(sun)
func box(at:Vector3,size:Vector3,color:Color,solid:bool,nav:bool=true):
 var mesh=MeshInstance3D.new();var b=BoxMesh.new();b.size=size;mesh.mesh=b;var material=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1;mesh.material_override=material;mesh.position=at;add_child(mesh)
 if solid:collider(at,size,nav)
func collider(at:Vector3,size:Vector3,nav:bool):
 var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=size;c.shape=s;body.add_child(c);add_child(body);body.position=at
 if nav and at.y+size.y*.5>.6 and at.y-size.y*.5<1.6:
  for x in range(floori(at.x-size.x*.5-.35),ceili(at.x+size.x*.5+.35)+1):
   for z in range(floori(at.z-size.z*.5-.35),ceili(at.z+size.z*.5+.35)+1):
    var cell=Vector2i(x,z)
    if navigation.is_in_boundsv(cell):navigation.set_point_solid(cell)
 return body
func interior_house(at:Vector3,title:String,safe:bool):
 var visual=game.assets.model("house");add_child(visual);visual.position=at
 collider(at+Vector3(0,.08,0),Vector3(12,.16,10),false)
 for x in [-6,6]:collider(at+Vector3(x,1.6,0),Vector3(.22,3.2,10),true)
 collider(at+Vector3(0,1.6,5),Vector3(12,3.2,.22),true)
 for x in [-3.65,3.65]:collider(at+Vector3(x,1.6,-5),Vector3(4.7,3.2,.22),true)
 collider(at+Vector3(0,2.85,-5),Vector3(2.6,.7,.22),false)
 for x in [-3.4,3.4]:collider(at+Vector3(x,1.6,1),Vector3(5.2,3.2,.16),true)
 collider(at+Vector3(0,3.6,0),Vector3(12,.25,10),false)
 label(title,at+Vector3(0,2.4,-5.16),Color("ebdcac"),24)
 if safe:
  label("MAKE YOURSELF AT HOME",at+Vector3(0,2.3,4.8),Color("c4d79f"),22)
  # Permanent table and shelves are valid surfaces but not inventory objects.
  for furnishing in [["table",Vector3(-3,.16,2.5)],["shelf",Vector3(3,.16,3.5)]]:
   var kind=furnishing[0];var offset=furnishing[1]
   var prop=game.assets.model(kind);add_child(prop);prop.position=at+offset
   if kind=="table":collider(at+offset+Vector3(0,.8,0),Vector3(1.8,.1,1),false)
   else:
    for y in [.1,.65,1.2,1.75]:collider(at+offset+Vector3(0,y,0),Vector3(1.5,.09,.5),false)
func label(text:String,at:Vector3,color:Color,size:int):
 var l=Label3D.new();l.text=text;l.font_size=size;l.pixel_size=.012;l.modulate=color;l.position=at;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.no_depth_test=false;add_child(l)
func near_house(at:Vector3,radius:float) -> bool:
 for house in [Vector3(-24,0,30),Vector3(25,0,-32),Vector3(-25,0,-52),Vector3(25,0,-55),Vector3(-26,0,-29),Vector3(25,0,7),Vector3(-25,0,7),Vector3(25,0,33)]:
  if at.distance_to(house)<radius:return true
 return false
func model_bounds(node:Node3D) -> AABB:
 var result=AABB()
 for child in node.get_children():
  if child is MeshInstance3D:result=result.merge(child.transform*child.get_aabb())
  elif child is Node3D:result=result.merge(child.transform*model_bounds(child))
 return result
func add_loot(ident:String,kind:String,at:Vector3,amount:int=1):
 if ident in game.state.collected:return
 var root=Node3D.new();add_child(root);root.position=at
 var visual=game.assets.model(kind if kind in ["plant","radio","guitar","chair","table","shelf"] else "crate");root.add_child(visual)
 var name=game.catalog.ITEMS[kind].name if game.catalog.ITEMS.has(kind) else kind.capitalize()+" ×"+str(amount)
 label("◇ "+name,at+Vector3(0,1.2,0),Color("e6c884"),22)
 # Label belongs to pickup so it vanishes with it.
 var marker=get_child(get_child_count()-1);remove_child(marker);root.add_child(marker);marker.position=Vector3(0,1.2,0);marker.visibility_range_end=18;marker.visibility_range_end_margin=2
 loot.append({"id":ident,"kind":kind,"amount":amount,"node":root})
func seed_loot():
 add_loot("porch-wood","wood",Vector3(-19,.1,23),12)
 add_loot("porch-scrap","scrap",Vector3(-19,.1,21),4)
 add_loot("fern","plant",Vector3(-12,.1,13))
 add_loot("radio","radio",Vector3(11,.1,4))
 add_loot("chair","chair",Vector3(-17,.1,-1))
 add_loot("table","table",Vector3(17,.1,-5))
 add_loot("guitar","guitar",Vector3(27,.2,-34))
 add_loot("shelf","shelf",Vector3(22,.2,-30))
 for i in range(16):
  var kind=["wood","scrap","ammo","medkit"][i%4]
  var at=Vector3(-11 if i%2 else 12,.1,16-i*5)
  add_loot("supplies-"+str(i),kind,at,1 if kind=="medkit" else (24 if kind=="ammo" else 8))
 for i in range(4):add_loot("supply-house-"+str(i),["wood","scrap","ammo","medkit"][i],Vector3(21+i*2,.2,-35),2 if i==3 else 24)
func nearest_loot(at:Vector3):
 var best=null;var distance=2.5
 for item in loot:
  if not is_instance_valid(item.node):continue
  var d=at.distance_to(item.node.global_position)
  if d<distance:best=item;distance=d
 return best
func route(from:Vector3,to:Vector3) -> PackedVector3Array:
 var first=Vector2i(roundi(from.x),roundi(from.z));var last=Vector2i(roundi(to.x),roundi(to.z));var result:PackedVector3Array=[]
 if not navigation.is_in_boundsv(first) or not navigation.is_in_boundsv(last):return result
 if navigation.is_point_solid(last):
  for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(2,0),Vector2i(-2,0)]:
   if navigation.is_in_boundsv(last+offset) and not navigation.is_point_solid(last+offset):last+=offset;break
 if navigation.is_point_solid(first):return result
 for point in navigation.get_point_path(first,last,true):result.append(Vector3(point.x,.2,point.y))
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
