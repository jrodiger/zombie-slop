extends CharacterBody3D
var game
var ident:String
var kind:String
var speed:float=0
var driver=null
var bump_left:float=0
var visual:Node3D
func configure(owner_game,id:String,model:String,at:Vector3,yaw:float):
 game=owner_game;ident=id;kind=model;position=at;rotation.y=yaw;collision_layer=1;collision_mask=5;floor_snap_length=.6;safe_margin=.02
 var shape=BoxShape3D.new();shape.size=Vector3(2.4,2.5,5.5) if kind.contains("truck") else (Vector3(2.3,1.85,4.8) if kind=="wreck" else Vector3(2,1.55,4.2))
 var collider=CollisionShape3D.new();collider.shape=shape;collider.position.y=shape.size.y/2;add_child(collider)
 visual=game.assets.model(model);add_child(visual);add_to_group("vehicles")
 if game.state.vehicles.has(id):
  var saved=game.state.vehicles[id];position=Vector3(saved.position[0],saved.position[1],saved.position[2]);rotation.y=float(saved.yaw);set_physics_process(false)
func _physics_process(delta):
 if game==null or not game.running or game.overlay:return
 bump_left=maxf(0,bump_left-delta)
 if driver!=null:
  var throttle=Input.get_axis("back","forward");var steering=Input.get_axis("right","left")
  var desired=throttle*15 if throttle>=0 else throttle*5
  speed=move_toward(speed,desired,delta*(14 if Input.is_action_pressed("jump") else 5))
  if Input.is_action_pressed("jump"):speed=move_toward(speed,0,delta*22)
  rotation.y+=steering*clampf(speed/5,-1,1)*delta*1.15
 else:speed=move_toward(speed,0,delta*7)
 var forward=global_basis.z.normalized();velocity.x=forward.x*speed;velocity.z=forward.z*speed
 velocity.y=0 if is_on_floor() else velocity.y-20*delta
 move_and_slide()
 for i in range(get_slide_collision_count()):
  var target=get_slide_collision(i).get_collider()
  if target!=null and target.is_in_group("zombies") and absf(speed)>3 and bump_left<=0:
   target.take_damage(absf(speed)*12);bump_left=.25
  if get_slide_collision(i).get_normal().y<.5:speed*=.65
 if driver==null and is_on_floor() and absf(speed)<.01:set_physics_process(false)
 if driver!=null:
  driver.global_position=global_position+Vector3.UP*.7;driver.reset_physics_interpolation()
 if position.y< -4:position=Vector3(0,.3,15);speed=0
func enter(player):
 if driver!=null:return
 set_physics_process(true);game.cancel_placement();driver=player;player.driving=self;player.reload_left=0;player.firing_left=0;player.melee_left=0;player.melee_pending=false;player.aiming=false;player.flash_left=0;player.flash.visible=false;player.velocity=Vector3.ZERO;player.visual.visible=false;player.collision_layer=0;player.collision_mask=0
 game.toast("W / S accelerate & reverse · A / D steer · Space brake · E exit")
func exit_driver() -> bool:
 if driver==null:return false
 var player=driver
 for offset in [Vector3(-2.3,0,0),Vector3(2.3,0,0),Vector3(0,0,-3.6),Vector3(0,0,3.6)]:
  var at=global_position+global_basis*offset
  var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at-Vector3.UP*3,1,[get_rid()]))
  if hit.is_empty() or hit.normal.y<.7:continue
  at.y=hit.position.y+.04
  var q=PhysicsShapeQueryParameters3D.new();q.shape=player.get_child(0).shape;q.transform=Transform3D(Basis(),at+Vector3.UP*.9);q.collision_mask=5;q.exclude=[get_rid(),player.get_rid()]
  if not get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():continue
  player.driving=null;player.global_position=at;player.velocity=Vector3.ZERO;player.visual.visible=true;player.collision_layer=2;player.collision_mask=1;player.reset_physics_interpolation();driver=null;speed=0
  game.toast("Left vehicle");return true
 game.toast("Exit blocked — move into an open space");return false
func snapshot() -> Dictionary:
 return {"position":[position.x,position.y,position.z],"yaw":rotation.y}
