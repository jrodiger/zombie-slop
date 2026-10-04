extends RefCounted
# Each new neighborhood gets a persisted seed; revisiting/loading never rerolls stock.
static func stock(seed_value:int,address:String,kind:String) -> Array:
 var rng=RandomNumberGenerator.new();rng.seed=(seed_value+address.hash())&0x7fffffff
 var key=address.to_lower().replace(" ","-");var result:Array=[]
 var add=func(item:String,amount:int,ident:String=""):
  if amount>0:result.append({"id":key+"-"+kind+"-"+item if ident=="" else ident,"kind":item,"amount":amount})
 if kind=="parts":
  add.call("vehicle_parts",rng.randi_range(3,5));add.call("scrap",rng.randi_range(8,14));add.call("wood",rng.randi_range(1,3))
 elif kind=="market":
  add.call("food",rng.randi_range(2,6));add.call("water",rng.randi_range(1,4))
  if rng.randf()<.3:add.call("medkit",1)
 elif kind=="chest":
  add.call("wood",rng.randi_range(2,6));add.call("ammo",rng.randi_range(8,20));add.call("scrap",rng.randi_range(2,5))
 elif kind=="fridge":
  add.call("food",rng.randi_range(1,4),key+"-food");add.call("water",rng.randi_range(0,3),key+"-water")
  if rng.randf()<.22:add.call("medkit",1)
 elif kind=="drawer":
  add.call("scrap",rng.randi_range(2,7),key+"-scrap")
  if rng.randf()<.6:add.call("wood",rng.randi_range(2,5))
  if rng.randf()<.7:add.call("ammo",rng.randi_range(8,24),key+"-ammo")
  if rng.randf()<.25:add.call("medkit",1)
 else:
  if rng.randf()<.65:add.call("medkit",rng.randi_range(1,2),key+"-medkit")
  var options=["rifle_ammo","shells","ammo"];var ammo=options[rng.randi_range(0,2)];add.call(ammo,rng.randi_range(8,32),key+"-rifle-ammo" if ammo=="rifle_ammo" else "")
  if rng.randf()<.25:add.call("scrap",rng.randi_range(3,8))
 if address=="14 Cedar Lane" and kind=="drawer":
  result=[{"id":"porch-wood","kind":"wood","amount":12},{"id":"porch-scrap","kind":"scrap","amount":4},{"id":"starter-axe","kind":"axe","amount":1}]
 if kind=="safe":
  var guaranteed={"8 Cedar Lane":["rifle","rifle_ammo",60,"rifle-supply","rifle-rounds"],"12 Cedar Lane":["shotgun","shells",18,"shotgun-porch","shotgun-shells"],"11 Cedar Lane":["smg","ammo",60,"smg-find","smg-rounds"],"3 Cedar Lane":["revolver","ammo",30,"revolver-find","revolver-rounds"],"4 Cedar Lane":["compact_shotgun","shells",14,"compact-find","compact-rounds"],"7 Cedar Lane":["bat","scrap",5,"bat-find","bat-scrap"],"2 Orchard Way":["knife","food",2,"knife-find","knife-food"]}
  if guaranteed.has(address):
   var entry=guaranteed[address];result=result.filter(func(item):return item.kind!=entry[1]);result.push_front({"id":entry[3],"kind":entry[0],"amount":1});result.append({"id":entry[4],"kind":entry[1],"amount":entry[2]})
 return result
