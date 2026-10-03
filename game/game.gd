extends Node3D
const State=preload("res://game/state.gd")
const Assets=preload("res://game/assets.gd")
const Player=preload("res://game/player.gd")
const World=preload("res://game/world.gd")
const Placed=preload("res://game/placed.gd")
const Hud=preload("res://game/hud.gd")
const catalog=preload("res://game/catalog.gd")
var save_path:String="user://survival.json"
var state=State.new()
var assets=Assets.new()
var player
var world
var ui
var running:bool=false
var overlay:bool=false
var placement_kind:String=""
var placement_preview:Node3D
var placement_position=Vector3.ZERO
var placement_yaw:float=0
var placement_height:float=0
var placement_distance:float=4
var placement_valid:bool=false
var placement_reason:String=""
var moving_id:int=-1
var snap:bool=false
var show_performance:bool=false
var damage_feedback:float=0
var hit_feedback:float=0
var autosave_left:float=60
var sound_players:Array=[]
var sound_index:int=0
var ambience:AudioStreamPlayer
var completed_announced:bool=false
func _ready():
 if "--integration" in OS.get_cmdline_user_args():save_path="user://integration-survival.json"
 if "--benchmark" in OS.get_cmdline_user_args():save_path="user://benchmark-survival.json"
 inputs();load_settings();create_world()
 ui=Hud.new();add_child(ui);ui.configure(self);ui.start_screen();apply_settings()
 for i in range(12):var s=AudioStreamPlayer.new();add_child(s);sound_players.append(s)
 ambience=AudioStreamPlayer.new();ambience.stream=load("res://assets/ambient.wav");ambience.volume_db=-9;add_child(ambience);ambience.finished.connect(func():ambience.play());ambience.play()
 if "--integration" in OS.get_cmdline_user_args():call_deferred("integration")
 if "--benchmark" in OS.get_cmdline_user_args():call_deferred("benchmark")
func create_world():
 world=World.new();add_child(world);world.configure(self)
 player=Player.new();add_child(player);player.configure(self);player.position=Vector3(-24,.2,22);player.yaw=PI;player.visual.rotation.y=0
 player.pivot.position=Vector3(0,1.5,0);player.pivot.rotation=Vector3(-.18,PI,0);player.camera.position=Vector3(.65,.25,4.6)
func inputs():
 bind("forward",KEY_W,JOY_BUTTON_INVALID,JOY_AXIS_LEFT_Y,-1)
 bind("back",KEY_S,JOY_BUTTON_INVALID,JOY_AXIS_LEFT_Y,1)
 bind("left",KEY_A,JOY_BUTTON_INVALID,JOY_AXIS_LEFT_X,-1)
 bind("right",KEY_D,JOY_BUTTON_INVALID,JOY_AXIS_LEFT_X,1)
 bind("look_left",0,JOY_BUTTON_INVALID,JOY_AXIS_RIGHT_X,-1)
 bind("look_right",0,JOY_BUTTON_INVALID,JOY_AXIS_RIGHT_X,1)
 bind("look_up",0,JOY_BUTTON_INVALID,JOY_AXIS_RIGHT_Y,-1)
 bind("look_down",0,JOY_BUTTON_INVALID,JOY_AXIS_RIGHT_Y,1)
 bind("sprint",KEY_SHIFT,JOY_BUTTON_LEFT_STICK)
 bind("jump",KEY_SPACE,JOY_BUTTON_RIGHT_SHOULDER)
 bind("interact",KEY_E,JOY_BUTTON_A)
 bind("build",KEY_B,JOY_BUTTON_Y)
 bind("reload",KEY_R,JOY_BUTTON_X)
 bind("heal",KEY_H,JOY_BUTTON_DPAD_UP)
 bind("pause",KEY_ESCAPE,JOY_BUTTON_START)
 bind("cancel",KEY_ESCAPE,JOY_BUTTON_B)
 bind("move_item",KEY_G,JOY_BUTTON_LEFT_SHOULDER)
 bind("pickup_item",KEY_X,JOY_BUTTON_DPAD_DOWN)
 bind("rotate_left",KEY_Q,JOY_BUTTON_LEFT_SHOULDER)
 bind("rotate_right",KEY_R,JOY_BUTTON_RIGHT_SHOULDER)
 bind("height_up",KEY_UP,JOY_BUTTON_DPAD_UP)
 bind("height_down",KEY_DOWN,JOY_BUTTON_DPAD_DOWN)
 bind("distance_up",KEY_EQUAL,JOY_BUTTON_DPAD_RIGHT)
 bind("distance_down",KEY_MINUS,JOY_BUTTON_DPAD_LEFT)
 bind("snap",KEY_T,JOY_BUTTON_X)
 bind("save",KEY_F5)
 bind("debug",KEY_F3)
 bind("aim",0,JOY_BUTTON_INVALID,JOY_AXIS_TRIGGER_LEFT,1,MOUSE_BUTTON_RIGHT)
 bind("fire",0,JOY_BUTTON_INVALID,JOY_AXIS_TRIGGER_RIGHT,1,MOUSE_BUTTON_LEFT)
 bind("confirm",KEY_ENTER,JOY_BUTTON_A,-1,0,MOUSE_BUTTON_LEFT)
