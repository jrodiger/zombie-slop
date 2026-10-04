extends RefCounted
# The Blender meshes and these collisions consume the same dimensioned plans.
const PATH="res://game/building_plans.json"
var world
var plans:Dictionary
func configure(owner_world):
 world=owner_world;plans=JSON.parse_string(FileAccess.get_file_as_string(PATH))
func point(at:Vector3,basis:Basis,local:Array) -> Vector3:
 return at+basis*Vector3(local[0],local[1],local[2])
func dimensions(basis:Basis,size:Vector3) -> Vector3:
 return basis.x.abs()*size.x+basis.y.abs()*size.y+basis.z.abs()*size.z
func create(at:Vector3,address:String,kind:String,yaw:float,street:Vector3,home:bool=false):
 var plan=plans[kind];var basis=Basis(Vector3.UP,yaw);var model=world.prop("district-"+kind,at,yaw,220)
 world.properties.append({"at":at,"basis":basis,"width":plan.width,"depth":plan.depth,"address":address,"plan":kind,"node":model})
 for element in plan.boxes:
  if element.solid:world.collider(point(at,basis,element.at),dimensions(basis,Vector3(element.size[0],element.size[1],element.size[2])),true)
 for ramp in plan.ramps:
  var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;world.add_child(body);body.position=point(at,basis,ramp.at);body.rotation.y=yaw
  var shape=ConvexPolygonShape3D.new();var w=float(ramp.width)/2;var l=float(ramp.length);var h=float(ramp.rise)
  shape.points=PackedVector3Array([Vector3(-w,0,0),Vector3(w,0,0),Vector3(-w,-.1,l),Vector3(w,-.1,l),Vector3(-w,h,l),Vector3(w,h,l)])
  var collider=CollisionShape3D.new();collider.shape=shape;body.add_child(collider);body.set_meta("staircase",true)
 var roof=model.find_child("Roof",true,false)
 if roof!=null:
  world.roofs.append({"at":at,"node":roof,"basis":basis,"width":plan.width,"depth":plan.depth,"height":plan.roof_height})
  var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;var shape=CollisionShape3D.new();shape.shape=roof.mesh.create_trimesh_shape();body.add_child(shape);roof.add_child(body)
 for entry in plan.props:
  var pos=point(at,basis,entry.at);var rotation=yaw+float(entry.yaw)
  if home and not world.furnishing_clear(pos,Vector3(2,2,2)):continue
  furnishing(entry.kind,pos,rotation,bool(entry.solid),address)
 for entry in plan.containers:
  var index=plan.containers.find(entry);var suffix="-"+str(index) if entry.kind in ["parts","market"] else ""
  var key=address.to_lower().replace(" ","-");var stock=world.LootTables.stock(world.game.state.loot_seed,address+suffix,entry.kind)
  world.add_container(key+"-"+entry.kind+suffix, {"fridge":"Refrigerator","drawer":"Kitchen drawers","safe":"Bedroom safe","chest":"Household chest","parts":"Auto-shop parts chest","market":"Store shelf supplies"}.get(entry.kind,entry.kind.capitalize()),address,entry.kind,point(at,basis,entry.at),Vector3(.8,1,.7),stock,yaw+float(entry.yaw))
 var label=address if kind in ["garage","grocery","convenience"] else address.split(" ")[0]
 mounted_sign(model,label,Vector3(0,2.75,-float(plan.depth)/2-.15),kind in ["garage","grocery","convenience"])
 if kind in ["cottage","townhouse","farmhouse"]:yard(at,basis,float(plan.width),float(plan.depth),street)
 if kind=="garage":
  for x in [-4,4]:furnishing("fuel-pump",at+basis*Vector3(x,0,-11),yaw,true,address)
  world.box(at+basis*Vector3(0,3.7,-11),dimensions(basis,Vector3(14,.2,6)),Color("bdbaaa"),true,false)
  for x in [-6,6]:world.box(at+basis*Vector3(x,1.85,-11),dimensions(basis,Vector3(.16,3.7,.16)),Color("67766b"),true)
  world.add_loot("garage-loose-parts","vehicle_parts",at+basis*Vector3(4,1.06,4),2,0)
 else:
  # Supplies out on counters/bedside surfaces are genuine visible pickups.
  var supply="food" if kind in ["grocery","convenience"] else "water"
  if not plan.props.is_empty():
   var counter=plan.props.filter(func(entry):return entry.kind=="counter")
   if not counter.is_empty():
    var fixture=world.furnishings.filter(func(entry):return entry.address==address and entry.kind=="counter")[0]
    var top=world.model_bounds(fixture.node).end.y
    world.add_loot(address+"-counter-supply",supply,point(at,basis,counter[0].at)+basis*Vector3(.55,top+.015,0),1)
