extends Node
var game
var suite
func check(condition:bool,message:String):suite.check(condition,message)
func wait(seconds:float=.2):await get_tree().create_timer(seconds).timeout
func bone(skeleton:Skeleton3D,name:String) -> Vector3:
 return skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin
func run(owner_game,test_suite):
 game=owner_game;suite=test_suite;game.close_overlay()
 game.player.set_process(false);game.player.set_physics_process(false)
 for enemy in get_tree().get_nodes_in_group("zombies"):
  enemy.set_physics_process(false);enemy.set_process(false);enemy.growl.stop()
 for character in game.catalog.CHARACTERS:
  game.change_character(character);game.player.position=Vector3(0,.04,100);game.player.visual.rotation.y=0
  var skeleton=game.assets.skeleton(game.player.visual);game.player.motion.legs.pause()
  for kind in ["pistol","revolver","rifle","shotgun","smg","compact_shotgun"]:
   game.state.weapons[kind]=0;game.player.equip(kind)
   var model=game.player.model_name(kind);var grip=game.player.visual.find_child(model+"Grip",true,false);var muzzle=game.player.visual.find_child(model+"Muzzle",true,false)
   for pose in ["LowerIdle","Aim"]:
    game.player.animation.play(game.player.weapon_clip(pose),0);game.player.animation.seek(.15,true);game.player.animation.pause();await wait(.05)
    var barrel=(muzzle.global_position-grip.global_position).normalized()
    var wrist=bone(skeleton,"Middle1.L");var shoulder=bone(skeleton,"UpperArm.L")
    check(wrist.distance_to(grip.global_position)<.16,character+" "+kind+" "+pose+" grip stays in the firing hand")
    if pose=="LowerIdle":
     var body_inverse=skeleton.get_bone_global_pose(skeleton.find_bone("Body")).affine_inverse()
     var symmetry_error=0.0
     for joint in ["UpperArm","LowerArm","Middle1"]:
      var dominant=body_inverse*skeleton.get_bone_global_pose(skeleton.find_bone(joint+".L")).origin
      var free=body_inverse*skeleton.get_bone_global_pose(skeleton.find_bone(joint+".R")).origin
      symmetry_error=maxf(symmetry_error,dominant.distance_to(Vector3(-free.x,free.y,free.z)))
     var elbow=bone(skeleton,"LowerArm.L")
     check(symmetry_error<.012,character+" "+kind+" lowered shoulder/elbow/wrist mirror the free arm")
     check((elbow-shoulder).normalized().dot((wrist-elbow).normalized())>.85,character+" "+kind+" lowered arm has a relaxed elbow without a backward zigzag")
     check(wrist.y<shoulder.y-.3 and absf(wrist.z-shoulder.z)<.25,character+" "+kind+" carry hand rests below the shoulder beside the body")
     check(muzzle.global_position.y<grip.global_position.y-.15 and muzzle.global_position.y>game.player.global_position.y+.025,character+" "+kind+" carry muzzle points down and clears the ground")
    else:
     check(barrel.dot(game.player.visual.global_basis.z.normalized())>.95,character+" "+kind+" aimed barrel points forward")
     if kind not in ["pistol","revolver"]:
      var fore=game.player.visual.find_child(model+"ForeGrip",true,false)
      check(bone(skeleton,"Middle1.R").distance_to(fore.global_position)<.12,character+" "+kind+" supporting hand reaches the foregrip")
  game.player.animation.play(game.player.weapon_clip("Reload"),0)
  game.player.motion.legs.play("Walk",0);game.player.motion.legs.seek(.1,true)
  var start=bone(skeleton,"Foot.L");await wait(.25)
  check(game.player.animation.current_animation.begins_with("Reload") and game.player.motion.legs.current_animation=="Walk" and bone(skeleton,"Foot.L").distance_to(start)>.08,character+" walking feet continue during reload")
  game.player.motion.legs.play("Run",0);game.player.motion.legs.seek(.05,true);start=bone(skeleton,"Foot.L");await wait(.2)
  check(bone(skeleton,"Foot.L").distance_to(start)>.12,character+" running feet continue during reload")
 # Imported mesh facing, rather than house/world orientation, defines furniture front.
 var fixtures=game.world.furnishings
 for entry in fixtures.filter(func(value):return value.kind in ["chair","couch"]):
  var partner="table" if entry.kind=="chair" else "tvstand"
  var matches=fixtures.filter(func(value):return value.address==entry.address and value.kind==partner)
  if matches.is_empty():continue
  var target=matches[0].node.global_position-entry.node.global_position;target.y=0
  check(entry.node.global_basis.z.normalized().dot(target.normalized())>.9,entry.address+" "+entry.kind+" faces "+partner)
 var raft=fixtures.filter(func(entry):return entry.kind=="raft")[0].node
 var bounds=game.world.model_bounds(raft)
 var ray=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(raft.global_position+Vector3.UP*2,raft.global_position-Vector3.UP*3,1,[fixtures.filter(func(entry):return entry.kind=="raft")[0].body.get_rid()]))
 check(not ray.is_empty() and absf(raft.global_position.y+bounds.position.y-ray.position.y)<.15,"Raft hull rests on the actual riverbank surface")
 game.player.set_physics_process(true)
 for z in [-17,65]:
  var x=game.world.river_x(z);game.player.position=Vector3(x,.5,z);game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation();await wait(.3)
  check(game.player.position.y>0 and game.player.position.y<.3,"River road crossing supports feet above water at z="+str(z))
 game.player.set_physics_process(false)
 var enemy=get_tree().get_nodes_in_group("zombies")[0];enemy.set_process(true);enemy.position=Vector3(0,.04,100);game.player.position=Vector3(0,.04,104);enemy.growl_left=0;await wait(.12)
 check(enemy.growl.playing and not enemy.growl.stream_paused and enemy.growl.stream!=null,"Nearby living zombie plays a positional recorded growl")
 game.ui.backpack();await wait(.1);check(enemy.growl.stream_paused,"Inventory pause suspends the nearby growl");game.close_overlay();await wait(.05)
 enemy.growl_left=0;enemy.growl.stop();game.player.position=Vector3(0,.04,130);await wait(.1);check(not enemy.growl.playing,"Distant zombie remains inaudible")
 game.player.position=Vector3(0,.04,104);enemy.growl_left=0;await wait(.1);enemy.take_damage(enemy.hp+1);check(not enemy.growl.playing,"Zombie death stops its warning growl")
 var before=game.state.snapshot();game.state.inventory.wood=100;game.state.inventory.scrap=100
 var blocked_at=game.world.safe_center+Vector3(5.2,.16,-.5)
 check(game.state.place("storage",blocked_at,0,true)>0,"Saved furniture can occupy the new home TV-stand location")
 game.rebuild();await wait(.1)
 check(game.world.furnishings.filter(func(entry):return entry.address=="14 Cedar Lane" and entry.kind=="tvstand").is_empty(),"Saved arrangement takes priority over the home TV stand")
 var floating_tv=false
 for child in game.world.get_children():
  if child is Node3D and child.position.distance_to(blocked_at+Vector3.UP*.74)<.05:floating_tv=true
 check(not floating_tv,"Omitted home TV stand does not leave a floating television")
 game.state.restore(before);game.rebuild()
 game.player.set_process(true);game.player.set_physics_process(true)
