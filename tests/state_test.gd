extends SceneTree
const Catalog=preload("res://game/catalog.gd")
const State=preload("res://game/state.gd")
var checks:int=0
var failures:int=0
func check(condition:bool,message:String):
 checks+=1
 if not condition:failures+=1;push_error(message)
func _initialize():
 var s=State.new()
 check(State.validate(s.snapshot()),"Fresh state validates")
 check(s.collect("fern","plant",1),"Pickup succeeds")
 check(not s.collect("fern","plant",1),"World pickup is idempotent")
 check(not s.collect("bad","unknown",1),"Unknown pickup rejected")
 var original=s.snapshot()
 check(s.place("plant",Vector3.ZERO,0,false)<0,"Invalid placement rejected")
 check(s.snapshot()==original,"Invalid placement preserves all state")
 var plant=s.place("plant",Vector3(-24,.2,30),PI/3,true)
 check(plant>0 and s.inventory.plant==0,"Successful placement consumes exactly one item")
 check(s.place("plant",Vector3.ZERO,0,true)<0,"Cannot duplicate item")
 for i in range(20):
  check(s.place("plant",Vector3(-23,.2,31),float(i),true,plant)==plant,"Moving retains identity")
  check(s.objects.size()==1,"Moving does not duplicate")
 check(s.remove(plant) and s.inventory.plant==1,"Pickup restores item")
 check(not s.remove(plant),"Repeated pickup rejected")
 check(s.place("wall",Vector3.ZERO,0,true)<0,"Insufficient materials rejected")
 s.inventory.wood=30;s.inventory.scrap=10
 var chest=s.place("storage",Vector3(-24,.2,30),0,true)
 check(chest>0 and s.inventory.wood==22 and s.inventory.scrap==8,"Construction costs charged once")
 check(s.transfer(chest,"ammo",12,true),"Deposit succeeds")
 check(s.inventory.ammo==36 and s.find_object(chest).contents.ammo==12,"Deposit conserves supplies")
 check(not s.transfer(chest,"ammo",100,true),"Oversized deposit rejected")
 check(not s.remove(chest),"Nonempty container cannot be recovered")
 check(s.transfer(chest,"ammo",12,false),"Retrieval succeeds")
 check(not s.transfer(chest,"ammo",12,false),"Repeated withdrawal cannot duplicate")
 var data=s.snapshot();var restored=State.new()
 check(restored.restore(data),"Snapshot restores")
 check(restored.snapshot()==data,"Roundtrip retains exact identity, transform and container")
 check(s.remove(chest) and s.inventory.wood==30 and s.inventory.scrap==10,"Full removal refund")
 var invalid=data.duplicate(true);invalid.objects.append(invalid.objects[0].duplicate(true))
 check(not restored.restore(invalid),"Duplicate identity save rejected")
 check(restored.snapshot()==data,"Bad load does not partially mutate state")
 invalid=data.duplicate(true);invalid.inventory.ammo=-1
 check(not restored.restore(invalid),"Negative inventory rejected")
 invalid=data.duplicate(true);invalid.settings.volume=5
 check(not restored.restore(invalid),"Invalid settings rejected")
 invalid=data.duplicate(true);invalid.objects[0].position=[NAN,0,0]
 check(not restored.restore(invalid),"Nonfinite transform rejected")
 invalid=data.duplicate(true);invalid.magazine=12.5
 check(not restored.restore(invalid),"Fractional ammo rejected")
 var legacy=data.duplicate(true);legacy.version=1;legacy.erase("weapons");legacy.erase("equipped");legacy.inventory.erase("rifle_ammo");legacy.inventory.erase("shells")
 var migrated=State.new()
 check(migrated.restore(legacy),"Version one progress migrates")
 check(migrated.objects==data.objects and migrated.collected==data.collected and migrated.magazine==12,"Migration preserves arrangement, collected items and pistol rounds")
 check(migrated.inventory.rifle_ammo==0 and migrated.inventory.shells==0,"Migration adds empty new ammo reserves")
 check(migrated.collect("rifle-pickup","rifle",1) and migrated.weapons.rifle==0,"Looted rifle starts unloaded")
 check(not migrated.collect("rifle-pickup","rifle",1),"Weapon pickup cannot duplicate")
 check(migrated.equip("rifle"),"Owned rifle can be equipped")
 migrated.magazine=20;migrated.equip("pistol");migrated.magazine=7;migrated.equip("rifle")
 check(migrated.magazine==20 and migrated.weapons.pistol==7,"Switching retains each weapon magazine")
 var gun_save=migrated.snapshot();var gun_load=State.new()
 check(gun_load.restore(gun_save) and gun_load.snapshot()==gun_save,"Equipped weapon and magazines persist exactly")
 check(not gun_load.equip("shotgun"),"Cannot equip an uncollected weapon")
 var version_two=gun_save.duplicate(true);version_two.version=2;version_two.inventory.erase("food");version_two.inventory.erase("water")
 var migrated_two=State.new()
 check(migrated_two.restore(version_two),"Version two progress migrates")
 check(migrated_two.weapons==gun_load.weapons and migrated_two.equipped==gun_load.equipped and migrated_two.objects==gun_load.objects,"Version two migration preserves guns and furnished base")
 check(migrated_two.inventory.food==0 and migrated_two.inventory.water==0,"Migration adds empty food and water stacks")
 var bad_legacy=version_two.duplicate(true);bad_legacy.inventory.food=-1
 check(not migrated_two.restore(bad_legacy),"Legacy save cannot introduce a negative optional food stack")
 bad_legacy.inventory.food=1.5
 check(not migrated_two.restore(bad_legacy),"Legacy optional supplies must remain whole counts")
 var bad_gun=gun_save.duplicate(true);bad_gun.weapons.rifle=31;bad_gun.magazine=31
 check(not gun_load.restore(bad_gun),"Overfilled weapon magazine rejected")
 bad_gun=gun_save.duplicate(true);bad_gun.weapons.rifle=19
 check(not gun_load.restore(bad_gun),"Conflicting active magazine rejected")
 var v3=gun_save.duplicate(true);v3.version=3;v3.erase("character");v3.erase("loot_seed");v3.erase("vehicles");v3.inventory.erase("backpack");v3.inventory.erase("campfire")
 var v4=State.new();check(v4.restore(v3) and v4.character=="matt" and v4.loot_seed==4815,"Version-three saves migrate with stable loot seed and Matt")
 var legacy_extra=v3.duplicate(true);legacy_extra.character={};legacy_extra.loot_seed="bad";legacy_extra.vehicles="bad"
 check(v4.restore(legacy_extra) and v4.character=="matt" and v4.loot_seed==4815 and v4.vehicles.is_empty(),"Legacy migration ignores unvalidated fields from future versions")
 check(v4.objects==gun_save.objects and v4.weapons==gun_save.weapons,"Migration keeps base and weapons")
 v4.character="lis";v4.vehicles={"parked-1":{"position":[5.0,.2,8.0],"yaw":.5,"armored":false}};v4.loot_seed=2147483646
 var json_state=State.parse_json(JSON.stringify(v4.snapshot(),"",true,true));var from_json=State.new()
 check(from_json.restore(json_state) and from_json.snapshot()==v4.snapshot(),"JSON roundtrip preserves character, seed and parked car transform")
 var bad_seed=v4.snapshot();bad_seed.loot_seed=1.25;check(not State.validate(bad_seed),"Fractional world seed rejected")
 var old_four=v4.snapshot();old_four.version=4;old_four.inventory.erase("vehicle_parts");old_four.vehicles["parked-1"].erase("armored")
 var migrated_four=State.new();check(migrated_four.restore(old_four) and migrated_four.character=="lis" and migrated_four.inventory.vehicle_parts==0 and not migrated_four.vehicles["parked-1"].armored,"Version-four save retains survivor and parked car, adding empty parts and unarmored state")
 var fresh=State.new();check(fresh.character=="shaun","New neighborhoods default to Shaun")
 fresh.vehicles={"test":{"position":[0.0,.04,0.0],"yaw":0.0,"armored":false}}
 var before_armor=fresh.snapshot();check(not fresh.purchase_armor("test") and fresh.snapshot()==before_armor,"Unavailable armor cannot spend supplies")
 fresh.inventory.vehicle_parts=2;fresh.inventory.scrap=10;check(fresh.purchase_armor("test") and fresh.vehicles.test.armored and fresh.inventory.vehicle_parts==0 and fresh.inventory.scrap==0,"Armor purchase spends exact parts/scrap and marks the selected car")
 var armored=fresh.snapshot();check(not fresh.purchase_armor("test") and fresh.snapshot()==armored,"Repeated armor purchase cannot spend again")
 var armor_reloaded=State.new();check(armor_reloaded.restore(JSON.parse_string(JSON.stringify(armored))) and armor_reloaded.vehicles.test.armored,"Fitted armor survives JSON save/reload")
 var malformed=armored.duplicate(true);malformed.vehicles.test.armored=1;check(not State.validate(malformed),"Nonboolean armor state rejected")
 var bad_character=v4.snapshot();bad_character.character="unknown";check(not State.validate(bad_character),"Unknown survivor rejected")
 var bad_vehicle=v4.snapshot();bad_vehicle.vehicles["parked-1"].yaw=NAN;check(not State.validate(bad_vehicle),"Nonfinite vehicle transform rejected")
 check(v4.collect("axe-found","axe",1) and v4.equip("axe") and v4.magazine==0,"Melee weapon can be looted and equipped without ammunition")
 var tables=load("res://game/loot_tables.gd")
 var stock=tables.stock(77,"8 Cedar Lane","safe")
 check(stock==tables.stock(77,"8 Cedar Lane","safe"),"Container loot is stable for a saved seed")
 check(stock!=tables.stock(78,"8 Cedar Lane","safe"),"Different neighborhoods vary their loot")
 check(stock.any(func(item):return item.kind=="rifle"),"Early safe always contains a rifle")
 var stocked:Array=[]
 for address in ["8 Cedar Lane","12 Cedar Lane","11 Cedar Lane","3 Cedar Lane","4 Cedar Lane","7 Cedar Lane","2 Orchard Way"]:
  for item in tables.stock(999,address,"safe"):
   if item.kind in Catalog.WEAPONS:stocked.append(item.kind)
 check(stocked.size()==7,"Every expanded weapon family has a guaranteed world location")
 var path="user://test-progress.json"
 check(restored.save_to(path),"Save writes")
 restored.inventory.wood+=1
 check(restored.save_to(path),"Save creates backup")
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string("broken");f.close()
 var recovery=State.new()
 check(recovery.load_from(path),"Corrupt save recovers backup")
 check(recovery.snapshot()==data,"Recovery matches prior valid checkpoint")
 DirAccess.remove_absolute(path);DirAccess.remove_absolute(path+".bak")
 print("STATE TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
