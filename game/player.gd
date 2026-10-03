extends CharacterBody3D
const Movement=preload("res://game/movement.gd")
var game
var visual:Node3D
var animation:AnimationPlayer
var pivot:Node3D
var camera:Camera3D
var yaw:float=0.0
var pitch:float=-.18
var sprint_energy:float=100.0
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
 visual=game.assets.model("survivor");add_child(visual);animation=game.assets.animation(visual)
 for kind in game.catalog.WEAPONS:
  var weapon=visual.find_child(kind.capitalize(),true,false)
  if weapon!=null:weapon_visuals[kind]=weapon
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
 shot_cooldown=maxf(0,shot_cooldown-delta);hurt_left=maxf(0,hurt_left-delta);recoil=move_toward(recoil,0,delta*2)
 flash_left=maxf(0,flash_left-delta);firing_left=maxf(0,firing_left-delta)
 if flash!=null:flash.visible=flash_left>0
 var stick=Input.get_vector("look_left","look_right","look_up","look_down")
 yaw-=stick.x*2.3*delta;pitch=clampf(pitch-stick.y*1.7*delta,-.95,.38)
 aiming=Input.is_action_pressed("aim") and game.placement_kind==""
 var move=Input.get_vector("left","right","forward","back")
 var direction=Basis(Vector3.UP,yaw)*Vector3(move.x,0,move.y)
 var sprint=Input.is_action_pressed("sprint") and not aiming and sprint_energy>1 and move.length()>.1
 var speed=7.2 if sprint else (2.9 if aiming else 4.2)
 sprint_energy=clampf(sprint_energy+(-24 if sprint else 18)*delta,0,100)
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
 if reload_left>0:game.assets.animate(animation,"Reload",.08,false)
 elif firing_left>0:game.assets.animate(animation,"Shoot",.03,false)
 elif move.length()>.1:game.assets.animate(animation,"Run_Gun" if sprint else "Walk_Gun",.12)
 else:game.assets.animate(animation,"Aim" if aiming else "Idle_Gun")
 if move.length()>.1 and is_on_floor():
  step_time-=delta
  if step_time<=0:game.sound("step",.3);step_time=.27 if sprint else .44
func _process(delta):
 if game==null or camera==null or not game.running or game.overlay:return
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
 if not game.state.equip(kind):game.toast("Find this weapon first");return
 reload_left=0;flash_left=0;firing_left=0;flash.visible=false;shot_cooldown=maxf(shot_cooldown,.2);update_weapon();game.toast("Equipped "+str(profile().name))
func cycle_weapon():
 var owned:Array=[]
 for kind in game.catalog.WEAPONS:
  if game.state.weapons.has(kind):owned.append(kind)
 equip(owned[(owned.find(game.state.equipped)+1)%owned.size()])
func update_weapon():
 for kind in weapon_visuals:weapon_visuals[kind].visible=kind==game.state.equipped
 var muzzle=visual.find_child(game.state.equipped.capitalize()+"Muzzle",true,false)
 if muzzle!=null:
  flash.reparent(muzzle,false);flash.position=Vector3.ZERO
func reload():
 var weapon=profile()
 if reload_left>0 or game.state.magazine>=int(weapon.capacity):return
 if int(game.state.inventory[weapon.ammo])<=0:game.toast("No reserve ammunition");return
 reload_left=float(weapon.reload);game.sound("reload");game.toast("Reloading…")
func shoot():
 if reload_left>0 or shot_cooldown>0:return
 if game.state.magazine<=0:game.toast("Empty magazine — reload");shot_cooldown=.4;return
 var weapon=profile()
 game.state.magazine-=1;shot_cooldown=float(weapon.interval);recoil=float(weapon.recoil)
 flash_left=.05;firing_left=.14;flash.visible=true
 game.sound("shot");game.world.alert_zombies(global_position,32)
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
func heal():
 if game.state.health>=100:game.toast("Already at full health");return
 if int(game.state.inventory.medkit)<=0:game.toast("No medkits");return
 game.state.inventory.medkit-=1;game.state.health=minf(100,game.state.health+45);game.sound("pickup");game.toast("Health restored +45")
func take_damage(amount:float):
 if hurt_left>0 or not game.running:return
 hurt_left=.6;game.state.health=maxf(0,game.state.health-amount);game.sound("hurt");game.damage_feedback=.45
 if game.state.health<=0:
  reload_left=0;game.assets.animate(animation,"Death",.1,false);game.die()
