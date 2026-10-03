extends CharacterBody3D
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
var hurt_left:float=0.0
var recoil:float=0.0
var step_time:float=0.0
var flash:MeshInstance3D
func configure(owner_game):
 game=owner_game;collision_layer=2;collision_mask=1;floor_snap_length=.25;safe_margin=.001
 var shape=CapsuleShape3D.new();shape.radius=.3;shape.height=1.75
 var collider=CollisionShape3D.new();collider.shape=shape;collider.position.y=.9;add_child(collider)
 visual=game.assets.model("survivor");add_child(visual);animation=game.assets.animation(visual)
 var skeleton=game.assets.skeleton(visual)
 if skeleton!=null:
  var hand=BoneAttachment3D.new();hand.bone_name="hand.R";skeleton.add_child(hand)
  var weapon=game.assets.model("pistol");hand.add_child(weapon)
  # Custom grip exported in game axes; attachment follows the hand's local bone frame.
  weapon.rotation.x=PI/2
  flash=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=.06;mesh.height=.12;flash.mesh=mesh;flash.position=Vector3(0,.05,.34);weapon.add_child(flash)
  var material=StandardMaterial3D.new();material.albedo_color=Color(1,.8,.25);material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;flash.material_override=material;flash.visible=false
 pivot=Node3D.new();add_child(pivot);camera=Camera3D.new();pivot.add_child(camera);camera.current=true;camera.fov=68;camera.far=170
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
 if flash!=null:flash.visible=shot_cooldown>.19
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
 elif Input.is_action_just_pressed("jump"):velocity.y=6
 else:velocity.y=0.0
 move_and_slide()
 if global_position.y < -5:game.recover_player()
 if aiming:visual.rotation.y=lerp_angle(visual.rotation.y,yaw+PI,delta*12)
 elif direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*12)
 pivot.position=Vector3(0,1.5,0);pivot.rotation=Vector3(pitch+recoil,yaw,0)
 var distance=2.5 if aiming else 4.6
 var desired=pivot.to_global(Vector3(.65,.25,distance))
 var query=PhysicsRayQueryParameters3D.create(pivot.global_position,desired,1,[get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():desired=hit.position+hit.normal*.22
 camera.global_position=camera.global_position.lerp(desired,1-exp(-delta*18));camera.look_at(pivot.global_position-pivot.global_basis.z*10)
 camera.fov=lerpf(camera.fov,54 if aiming else 68,delta*6)
 if reload_left>0:
  reload_left=maxf(0,reload_left-delta)
  if reload_left==0:
   var amount=mini(12-game.state.magazine,int(game.state.inventory.ammo));game.state.inventory.ammo-=amount;game.state.magazine+=amount;game.toast("Reloaded")
 if Input.is_action_just_pressed("reload"):reload()
 if Input.is_action_pressed("fire") and game.placement_kind=="":shoot()
 if Input.is_action_just_pressed("heal"):heal()
 if reload_left>0:game.assets.animate(animation,"Reload",.08,false)
 elif shot_cooldown>.16:game.assets.animate(animation,"Shoot",.03,false)
 elif move.length()>.1:game.assets.animate(animation,"Run" if sprint else "Walk",.12)
 else:game.assets.animate(animation,"Aim" if aiming else "Idle")
 if move.length()>.1 and is_on_floor():
  step_time-=delta
  if step_time<=0:game.sound("step",.3);step_time=.27 if sprint else .44
func reload():
 if reload_left>0 or game.state.magazine>=12:return
 if int(game.state.inventory.ammo)<=0:game.toast("No reserve ammunition");return
 reload_left=1.6;game.sound("reload");game.toast("Reloading…")
func shoot():
 if reload_left>0 or shot_cooldown>0:return
 if game.state.magazine<=0:game.toast("Empty magazine — reload");shot_cooldown=.4;return
 game.state.magazine-=1;shot_cooldown=.24;recoil=.018
 game.sound("shot");game.world.alert_zombies(global_position,32)
 var origin=camera.global_position;var endpoint=origin-camera.global_basis.z*90
 var query=PhysicsRayQueryParameters3D.create(origin,endpoint,5,[get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():
  if hit.collider.has_method("take_damage"):hit.collider.take_damage(40);game.hit_feedback=.2
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
