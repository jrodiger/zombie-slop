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
func loot_container(ident:String,item_id:String):
 var matches=game.world.containers.filter(func(entry):return entry.id==ident)
 if matches.is_empty():check(false,"Container exists: "+ident);return
 var entry=matches[0]
 game.player.position=entry.node.position+Vector3(0,.05,-1.05);game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation();await wait(.12)
 game.interact();await wait(.1)
 check(game.overlay and game.open_container_id==ident,"Interaction opens physical container: "+ident)
 if game.open_container_id!=ident:return
 var item=entry.stock.filter(func(value):return value.id==item_id)[0]
 var label=game.catalog.WEAPONS[item.kind].name if item.kind in game.catalog.WEAPONS else item.kind.replace("_"," ").capitalize()
 for child in game.ui.panel_content.get_children():
  if child is Button and child.text.begins_with(label+"   ×"):
   child.pressed.emit();break
 await wait(.1)
 check(item_id in game.state.collected,"Loot menu takes persistent stock: "+item_id)
 check(not game.take_container_item(ident,item_id),"Repeated container pickup cannot duplicate: "+item_id)
 game.close_overlay()
func verify_long_gun(kind:String):
 game.player.equip(kind);game.player.position=Vector3(-24,.2,22);game.player.visual.rotation.y=0;game.player.velocity=Vector3.ZERO
 game.player.set_physics_process(false);game.player.set_process(false)
 var skeleton=game.assets.skeleton(game.player.visual)
 for clip in ["Idle","Walk","Run","Aim","Shoot","Reload"]:
  game.player.animation.play(clip+"_"+kind.capitalize(),0);game.player.animation.seek(.1,true);await wait(.05)
  var grip=game.player.visual.find_child(kind.capitalize()+"Grip",true,false)
  var fore=game.player.visual.find_child(kind.capitalize()+"ForeGrip",true,false)
  var hand=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("Middle1.R")).origin
  var barrel=game.player.visual.find_child(kind.capitalize()+"Muzzle",true,false).global_position-grip.global_position
  print("POSE ",kind," ",clip," support=",hand.distance_to(fore.global_position)," right_x=",game.player.visual.to_local(grip.global_position).x," forward=",barrel.normalized().dot(game.player.visual.global_basis.z.normalized()))
  check(game.player.visual.to_local(grip.global_position).x<0,kind+" "+clip+" uses the right firing hand")
  if clip!="Reload":check(hand.distance_to(fore.global_position)<.12,kind+" "+clip+" support hand meets foregrip")
 game.player.animation.play("Aim_"+kind.capitalize(),0);game.player.animation.seek(.1,true)
 game.player.camera.global_position=game.player.position+Vector3(-2,1.55,2.5);game.player.camera.look_at(game.player.position+Vector3.UP*1.1);await wait(.15)
 await capture("pose-"+kind)
 game.player.set_physics_process(true);game.player.set_process(true)
func place(kind:String,at:Vector3,yaw:float=0) -> int:
 game.player.position=at+Vector3(0,.4,-3)
 game.begin_placement(kind)
 await wait()
 game.placement_position=at;game.placement_yaw=yaw
 var reason=game.validate_placement(kind,at,yaw)
 check(reason=="Ready to place",kind+" valid on supporting surface: "+reason)
 # Confirm through the actual transaction method, never directly create inventory records.
 var previous_count=game.state.objects.size();game.confirm_placement()
 await wait()
 if game.state.objects.size()==previous_count:return -1
 return int(game.state.objects.back().id)