func bind(action:String,key:int=0,button:int=JOY_BUTTON_INVALID,axis:int=-1,value:float=0,mouse:int=0):
 if not InputMap.has_action(action):InputMap.add_action(action,.2)
 if key!=0:var e=InputEventKey.new();e.physical_keycode=key;InputMap.action_add_event(action,e)
 if button!=JOY_BUTTON_INVALID:var e=InputEventJoypadButton.new();e.button_index=button;InputMap.action_add_event(action,e)
 if axis>=0:var e=InputEventJoypadMotion.new();e.axis=axis;e.axis_value=value;InputMap.action_add_event(action,e)
 if mouse>0:var e=InputEventMouseButton.new();e.button_index=mouse;InputMap.action_add_event(action,e)
func _unhandled_input(event):
 if event is InputEventKey and event.echo:return
 if event.is_action_pressed("debug"):show_performance=not show_performance
 if event.is_action_pressed("save") and running:save_game()
 if overlay:
  if event.is_action_pressed("cancel") and running:close_overlay()
  return
 if not running:return
 if placement_kind!="":
  if event.is_action_pressed("cancel"):cancel_placement();return
  if event.is_action_pressed("confirm"):confirm_placement();return
  if event.is_action_pressed("rotate_left"):placement_yaw-=PI/12
  if event.is_action_pressed("rotate_right"):placement_yaw+=PI/12
  if event.is_action_pressed("height_up"):placement_height+=.1
  if event.is_action_pressed("height_down"):placement_height-=.1
  if event.is_action_pressed("distance_up"):placement_distance=minf(8,placement_distance+.25)
  if event.is_action_pressed("distance_down"):placement_distance=maxf(1.5,placement_distance-.25)
  if event.is_action_pressed("snap"):snap=not snap
  if event is InputEventMouseButton:
   if event.button_index==MOUSE_BUTTON_WHEEL_UP:placement_distance=minf(8,placement_distance+.25)
   if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:placement_distance=maxf(1.5,placement_distance-.25)
  return
 if event.is_action_pressed("pause"):ui.pause()
 if event.is_action_pressed("build"):ui.build_menu()
 if event.is_action_pressed("interact"):interact()
 if event.is_action_pressed("move_item"):move_nearest()
 if event.is_action_pressed("pickup_item"):pickup_nearest()
func _process(delta):
 damage_feedback=maxf(0,damage_feedback-delta);hit_feedback=maxf(0,hit_feedback-delta)
 if not running or overlay:return
 if placement_kind!="":update_placement()
 if state.objective.collectible and player.global_position.distance_to(world.safe_center)<12:state.objective.returned=true
 if objective_complete() and not completed_announced:completed_announced=true;toast("A PLACE TO CALL HOME  ·  Starter objective complete. Keep exploring and building.");sound("pickup")
 autosave_left-=delta
 if autosave_left<=0 and placement_kind=="":autosave_left=60;save_game(false)
func new_game():
 state.reset();completed_announced=false;rebuild();running=true;close_overlay();toast("Find wood and scrap on the porch, then bring home the fern by the street.")
