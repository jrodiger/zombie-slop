extends StaticBody3D
const Catalog=preload("res://game/catalog.gd")
var game
var data:Dictionary={}
var visual:Node3D
var colliders:Array=[]
var obstacle:NavigationObstacle3D
var door_leaf:Node3D
var blocked:bool=true
func configure(owner_game,record:Dictionary):
 game=owner_game;data=record
 collision_layer=1;collision_mask=0
 add_to_group("placed")
 position=Vector3(record.position[0],record.position[1],record.position[2]);rotation.y=float(record.yaw)
 visual=game.assets.model(Catalog.ITEMS[data.kind].asset);add_child(visual)
 var size:Vector3=Catalog.ITEMS[data.kind].size
 if data.kind=="door":
  box(Vector3(-1.08,1.25,0),Vector3(.84,2.5,.22))
  box(Vector3(1.08,1.25,0),Vector3(.84,2.5,.22))
  box(Vector3(0,2.34,0),Vector3(1.3,.32,.22))
  box(Vector3(0,1.08,0),Vector3(1.2,2.16,.22))
  door_leaf=visual.find_child("DoorPivot",true,false)
  update_door()
 elif data.kind=="table":
  box(Vector3(0,.8,0),Vector3(1.8,.1,1.0))
  for x in [-.83,.83]:
   for z in [-.43,.43]:box(Vector3(x,.4,z),Vector3(.1,.8,.1))
 elif data.kind=="shelf":
  for x in [-.7,.7]:box(Vector3(x,.9,0),Vector3(.1,1.8,.5))
  for y in [.1,.65,1.2,1.75]:box(Vector3(0,y,0),Vector3(1.5,.09,.5))
 else:box(Vector3(0,size.y/2,0),size)
 if data.kind in ["wall","barricade","door","storage"]:
  obstacle=NavigationObstacle3D.new();obstacle.radius=maxf(size.x,size.z)*.5;obstacle.height=size.y;obstacle.avoidance_enabled=true;add_child(obstacle)
func box(at:Vector3,size:Vector3):
 var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;c.position=at;add_child(c);colliders.append(c)
func update_door():
 blocked=not data.open
 if colliders.size()==4:colliders[3].set_deferred("disabled",bool(data.open))
 if door_leaf!=null:door_leaf.rotation.y=-PI/2 if data.open else 0.0
 if obstacle!=null:obstacle.avoidance_enabled=not data.open
func toggle():
 if data.kind!="door":return
 # Do not close on the survivor or an enemy in the doorway.
 if data.open:
  var query=PhysicsShapeQueryParameters3D.new();var s=BoxShape3D.new();s.size=Vector3(1.2,2.16,.5);query.shape=s;query.transform=global_transform*Transform3D(Basis(),Vector3(0,1.08,0));query.collision_mask=6;query.exclude=[get_rid()]
  if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():game.toast("Doorway occupied");return
 data.open=not data.open;update_door();game.sound("build");game.toast("Door open" if data.open else "Door closed")
func damage(amount:float):
 data.hp=maxf(0,float(data.hp)-amount)
 if data.hp<=0:
  var ident=int(data.id)
  game.cancel_if_moving(ident)
  # Containers spill contents to player inventory rather than lose them.
  for key in data.contents:game.state.inventory[key]=int(game.state.inventory.get(key,0))+int(data.contents[key])
  data.contents.clear();game.state.remove(ident,false);game.toast(Catalog.ITEMS[data.kind].name+" destroyed");queue_free()
