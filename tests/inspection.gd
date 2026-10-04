extends Node
var game
var failed:int=0
var targets:int=0
func shot(name:String,at:Vector3,target:Vector3,hide_player:bool=true):
 game.player.visual.visible=not hide_player;game.player.camera.global_position=at;game.player.camera.look_at(target)
 await get_tree().create_timer(.15).timeout;await RenderingServer.frame_post_draw
 game.get_viewport().get_texture().get_image().save_png(game.report_dir()+"/"+name+".png");game.player.visual.visible=true
func walk(target:Vector3) -> bool:
 targets+=1;game.player.set_physics_process(true)
 for i in range(300):
  var offset=target-game.player.position;offset.y=0
  if offset.length()<.18:break
  game.player.yaw=atan2(-offset.x,-offset.z);Input.action_press("forward");await get_tree().physics_frame
 Input.action_release("forward");game.player.velocity=Vector3.ZERO;game.player.set_physics_process(false)
 var reached=Vector2(game.player.position.x-target.x,game.player.position.z-target.z).length()<.4 and absf(game.player.position.y-target.y)<.35
 print("ROOM WALK ",target," reached=",reached," actual=",game.player.position)
 if not reached:failed+=1
 return reached
func poses():
 game.change_character("shaun");game.player.position=Vector3(-24,.04,19);game.player.visual.rotation.y=0;game.player.set_physics_process(false)
 for kind in ["pistol","rifle","shotgun","smg","revolver","compact_shotgun"]:
  game.state.weapons[kind]=0;game.player.equip(kind)
  for pose in ["LowerIdle","Aim","Shoot","Reload"]:
   game.player.animation.play(game.player.weapon_clip(pose),0);game.player.animation.seek(.15 if pose!="Reload" else .95,true);game.player.animation.pause()
   for side in [-1,1]:
    await shot("shaun-"+kind+"-"+pose+"-"+str(side),game.player.position+Vector3(side*1.5,1.4,1.7),game.player.position+Vector3(0,1.12,.35),false)
   if pose=="Reload":
    for time in [.25,.65,1.4,1.8]:
     game.player.animation.play(game.player.weapon_clip(pose),0);game.player.animation.seek(time,true);game.player.animation.pause()
     await shot("shaun-"+kind+"-reload-"+str(time),game.player.position+Vector3(-1.3,1.5,1.7),game.player.position+Vector3(0,1.05,.2),false)
 if "--all-survivors" in OS.get_cmdline_user_args():
  for character in ["matt","lis","sam"]:
   game.change_character(character)
   for kind in ["pistol","rifle","shotgun","smg","revolver","compact_shotgun"]:
    game.player.equip(kind)
    for pose in ["LowerIdle","Aim"]:
     game.player.animation.play(game.player.weapon_clip(pose),0);game.player.animation.seek(.15,true);game.player.animation.pause()
     for side in [-1,1]:await shot(character+"-"+kind+"-"+pose+"-"+str(side),game.player.position+Vector3(side*1.5,1.4,1.7),game.player.position+Vector3(0,1.05,.25),false)
 game.change_character("shaun");game.player.equip("rifle");game.player.motion.legs.pause()
 for gait in ["Walk","Run"]:
  for reload in [false,true]:
   for time in [.05,.2,.35,.5]:
    game.player.motion.legs.play(gait,0);game.player.motion.legs.seek(time,true);game.player.motion.legs.pause()
    game.player.animation.play(game.player.weapon_clip("Reload" if reload else "Lower"+gait),0);game.player.animation.seek(.8 if reload else time,true);game.player.animation.pause()
    await shot("gait-"+gait+("-reload" if reload else "")+"-"+str(time),game.player.position+Vector3(-2,1.0,.2),game.player.position+Vector3(0,.65,0),false)