func rebuild():
 cancel_placement()
 if is_instance_valid(world):remove_child(world);world.queue_free()
 if is_instance_valid(player):remove_child(player);player.queue_free()
 for piece in get_tree().get_nodes_in_group("placed"):piece.get_parent().remove_child(piece);piece.queue_free()
 create_world()
 for obj in state.objects:spawn_piece(obj)
 player.position=Vector3(state.player_position[0],state.player_position[1],state.player_position[2])
 # Detect corrupt/obsolete locations or placement intersecting the capsule.
 var q=PhysicsShapeQueryParameters3D.new();q.shape=player.get_child(0).shape;q.transform=Transform3D(Basis(),player.position+Vector3.UP*.9);q.collision_mask=1
 if player.position.y<-.5 or player.position.y>8 or absf(player.position.x)>72 or absf(player.position.z)>72 or not get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():recover_player()
 apply_settings()
func close_overlay():
 ui.clear_panel();overlay=false
 if running:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func die():
 running=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;cancel_placement();ui.death()
func recover_player():
 player.global_position=Vector3(-24,.4,20);player.velocity=Vector3.ZERO
 if ui!=null:toast("Returned to the home path")
func save_game(notify:bool=true) -> bool:
 if not running or state.health<=0:return false
 state.player_position=[player.position.x,player.position.y,player.position.z]
 var success=state.save_to(save_path)
 if notify:toast("Progress saved" if success else state.save_error)
 return success
func load_game():
 if not state.load_from(save_path):toast(state.save_error);return
 var notice=state.save_error;rebuild();running=true;close_overlay();toast("Welcome home" if notice=="" else notice)
func save_settings():
 var config=ConfigFile.new()
 for key in state.settings:config.set_value("settings",key,state.settings[key])
 config.save("user://settings.cfg")
func load_settings():
 var config=ConfigFile.new()
 if config.load("user://settings.cfg")!=OK:return
 var candidate=state.snapshot()
 for key in state.settings:candidate.settings[key]=config.get_value("settings",key,state.settings[key])
 if State.validate(candidate):state.settings=candidate.settings
func apply_settings():
 Engine.max_fps=60 if state.settings.cap else 0
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.001,float(state.settings.volume))))
 if world!=null and world.sun!=null:world.sun.shadow_enabled=bool(state.settings.shadows)
func quit_game():
 save_settings();get_tree().quit()
func toast(value:String):
 if ui!=null:ui.toast(value)
func sound(name:String,volume:float=1):
 if sound_players.is_empty():return
 var s=sound_players[sound_index%sound_players.size()];sound_index+=1;s.stream=load("res://assets/"+name+".wav");s.volume_db=linear_to_db(maxf(.001,volume));s.play()
func impact(at:Vector3):
 var mesh=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.045;sphere.height=.09;mesh.mesh=sphere;var material=StandardMaterial3D.new();material.albedo_color=Color("e4ba70");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=material;add_child(mesh);mesh.position=at
 get_tree().create_timer(.13).timeout.connect(mesh.queue_free)
func nearest_piece():
 var best=null;var distance=2.8
 for piece in get_tree().get_nodes_in_group("placed"):
  var d=player.global_position.distance_to(piece.global_position)
  if d<distance:best=piece;distance=d
 return best
func interaction_prompt() -> String:
 if placement_kind!="":return "" if placement_valid else placement_reason
 var loot=world.nearest_loot(player.global_position)
 if loot!=null:return "E / A  ·  Take "+(catalog.ITEMS[loot.kind].name if catalog.ITEMS.has(loot.kind) else loot.kind.capitalize()+" ×"+str(loot.amount))
 var piece=nearest_piece()
 if piece!=null:
  var name=catalog.ITEMS[piece.data.kind].name
  return ("E / A  Use   ·   " if piece.data.kind in ["door","storage"] else "")+"G / LB  Move   ·   X / D-pad ↓  Recover "+name
 return ""
func interact():
 var loot=world.nearest_loot(player.global_position)
 if loot!=null:
  if state.collect(loot.id,loot.kind,loot.amount):loot.node.queue_free();sound("pickup");toast("Collected "+loot.kind+" ×"+str(loot.amount))
  return
 var piece=nearest_piece()
 if piece==null:return
 if piece.data.kind=="door":piece.toggle()
 if piece.data.kind=="storage":ui.storage_menu(int(piece.data.id))
func move_nearest():
 var piece=nearest_piece()
 if piece==null:return
 begin_placement(piece.data.kind,int(piece.data.id))
