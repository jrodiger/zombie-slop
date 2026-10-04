extends Node
var game
var suite
func wait(seconds:float=.15):await get_tree().create_timer(seconds).timeout
func capture(name:String):await suite.capture(name)
func check(condition:bool,message:String):suite.check(condition,message)
func run(owner_game,test_suite):
 game=owner_game;suite=test_suite
 game.close_overlay();game.player.set_physics_process(false);game.player.set_process(false)
 for enemy in get_tree().get_nodes_in_group("zombies"):enemy.set_physics_process(false)
 var kinds=[]
 for enemy in get_tree().get_nodes_in_group("zombies"):
  if enemy.variant not in kinds:kinds.append(enemy.variant)
 check(kinds.size()==4,"Neighborhood population includes all four zombie variants")
 var bulky=get_tree().get_nodes_in_group("zombies").filter(func(enemy):return enemy.variant=="zombie-chubby")[0]
 check(bulky.max_hp==220 and bulky.max_hp>100 and bulky.get_child(0).shape.radius>.34,"Larger zombie has more health and an appropriately larger capsule")
 var hill_trees=0;var blocked_hill_trees=0
 for node in game.world.get_children():
  if not node is StaticBody3D or node.get_child_count()==0:continue
  var shape=node.get_child(0).shape
  if shape is BoxShape3D and shape.size==Vector3(.55,2,.55) and node.position.y>2.6:
   hill_trees+=1
   if game.world.navigation.is_point_solid(Vector2i(roundi(node.position.x),roundi(node.position.z))):blocked_hill_trees+=1
 check(hill_trees>0 and blocked_hill_trees==hill_trees,"All hillside tree trunks block the navigation grid at their actual ground height")
 game.player.set_physics_process(true);game.player.position=Vector3(-95,game.world.ground_height(-95,-35)+.2,-35);game.player.velocity=Vector3.ZERO;game.player.yaw=PI/2;game.player.reset_physics_interpolation();await wait(.2)
 Input.action_press("forward");await wait(1.9);Input.action_release("forward")
 check(game.player.position.x< -101 and absf(game.player.position.y-game.world.ground_height(game.player.position.x,-35))<.2,"Actual walking climbs the sloped outskirts without jumping or falling through terrain")
 game.player.position=Vector3(84,game.world.ground_height(84,55)+.2,55);game.player.velocity=Vector3.ZERO;game.player.yaw=-PI/2;game.player.reset_physics_interpolation();await wait(.2)
 Input.action_press("forward");await wait(5.7);Input.action_release("forward");game.player.set_physics_process(false)
 check(game.player.position.x>106 and game.player.position.y>-.2,"Actual walking crosses the river bridge and both approaches without jumping")
 game.player.set_physics_process(true);game.player.position=Vector3(162.7,game.world.ground_height(162.7,-161)+.2,-161);game.player.velocity=Vector3.ZERO;game.player.yaw=-PI/2;game.player.reset_physics_interpolation();await wait(.2)
 Input.action_press("forward");await wait(.6);Input.action_release("forward");game.player.set_physics_process(false)
 check(game.player.position.x<163.25 and game.player.position.y>6,"High corner terrain remains contained by the map boundary")
 for entry in game.world.containers:
  if entry.kind not in ["safe","fridge"]:continue
  var door=entry.door;var mesh=door.get_child(0) as MeshInstance3D;var faces=mesh.mesh.get_faces();var nearest=100.0
  for point in faces:
   var world=mesh.global_transform*point;nearest=minf(nearest,Vector2(world.x-door.global_position.x,world.z-door.global_position.z).length())
  check(nearest<.045,entry.address+" "+entry.kind+" exported front is attached to its hinge")
 for roof in game.world.roofs:check(roof.node.get_aabb().position.y<=float(roof.get("height",3.2)),"Imported roof eave meets the wall top: "+str(roof.at))
 var stocks=[]
 for entry in game.world.containers:
  if entry.kind=="fridge":stocks.append(JSON.stringify(entry.stock.map(func(item):return [item.kind,item.amount])))
 check(stocks.any(func(stock):return stock!=stocks[0]),"House refrigerators vary their contents")
 for weapon in [["8-cedar-lane-safe","rifle-supply"],["12-cedar-lane-safe","shotgun-porch"],["14-cedar-lane-drawer","starter-axe"],["11-cedar-lane-safe","smg-find"],["3-cedar-lane-safe","revolver-find"],["4-cedar-lane-safe","compact-find"],["7-cedar-lane-safe","bat-find"],["2-orchard-way-safe","knife-find"]]:
  game.player.set_physics_process(true)
  await suite.loot_container(weapon[0],weapon[1]);game.player.set_physics_process(false)
 check(game.state.weapons.size()==game.catalog.WEAPONS.size(),"Every usable firearm and melee weapon can be found through real container interactions")
 game.player.position=Vector3(-24,.2,22);game.player.velocity=Vector3.ZERO
 for character in game.catalog.CHARACTERS:
  game.ui.backpack()
  var select=game.ui.panel_content.get_child(2).get_child(1)
  select.item_selected.emit(game.catalog.CHARACTERS.keys().find(character));select.grab_focus()
  var tab=InputEventKey.new();tab.physical_keycode=KEY_TAB;tab.pressed=true;Input.parse_input_event(tab)
  await get_tree().process_frame
  tab=InputEventKey.new();tab.physical_keycode=KEY_TAB;Input.parse_input_event(tab)
  check(not game.inventory_open and not game.overlay,"Real Tab input closes the focused survivor selector for "+character)
  check(game.state.character==character and game.player.weapon_visuals.size()==game.catalog.WEAPONS.size(),"Inventory selects "+character+" with all weapon attachments")
  game.player.visual.rotation.y=0
  var skeleton=game.assets.skeleton(game.player.visual)
  for kind in ["pistol","rifle","shotgun","smg","revolver","compact_shotgun"]:
   game.player.equip(kind)
   var model=game.player.model_name(kind);var grip=game.player.visual.find_child(model+"Grip",true,false);var muzzle=game.player.visual.find_child(model+"Muzzle",true,false)
   for clip in ["Aim_","LowerWalk_"]:
    game.player.animation.play(clip+model,0);game.player.animation.seek(.15,true);await wait(.02)
    var barrel=(muzzle.global_position-grip.global_position).normalized()
    check(game.player.visual.to_local(grip.global_position).x<0,character+" "+kind+" "+clip+" is right handed")
    check(barrel.y<-.5 if clip=="LowerWalk_" else barrel.dot(game.player.visual.global_basis.z.normalized())>.85,character+" "+kind+" barrel lowers for travel and rises for aim")
    if kind in ["rifle","shotgun","smg","compact_shotgun"]:
     var fore=game.player.visual.find_child(model+"ForeGrip",true,false);var hand=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("Middle1.R")).origin
     check(hand.distance_to(fore.global_position)<.14,character+" "+kind+" support hand meets foregrip")
   if kind=="rifle":
    game.player.camera.global_position=game.player.position+Vector3(-2,1.6,2.5);game.player.camera.look_at(game.player.position+Vector3.UP*1.1)
    await capture("character-"+character+"-rifle-lowered")
    game.player.animation.play("Aim_Rifle",0);game.player.animation.seek(.15,true);await wait(.05);await capture("character-"+character+"-rifle-aim")
  for kind in ["axe","bat","knife"]:
   game.player.equip(kind);game.player.animation.play("Stab" if kind=="knife" else "Slash",0);game.player.animation.seek(.15,true);await wait(.04)
   var mesh=game.player.weapon_visuals[kind]
   check(mesh.visible and not game.player.weapon_visuals.pistol.visible,character+" "+kind+" uses its authored hand attachment")
   if kind=="axe":await capture("character-"+character+"-axe")
 game.change_character("matt");game.player.equip("axe");game.player.visual.rotation.y=0
 var enemy=get_tree().get_nodes_in_group("zombies").filter(func(z):return z.alive)[0]
 enemy.position=game.player.position+Vector3(0,0,1.5);enemy.hp=100;var ammo=game.state.inventory.ammo
 game.player.shot_cooldown=0;game.player.shoot();check(enemy.hp==100,"Melee damage waits for the swing contact")
 game.player.set_physics_process(true);await wait(.4);game.player.set_physics_process(false)
 check(enemy.hp==35 and game.state.inventory.ammo==ammo,"Axe swing hits once at contact without consuming ammunition")
 var wall=game.world.collider(game.player.position+Vector3(0,1,1),Vector3(2,2,.15),false);await get_tree().physics_frame
 enemy.hp=100;game.player.melee_hit();check(enemy.hp==100,"Melee cannot hit through a wall");wall.queue_free();await get_tree().physics_frame
 game.player.melee_left=0;game.player.melee_pending=false
 # Exercise every firearm's actual pellet/muzzle rays, not just attachment visibility.
 game.player.position=Vector3(-24,.2,22);game.player.visual.rotation.y=0;game.player.aiming=true
 enemy.position=game.player.position+Vector3(0,0,3);enemy.alive=true;enemy.collision_layer=4
 for kind in ["smg","revolver","compact_shotgun"]:
  game.player.equip(kind);game.state.magazine=1;enemy.hp=1000
  game.player.animation.play(game.player.weapon_clip("Aim"),0);game.player.animation.seek(.15,true);await wait(.1)
  game.player.camera.global_position=game.player.position+Vector3(-.65,1.6,-2.5);game.player.camera.look_at(enemy.position+Vector3.UP*.9)
  game.player.shot_cooldown=0;game.player.shoot()
  check(game.state.magazine==0 and enemy.hp<1000,"Looted "+kind+" fires its real damage rays and consumes one round")
 game.player.aiming=false;enemy.alive=true
 # Real car controls, collision, safe exit and persisted transforms.
 var car=game.world.vehicles[3];game.player.position=car.position+car.global_basis*Vector3(-2.6,.05,0);game.player.velocity=Vector3.ZERO
 game.player.set_physics_process(true);await wait(.2);game.player.melee_left=.5;game.player.melee_pending=true;game.player.reload_left=1;game.player.aiming=true;game.interact()
 check(game.player.driving==car and not game.player.visual.visible,"Interaction enters a drivable car and hides the standing survivor")
 check(not game.player.melee_pending and game.player.melee_left==0 and game.player.reload_left==0 and not game.player.aiming,"Entering a vehicle cancels pending melee, reload and aim")
 var start=car.position;Input.action_press("forward");await wait(1.5);Input.action_release("forward")
 check(car.position.distance_to(start)>2 and absf(car.speed)>2,"Driving accelerates and moves using actual controls")
 var yaw=car.rotation.y;Input.action_press("left");Input.action_press("forward");await wait(.4);Input.action_release("left");Input.action_release("forward")
 check(absf(car.rotation.y-yaw)>.1,"Steering turns a moving car")
 Input.action_press("jump");await wait(.7);Input.action_release("jump");check(absf(car.speed)<.5,"Vehicle brake settles to a stop")
 game.player.set_physics_process(false);game.player.set_process(false);game.player.camera.global_position=car.position+Vector3(-5,3,-5);game.player.camera.look_at(car.position+Vector3.UP);await capture("driving")
 check(car.exit_driver() and game.player.driving==null and game.player.visual.visible and game.player.collision_layer==2,"Vehicle exits onto clear supported ground and restores movement")
 var transforms={}
 for vehicle in game.world.vehicles:transforms[vehicle.ident]=vehicle.snapshot()
 game.save_game(false);var seed=game.state.loot_seed;game.change_character("sam");game.save_game(false);game.load_game();await wait(.2)
 check(game.state.character=="sam" and game.state.loot_seed==seed,"Character choice and randomized neighborhood seed persist")
 check(game.world.vehicles.all(func(vehicle):return vehicle.snapshot()==transforms[vehicle.ident]),"Every driven/parked car transform persists through save/load")
 game.ui.backpack();check(game.inventory_open and game.overlay,"Inventory opens as a dedicated paused overlay")
 await capture("inventory-expanded");await suite.tap("inventory");check(not game.inventory_open and not game.overlay,"Tab closes inventory and returns to play")
 for vehicle in game.world.vehicles:
  check(game.world.model_bounds(vehicle.visual).size.distance_to(vehicle.get_child(0).shape.size)<.12,"Vehicle collider fits the actual imported model: "+vehicle.kind)
  game.player.position=vehicle.position+vehicle.global_basis*Vector3(-2.6,.05,0);vehicle.enter(game.player)
  check(vehicle.driver==game.player and vehicle.exit_driver(),"Every intact vehicle model supports entry and safe exit: "+vehicle.kind)
 game.change_character("matt");game.player.equip("pistol")
 # River beds are below the old flat-map recovery threshold. Valid supported
 # river positions must reload there; old flat-map saves below new hills recover.
 var river=Vector3(game.world.river_x(-20),-1.57,-20);game.player.position=river;game.save_game(false);game.load_game();await wait(.2)
 check(game.player.position.distance_to(river)<.2,"A supported river-bed save reloads there instead of incorrectly returning home")
 game.state.player_position=[-103,.2,-17];game.rebuild()
 check(game.player.position.distance_to(Vector3(-24,.4,20))<1,"An old flat-map save below a new hillside safely recovers to the home path")