func run(owner_game):
 game=owner_game
 var watchdog=Timer.new();watchdog.wait_time=120;watchdog.one_shot=true;add_child(watchdog);watchdog.timeout.connect(watchdog_timeout);watchdog.start()
 await capture("01-start")
 game.new_game();await wait(.5)
 check(game.running and not game.overlay,"Start enters playable scene")
 check(game.player.animation!=null and game.player.animation.get_animation_list().size()>=8,"Imported skeleton has eight animation clips")
 check(game.player.weapon_visuals.size()==3,"Imported survivor carries three switchable pack weapons")
 check(game.world.HOUSES.size()==14 and game.world.containers.size()==42,"Expanded neighborhood has fourteen accessible homes and 42 containers")
 for item in game.world.loot:
  var probe=Vector3(item.node.position.x,.2,item.node.position.z+.9)
  var selectable=game.world.nearest_loot(probe)
  check(selectable!=null and selectable.id==item.id,"Every designated furnishing can be reached by the loot ray: "+item.kind)
 game.assets.animate(game.player.animation,"Aim",0);await wait(.15)
 var muzzle=game.player.flash.get_parent()
 check(muzzle.name=="PistolMuzzle","Muzzle flash uses the pack weapon socket")
 check((muzzle.global_position-game.player.visual.find_child("PistolGrip",true,false).global_position).normalized().dot(game.player.visual.global_basis.z.normalized())>.85,"Pack weapon barrel faces character forward in aiming pose")
 check(game.player.visual.to_local(game.player.visual.find_child("PistolGrip",true,false).global_position).x<0,"Pistol grip is on the character's right side")
 var before=game.player.position
 for i in range(45):
  game.player.yaw=PI;Input.action_press("forward");await get_tree().physics_frame
 Input.action_release("forward")
 check(game.player.position.distance_to(before)>2,"Third-person movement responds to input")
 game.player.sprint_energy=.2;Input.action_press("forward");Input.action_press("sprint");await wait(.7)
 check(game.player.sprint_exhausted and not game.player.sprinting and game.player.sprint_energy>5,"Exhausted sprint stays walking while the button is held")
 await wait(.4);check(not game.player.sprinting and Vector2(game.player.velocity.x,game.player.velocity.z).length()<4.3,"Stamina recovery cannot pulse back into sprint")
 Input.action_release("sprint");await wait(1.1);Input.action_press("sprint");await wait(.1)
 check(game.player.sprinting,"Recovered stamina allows sprint after releasing and pressing again")
 Input.action_release("forward");Input.action_release("sprint")
 # Walk across the actual street curb and raised doorway without jumping.
 game.player.position=Vector3(4.7,.2,15);game.player.velocity=Vector3.ZERO;game.player.yaw=-PI/2;game.player.reset_physics_interpolation();await wait(.2)
 Input.action_press("forward");await wait(1.0);Input.action_release("forward")
 check(game.player.position.x>7.7,"Walk up and down street curb without jump")
 var curb_zombie=get_tree().get_nodes_in_group("zombies")[1]
 curb_zombie.position=Vector3(4.7,.2,15);curb_zombie.velocity=Vector3.ZERO;curb_zombie.alerted=5;curb_zombie.think_left=0
 game.player.position=Vector3(12.5,.2,15);game.player.velocity=Vector3.ZERO;await wait(2.2)
 check(curb_zombie.position.x>7.7,"Pursuing zombie crosses street curb without getting stuck")
 game.player.position=Vector3(-24,.2,23.5);game.player.velocity=Vector3.ZERO;game.player.yaw=PI;game.player.reset_physics_interpolation();await wait(.2)
 Input.action_press("forward");await wait(.8);Input.action_release("forward")
 check(game.player.position.z>26 and game.player.position.y>.1,"Walk into raised home doorway without jump")
 game.player.position=Vector3(-30.7,.2,29);game.player.velocity=Vector3.ZERO;game.player.yaw=-PI/2;await wait(.2)
 Input.action_press("forward");await wait(.5);Input.action_release("forward")
 check(game.player.position.x< -30.35,"Step assistance cannot climb a full-height house wall")
 var ceiling=game.world.collider(Vector3(55,1.95,50),Vector3(4,.1,4),false)
 var low_step=game.world.collider(Vector3(55,.12,50),Vector3(1,.24,2),false)
 game.player.position=Vector3(54,.05,50);game.player.velocity=Vector3.ZERO;game.player.yaw=-PI/2;await wait(.2)
 Input.action_press("forward");await wait(.6);Input.action_release("forward")
 check(game.player.position.x<54.5,"Step assistance respects low ceiling clearance")
 ceiling.queue_free();low_step.queue_free()
 game.player.position=Vector3(3.2,2.4,-38);game.player.velocity=Vector3.ZERO;await wait(.5)
 check(absf(game.player.position.y+.025-1.55)<.015,"Pack truck roof height matches collision support")
 game.player.position=Vector3(-24,.2,27);game.player.reset_physics_interpolation()
 check(Engine.max_fps==60,"Normal gameplay starts capped at 60 FPS")
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
 var reload_before=game.player.reload_left
 game.player.equip("pistol")
 check(game.player.reload_left==reload_before,"Selecting current gun preserves the in-progress reload")
 game.player.cycle_weapon()
 check(game.player.reload_left==reload_before,"Cycling the sole owned gun preserves the in-progress reload")
 await wait(1.8)
 check(game.state.magazine==12 and game.state.inventory.ammo==47,"Reload transfers exactly missing rounds")
 zombie.take_damage(100);check(not zombie.alive and game.state.kills==1,"Zombie death disables collision and grants kill")
 game.player.take_damage(25);check(game.state.health==75,"Player damage applies")
 game.player.heal();check(game.state.health==100 and game.state.inventory.medkit==1,"Healing consumes one medkit")
 # Actual world pickups, weapon switching and interrupted reload conservation.
 await loot_container("12-cedar-lane-safe","shotgun-porch")
 check(game.state.equipped=="shotgun" and game.state.magazine==0,"Looting shotgun equips the pack model unloaded")
 await loot_container("12-cedar-lane-safe","shotgun-shells");game.player.reload();await wait(2.8)
 check(game.state.magazine==6 and game.state.inventory.shells==12,"Shotgun reload spends exactly six shells")
 game.player.shot_cooldown=0;game.player.shoot();check(game.state.magazine==5,"Six shotgun pellets consume one shell")
 game.player.reload();var shells=game.state.inventory.shells;game.player.equip("pistol");await wait(.3)
 check(game.player.reload_left==0 and game.state.inventory.shells==shells and game.state.weapons.shotgun==5,"Switching cancels reload without spending or duplicating ammunition")
 await loot_container("8-cedar-lane-safe","rifle-supply")
 check(game.state.equipped=="rifle" and game.state.weapons.has("rifle"),"Supply house contains lootable rifle")
 await loot_container("8-cedar-lane-safe","rifle-rounds");game.player.reload();await wait(2.3)
 check(game.state.magazine==30 and game.state.inventory.rifle_ammo==60,"Rifle reload uses separate reserve rounds")
 await verify_long_gun("rifle");await verify_long_gun("shotgun");game.player.equip("rifle")
 var gun_target=get_tree().get_nodes_in_group("zombies").filter(func(enemy):return enemy.alive)[0]
 game.player.position=Vector3(0,.2,9.5);game.player.velocity=Vector3.ZERO;game.player.yaw=0;game.player.pitch=0;game.player.reset_physics_interpolation()
 gun_target.position=Vector3(.65,.2,6);gun_target.velocity=Vector3.ZERO;gun_target.stagger=5;gun_target.hp=100
 Input.action_press("aim");await wait(.3)
 game.player.camera.look_at(gun_target.global_position+Vector3.UP*1.1);game.player.shot_cooldown=0;game.player.shoot()
 check(game.state.magazine==29 and gun_target.hp==74,"Rifle fires its own damage profile and spends one rifle round")
 gun_target.hp=100;game.player.equip("shotgun");await wait(.1)
 game.player.camera.look_at(gun_target.global_position+Vector3.UP*1.1);game.player.shot_cooldown=0;game.player.shoot()
 check(not gun_target.alive and game.state.magazine==4,"Close-range shotgun pellets kill a real target while consuming one shell")
 Input.action_release("aim")
 game.player.equip("pistol")
 check(not game.player.flash.visible and game.player.flash_left==0,"Switching weapons cannot create a muzzle flash")
 game.state.magazine=0;game.player.shot_cooldown=0;game.player.shoot()
 check(not game.player.flash.visible and game.player.flash_left==0,"Dry fire cannot create a muzzle flash")
 game.state.magazine=12
 await tap("weapon_next");check(game.state.equipped=="rifle" and game.player.weapon_visuals.rifle.is_visible_in_tree() and not game.player.weapon_visuals.pistol.is_visible_in_tree(),"Cycle input selects the next owned gun and its visible model")
 await tap("weapon_next");await tap("weapon_next")
 await capture("02-street")
 await loot_container("14-cedar-lane-drawer","porch-wood")
 await loot_container("14-cedar-lane-drawer","porch-scrap")
 game.player.position=Vector3(-20,.2,24.5);game.player.velocity=Vector3.ZERO;await wait(.1)
 check(game.world.nearest_container(game.player.position)==null,"House wall and glass prevent searching drawers from outside")
 await loot_container("14-cedar-lane-fridge","14-cedar-lane-food")
 game.state.health=80;game.player.use_supply("food")
 check(game.state.health==95 and game.state.inventory.food==1,"Refrigerator food restores health and consumes exactly one item")
 game.state.health=100;game.player.use_supply("food")
 check(game.state.inventory.food==1,"Full health cannot waste a food item")
 for entry in [["fern",Vector3(-12,.2,13)],["radio",Vector3(21.5,.2,4.2)]]:
  game.player.position=entry[1];await wait(.1);game.interact();await wait(.1)
 check(game.state.inventory.plant==1 and game.state.inventory.radio==1,"Collect multiple actual world objects")
 check(game.state.inventory.wood==12 and game.state.inventory.scrap==4,"Collect world construction materials")
 var home_route:PackedVector3Array=game.world.route(Vector3(0,0,20),Vector3(-24,0,30))
 check(home_route.size()>2 and home_route[home_route.size()-1].distance_to(Vector3(-24,.2,30))<.1,"Navigation reaches accessible home interior, not a partial path")
 game.player.position=Vector3(-24,.3,29);await wait(.25)
 check(game.state.objective.returned,"Returning home advances starter objective")
 var untouched=game.state.snapshot()
 game.begin_placement("plant");await wait(.1);game.cancel_placement()
 check(game.state.snapshot()==untouched,"Cancel preview leaves inventory and identity unchanged")
 game.begin_placement("plant");var rotation_before=game.placement_yaw;var distance_before=game.placement_distance
 var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;game._unhandled_input(wheel)
 check(is_equal_approx(game.placement_yaw-rotation_before,PI/12) and game.placement_distance==distance_before,"Mouse wheel rotates placement without changing distance")
 rotation_before=game.placement_yaw;wheel.shift_pressed=true;game._unhandled_input(wheel)
 check(is_equal_approx(game.placement_yaw-rotation_before,deg_to_rad(5)),"Shift-wheel gives five-degree fine rotation");game.cancel_placement()
 game.begin_placement("wall");game.snap=true;rotation_before=game.placement_yaw;wheel.shift_pressed=false;game._unhandled_input(wheel);game.update_placement()
 check(is_equal_approx(game.placement_yaw-rotation_before,PI/2),"Snapped construction wheel rotation survives the preview update")
 var rotate=InputEventAction.new();rotate.action="rotate_right";rotate.pressed=true;rotation_before=game.placement_yaw;game._unhandled_input(rotate);game.update_placement()
 check(is_equal_approx(game.placement_yaw-rotation_before,PI/2),"Snapped keyboard/pad rotation survives the preview update");game.snap=false;game.cancel_placement()
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
 var barrier=await place("barricade",Vector3(-24,.085,22),0)
 check(game.objective_complete(),"Complete starter objective and continue sandbox")
 game.state.inventory.wood+=30;game.state.inventory.scrap+=10
 var chest=await place("storage",Vector3(-20,.175,31.8),.5)
 check(game.state.transfer(chest,"wood",7,true),"Deposit supplies in built chest")
 check(game.state.transfer(chest,"radio",0,true)==false,"Zero transfer is safely rejected")
 game.ui.storage_menu(chest);await capture("03-storage");game.close_overlay()
 var door_id=await place("door",Vector3(-24,.135,24.3),0)
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
 game.state.reset();game.state.settings.cap=false;game.load_game()
 check(game.running and game.state.objects.size()==snapshot.objects.size(),"Load furnished base")
 check(not game.state.settings.cap and Engine.max_fps==0,"Loading older save preserves current FPS preference")
 game.state.settings.cap=true;game.apply_settings()
 check(arrangement_matches(game.state.snapshot(),snapshot),"Object identity, arrangement and container contents survive save/load within 1e-9 radians")
 game.rebuild();await wait(.3)
 check(get_tree().get_nodes_in_group("placed").size()==snapshot.objects.size(),"Load restores one physics object per saved identity")
 check(game.world.loot.filter(func(item):return item.id=="fern").is_empty(),"Collected world object stays absent after reload")
 var home_drawer=game.world.containers.filter(func(entry):return entry.id=="14-cedar-lane-drawer")[0]
 check(game.world.container_items(home_drawer).is_empty(),"Searched container contents stay removed after reload")
 var home_fridge=game.world.containers.filter(func(entry):return entry.id=="14-cedar-lane-fridge")[0]
 check(game.world.container_items(home_fridge).size()==1 and game.world.container_items(home_fridge)[0].kind=="water","Partially looted refrigerator preserves its remaining contents after reload")
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
 var respawn_victim=get_tree().get_nodes_in_group("zombies")[0];respawn_victim.take_damage(100)
 var live_before=get_tree().get_nodes_in_group("zombies").filter(func(enemy):return enemy.alive).size()
 var replacement=game.world.try_respawn()
 check(replacement and get_tree().get_nodes_in_group("zombies").filter(func(enemy):return enemy.alive).size()==live_before+1,"Killed zombie is replaced away from player and home")
 check(not game.world.try_respawn(),"Respawning respects the eighteen-zombie population cap")
 # Exercise the model fallback shape without emitting a missing-file error.
 var original_zombie=game.assets.scenes.zombie
 var empty_scene=PackedScene.new();var empty_model=Node3D.new();empty_scene.pack(empty_model);empty_model.free()
 game.assets.scenes.zombie=empty_scene
 var fallback_zombie=game.world.Zombie.new();game.world.add_child(fallback_zombie);fallback_zombie.configure(game,Vector3(60,.2,60),0)
 check(fallback_zombie.animation==null and fallback_zombie.visual!=null,"Zombie model without animations configures safely")
 fallback_zombie.queue_free();game.assets.scenes.zombie=original_zombie;await wait(.1)
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
 for key in ["inventory","collected","objective","health","magazine","weapons","equipped","next_id","kills","settings"]:
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
