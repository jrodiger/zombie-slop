extends CharacterBody3D
const Movement=preload("res://game/movement.gd")
var game
var driving=null
var melee_left:float=0
var melee_pending:bool=false
var visual:Node3D
var animation:AnimationPlayer
var pivot:Node3D
var camera:Camera3D
var yaw:float=0.0
var pitch:float=-.18
var sprint_energy:float=100.0
var sprint_exhausted:bool=false
var sprinting:bool=false
var aiming:bool=false
var reload_left:float=0.0
var shot_cooldown:float=0.0
var flash_left:float=0.0
var firing_left:float=0.0
var hurt_left:float=0.0
var recoil:float=0.0
var step_time:float=0.0
var flash:MeshInstance3D
var weapon_visuals:Dictionary={}
func configure(owner_game):
 game=owner_game;collision_layer=2;collision_mask=1;floor_snap_length=.25;safe_margin=.001
 var shape=CapsuleShape3D.new();shape.radius=.3;shape.height=1.75
 var collider=CollisionShape3D.new();collider.shape=shape;collider.position.y=.9;add_child(collider)
 set_character(game.state.character)
 flash=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=.045;mesh.height=.09;flash.mesh=mesh
 var material=StandardMaterial3D.new();material.albedo_color=Color(1,.8,.25);material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;flash.material_override=material;flash.visible=false
 visual.add_child(flash);update_weapon()
 pivot=Node3D.new();add_child(pivot);camera=Camera3D.new();pivot.add_child(camera);camera.top_level=true;camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;camera.current=true;camera.fov=68;camera.far=170
func _unhandled_input(event):
 if not game.running or game.overlay:return
 if "--integration" in OS.get_cmdline_user_args() or "--benchmark" in OS.get_cmdline_user_args():return
 if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  yaw-=event.relative.x*.0025*float(game.state.settings.sensitivity)
  pitch=clampf(pitch-event.relative.y*.0025*float(game.state.settings.sensitivity),-.95,.38)
func _physics_process(delta):
 if game==null:return
 if not game.running or game.overlay:return
 if driving!=null:return
 shot_cooldown=maxf(0,shot_cooldown-delta);hurt_left=maxf(0,hurt_left-delta);recoil=move_toward(recoil,0,delta*2)
 flash_left=maxf(0,flash_left-delta);firing_left=maxf(0,firing_left-delta)
 if flash!=null:flash.visible=flash_left>0
 var stick=Input.get_vector("look_left","look_right","look_up","look_down")
 yaw-=stick.x*2.3*delta;pitch=clampf(pitch-stick.y*1.7*delta,-.95,.38)
 aiming=not profile().get("melee",false) and Input.is_action_pressed("aim") and game.placement_kind==""
 var move=Input.get_vector("left","right","forward","back")
 var direction=Basis(Vector3.UP,yaw)*Vector3(move.x,0,move.y)
 var wants_sprint=Input.is_action_pressed("sprint")
 if sprint_exhausted and not wants_sprint and sprint_energy>=25:sprint_exhausted=false
 sprinting=wants_sprint and not sprint_exhausted and not aiming and sprint_energy>0 and move.length()>.1 and game.placement_kind==""
 sprint_energy=clampf(sprint_energy+(-24 if sprinting else 18)*delta,0,100)
 if sprinting and sprint_energy<=0:sprint_exhausted=true;sprinting=false
 var speed=7.2 if sprinting else (2.9 if aiming else 4.2)
 velocity.x=move_toward(velocity.x,direction.x*speed,delta*22);velocity.z=move_toward(velocity.z,direction.z*speed,delta*22)
 if not is_on_floor():velocity.y-=20*delta
 elif Input.is_action_just_pressed("jump") and game.placement_kind=="":velocity.y=6
 else:velocity.y=0.0
 var travel=Vector3(velocity.x,0,velocity.z)*delta
 if Movement.step_up(self,travel):
  # Step already consumed this frame's horizontal movement.
  var horizontal=Vector2(velocity.x,velocity.z);velocity.x=0;velocity.z=0;move_and_slide();velocity.x=horizontal.x;velocity.z=horizontal.y
 else:move_and_slide()
 if global_position.y < -5:game.recover_player()
 if aiming:visual.rotation.y=lerp_angle(visual.rotation.y,yaw+PI,delta*12)
 elif direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*12)
 if reload_left>0:
  reload_left=maxf(0,reload_left-delta)
  if reload_left==0:
   var weapon=profile();var amount=mini(int(weapon.capacity)-game.state.magazine,int(game.state.inventory[weapon.ammo]));game.state.inventory[weapon.ammo]-=amount;game.state.magazine+=amount;game.toast("Reloaded")
 if Input.is_action_just_pressed("reload") and game.placement_kind=="":reload()
 if Input.is_action_pressed("fire") and game.placement_kind=="":shoot()
 if Input.is_action_just_pressed("heal") and game.placement_kind=="":heal()
 if melee_left>0:
  var previous=melee_left;melee_left=maxf(0,melee_left-delta)
  if melee_pending and previous>.36 and melee_left<=.36:melee_hit();melee_pending=false
 if melee_left>0:game.assets.animate(animation,"Stab" if game.state.equipped=="knife" else "Slash",.05,false)
 elif reload_left>0:game.assets.animate(animation,weapon_clip("Reload"),.08,false)
 elif firing_left>0:game.assets.animate(animation,weapon_clip("Shoot"),.03,false)
 elif move.length()>.1:game.assets.animate(animation,locomotion_clip("Run" if sprinting else "Walk"),.18)
 else:game.assets.animate(animation,weapon_clip("Aim") if aiming else locomotion_clip("Idle"),.18)
 if move.length()>.1 and is_on_floor():
  step_time-=delta
  if step_time<=0:
   var step=game.world.footstep(global_position);var variant=randi_range(0,2)
   game.sound(step+("" if variant==0 else "-"+str(variant)),.38);step_time=.27 if sprinting else .44
