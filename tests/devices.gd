extends Node
var game
var checks:int=0
var failures:int=0
func check(condition:bool,label:String):
 checks+=1
 if not condition:failures+=1
 print("PASS: " if condition else "FAIL: ",label)
func wait(seconds:float=.12):await get_tree().create_timer(seconds).timeout
func finger(ident:int,at:Vector2,pressed:bool):
 var e=InputEventScreenTouch.new();e.index=ident;e.position=game.get_viewport().get_final_transform()*at;e.pressed=pressed;Input.parse_input_event(e)
func drag(ident:int,at:Vector2,delta:Vector2):
 var transform=game.get_viewport().get_final_transform()
 var e=InputEventScreenDrag.new();e.index=ident;e.position=transform*at;e.relative=transform.basis_xform(delta);Input.parse_input_event(e)
func tap(action:String):
 var at=game.touch.buttons[action].rect.get_center()
 finger(5,at,true);await wait(.04);finger(5,at,false);await wait()
func capture(name:String):
 await RenderingServer.frame_post_draw
 game.get_viewport().get_texture().get_image().save_png(game.report_dir()+"/"+name+".png")
func run(owner_game) -> int:
 game=owner_game;game.new_game();await wait(.4)
 for enemy in get_tree().get_nodes_in_group("zombies"):enemy.set_physics_process(false)
 var touch=game.touch;check(touch.active(),"Touch layout is enabled in isolated test")
 check(InputMap.action_get_events("fire").all(func(e):return not e is InputEventMouseButton),"Emulated touch clicks cannot become gunfire")
 for action in touch.buttons:check(Rect2(Vector2.ZERO,touch.size).encloses(touch.buttons[action].rect),action+" is inside the landscape viewport")
 var origin=game.player.position;var center=touch.move_center
 finger(0,center,true);drag(0,center+Vector2(0,-60),Vector2(0,-60));await wait(.35)
 check(game.player.position.distance_to(origin)>.7,"Touch stick moves the survivor")
 var yaw=game.player.yaw;var aim=touch.buttons.aim.rect.get_center()
 finger(1,Vector2(640,340),true);drag(1,Vector2(700,340),Vector2(60,0));await wait()
 check(absf(game.player.yaw-yaw)>.1 and Input.is_action_pressed("forward"),"A second finger looks while movement stays held")
 finger(1,Vector2(700,340),false);finger(0,center,false);await wait()
 check(not Input.is_action_pressed("forward"),"Lifting the movement finger stops its axis")
 await tap("aim");check(game.player.aiming,"Aim toggle raises the weapon")
 var magazine=game.state.magazine
 finger(2,touch.buttons.fire.rect.get_center(),true);await wait(.32);finger(2,touch.buttons.fire.rect.get_center(),false);await wait()
 check(game.state.magazine<magazine,"Independent fire finger shoots while aiming")
 check(not Input.is_action_pressed("fire"),"Fire releases when its finger lifts")
 await tap("reload");check(game.player.reload_left>0,"Touch reload starts the real reload transaction")
 await tap("inventory");check(game.overlay and game.inventory_open,"Touch Pack opens inventory")
 check(not Input.is_action_pressed("aim") and touch.held.is_empty(),"Opening a menu releases virtual holds")
 await capture("inventory");game.close_overlay();await wait()
 await tap("sprint");finger(0,center,true);drag(0,center+Vector2(0,-60),Vector2(0,-60));await wait()
 check(game.player.sprinting,"Sprint toggle works with movement")
 touch.notification(NOTIFICATION_APPLICATION_FOCUS_OUT);await wait()
 check(touch.held.is_empty() and not Input.is_action_pressed("sprint") and not Input.is_action_pressed("forward"),"App focus loss clears all touch holds")
 game.state.inventory.wood=30;game.state.inventory.scrap=30;game.player.velocity=Vector3.ZERO
 game.begin_placement("wall");await wait()
 check(touch.buttons.has("confirm") and touch.buttons.has("rotate_right"),"Building replaces combat buttons with placement controls")
 var rotation=game.placement_yaw;await tap("rotate_right")
 check(game.placement_yaw>rotation,"Touch rotation updates placement")
 var height=game.placement_height;await tap("height_up");check(game.placement_height>height,"Touch height control updates placement")
 await capture("placement");await tap("cancel");check(game.placement_kind=="","Touch cancel leaves materials unspent")
 check(game.state.inventory.wood==30 and game.state.inventory.scrap==30,"Cancelled touch placement is transactional")
 var car=game.get_tree().get_nodes_in_group("vehicles")[0];car.enter(game.player);await wait()
 check(touch.buttons.interact.label=="Exit" and touch.buttons.jump.label=="Brake","Driving exposes exit and brake controls")
 finger(0,center,true);drag(0,center+Vector2(0,-60),Vector2(0,-60));await wait(.3)
 check(absf(car.speed)>.5,"Touch stick accelerates the actual car")
 touch.release_all();car.exit_driver();game.recover_player();await wait()
 finger(0,center,true);drag(0,center+Vector2(0,-60),Vector2(0,-60));await wait()
 var pad=InputEventJoypadMotion.new();pad.axis=JOY_AXIS_LEFT_Y;pad.axis_value=-1;pad.device=0;Input.parse_input_event(pad);await wait()
 print("HANDOFF: shown=",touch.shown," virtual=",touch.held," forward=",Input.is_action_pressed("forward"))
 check(not touch.shown and touch.held.is_empty() and Input.is_action_pressed("forward"),"Gamepad handoff hides touch controls and preserves the first stick event")
 pad.axis_value=0;Input.parse_input_event(pad);await wait()
 check(not Input.is_action_pressed("forward"),"Releasing the physical stick clears its restored action")
 finger(0,center,true);finger(0,center,false);await wait();check(touch.shown,"Touch can resume after using a gamepad")
 game.ui.pause();await wait();await capture("pause")
 var rect=game.ui.panel.get_global_rect()
 check(Rect2(Vector2.ZERO,game.get_viewport().get_visible_rect().size).encloses(rect),"Scrollable menu stays inside the landscape viewport")
 game.notification(NOTIFICATION_WM_GO_BACK_REQUEST);await wait()
 check(not game.overlay,"Android Back closes an open menu")
 game.notification(NOTIFICATION_WM_GO_BACK_REQUEST);await wait()
 check(game.overlay,"Android Back pauses ongoing play")
 check(not game.get_tree().quit_on_go_back,"Android Back does not quit the app automatically")
 game.close_overlay();await wait();await capture("touch-play")
 var report={"checks":checks,"failures":failures,"graphical":DisplayServer.get_name()!="headless","physical_device":false,"physical_gamepad":false}
 var f=FileAccess.open(game.report_dir()+"/devices.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("DEVICE INPUT TESTS: ",checks," checks, ",failures," failures")
 return 1 if failures else 0
