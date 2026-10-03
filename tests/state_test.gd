extends SceneTree
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
 var bad_gun=gun_save.duplicate(true);bad_gun.weapons.rifle=31;bad_gun.magazine=31
 check(not gun_load.restore(bad_gun),"Overfilled weapon magazine rejected")
 bad_gun=gun_save.duplicate(true);bad_gun.weapons.rifle=19
 check(not gun_load.restore(bad_gun),"Conflicting active magazine rejected")
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
