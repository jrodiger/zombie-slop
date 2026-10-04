extends CharacterBody3D
const Movement=preload("res://game/movement.gd")
var game
var visual:Node3D
var animation:AnimationPlayer
var variant:String="zombie"
var max_hp:float=100
var attack_damage:float=12
var chase_speed:float=2.15
var hp:float=100
var think_left:float=0
var attack_left:float=0
var alive:bool=true
var alerted:float=0
var origin:Vector3
var destination:Vector3
var path:PackedVector3Array=[]
var path_index:int=0
var stagger:float=0
var growl:AudioStreamPlayer3D
var growl_left:float=0
func configure(owner_game,spawn:Vector3,index:int):
 game=owner_game;floor_snap_length=.25;position=spawn;origin=spawn;destination=spawn;think_left=float(index)*.043;collision_layer=4;collision_mask=1
 variant=["zombie","zombie","zombie-chubby","zombie-arm","zombie-ribcage"][index%5]
 max_hp=220 if variant=="zombie-chubby" else (70 if variant=="zombie-ribcage" else (130 if variant=="zombie-arm" else 100));hp=max_hp
 chase_speed=1.9 if variant=="zombie-chubby" else (3.15 if variant=="zombie-ribcage" else (2.7 if variant=="zombie-arm" else 2.15));attack_damage=4 if variant=="zombie-ribcage" else (22 if variant=="zombie-chubby" else 12)
 var shape=CapsuleShape3D.new();shape.radius=.48 if variant=="zombie-chubby" else .34;shape.height=1.95 if variant=="zombie-chubby" else (1.05 if variant=="zombie-ribcage" else 1.75)
 var collider=CollisionShape3D.new();collider.shape=shape;collider.position.y=shape.height/2+.025;add_child(collider)
 visual=game.assets.model(variant);add_child(visual);animation=game.assets.animation(visual);add_to_group("zombies")
 growl=AudioStreamPlayer3D.new();growl.position.y=.65 if variant=="zombie-ribcage" else 1.1;growl.max_distance=18;growl.unit_size=5;add_child(growl)
 growl_left=randf_range(.4,2.0)+float(index%5)*.35
 # AI/collision remain live; hidden skeletons do not need pose updates. The
 # notifier follows the capsule and resumes the current clip when visible.
 var visibility=VisibleOnScreenNotifier3D.new();visibility.aabb=AABB(Vector3(-1,-.1,-1),Vector3(2,2.2,2));add_child(visibility)
 if animation!=null:
  game.assets.animate(animation,"Idle",0);animation.seek(.1,true)
  animation.active=false
  visibility.screen_entered.connect(func():animation.active=true)
  visibility.screen_exited.connect(func():animation.active=false)
func _process(delta):
 if game==null or growl==null:return
 if not alive:growl.stop();return
 growl.stream_paused=not game.running or game.overlay
 if growl.stream_paused or not is_instance_valid(game.player):return
 if global_position.distance_to(game.player.global_position)>18:growl.stop();return
 growl_left-=delta
 if growl_left>0 or growl.playing:return
 var voices=0
 for enemy in get_tree().get_nodes_in_group("zombies"):
  if enemy.growl!=null and enemy.growl.playing:voices+=1
 if voices>=3:growl_left=.5;return
 var name="zombie-growl-"+str(randi_range(0,2))
 if not game.sound_cache.has(name):game.sound_cache[name]=load("res://assets/"+name+".wav")
 growl.stream=game.sound_cache[name]
 growl.pitch_scale=(.78 if variant=="zombie-chubby" else (1.12 if variant=="zombie-ribcage" else .96))+randf_range(-.05,.05)
 var blocked=not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,game.player.global_position+Vector3.UP,1,[get_rid()])).is_empty()
 growl.volume_db=-15 if blocked else -7
 growl.play();growl_left=randf_range(3,6)
func _physics_process(delta):
 if game==null or not game.running or game.overlay or not alive:return
 think_left-=delta;attack_left=maxf(0,attack_left-delta);alerted=maxf(0,alerted-delta);stagger=maxf(0,stagger-delta)
 var player_distance=global_position.distance_to(game.player.global_position)
 if player_distance>75:return
 if think_left<=0:
  think_left=.45
  if player_distance<18:
   var q=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.3,game.player.global_position+Vector3.UP,1,[get_rid()])
   if get_world_3d().direct_space_state.intersect_ray(q).is_empty():alerted=12
  if alerted>0:destination=game.player.global_position
  elif global_position.distance_to(destination)<1.1:destination=origin+Vector3(randf_range(-7,7),0,randf_range(-7,7))
  path=game.world.route(global_position,destination);path_index=1 if path.size()>1 else 0
 var target=destination
 if path_index<path.size():
  target=path[path_index]
  if Vector2(global_position.x-target.x,global_position.z-target.z).length()<.6:path_index+=1
 var direction=target-global_position;direction.y=0
 if direction.length()>.2:direction=direction.normalized()
 var speed=chase_speed if alerted>0 else .75
 velocity.x=direction.x*speed if stagger<=0 else 0.0;velocity.z=direction.z*speed if stagger<=0 else 0.0
 if not is_on_floor():velocity.y-=20*delta
 else:velocity.y=0.0
 if player_distance<1.4 and game.player.driving==null:
  velocity.x=0;velocity.z=0
  if attack_left<=0:attack_left=1.25;game.player.take_damage(attack_damage);game.assets.animate(animation,"Attack",.08,false)
 if Movement.step_up(self,Vector3(velocity.x,0,velocity.z)*delta):
  var horizontal=Vector2(velocity.x,velocity.z);velocity.x=0;velocity.z=0;move_and_slide();velocity.x=horizontal.x;velocity.z=horizontal.y
 else:move_and_slide()
 for i in range(get_slide_collision_count()):
  var blocker=get_slide_collision(i).get_collider()
  if blocker!=null and blocker.is_in_group("placed") and blocker.blocked:
   if attack_left<=0:attack_left=1.2;blocker.damage(16);game.assets.animate(animation,"Attack",.08,false)
 if direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*7)
 if attack_left>.8:game.assets.animate(animation,"Attack",.1,false)
 else:game.assets.animate(animation,"Walk" if velocity.length()>.4 else "Idle")
func take_damage(amount:float):
 if not alive:return
 hp-=amount;alerted=15;stagger=.15
 if hp<=0:
  alive=false;collision_layer=0;game.state.kills+=1;game.assets.animate(animation,"Death",.05,false)
  growl.stop()
  var timer=get_tree().create_timer(8);timer.timeout.connect(queue_free)