func model_name(kind:String) -> String:
 return str(game.catalog.WEAPONS[kind].get("model",kind.capitalize()))
func set_character(kind:String):
 var facing=visual.rotation.y if is_instance_valid(visual) else 0.0
 if is_instance_valid(flash):flash.reparent(self,false)
 if is_instance_valid(visual):remove_child(visual);visual.queue_free()
 visual=game.assets.model("survivor" if kind=="matt" else "survivor-"+kind);add_child(visual);visual.rotation.y=facing;animation=game.assets.animation(visual);weapon_visuals.clear()
 for weapon_kind in game.catalog.WEAPONS:
  var weapon=visual.find_child(model_name(weapon_kind),true,false)
  if weapon!=null:weapon_visuals[weapon_kind]=weapon
 if is_instance_valid(flash):visual.add_child(flash) if flash.get_parent()==null else flash.reparent(visual,false);update_weapon()
 game.state.character=kind;reload_left=0;melee_left=0;melee_pending=false
func weapon_clip(clip:String) -> String:
 return clip.replace("_Gun","")+"_"+model_name(game.state.equipped)
func locomotion_clip(clip:String) -> String:
 if profile().get("melee",false):return ("Run_Stab" if game.state.equipped=="knife" else "Run_Slash") if clip=="Run" else clip
 return weapon_clip(clip) if aiming or firing_left>0 else "Lower"+clip+"_"+model_name(game.state.equipped)
func _process(delta):
 if game==null or camera==null or not game.running or game.overlay:return
 if driving!=null:
  var center=driving.get_global_transform_interpolated().origin+Vector3.UP*1.5
  var desired=center+driving.global_basis*Vector3(0,2.3,-7)
  var ray=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center,desired,1,[driving.get_rid()]))
  if not ray.is_empty():desired=ray.position+ray.normal*.25
  camera.global_position=camera.global_position.lerp(desired,1-exp(-delta*8));camera.look_at(center+driving.global_basis.z*3);camera.fov=68;return
 # Independent camera follows the rendered body pose without inheriting its
 # unsmoothed parent translation. Mouse look is sampled each rendered frame.
 var center=get_global_transform_interpolated().origin+Vector3.UP*1.5
 var orientation=Basis.from_euler(Vector3(pitch+recoil,yaw,0))
 var desired=center+orientation*Vector3(.65,.25,2.5 if aiming else 4.6)
 var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center,desired,1,[get_rid()]))
 if not hit.is_empty():desired=hit.position+hit.normal*.22
 if camera.global_position.distance_to(desired)>10:camera.global_position=desired
 else:camera.global_position=camera.global_position.lerp(desired,1-exp(-delta*18))
 # Sweep again after smoothing so corner transitions cannot trail through walls.
 hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center,camera.global_position,1,[get_rid()]))
 if not hit.is_empty():camera.global_position=hit.position+hit.normal*.22
 camera.look_at(center-orientation.z*10)
 camera.fov=lerpf(camera.fov,54 if aiming else 68,1-exp(-delta*6))
func profile() -> Dictionary:
 return game.catalog.WEAPONS[game.state.equipped]
