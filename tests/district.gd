extends Node
var game
var suite
func check(condition:bool,message:String):suite.check(condition,message)
func wait(seconds:float=.2):await get_tree().create_timer(seconds).timeout
func run(owner_game,test_suite):
 game=owner_game;suite=test_suite;game.close_overlay()
 for enemy in get_tree().get_nodes_in_group("zombies"):enemy.set_physics_process(false)
 var variants=get_tree().get_nodes_in_group("zombies")
 var legs=variants.filter(func(enemy):return enemy.variant=="zombie-ribcage")[0]
 var basic=variants.filter(func(enemy):return enemy.variant=="zombie")[0]
 var large=variants.filter(func(enemy):return enemy.variant=="zombie-chubby")[0]
 check(legs.chase_speed>basic.chase_speed and legs.attack_damage<=4 and large.chase_speed<basic.chase_speed,"Leg-only zombie is fastest and weak; bulky zombie moves slightly slower than the standard")
 check(game.world.vehicles.size()==6 and game.world.vehicles.all(func(car):return not car.armored and car.base_kind in ["car","car-sports","car-truck"]),"New districts park only intact unarmored pickup, sports car and truck models")
 var car=game.world.vehicles[0];game.state.inventory.vehicle_parts=2;game.state.inventory.scrap=10
 var before=car.visual;check(car.upgrade() and car.armored and car.kind=="car-pickup-armored" and car.visual!=before,"Fitting collected parts swaps to the matching armored model")
 var inventory=game.state.inventory.duplicate(true);check(not car.upgrade() and game.state.inventory==inventory,"A fitted vehicle cannot spend another upgrade")
 car.position=Vector3(0,.06,-106);car.rotation.y=PI/2;car.speed=0;car.velocity=Vector3.ZERO;car.reset_physics_interpolation()
 game.player.position=car.position+car.global_basis*Vector3(-2.6,.05,0);car.enter(game.player);await wait(.3)
 check(car.engine.playing and not car.engine.stream_paused and car.engine.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Entering starts an audible looping positional engine")
 check(absf(car.engine.stream.get_length()-8.0)<.01 and car.engine.stream.loop_end==roundi(8.0*car.engine.stream.mix_rate),"Encoded engine loop uses all eight seconds of samples")
 await wait(8.1);check(car.engine.playing,"Engine playback continues after a complete idle loop")
 var idle=car.engine.pitch_scale;Input.action_press("forward");await wait(.8);Input.action_release("forward")
 check(car.engine.pitch_scale>idle+.1,"Engine pitch responds to throttle and acceleration")
 game.ui.backpack();await wait(.1);check(car.engine.stream_paused,"Paused inventory suspends engine playback");game.close_overlay();await wait(.1)
 Input.action_press("forward");await wait(1.6);Input.action_release("forward")
 check(car.position.x>10,"A driven car crosses the sidewalk into the connected fuel forecourt")
 check(car.exit_driver() and not car.engine.playing,"Leaving switches the engine off")
 game.save_game(false);game.load_game();await wait(.2)
 check(game.world.vehicles[0].armored and game.world.vehicles[0].kind=="car-pickup-armored","Fitted vehicle model survives save/load")
 var outskirts=Vector3(-105,game.world.ground_height(-105,130)+.05,130)
 game.player.position=outskirts;game.player.velocity=Vector3.ZERO;game.player.set_physics_process(false);game.save_game(false);game.load_game();await wait(.1)
 check(game.player.position.distance_to(outskirts)<.25,"A supported save beyond the old map limit reloads on the expanded rural road")
 # The visual asphalt and its collision share one mesh, including cosmetic cracks.
 var road=game.world.find_child("ContinuousRoad",false,false);check(road!=null and road.get_child(0).get_child(0).shape is ConcavePolygonShape3D,"One continuous custom road owns its matching triangle collision")
 game.player.set_process(false);game.player.set_physics_process(true)
 for z in [-96,-48,0,48]:
  game.player.position=Vector3(0,.25,z);game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation();await wait(.3)
  check(absf(game.player.position.y+.025-.04)<.04,"Road supports feet above the visible surface at z="+str(z))
 game.player.set_physics_process(false)
 # Compare every solid furnishing and searchable cabinet, including rotated rooms.
 var fixtures=game.world.furnishings+game.world.containers;var overlaps:Array=[]
 for i in range(fixtures.size()):
  var a=fixtures[i];var aa=fixture_bounds(a.body).grow(-.025)
  for j in range(i+1,fixtures.size()):
   var b=fixtures[j]
   if a.address!=b.address:continue
   var bb=fixture_bounds(b.body).grow(-.025)
   if aa.intersects(bb):overlaps.append(a.address+": "+a.kind+" / "+b.kind+" at "+str(a.body.global_position))
 check(overlaps.is_empty(),"Solid furniture/containers have no unintended overlaps: "+str(overlaps))
 for entry in game.world.furnishings:
  var bounds=game.world.model_bounds(entry.node);var expected=game.world.buildings.dimensions(entry.node.global_basis,bounds.size)
  check(expected.distance_to(fixture_bounds(entry.body).size)<.02,"Solid furnishing collision fits its actual mesh: "+entry.address+" "+entry.kind)
 for path in game.world.paths:
  var at=path.at+path.basis*Vector3(0,1.0,path.gate);var query=PhysicsShapeQueryParameters3D.new();query.shape=game.player.get_child(0).shape;query.transform=Transform3D(Basis(),at);query.collision_mask=1;query.exclude=[game.player.get_rid()]
  check(game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),"Doorway-center path has an unobstructed fence gate: "+str(path.at))
 var parts=game.world.containers.filter(func(entry):return entry.kind=="parts");check(parts.size()==2 and parts[0].stock[0].id!=parts[1].stock[0].id,"Each auto-shop parts chest has independently persistent stock")
 var preview_character=game.state.character;game.ui.backpack();await wait(.2)
 var select=game.ui.panel_content.get_child(2).get_child(1);var preview=game.ui.panel_content.get_child(2).get_child(2)
 for character in game.catalog.CHARACTERS:
  select.item_selected.emit(game.catalog.CHARACTERS.keys().find(character));await wait(.1)
  check(preview.model.name!="" and game.state.character==character and preview.viewport.get_texture().get_image().get_size().x>0,"Selecting "+character+" refreshes its real model preview")
 game.change_character(preview_character);game.close_overlay();game.player.set_process(true);game.player.set_physics_process(true)
func fixture_bounds(body:StaticBody3D) -> AABB:
 var bounds=AABB();var found=false
 for child in body.get_children():
  if child is CollisionShape3D:
   var box=AABB(body.global_position+child.position-child.shape.size/2,child.shape.size);bounds=bounds.merge(box) if found else box;found=true
 return bounds
