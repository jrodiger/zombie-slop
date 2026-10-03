extends RefCounted
const Catalog = preload("res://game/catalog.gd")
const VERSION = 1
var inventory:Dictionary = {}
var objects:Array = []
var collected:Array = []
var objective:Dictionary = {"supplies":false,"collectible":false,"returned":false,"decorated":false,"built":false}
var player_position:Array = [-24.0,0.35,26.0]
var health:float = 100.0
var magazine:int = 12
var next_id:int = 1
var kills:int = 0
var settings:Dictionary = {"cap":true,"shadows":false,"sensitivity":1.0,"volume":0.7}
var save_error:String = ""
func _init():
 reset()
func reset():
 inventory={"wood":0,"scrap":0,"ammo":48,"medkit":2}
 for k in Catalog.FURNITURE: inventory[k]=0
 objects=[]; collected=[]; next_id=1; kills=0
 objective={"supplies":false,"collectible":false,"returned":false,"decorated":false,"built":false}
 player_position=[-24.0,0.35,26.0]; health=100.0; magazine=12
func can_afford(kind:String) -> bool:
 if not Catalog.ITEMS.has(kind):return false
 var cost:Dictionary=Catalog.ITEMS[kind].cost
 if cost.is_empty():return int(inventory.get(kind,0))>0
 for resource in cost:
  if int(inventory.get(resource,0))<int(cost[resource]):return false
 return true
func collect(world_id:String,kind:String,amount:int) -> bool:
 if world_id in collected or amount<=0:return false
 if not kind in Catalog.SUPPLIES and not kind in Catalog.FURNITURE:return false
 collected.append(world_id)
 inventory[kind]=int(inventory.get(kind,0))+amount
 if kind in Catalog.SUPPLIES:objective.supplies=true
 if kind in Catalog.FURNITURE:objective.collectible=true
 return true
func place(kind:String,pos:Vector3,yaw:float,valid:bool,moving_id:int=-1) -> int:
 if not valid or not Catalog.ITEMS.has(kind) or not pos.is_finite() or not is_finite(yaw):return -1
 if moving_id>=0:
  for obj in objects:
   if int(obj.id)==moving_id and obj.kind==kind:
    obj.position=[pos.x,pos.y,pos.z];obj.yaw=yaw
    return moving_id
  return -1
 if not can_afford(kind):return -1
 var cost:Dictionary=Catalog.ITEMS[kind].cost
 if cost.is_empty():inventory[kind]-=1
 else:
  for resource in cost:inventory[resource]-=cost[resource]
 var ident=next_id;next_id+=1
 objects.append({"id":ident,"kind":kind,"position":[pos.x,pos.y,pos.z],"yaw":yaw,"hp":160.0,"open":false,"contents":{}})
 if Catalog.built(kind):objective.built=true
 else:objective.decorated=true
 return ident
func find_object(ident:int) -> Dictionary:
 for obj in objects:
  if int(obj.id)==ident:return obj
 return {}
func remove(ident:int,refund:bool=true) -> bool:
 for index in range(objects.size()):
  var obj:Dictionary=objects[index]
  if int(obj.id)!=ident:continue
  if not obj.contents.is_empty():return false
  if refund:
   var cost:Dictionary=Catalog.ITEMS[obj.kind].cost
   if cost.is_empty():inventory[obj.kind]=int(inventory.get(obj.kind,0))+1
   else:
    # Full refund; destroyed pieces return nothing.
    for key in cost:inventory[key]=int(inventory.get(key,0))+int(cost[key])
  objects.remove_at(index)
  return true
 return false
func transfer(ident:int,kind:String,amount:int,deposit:bool) -> bool:
 var obj=find_object(ident)
 if obj.is_empty() or obj.kind!="storage" or amount<=0:return false
 if not kind in Catalog.SUPPLIES and not kind in Catalog.FURNITURE:return false
 var source:Dictionary=inventory if deposit else obj.contents
 var destination:Dictionary=obj.contents if deposit else inventory
 if int(source.get(kind,0))<amount:return false
 source[kind]=int(source.get(kind,0))-amount
 destination[kind]=int(destination.get(kind,0))+amount
 if source!=inventory and source[kind]==0:source.erase(kind)
 return true
func snapshot() -> Dictionary:
 return {"version":VERSION,"inventory":inventory.duplicate(true),"objects":objects.duplicate(true),"collected":collected.duplicate(),"objective":objective.duplicate(),"player_position":player_position.duplicate(),"health":health,"magazine":magazine,"next_id":next_id,"kills":kills,"settings":settings.duplicate()}