func equip(kind:String):
 if kind==game.state.equipped:return
 if not game.state.equip(kind):game.toast("Find this weapon first");return
 reload_left=0;melee_left=0;melee_pending=false;flash_left=0;firing_left=0;flash.visible=false;shot_cooldown=maxf(shot_cooldown,.2);update_weapon();game.toast("Equipped "+str(profile().name))
func cycle_weapon():
 var owned:Array=[]
 for kind in game.catalog.WEAPONS:
  if game.state.weapons.has(kind):owned.append(kind)
 equip(owned[(owned.find(game.state.equipped)+1)%owned.size()])
func update_weapon():
 for kind in weapon_visuals:weapon_visuals[kind].visible=kind==game.state.equipped
 var muzzle=visual.find_child(model_name(game.state.equipped)+"Muzzle",true,false)
 if muzzle!=null:
  flash.reparent(muzzle,false);flash.position=Vector3.ZERO
func reload():
 var weapon=profile()
 if weapon.get("melee",false):return
 if reload_left>0 or game.state.magazine>=int(weapon.capacity):return
 if int(game.state.inventory[weapon.ammo])<=0:game.toast("No reserve ammunition");return
 reload_left=float(weapon.reload);game.sound("reload-"+sound_family(),.7);game.toast("Reloading…")
func shoot():
 if reload_left>0 or shot_cooldown>0:return
 if profile().get("melee",false):
  shot_cooldown=float(profile().interval);melee_left=.62;melee_pending=true;game.sound("build",.3);return
 if game.state.magazine<=0:game.toast("Empty magazine — reload");shot_cooldown=.4;return
 var weapon=profile()
 game.state.magazine-=1;shot_cooldown=float(weapon.interval);recoil=float(weapon.recoil)
 flash_left=.05;firing_left=.14;flash.visible=true
 game.sound("shot-"+sound_family(),.8);game.world.alert_zombies(global_position,32)
 var origin=camera.global_position
 for pellet in range(int(weapon.pellets)):
  var spread=float(weapon.spread)*(.55 if aiming else 1.0)
  var direction=(camera.global_basis*Vector3(randf_range(-spread,spread),randf_range(-spread,spread),-1)).normalized()
  var endpoint=origin+direction*float(weapon.range)
  var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,endpoint,5,[get_rid()]))
  var target=hit.position if not hit.is_empty() else endpoint
  # The crosshair may see around cover that still blocks the weapon muzzle.
  var muzzle_hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(flash.global_position,target,5,[get_rid()]))
  if not muzzle_hit.is_empty():hit=muzzle_hit
  if not hit.is_empty():
   if hit.collider.has_method("take_damage"):hit.collider.take_damage(float(weapon.damage));game.hit_feedback=.2
   game.impact(hit.position)
func sound_family() -> String:
 if game.state.equipped in ["revolver","smg"]:return "pistol"
 if game.state.equipped=="compact_shotgun":return "shotgun"
 return game.state.equipped
func melee_hit():
 var facing=visual.global_basis.z.normalized();var origin=global_position+Vector3.UP*.9
 for enemy in get_tree().get_nodes_in_group("zombies"):
  if not enemy.alive:continue
  var target=enemy.global_position+Vector3.UP*.7;var offset=target-origin
  if offset.length()>float(profile().range) or offset.normalized().dot(facing)<.35:continue
  var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,target,1,[get_rid()]))
  if not hit.is_empty():continue
  enemy.take_damage(float(profile().damage));game.hit_feedback=.2;game.sound("hurt",.3);break
func heal():
 if game.state.health>=100:game.toast("Already at full health");return
 for kind in ["medkit","food","water"]:
  if int(game.state.inventory[kind])>0:use_supply(kind);return
 game.toast("Find medical supplies, food or water")
func use_supply(kind:String):
 if game.state.health>=100 or kind not in ["medkit","food","water"] or int(game.state.inventory[kind])<=0:return
 game.state.inventory[kind]-=1
 var amount=45 if kind=="medkit" else (15 if kind=="food" else 8)
 game.state.health=minf(100,game.state.health+amount);game.sound("pickup",.4);game.toast("Used "+kind.capitalize()+" · health +"+str(amount))
func take_damage(amount:float):
 if hurt_left>0 or not game.running:return
 hurt_left=.6;game.state.health=maxf(0,game.state.health-amount);game.sound("hurt");game.damage_feedback=.45
 if game.state.health<=0:
  reload_left=0;melee_left=0;melee_pending=false;game.assets.animate(animation,"Death",.1,false);game.die()