func carry_views():
 # Match the user's full-body front/side views, then inspect the same silhouette
 # closer up using normal simulation, then press/release the real aim action.
 var cases=[];var transitions=[];var gaits=[];var failures=0
 for character in ["shaun","matt","lis","sam"]:
  game.change_character(character)
  for kind in ["pistol","revolver","rifle","shotgun","smg","compact_shotgun"]:
   game.state.weapons[kind]=0;game.player.equip(kind)
   game.player.position=Vector3(0,.04,100);game.player.visual.rotation.y=0
   Input.action_release("aim");game.player.set_physics_process(true)
   await get_tree().create_timer(.4).timeout
   var playing_clip=game.player.animation.current_animation
   game.player.set_physics_process(false);game.player.motion.legs.pause();game.player.animation.pause()
   var skeleton=game.assets.skeleton(game.player.visual)
   var inverse=skeleton.get_bone_global_pose(skeleton.find_bone("Body")).affine_inverse()
   var error=0.0
   for joint in ["UpperArm","LowerArm","Middle1"]:
    var dominant=inverse*skeleton.get_bone_global_pose(skeleton.find_bone(joint+".L")).origin
    var free=inverse*skeleton.get_bone_global_pose(skeleton.find_bone(joint+".R")).origin
    error=maxf(error,dominant.distance_to(Vector3(-free.x,free.y,free.z)))
   var shoulder=skeleton.get_bone_global_pose(skeleton.find_bone("UpperArm.L")).origin
   var elbow=skeleton.get_bone_global_pose(skeleton.find_bone("LowerArm.L")).origin
   var wrist=skeleton.get_bone_global_pose(skeleton.find_bone("Middle1.L")).origin
   var alignment=(elbow-shoulder).normalized().dot((wrist-elbow).normalized())
   var passed=error<.012 and alignment>.85 and playing_clip==game.player.weapon_clip("LowerIdle")
   if not passed:failures+=1
   cases.append({"character":character,"weapon":kind,"clip":playing_clip,"symmetry_error":error,"arm_alignment":alignment,"passed":passed})
   print("CARRY ",character," ",kind," clip=",playing_clip," symmetry=",error," alignment=",alignment," passed=",passed)
   for view in [{"name":"front","offset":Vector3(0,1.1,2.4)},{"name":"side","offset":Vector3(-2.4,1.1,0)}]:
    await shot(character+"-"+kind+"-"+view.name,game.player.position+view.offset,game.player.position+Vector3.UP*.8,false)
   if character=="shaun" and kind=="pistol":
    await shot("carry-front",game.player.position+Vector3(0,1.7,6),game.player.position+Vector3.UP*.8,false)
    await shot("carry-side",game.player.position+Vector3(-6,2,0),game.player.position+Vector3.UP*.8,false)
 game.change_character("shaun")
 for kind in ["pistol","revolver","rifle","shotgun","smg","compact_shotgun"]:
  game.player.equip(kind);game.player.set_physics_process(true);Input.action_press("aim")
  await get_tree().create_timer(.4).timeout
  var model=game.player.model_name(kind)
  var grip=game.player.visual.find_child(model+"Grip",true,false)
  var muzzle=game.player.visual.find_child(model+"Muzzle",true,false)
  var aimed=game.player.animation.current_animation==game.player.weapon_clip("Aim") and (muzzle.global_position-grip.global_position).normalized().dot(game.player.visual.global_basis.z.normalized())>.95
  game.player.set_physics_process(false);game.player.motion.legs.pause();game.player.animation.pause()
  await shot(kind+"-aim",game.player.position+Vector3(-2,1.2,1.6),game.player.position+Vector3.UP*.8,false)
  game.player.set_physics_process(true);Input.action_release("aim")
  await get_tree().create_timer(.4).timeout
  var skeleton=game.assets.skeleton(game.player.visual)
  var shoulder=skeleton.get_bone_global_pose(skeleton.find_bone("UpperArm.L")).origin
  var elbow=skeleton.get_bone_global_pose(skeleton.find_bone("LowerArm.L")).origin
  var wrist=skeleton.get_bone_global_pose(skeleton.find_bone("Middle1.L")).origin
  var returned=game.player.animation.current_animation==game.player.weapon_clip("LowerIdle") and (elbow-shoulder).normalized().dot((wrist-elbow).normalized())>.85
  transitions.append({"weapon":kind,"aimed":aimed,"returned_to_relaxed_carry":returned})
  if not aimed or not returned:failures+=1
  game.player.set_physics_process(false);game.player.motion.legs.pause();game.player.animation.pause()
  await shot(kind+"-released",game.player.position+Vector3(-2.4,1.1,0),game.player.position+Vector3.UP*.8,false)
 for kind in ["pistol","revolver","rifle","shotgun","smg","compact_shotgun"]:
  game.player.equip(kind)
  var model=game.player.model_name(kind)
  var grip=game.player.visual.find_child(model+"Grip",true,false)
  var muzzle=game.player.visual.find_child(model+"Muzzle",true,false)
  var skeleton=game.assets.skeleton(game.player.visual)
  for gait in ["Walk","Run"]:
   for time in [.05,.2,.35,.5]:
    game.player.motion.legs.play(gait,0);game.player.motion.legs.seek(time,true);game.player.motion.legs.pause()
    game.player.animation.play(game.player.weapon_clip("Lower"+gait),0);game.player.animation.seek(time,true);game.player.animation.pause()
    # BoneAttachment3D updates grip/muzzle transforms after skeleton evaluation.
    await RenderingServer.frame_post_draw
    var shoulder=skeleton.get_bone_global_pose(skeleton.find_bone("UpperArm.L")).origin
    var elbow=skeleton.get_bone_global_pose(skeleton.find_bone("LowerArm.L")).origin
    var wrist=skeleton.get_bone_global_pose(skeleton.find_bone("Middle1.L")).origin
    var relaxed=(elbow-shoulder).normalized().dot((wrist-elbow).normalized())>.85
    var downward=muzzle.global_position.y<grip.global_position.y-.15
    var clear=muzzle.global_position.y>game.player.global_position.y+.025
    gaits.append({"weapon":kind,"gait":gait,"time":time,"relaxed":relaxed,"muzzle_down":downward,"clear":clear})
    if not relaxed or not downward or not clear:failures+=1
    await shot(kind+"-"+gait+"-"+str(time),game.player.position+Vector3(-2.4,1.1,0),game.player.position+Vector3.UP*.8,false)
 var f=FileAccess.open(game.report_dir()+"/carry.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"cases":cases,"transitions":transitions,"gaits":gaits,"failures":failures,"graphical":DisplayServer.get_name()!="headless"},"  "))
 return 1 if failures else 0
func run(owner_game):
 game=owner_game;game.new_game();game.player.set_process(false)
 for enemy in get_tree().get_nodes_in_group("zombies"):enemy.set_physics_process(false)
 if "--carry-only" in OS.get_cmdline_user_args():return await carry_views()
 if not "--environment-only" in OS.get_cmdline_user_args() and not "--rooms-only" in OS.get_cmdline_user_args():await poses()
 if "--poses-only" in OS.get_cmdline_user_args():return 0
 var addresses=[] if "--environment-only" in OS.get_cmdline_user_args() else ["12 Cedar Lane","8 Cedar Lane","11 Cedar Lane","CEDAR AUTO & FUEL","CEDAR MARKET","ORCHARD MART","1 Meadow Farm"]
 for address in addresses:
  var plot=game.world.properties.filter(func(entry):return entry.address==address)[0];var at:Vector3=plot.at;var basis:Basis=plot.basis;var depth=float(plot.depth);var name=address.to_lower().replace(" ","-")
  var entry_x=3.5 if plot.plan=="garage" else 0.0
  game.player.position=at+basis*Vector3(entry_x,.2,-depth/2-2.0);game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation()
  await shot(name+"-front",at+basis*Vector3(-10,5,-16),at+Vector3.UP*2.8)
  await walk(at+basis*Vector3(entry_x,.16,-depth/2+1.5))
  await shot(name+"-inside",at+basis*Vector3(.5,1.85,-depth/2+1.5),at+basis*Vector3(-2,1,.4))
  if plot.plan in ["cottage","townhouse","farmhouse"]:
   var sofa=game.world.furnishings.filter(func(entry):return entry.address==address and entry.kind=="couch")[0].node.global_position
   await shot(name+"-living-front",sofa+basis*Vector3(2,2.3,-2.5),sofa+basis*Vector3(.8,.5,.1))
   await shot(name+"-living-reverse",sofa+basis*Vector3(-1,2.2,-1.4),sofa+basis*Vector3(1.5,.7,0))
   var table=game.world.furnishings.filter(func(entry):return entry.address==address and entry.kind=="table")[0].node.global_position
   await shot(name+"-dining",table+basis*Vector3(-1.8,2.1,1.8),table+Vector3.UP*.5)
  if plot.plan=="cottage":
   for point in [Vector3(-2,.16,-2),Vector3(2,.16,-2),Vector3(0,.16,-.2),Vector3(0,.16,2.25),Vector3(-1.5,.16,2.25),Vector3(0,.16,2.25),Vector3(2.5,.16,2.25)]:await walk(at+basis*point)
   await shot(name+"-kitchen",at+basis*Vector3(0,1.85,-1.7),at+basis*Vector3(-3.8,1.05,-3.8));await shot(name+"-bedroom",at+basis*Vector3(-.5,1.7,2.1),at+basis*Vector3(-3.6,.7,3.8));await shot(name+"-bathroom",at+basis*Vector3(2.4,1.7,2.1),at+basis*Vector3(4.5,.8,4.1))
  elif plot.plan in ["townhouse","farmhouse"]:
   var sx=float(plot.width)/2-1.3
   await walk(at+basis*Vector3(0,.16,-4.5));await walk(at+basis*Vector3(sx,.16,-4.5));await walk(at+basis*Vector3(sx,3.36,2.8))
   await shot(name+"-stairs-top",at+basis*Vector3(sx,5.1,3.1),at+basis*Vector3(sx,1,-2.5))
   await walk(at+basis*Vector3(0,3.36,3));await shot(name+"-upper-bedroom",at+basis*Vector3(-.6,5.0,.2),at+basis*Vector3(-float(plot.width)/2+1.5,4.1,-2))
   var bath_entry=Vector3(-1.3,3.36,2.7) if plot.plan=="townhouse" else Vector3(2.6,3.36,4.4)
   if plot.plan=="farmhouse":await walk(at+basis*Vector3(2.6,3.36,3))
   await walk(at+basis*bath_entry)
   await shot(name+"-upper-bathroom",at+basis*(bath_entry+Vector3(0,1.6,0)),at+basis*(Vector3(-2.7,4.2,5.4) if plot.plan=="townhouse" else Vector3(2.5,4.2,5.45)))
   if plot.plan=="farmhouse":await walk(at+basis*Vector3(2.6,3.36,3))
   await walk(at+basis*Vector3(0,3.36,3))
   await walk(at+basis*Vector3(sx,3.36,2.8));await walk(at+basis*Vector3(sx,.16,-4.5))
  else:
   await shot(name+"-reverse",at+basis*Vector3(-float(plot.width)/2+1,2.1,3.5),at+basis*Vector3(2,1,-3))
   await walk(at+basis*Vector3(entry_x,.16,-depth/2+1));await walk(at+basis*Vector3(entry_x,.16,-depth/2-2))
  for entry in game.world.containers.filter(func(entry):return entry.address==address):
   game.world.search_container(entry);await get_tree().create_timer(.3).timeout
   var target=entry.node.global_position+Vector3.UP*.6
   await shot(name+"-"+entry.kind+"-open",target+entry.node.global_basis*Vector3(-1.8,.8,-1.8),target)
   game.world.close_containers()
 var raft=game.world.furnishings.filter(func(entry):return entry.kind=="raft")[0].node.global_position
 for view in [{"name":"fuel-forecourt","at":Vector3(-3,5,-115),"target":Vector3(20,1,-106)},{"name":"orchard-approach","at":Vector3(51,5,-50),"target":Vector3(62,1,-42)},{"name":"river-raft","at":raft+Vector3(-4,3,-5),"target":raft+Vector3.UP*.4},{"name":"forest-camp","at":Vector3(-104,7,43),"target":Vector3(-98,4,48)},{"name":"street-asphalt","at":Vector3(1,1,-45),"target":Vector3(0,.04,-52)}]:await shot(view.name,view.at,view.target)
 await shot("raft-ground-contact",raft+Vector3(-3,1.1,-3),raft+Vector3.UP*.2)
 await shot("street-sign-front",Vector3(8,2.6,-18),Vector3(8,2.55,-22))
 await shot("intersection-clear",Vector3(0,3,-11),Vector3(0,.1,-22))
 for z in [-17,65]:await shot("river-road-bridge-"+str(z),Vector3(game.world.river_x(z)-12,2,z-4),Vector3(game.world.river_x(z),.2,z))
 for index in [0,1,2]:
  var car=game.world.vehicles[index]
  var bounds=game.world.model_bounds(car.visual)
  var ground=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(car.global_position+Vector3.UP,car.global_position-Vector3.UP*2,1,[car.get_rid()]))
  print("CAR CONTACT ",car.kind," root=",car.global_position.y," minimum=",car.visual.to_global(bounds.position).y," road=",ground.get("position",Vector3.ZERO).y)
  await shot("car-tires-"+str(index),car.global_position+car.global_basis*Vector3(-3.5,.7,3.5),car.global_position+Vector3.UP*.4)
 var shelf=game.world.loot.filter(func(entry):return entry.id=="shelf")[0].node
 await shot("shelf-board-joins",shelf.global_position+shelf.global_basis*Vector3(-1.5,1.4,2),shelf.global_position+Vector3.UP*.9)
 game.ui.backpack();await shot("inventory-preview",game.player.camera.position,game.player.camera.position-game.player.camera.global_basis.z)
 game.close_overlay()
 var safe=game.world.containers.filter(func(entry):return entry.id=="8-cedar-lane-safe")[0]
 game.ui.loot_menu(safe);await shot("loot-model-pictures",game.player.camera.position,game.player.camera.position-game.player.camera.global_basis.z)
 game.close_overlay()
 for variant in ["zombie","zombie-chubby","zombie-arm","zombie-ribcage"]:
  var enemy=get_tree().get_nodes_in_group("zombies").filter(func(entry):return entry.variant==variant)[0]
  for entry in get_tree().get_nodes_in_group("zombies"):entry.visible=entry==enemy
  enemy.animation.active=true;game.assets.animate(enemy.animation,"Idle",0);enemy.animation.seek(.1,true);enemy.animation.pause()
  enemy.position=Vector3(0,.04,18);enemy.visual.rotation.y=0
  await shot("variant-"+variant,enemy.position+Vector3(-1.8,1.4,2.2),enemy.position+Vector3.UP*.9)
 var f=FileAccess.open(game.report_dir()+"/inspection.json",FileAccess.WRITE);f.store_string(JSON.stringify({"targets":targets,"failures":failed,"graphical":DisplayServer.get_name()!="headless"},"  "))
 print("VISUAL INSPECTION ",targets," targets, ",failed," failures");return 1 if failed else 0