static func valid_count(value) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=0 and value<=100000
static func valid_position(value) -> bool:
 if not value is Array or value.size()!=3:return false
 for n in value:
  if not (n is int or n is float) or not is_finite(float(n)) or abs(float(n))>1000:return false
 return true
static func validate(data) -> bool:
 if not data is Dictionary or data.get("version")!=VERSION:return false
 for k in ["inventory","objective","settings"]:
  if not data.get(k) is Dictionary:return false
 if not data.get("objects") is Array or not data.get("collected") is Array:return false
 if not valid_position(data.get("player_position")):return false
 if not valid_count(data.get("magazine")) or data.magazine>12:return false
 if not valid_count(data.get("next_id")) or data.next_id<1:return false
 if not valid_count(data.get("kills")):return false
 if not (data.get("health") is float or data.get("health") is int) or not is_finite(float(data.health)) or data.health<0 or data.health>100:return false
 for k in Catalog.SUPPLIES+Catalog.FURNITURE:
  if not valid_count(data.inventory.get(k)):return false
 for k in ["supplies","collectible","returned","decorated","built"]:
  if not data.objective.get(k) is bool:return false
 var s:Dictionary=data.settings
 if not s.get("cap") is bool or not s.get("shadows") is bool:return false
 for k in ["sensitivity","volume"]:
  if not (s.get(k) is int or s.get(k) is float) or not is_finite(float(s[k])):return false
 if s.sensitivity<0.2 or s.sensitivity>3 or s.volume<0 or s.volume>1:return false
 var ids:Array=[]
 if data.objects.size()>1000 or data.collected.size()>10000:return false
 for obj in data.objects:
  if not obj is Dictionary or not Catalog.ITEMS.has(obj.get("kind","")):return false
  if not valid_count(obj.get("id")) or obj.id in ids or obj.id<1 or obj.id>=data.next_id:return false
  ids.append(obj.id)
  if not valid_position(obj.get("position")):return false
  if not (obj.get("yaw") is int or obj.get("yaw") is float) or not is_finite(float(obj.yaw)):return false
  if not (obj.get("hp") is int or obj.get("hp") is float) or not is_finite(float(obj.hp)) or obj.hp<=0 or obj.hp>160:return false
  if not obj.get("open") is bool or not obj.get("contents") is Dictionary:return false
  if obj.kind!="storage" and not obj.contents.is_empty():return false
  for k in obj.contents:
   if not k in Catalog.SUPPLIES and not k in Catalog.FURNITURE:return false
   if not valid_count(obj.contents[k]):return false
 var unique:Array=[]
 for ident in data.collected:
  if not ident is String or ident in unique:return false
  unique.append(ident)
 return true
func restore(data) -> bool:
 if not validate(data):return false
 inventory=data.inventory.duplicate(true); objects=data.objects.duplicate(true); collected=data.collected.duplicate()
 for key in inventory:inventory[key]=int(inventory[key])
 for obj in objects:
  obj.id=int(obj.id);obj.yaw=float(obj.yaw);obj.hp=float(obj.hp)
  for i in range(3):obj.position[i]=float(obj.position[i])
  for key in obj.contents:obj.contents[key]=int(obj.contents[key])
 objective=data.objective.duplicate();player_position=data.player_position.duplicate();health=float(data.health)
 for i in range(3):player_position[i]=float(player_position[i])
 magazine=int(data.magazine);next_id=int(data.next_id);kills=int(data.kills);settings=data.settings.duplicate()
 settings.sensitivity=float(settings.sensitivity);settings.volume=float(settings.volume)
 return true
func save_to(path:String="user://survival.json") -> bool:
 var data=snapshot()
 if not validate(data):save_error="Progress failed validation; existing save preserved.";return false
 var temporary=path+".tmp"
 var file=FileAccess.open(temporary,FileAccess.WRITE)
 if file==null:save_error="Cannot write save.";return false
 file.store_string(JSON.stringify(data,"",true,true));file.flush();file.close()
 if FileAccess.file_exists(path):
  var previous=parse_json(FileAccess.get_file_as_string(path))
  if validate(previous):
   var code=DirAccess.copy_absolute(path,path+".bak")
   if code!=OK:save_error="Cannot back up save.";return false
 var code=DirAccess.rename_absolute(temporary,path)
 save_error="" if code==OK else "Cannot replace save."
 return code==OK
func load_from(path:String="user://survival.json") -> bool:
 for candidate in [path,path+".bak"]:
  if FileAccess.file_exists(candidate) and restore(parse_json(FileAccess.get_file_as_string(candidate))):
   save_error="Recovered backup save." if candidate.ends_with(".bak") else ""
   return true
 save_error="No valid save found; start a new neighborhood."
 return false

static func parse_json(text:String):
 var json=JSON.new()
 return json.data if json.parse(text)==OK else null
