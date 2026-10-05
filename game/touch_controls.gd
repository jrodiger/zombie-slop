extends Control
# Multiple fingers own independent controls. Gameplay uses action events, so
# touch, keyboard and controller share the same transactions and combat code.
var game
var enabled:bool=false
var shown:bool=true
var fingers:Dictionary={}
var held:Dictionary={}
var buttons:Dictionary={}
var move_center=Vector2.ZERO
var move_tip=Vector2.ZERO
var context:String=""
const RADIUS=66.0
func configure(owner_game):
 game=owner_game;enabled=OS.has_feature("mobile") or "--touch-test" in OS.get_cmdline_user_args()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
 visible=false;resized.connect(layout)
func active() -> bool:
 return enabled and shown and game.running and not game.overlay
func add_button(action:String,label:String,at:Vector2,extent=Vector2(96,96),toggle:bool=false):
 buttons[action]={"label":label,"rect":Rect2(at,extent),"toggle":toggle}
func layout():
 if game==null:return
 buttons.clear();move_center=Vector2(110,size.y-116);move_tip=move_center
 var x=size.x;var y=size.y
 add_button("pause","Menu",Vector2(x-116,14),Vector2(96,80))
 add_button("inventory","Pack",Vector2(x-224,14),Vector2(96,80))
 add_button("build","Build",Vector2(x-332,14),Vector2(96,80))
 if game.placement_kind!="":
  var actions=["rotate_left","rotate_right","height_down","height_up","distance_down","distance_up","snap","cancel"]
  var labels=["Rotate −","Rotate +","Lower","Raise","Nearer","Farther","Snap","Cancel"]
  for i in range(actions.size()):add_button(actions[i],labels[i],Vector2(x-224+(i%2)*108,y-540+floori(i/2.0)*108))
  add_button("confirm","Place",Vector2(x-224,y-108),Vector2(204,88))
 else:
  add_button("fire","Fire",Vector2(x-116,y-116))
  add_button("aim","Aim",Vector2(x-224,y-116),Vector2(96,96),true)
  add_button("interact","Exit" if game.player.driving!=null else "Use",Vector2(x-332,y-116))
  add_button("jump","Brake" if game.player.driving!=null else "Jump",Vector2(x-116,y-224))
  if game.player.driving==null:
   add_button("reload","Reload",Vector2(x-224,y-224))
   add_button("weapon_next","Weapon",Vector2(x-332,y-224))
   add_button("sprint","Sprint",Vector2(196,y-116),Vector2(96,96),true)
   add_button("heal","Heal",Vector2(386,140),Vector2(96,80))
   add_button("move_item","Move item",Vector2(x-440,y-116))
   add_button("pickup_item","Take item",Vector2(x-440,y-224))
 queue_redraw()
func send_action(action:String,pressed:bool):
 if pressed:held[action]=true
 else:held.erase(action)
 var event=InputEventAction.new();event.action=action;event.pressed=pressed
 Input.parse_input_event(event)
func move_axes(point:Vector2):
 var vector=(point-move_center)/RADIUS
 if vector.length()>1:vector=vector.normalized()
 move_tip=move_center+vector*RADIUS
 for pair in [["left",maxf(0,-vector.x)],["right",maxf(0,vector.x)],["forward",maxf(0,-vector.y)],["back",maxf(0,vector.y)]]:
  if pair[1]>.08:Input.action_press(pair[0],pair[1]);held[pair[0]]=true
  elif held.has(pair[0]):Input.action_release(pair[0]);held.erase(pair[0])
 queue_redraw()
func release_all():
 for action in held.keys():Input.action_release(action)
 held.clear();fingers.clear();move_tip=move_center;queue_redraw()
func _input(event):
 if not enabled:return
 if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value)>.25:
  if shown:
   release_all();shown=false
   # The physical event has already updated Input before _input runs.
   # Releasing a shared virtual action clears it; Android may ignore a
   # repeated unchanged axis event, so restore its mapped strength now.
   for action in InputMap.get_actions():
    var strength=event.get_action_strength(action)
    if strength>0:Input.action_press(action,strength)
   # Deliver buttons once to gameplay after consuming the original event.
   get_viewport().set_input_as_handled();Input.call_deferred("parse_input_event",event)
  return
 if not game.running or game.overlay:return
 if event is InputEventScreenTouch:
  if not shown:shown=true;layout()
  if event.pressed:
   var role="look"
   for action in buttons:
    if buttons[action].rect.has_point(event.position):
     role=action
     if buttons[action].toggle:send_action(action,not held.has(action));role="toggle"
     else:send_action(action,true)
     break
   if role=="look" and event.position.distance_to(move_center)<RADIUS*1.5 and not fingers.values().has("move"):
    role="move";move_axes(event.position)
   elif role=="look" and fingers.values().has("look"):role="ignored"
   fingers[event.index]=role
  elif fingers.has(event.index):
   var role=fingers[event.index];fingers.erase(event.index)
   if role=="move":move_axes(move_center)
   elif held.has(role) and not fingers.values().has(role):send_action(role,false)
  get_viewport().set_input_as_handled();queue_redraw()
 elif event is InputEventScreenDrag and fingers.has(event.index):
  var role=fingers[event.index]
  if role=="move":move_axes(event.position)
  elif role=="look":
   game.player.yaw-=event.relative.x*.003*float(game.state.settings.sensitivity)
   game.player.pitch=clampf(game.player.pitch-event.relative.y*.003*float(game.state.settings.sensitivity),-.95,.38)
  get_viewport().set_input_as_handled()
func _process(_delta):
 if not enabled:return
 var next_context=str(game.placement_kind)+str(game.player.driving!=null)
 if next_context!=context:release_all();context=next_context;layout()
 if not active() and (not held.is_empty() or not fingers.is_empty()):release_all()
 visible=active()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:release_all()
func _draw():
 if not active():return
 draw_circle(move_center,RADIUS,Color(.06,.12,.10,.45))
 draw_arc(move_center,RADIUS,0,TAU,48,Color(.8,.8,.7,.65),2,true)
 draw_circle(move_tip,28,Color(.7,.75,.6,.65))
 var font=ThemeDB.fallback_font
 draw_string(font,move_center+Vector2(-24,5),"Move",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 for action in buttons:
  var entry=buttons[action];var rect:Rect2=entry.rect
  draw_style_box(button_style(held.has(action)),rect)
  draw_string(font,rect.position+Vector2(0,rect.size.y/2+6),entry.label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,18,Color("e4dfcc"))
func button_style(pressed:bool) -> StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=Color(.25,.35,.22,.85) if pressed else Color(.06,.12,.10,.65)
 style.border_color=Color("e4ba70") if pressed else Color(.8,.8,.7,.65)
 style.set_border_width_all(1);style.set_corner_radius_all(10);return style
