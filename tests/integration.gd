extends Node
var checks:int=0
var failures:int=0
var game
func check(condition:bool,message:String):
 checks+=1
 if not condition:failures+=1;push_error("INTEGRATION: "+message)
 else:print("PASS: "+message)
func wait(seconds:float=.2):
 await get_tree().create_timer(seconds).timeout
func capture(name:String):
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var root=OS.get_environment("ZOMBIE_REPORT_DIR")
 if root=="":root=OS.get_user_data_dir()+"/verification"
 DirAccess.make_dir_recursive_absolute(root)
 game.get_viewport().get_texture().get_image().save_png(root+"/"+name+".png")
func tap(action:String):
 var e=InputEventAction.new();e.action=action;e.pressed=true;Input.parse_input_event(e)
 await get_tree().process_frame
 e=InputEventAction.new();e.action=action;e.pressed=false;Input.parse_input_event(e)
 await get_tree().process_frame
func place(kind:String,at:Vector3,yaw:float=0) -> int:
 game.player.position=at+Vector3(0,.4,-3)
 game.begin_placement(kind)
 await wait()
 game.placement_position=at;game.placement_yaw=yaw
 var reason=game.validate_placement(kind,at,yaw)
 check(reason=="Ready to place",kind+" valid on supporting surface: "+reason)
 # Confirm through the actual transaction method, never directly create inventory records.
 game.confirm_placement()
 await wait()
 if game.state.objects.is_empty():return -1
 return int(game.state.objects.back().id)