func furnishing(kind:String,at:Vector3,yaw:float,solid:bool,address:String):
 var node=world.prop(kind,at,yaw,65);var bounds=world.model_bounds(node)
 if solid:
  var basis=Basis(Vector3.UP,yaw);var center=at+basis*bounds.get_center();var size=dimensions(basis,bounds.size)
  var body=world.collider(center,Vector3(maxf(.06,size.x),maxf(.06,size.y),maxf(.06,size.z)),true)
  body.set_meta("fixture_bounds",AABB(center-size/2,size))
  if kind=="shelf":
   # Keep the actual uprights and shelf boards solid while leaving space for
   # small decorations. A single bounding box seals off every shelf opening.
   var old=body.get_child(0);body.remove_child(old);old.free()
   var pieces=[]
   for x in [-.7,.7]:pieces.append({"at":Vector3(x,.9,0),"size":Vector3(.1,1.8,.5)})
   for y in [.1,.65,1.2,1.75]:pieces.append({"at":Vector3(0,y,0),"size":Vector3(1.5,.09,.5)})
   for piece in pieces:
    var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=dimensions(basis,piece.size);shape.shape=box;shape.position=at+basis*piece.at-center;body.add_child(shape)
  world.furnishings.append({"kind":kind,"node":node,"body":body,"address":address})
 return node
func mounted_sign(parent:Node3D,value:String,at:Vector3,large:bool):
 var plaque=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=Vector3(6 if large else .7,.48 if large else .4,.06);plaque.mesh=mesh;plaque.position=at;parent.add_child(plaque)
 var material=StandardMaterial3D.new();material.albedo_color=Color("24382d");plaque.material_override=material
 var number=MeshInstance3D.new();var text=TextMesh.new();text.text=value;text.font_size=48;text.pixel_size=.007 if large else .006;text.depth=.002;number.mesh=text;parent.add_child(number);number.position=at+Vector3(0,0,-.04);number.rotation.y=PI
 var ink=StandardMaterial3D.new();ink.albedo_color=Color("e4dfcc");ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;number.material_override=ink;number.visibility_range_end=50
func yard(at:Vector3,basis:Basis,width:float,depth:float,street:Vector3):
 var half=maxf(7,width/2+1.3);var front=-depth/2-3;var rear=depth/2+2
 # The gate and the entire straight approach share the doorway centerline.
 for x in [-half,half]:world.box(at+basis*Vector3(x,.65,(front+rear)/2),dimensions(basis,Vector3(.12,1.3,rear-front)),Color("6b664e"),true)
 world.box(at+basis*Vector3(0,.65,rear),dimensions(basis,Vector3(half*2,1.3,.12)),Color("6b664e"),true)
 for side in [-1,1]:world.box(at+basis*Vector3(side*(half+1.8)/2,.65,front),dimensions(basis,Vector3(half-1.8,1.3,.12)),Color("6b664e"),true)
 var target=basis.inverse()*(street-at);var end=minf(front,float(target.z));var start=-depth/2
 world.box(at+basis*Vector3(0,.035,(start+end)/2),dimensions(basis,Vector3(1.5,.07,start-end)),Color("959986"),true,false)
 world.paths.append({"at":at,"basis":basis,"gate":front,"end":end,"width":1.5})
 furnishing("grill",at+basis*Vector3(half-1.1,0,rear-1.2),0,true,"yard")
 furnishing("trashcan",at+basis*Vector3(-half+.6,0,front+1),0,true,"yard")
 world.prop("trashbag",at+basis*Vector3(-half+1.3,0,front+1),0,45)