func pickup_nearest():
 var piece=nearest_piece()
 if piece==null:return
 if not piece.data.contents.is_empty():toast("Empty the supply chest before moving it to inventory");return
 if state.remove(int(piece.data.id)):piece.queue_free();sound("pickup");toast("Recovered item / full construction refund")
func begin_placement(kind:String,ident:int=-1):
 if ident<0 and not state.can_afford(kind):toast("Collect this object or gather its materials first");return
 cancel_placement();close_overlay();placement_kind=kind;moving_id=ident;placement_height=0;placement_distance=4;placement_yaw=player.yaw
 if ident>=0:placement_yaw=float(state.find_object(ident).yaw)
 placement_preview=assets.model(catalog.ITEMS[kind].asset);add_child(placement_preview);ghost_material(placement_preview,Color(.5,.9,.4,.5))
func cancel_placement():
 placement_kind="";moving_id=-1
 if is_instance_valid(placement_preview):placement_preview.queue_free()
 placement_preview=null
func cancel_if_moving(ident:int):
 if ident==moving_id:cancel_placement()
func ghost_material(root:Node,color:Color):
 if root is MeshInstance3D:
  var material=root.material_override
  if material==null:material=StandardMaterial3D.new()
  material.albedo_color=color;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;root.material_override=material;root.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 for child in root.get_children():ghost_material(child,color)
func moving_rid() -> RID:
 for piece in get_tree().get_nodes_in_group("placed"):
  if int(piece.data.id)==moving_id:return piece.get_rid()
 return RID()
func update_placement():
 var forward=Vector3(-sin(player.yaw),0,-cos(player.yaw))
 var horizontal=player.global_position+forward*placement_distance
 var excluded:Array[RID]=[player.get_rid()]
 var moving=moving_rid()
 if moving.is_valid():excluded.append(moving)
 # Camera ray chooses actual floors, tables and shelves. Distance control remains available on pad.
 var origin=player.camera.global_position;var endpoint=origin-player.camera.global_basis.z*12
 var ray=PhysicsRayQueryParameters3D.create(origin,endpoint,1,excluded)
 var hit=get_world_3d().direct_space_state.intersect_ray(ray)
 if not hit.is_empty() and hit.normal.y>.65 and player.global_position.distance_to(hit.position)<placement_distance+1:
  horizontal=hit.position
 var down=PhysicsRayQueryParameters3D.create(Vector3(horizontal.x,horizontal.y+3,horizontal.z),Vector3(horizontal.x,horizontal.y-4,horizontal.z),1,excluded)
 # If the reticle hits a shelf/table, preserve the selected level rather than the highest shelf.
 if not hit.is_empty() and hit.normal.y>.65:down.from=hit.position+Vector3.UP*.06
 var support=get_world_3d().direct_space_state.intersect_ray(down)
 var bottom=float(support.position.y)+.015 if not support.is_empty() else 0.0
 placement_position=Vector3(horizontal.x,bottom+placement_height,horizontal.z)
 if snap and catalog.built(placement_kind):placement_position.x=round(placement_position.x/3)*3;placement_position.z=round(placement_position.z/3)*3;placement_yaw=snappedf(placement_yaw,PI/2)
 placement_preview.position=placement_position;placement_preview.rotation.y=placement_yaw
 placement_reason=validate_placement(placement_kind,placement_position,placement_yaw,moving_id)
 placement_valid=placement_reason=="Ready to place"
 ghost_material(placement_preview,Color(.48,.83,.35,.48) if placement_valid else Color(.95,.25,.16,.48))