func run(owner_game):
 game=owner_game
 var watchdog=Timer.new();watchdog.wait_time=120;watchdog.one_shot=true;add_child(watchdog);watchdog.timeout.connect(watchdog_timeout);watchdog.start()
 await capture("01-start")
 game.new_game();await wait(.5)
 check(game.running and not game.overlay,"Start enters playable scene")
 check(game.player.animation!=null and game.player.animation.get_animation_list().size()>=8,"Imported skeleton has eight animation clips")
 var weapon=game.player.flash.get_parent()
 check(weapon.global_basis.z.normalized().dot(game.player.visual.global_basis.z.normalized())>.98,"Weapon muzzle points along character forward")
 check(weapon.global_basis.y.normalized().dot(Vector3.UP)>.98,"Weapon grip preserves upright orientation")
 var before=game.player.position
 for i in range(45):
  game.player.yaw=PI;Input.action_press("forward");await get_tree().physics_frame
 Input.action_release("forward")
 check(game.player.position.distance_to(before)>2,"Third-person movement responds to input")
 Input.action_press("aim");await wait(.3)
 check(game.player.aiming and game.player.camera.fov<68,"Aiming adjusts shoulder camera")
 Input.action_release("aim")
 var zombie=get_tree().get_nodes_in_group("zombies")[0]
 check(zombie.animation.get_animation_list().has("Walk") and zombie.animation.get_animation_list().has("Attack"),"Zombie imports exact locomotion and attack clip names")
 # Target a real physics character with the actual camera raycast.
 game.player.position=Vector3(0,.2,14);game.player.yaw=0;game.player.pitch=0
 zombie.position=Vector3(.65,.2,5);zombie.velocity=Vector3.ZERO
 await wait(.4)
 game.player.camera.look_at(zombie.global_position+Vector3.UP*1.1)
 game.player.shot_cooldown=0;game.player.shoot();await wait(.03)
 check(game.state.magazine==11 and zombie.hp<100,"Fire spends ammunition and damages raycast target")
 game.player.reload();check(game.player.reload_left>0,"Reload starts")
 await wait(1.8)
 check(game.state.magazine==12 and game.state.inventory.ammo==47,"Reload transfers exactly missing rounds")
 zombie.take_damage(100);check(not zombie.alive and game.state.kills==1,"Zombie death disables collision and grants kill")
 game.player.take_damage(25);check(game.state.health==75,"Player damage applies")
 game.player.heal();check(game.state.health==100 and game.state.inventory.medkit==1,"Healing consumes one medkit")
 await capture("02-street")
 for entry in [["porch-wood",Vector3(-19,.2,23)],["porch-scrap",Vector3(-19,.2,21)],["fern",Vector3(-12,.2,13)],["radio",Vector3(11,.2,4)]]:
  game.player.position=entry[1];await wait(.1);game.interact();await wait(.1)
 check(game.state.inventory.plant==1 and game.state.inventory.radio==1,"Collect multiple actual world objects")
 check(game.state.inventory.wood==12 and game.state.inventory.scrap==4,"Collect world construction materials")
 check(game.world.route(Vector3(0,0,20),Vector3(-24,0,30)).size()>2,"Navigation finds path into accessible home interior")
 game.player.position=Vector3(-24,.3,29);await wait(.25)
 check(game.state.objective.returned,"Returning home advances starter objective")
 var untouched=game.state.snapshot()
 game.begin_placement("plant");await wait(.1);game.cancel_placement()
 check(game.state.snapshot()==untouched,"Cancel preview leaves inventory and identity unchanged")
 game.begin_placement("plant");game.state.health=75;game.state.magazine=11
 for action in ["reload","heal","jump"]:Input.action_press(action)
 for i in range(3):await get_tree().physics_frame
 check(game.player.reload_left==0 and game.state.health==75 and game.state.inventory.medkit==1,"Placement input cannot reload or spend a healing item")
 check(game.player.velocity.y<=0,"Placement rotation cannot also trigger a jump")
 for action in ["reload","heal","jump"]:Input.action_release(action)
 game.cancel_placement();game.state.health=100;game.state.magazine=12
 check(game.validate_placement("plant",Vector3(-30,.1,30),0)!="Ready to place","Occupied wall placement denied")
 var fern=await place("plant",Vector3(-28.3,.175,29),PI/3)
 check(game.state.inventory.plant==0,"Placed collectible consumed exactly once")
 var old=game.state.find_object(fern).duplicate(true)
 game.player.position=Vector3(-25,.2,32.5);game.begin_placement("plant",fern);await wait(.1);game.cancel_placement()
 check(game.state.find_object(fern)==old,"Cancelled reposition keeps exact transform")
 # Place radio on the permanent tabletop at height 1.01m (house floor + table top).
 var radio=await place("radio",Vector3(-27,1.025,32.5),-.4)
 check(radio>0,"Table surface accepts a freely rotated small object")
 game.state.inventory.radio+=1
 var shelf_radio=await place("radio",Vector3(-21,.87,33.5),.7)
 check(shelf_radio>0,"Middle shelf accepts precise height placement")
 # Reposition via transaction, preserving identity and contents.
 game.player.position=Vector3(-26,.2,29);game.begin_placement("plant",fern);await wait(.1)
 game.placement_position=Vector3(-27,.175,29);game.placement_yaw=.8;game.confirm_placement();await wait(.2)
 check(game.state.find_object(fern).position==[float(Vector3(-27,.175,29).x),float(Vector3(-27,.175,29).y),float(Vector3(-27,.175,29).z)],"Reposition changes transform without identity duplication")
 game.player.position=Vector3(-27,.3,29);game.pickup_nearest();await wait(.2)
 check(game.state.inventory.plant==1 and game.state.find_object(fern).is_empty(),"Recover placed object to inventory")
 await place("plant",Vector3(-28,.175,29),1.2)
 var barrier=await place("barricade",Vector3(-24,.015,22),0)
 check(game.objective_complete(),"Complete starter objective and continue sandbox")
 game.state.inventory.wood+=30;game.state.inventory.scrap+=10
 var chest=await place("storage",Vector3(-20,.175,29),.5)
 check(game.state.transfer(chest,"wood",7,true),"Deposit supplies in built chest")
 check(game.state.transfer(chest,"radio",0,true)==false,"Zero transfer is safely rejected")
 game.ui.storage_menu(chest);await capture("03-storage");game.close_overlay()
 var door_id=await place("door",Vector3(-24,.015,24.3),0)
 var door
 for p in get_tree().get_nodes_in_group("placed"):
  if int(p.data.id)==door_id:door=p
 if door!=null:
  door.toggle();await wait(.1);check(door.data.open and door.colliders[3].disabled,"Built door opens and clears doorway collision")
  door.toggle();await wait(.1);check(not door.data.open and not door.colliders[3].disabled,"Built door closes and restores collision")
 else:check(false,"Built door created")
 # Spawn encounter immediately outside barricade and let actual AI attack it.
 var attacker=get_tree().get_nodes_in_group("zombies")[1]
 attacker.position=Vector3(-24,.2,20.9);attacker.alerted=12;attacker.attack_left=0
 game.player.position=Vector3(-24,.2,23.4)
 var barricade=game.state.find_object(barrier)
 var initial_hp=float(barricade.get("hp",0))
 await wait(2.5)
 check(float(barricade.get("hp",0))<initial_hp,"Pursuing zombie attacks a blocking barricade")
 # Build a real supported freestanding shelter, then reject an unsupported roof.
 game.state.inventory.wood+=30
 var shelter=Vector3(-36,.015,40)
 for x in [-36,-38,-34]:
  game.player.position=Vector3(x,.3,37)
  if game.validate_placement("foundation",Vector3(x,.015,40),0)=="Ready to place":shelter.x=x;break
 await place("foundation",shelter)
 await place("wall",shelter+Vector3(0,.215,-1.45))
 await place("wall",shelter+Vector3(0,.215,1.45))
 await place("roof",shelter+Vector3(0,2.73,0))
 game.player.position=shelter+Vector3(0,.3,-3)
 check(game.validate_placement("roof",shelter+Vector3(4,2.73,0),0)!="Ready to place","Unsupported roof is denied")
 game.player.position=Vector3(-25,.3,29);game.save_game(false)
 var snapshot=game.state.snapshot();check(game.state.save_to(game.save_path),"Save furnished base to isolated integration file")
 var expected=FileAccess.open(game.report_dir()+"/relaunch-expected.json",FileAccess.WRITE);expected.store_string(JSON.stringify(snapshot,"  ",false,true));expected.close()
 game.state.reset();check(game.state.load_from(game.save_path),"Load furnished base")
 check(arrangement_matches(game.state.snapshot(),snapshot),"Object identity, arrangement and container contents survive save/load within 1e-9 radians")
 game.rebuild();await wait(.3)
 check(get_tree().get_nodes_in_group("placed").size()==snapshot.objects.size(),"Load restores one physics object per saved identity")
 check(game.world.loot.filter(func(item):return item.id=="fern").is_empty(),"Collected world object stays absent after reload")
 await capture("04-furnished-base")
 game.ui.pause();await capture("05-pause");game.ui.settings();await capture("06-settings");game.close_overlay()
 # Test supported gamepad event mapping without claiming a physical controller.
 var pad=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_Y;pad.pressed=true;Input.parse_input_event(pad);await wait(.15)
 check(game.overlay,"Synthetic gamepad Y opens construction menu")
 game.close_overlay();pad.pressed=false;Input.parse_input_event(pad)
 game.player.reload_left=1;game.state.magazine=4;game.state.health=10;game.player.hurt_left=0;game.player.take_damage(20)
 check(not game.running and game.player.reload_left==0,"Death interrupts reload without duplicating ammo")
 await capture("07-death")
 game.new_game();await wait(.3);check(game.running and game.state.health==100,"Restart creates fresh playable state")
 var report={"checks":checks,"failures":failures,"graphical":DisplayServer.get_name()!="headless","engine":Engine.get_version_info().string,"physical_gamepad":false}
 var f=FileAccess.open(game.report_dir()+"/integration.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("INTEGRATION TESTS: %d checks, %d failures"%[checks,failures])
 return 1 if failures else 0

func arrangement_matches(a:Dictionary,b:Dictionary) -> bool:
 if a.objects.size()!=b.objects.size():return false
 for i in range(a.objects.size()):
  var x:Dictionary=a.objects[i];var y:Dictionary=b.objects[i]
  for key in ["id","kind","hp","open","contents"]:
   if x[key]!=y[key]:return false
  if Vector3(x.position[0],x.position[1],x.position[2])!=Vector3(y.position[0],y.position[1],y.position[2]):return false
  if absf(float(x.yaw)-float(y.yaw))>1e-9:return false
 for key in ["inventory","collected","objective","health","magazine","next_id","kills","settings"]:
  if a[key]!=b[key]:return false
 return true

func watchdog_timeout():
 push_error("Integration watchdog timeout");get_tree().quit(2)

func verify_relaunch(owner_game) -> int:
 game=owner_game
 var path=game.report_dir()+"/relaunch-expected.json"
 check(FileAccess.file_exists(path),"Prior process wrote expected furnished base")
 if failures:return 1
 var expected=JSON.parse_string(FileAccess.get_file_as_string(path))
 # Normalize the JSON numeric representation through the same state loader.
 var reference=game.State.new()
 check(reference.restore(expected),"Expected arrangement validates")
 game.load_game();await wait(.5)
 check(game.running,"Fresh graphical process loads integration save")
 check(arrangement_matches(game.state.snapshot(),reference.snapshot()),"Exact identities, arrangement and chest contents survive quit and relaunch")
 check(get_tree().get_nodes_in_group("placed").size()==reference.objects.size(),"Relaunch restores one collider per placed identity")
 check(game.world.loot.filter(func(item):return item.id=="fern").is_empty(),"Relaunch preserves collected world identity")
 await capture("08-relaunched-base")
 game.player.position=Vector3(-36,.3,34);game.player.yaw=PI;game.player.pitch=-.18
 await wait(.4);await capture("09-freestanding-shelter")
 print("RELAUNCH TESTS: %d checks, %d failures"%[checks,failures])
 return 1 if failures else 0