func validate_placement(kind:String,at:Vector3,yaw:float,ident:int=-1) -> String:
 if not at.is_finite() or not is_finite(yaw) or not catalog.ITEMS.has(kind):return "Invalid transform"
 if Vector2(at.x-world.safe_center.x,at.z-world.safe_center.z).length()>20:return "Build and furnish within 20m of HOME"
 if at.distance_to(player.global_position)>10:return "Move closer"
 if ident<0 and not state.can_afford(kind):return "Insufficient materials / item unavailable"
 var size:Vector3=catalog.ITEMS[kind].size
 var excluded:Array[RID]=[player.get_rid()]
 var moving=moving_rid()
 if moving.is_valid():excluded.append(moving)
 var q=PhysicsShapeQueryParameters3D.new();var shape=BoxShape3D.new();shape.size=Vector3(maxf(.03,size.x-.05),maxf(.03,size.y-.06),maxf(.03,size.z-.05));q.shape=shape;q.transform=Transform3D(Basis(Vector3.UP,yaw),at+Vector3.UP*(size.y/2+.015));q.collision_mask=1;q.exclude=excluded
 if not get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():return "Occupied — leave clearance from walls and furniture"
 # Ensure the player is not enclosed by a newly placed object.
 var local=Basis(Vector3.UP,yaw).inverse()*(player.global_position+Vector3.UP*.9-at)
 if absf(local.x)<size.x/2+.35 and absf(local.z)<size.z/2+.35 and local.y>-.2 and local.y<size.y+1:return "Leave room for yourself"
 var supported=0
 var offsets=[Vector3.ZERO]
 if catalog.built(kind) and kind!="roof":
  offsets=[Vector3(-size.x*.35,0,-size.z*.35),Vector3(size.x*.35,0,size.z*.35)]
 for offset in offsets:
  var point=at+Basis(Vector3.UP,yaw)*offset
  var ray=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.06,point-Vector3.UP*.13,1,excluded)
  var hit=get_world_3d().direct_space_state.intersect_ray(ray)
  if not hit.is_empty() and hit.normal.y>.65:supported+=1
 if kind=="roof":
  # Roof must sit on the top of at least two wall/frame supports at its perimeter.
  supported=0
  for offset in [Vector3(-1.5,0,0),Vector3(1.5,0,0),Vector3(0,0,-1.5),Vector3(0,0,1.5)]:
   var point=at+Basis(Vector3.UP,yaw)*offset;var ray=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.08,point-Vector3.UP*.18,1,excluded);var hit=get_world_3d().direct_space_state.intersect_ray(ray)
   if not hit.is_empty() and hit.collider.is_in_group("placed") and hit.collider.data.kind in ["wall","door"]:supported+=1
  if supported<2:return "Roof needs two wall/frame supports at its edges"
 elif supported<offsets.size():return "Needs a level supporting surface — adjust height"
 return "Ready to place"
func confirm_placement():
 if placement_kind=="":return
 # Recheck in the same transaction; stale previews never consume resources.
 placement_reason=validate_placement(placement_kind,placement_position,placement_yaw,moving_id)
 var ident=state.place(placement_kind,placement_position,placement_yaw,placement_reason=="Ready to place",moving_id)
 if ident<0:toast(placement_reason);return
 if moving_id>=0:
  for piece in get_tree().get_nodes_in_group("placed"):
   if int(piece.data.id)==moving_id:piece.queue_free()
 spawn_piece(state.find_object(ident));sound("build");toast("Placed "+catalog.ITEMS[placement_kind].name);cancel_placement()
func spawn_piece(record:Dictionary):
 var piece=Placed.new();add_child(piece);piece.configure(self,record);return piece
func objective_complete() -> bool:
 for value in state.objective.values():
  if not value:return false
 return true
func objective_text() -> String:
 var o=state.objective
 if not o.supplies:return "01  /  Collect wood and scrap on the porch."
 if not o.collectible:return "02  /  Bring home the fern near the street."
 if not o.returned:return "03  /  Return to HOME with your finds."
 if not o.decorated:return "04  /  B / Y → choose your object and place it."
 if not o.built:return "05  /  Build a barricade or supply chest."
 return "HOME, SWEET HOME  ✓\nKeep scavenging. Make this place yours."
func heading() -> String:
 var directions=["N","NW","W","SW","S","SE","E","NE"]
 return directions[posmod(roundi(player.yaw/(PI/4)),8)]
func integration():
 var script=load("res://tests/integration.gd").new();add_child(script);var code=await script.run(self)
 script.queue_free();await get_tree().process_frame;get_tree().quit(code)
func benchmark():
 var script=load("res://tests/benchmark.gd").new();add_child(script);await script.run(self)
 script.queue_free();await get_tree().process_frame;get_tree().quit()

func report_dir() -> String:
 var root=OS.get_environment("ZOMBIE_REPORT_DIR")
 if root=="":root=OS.get_user_data_dir()+"/verification"
 DirAccess.make_dir_recursive_absolute(root)
 return root
