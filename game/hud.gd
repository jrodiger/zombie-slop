extends CanvasLayer
var game
var root:Control
var hud:Control
var status:Label
var objective:Label
var prompt:Label
var message:Label
var ammo:Label
var health:ProgressBar
var stamina:ProgressBar
var compass:Label
var performance:Label
var placement:Label
var damage:ColorRect
var reticle:Label
var panel:PanelContainer
var panel_content:VBoxContainer
var notice_left:float=0
const INK=Color("101a18")
const CREAM=Color("e4dfcc")
const GOLD=Color("e4ba70")
func configure(owner_game):
 game=owner_game;root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 var theme=Theme.new();theme.default_font_size=18
 var style=StyleBoxFlat.new();style.bg_color=Color("22322c");style.border_color=Color("52644e");style.set_border_width_all(1);style.set_corner_radius_all(3);style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=12;style.content_margin_bottom=12
 theme.set_stylebox("normal","Button",style)
 var hover=style.duplicate();hover.bg_color=Color("40533c");hover.border_color=GOLD;theme.set_stylebox("hover","Button",hover);theme.set_stylebox("focus","Button",hover)
 theme.set_color("font_color","Label",CREAM);theme.set_color("font_color","Button",CREAM);root.theme=theme
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud)
 var top=PanelContainer.new();top.position=Vector2(28,24);top.size=Vector2(370,145);top.add_theme_stylebox_override("panel",panel_style());hud.add_child(top)
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",8);top.add_child(v)
 v.add_child(text("ZOMBIE SLOP  /  CEDAR END",16,GOLD))
 status=text("",17);v.add_child(status)
 objective=text("",18);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;v.add_child(objective)
 compass=text("",16,GOLD);compass.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);compass.position=Vector2(-300,32);compass.size=Vector2(270,30);compass.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(compass)
 var bottom=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);bottom.position=Vector2(28,-125);bottom.size=Vector2(340,94);bottom.add_theme_stylebox_override("panel",panel_style());hud.add_child(bottom)
 var bv=VBoxContainer.new();bottom.add_child(bv);ammo=text("",21,GOLD);bv.add_child(ammo)
 health=ProgressBar.new();health.max_value=100;health.show_percentage=false;health.custom_minimum_size=Vector2(310,12);bv.add_child(health)
 stamina=ProgressBar.new();stamina.max_value=100;stamina.show_percentage=false;stamina.custom_minimum_size=Vector2(310,5);bv.add_child(stamina)
 prompt=text("",19,CREAM);prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);prompt.position=Vector2(-350,-95);prompt.size=Vector2(700,40);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(prompt)
 message=text("",20,GOLD);message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);message.position=Vector2(-350,75);message.size=Vector2(700,40);message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(message)
 placement=text("",18);placement.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);placement.position=Vector2(-460,-175);placement.size=Vector2(430,145);placement.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(placement)
 var controls=text("B  Build / decorate     E  Interact     H  Heal     F5  Save     Esc  Pause",15,Color("d3d3bd"));controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);controls.position=Vector2(-360,-30);controls.size=Vector2(720,25);controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(controls)
 performance=text("",14);performance.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);performance.position=Vector2(-350,64);performance.size=Vector2(320,60);performance.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(performance)
 reticle=text("·",32,CREAM);reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER);reticle.position=Vector2(-20,-20);reticle.size=Vector2(40,40);reticle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(reticle)
 damage=ColorRect.new();damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);damage.color=Color(.65,.14,.08,0);damage.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(damage)
func text(value:String,size:int,color:Color=CREAM) -> Label:
 var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l
func panel_style() -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(.045,.075,.06,.89);s.border_color=Color("52644e");s.set_border_width_all(1);s.content_margin_left=18;s.content_margin_right=18;s.content_margin_top=16;s.content_margin_bottom=16;return s
func _process(delta):
 if game==null:return
 hud.visible=game.running
 notice_left=maxf(0,notice_left-delta);message.visible=notice_left>0
 if not game.running:return
 health.value=game.state.health;stamina.value=game.player.sprint_energy
 ammo.text="%02d / %03d   ·   HEALTH %d"%[game.state.magazine,int(game.state.inventory.ammo),game.state.health]
 if game.player.reload_left>0:ammo.text="RELOADING…  %.1fs"%game.player.reload_left
 status.text="DAY 01   ·   WOOD %d   SCRAP %d   MED %d"%[game.state.inventory.wood,game.state.inventory.scrap,game.state.inventory.medkit]
 objective.text=game.objective_text()
 compass.text="HOME  %dm  ·  %s"%[game.player.global_position.distance_to(game.world.safe_center),game.heading()]
 prompt.text=game.interaction_prompt()
 placement.visible=game.placement_kind!=""
 if placement.visible:
  placement.text="%s  ·  %s\n%s\nQ / R  rotate   Wheel  distance\n↑ / ↓  height   LMB / A  place   Esc / B  cancel"%[game.catalog.ITEMS[game.placement_kind].name,"SNAP" if game.snap else "FREE",game.placement_reason]
  placement.modulate=Color("c0db89") if game.placement_valid else Color("e99279")
 reticle.text="×" if game.hit_feedback>0 else ("+" if game.player.aiming else "·")
 damage.color.a=game.damage_feedback*.55
 performance.visible=game.show_performance
 if performance.visible:performance.text="%d FPS  ·  %.2f ms\n%d enemies  ·  %d placed\n%d draws  ·  %d triangles"%[Engine.get_frames_per_second(),Performance.get_monitor(Performance.TIME_PROCESS)*1000,get_tree().get_nodes_in_group("zombies").size(),game.state.objects.size(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)]
func toast(value:String):
 message.text=value;notice_left=3.0
func clear_panel():
 if is_instance_valid(panel):panel.queue_free()
 panel=null
func open_panel(title:String,subtitle:String="") -> VBoxContainer:
 clear_panel();game.overlay=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);panel.position=Vector2(-300,-320);panel.size=Vector2(600,640);panel.add_theme_stylebox_override("panel",panel_style());root.add_child(panel)
 panel_content=VBoxContainer.new();panel_content.add_theme_constant_override("separation",10);panel.add_child(panel_content)
 panel_content.add_child(text(title,31,GOLD))
 if subtitle!="":var label=text(subtitle,16);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;panel_content.add_child(label)
 return panel_content
func button(value:String,callback:Callable,parent:Node=null) -> Button:
 var b=Button.new();b.text=value;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.pressed.connect(callback);(parent if parent!=null else panel_content).add_child(b);return b
func start_screen():
 open_panel("ZOMBIE SLOP","CEDAR END  /  AN OFFLINE SURVIVAL SANDBOX")
 panel_content.add_child(text("The street is quiet. The houses are not.\nFind something worth bringing home.",21))
 panel_content.add_child(text("Explore · Scavenge · Furnish · Fortify",18,GOLD))
 button("NEW NEIGHBORHOOD",game.new_game).grab_focus()
 button("CONTINUE SAVED GAME",game.load_game)
 button("SETTINGS",settings)
 button("QUIT",game.quit_game)
 var help=text("WASD / left stick  move   ·   Mouse / right stick  look\nRMB / LT  aim   ·   LMB / RT  fire   ·   R / X  reload\nE / A  collect   ·   B / Y  build & furnish\nShift / L3  sprint   ·   H / D-pad up  heal",16);panel_content.add_child(help)
func pause():
 open_panel("TAKE A BREATH","Game paused. Essential progress is saved locally.")
 button("RESUME",game.close_overlay).grab_focus()
 button("SAVE GAME",game.save_game)
 button("BUILD / DECORATE",build_menu)
 button("SETTINGS",settings)
 button("RETURN HOME IF STUCK",func():game.recover_player();game.close_overlay())
 button("SAVE AND QUIT",func():if game.save_game():game.quit_game())
func settings():
 open_panel("FIELD SETTINGS","Compatibility renderer · 1280 × 800 desktop target")
 var cap=CheckButton.new();cap.text="60 FPS cap (off = uncapped profiling)";cap.button_pressed=bool(game.state.settings.cap);cap.toggled.connect(func(on):game.state.settings.cap=on;game.apply_settings());panel_content.add_child(cap);cap.grab_focus()
 var shadows=CheckButton.new();shadows.text="Sun shadows";shadows.button_pressed=bool(game.state.settings.shadows);shadows.toggled.connect(func(on):game.state.settings.shadows=on;game.apply_settings());panel_content.add_child(shadows)
 panel_content.add_child(text("Mouse sensitivity",17));var sensitivity=HSlider.new();sensitivity.min_value=.2;sensitivity.max_value=3;sensitivity.step=.1;sensitivity.value=float(game.state.settings.sensitivity);sensitivity.value_changed.connect(func(value):game.state.settings.sensitivity=value);panel_content.add_child(sensitivity)
 panel_content.add_child(text("Sound volume",17));var volume=HSlider.new();volume.min_value=0;volume.max_value=1;volume.step=.05;volume.value=float(game.state.settings.volume);volume.value_changed.connect(func(value):game.state.settings.volume=value;game.apply_settings());panel_content.add_child(volume)
 button("BACK",func():game.save_settings();pause() if game.running else start_screen())
func build_menu():
 if not game.running:return
 open_panel("MAKE IT YOURS","Choose a carried object or a simple recipe. Materials are spent only when placement succeeds. Removing a surviving piece refunds its full cost; empty storage first.")
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(550,380);panel_content.add_child(scroll);var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 list.add_child(text("COLLECTED OBJECTS",16,GOLD))
 var first:Button=null
 for kind in game.catalog.FURNITURE:
  var entry=game.catalog.ITEMS[kind];var b=button("%s   ×%d"%[entry.name,int(game.state.inventory.get(kind,0))],func():game.begin_placement(kind),list)
  if first==null:first=b
 list.add_child(text("CONSTRUCTION",16,GOLD))
 for kind in game.catalog.BUILD:
  var costs:Array=[]
  for key in game.catalog.ITEMS[kind].cost:costs.append(str(game.catalog.ITEMS[kind].cost[key])+" "+key)
  button(game.catalog.ITEMS[kind].name+"  ·  "+", ".join(costs),func():game.begin_placement(kind),list)
 button("BACK",game.close_overlay)
 if first!=null:first.grab_focus()
func storage_menu(ident:int):
 var record=game.state.find_object(ident)
 if record.is_empty():return
 open_panel("SUPPLY CHEST","Move stacks between your pack and this chest. Contents are saved with the container.")
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(550,390);panel_content.add_child(scroll);var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for kind in game.catalog.SUPPLIES+game.catalog.FURNITURE:
  var carried=int(game.state.inventory.get(kind,0));var stored=int(record.contents.get(kind,0))
  if carried+stored==0:continue
  list.add_child(text("%s   Pack %d  /  Chest %d"%[kind.capitalize(),carried,stored],16))
  var row=HBoxContainer.new();list.add_child(row)
  var b=button("Store all",func():game.state.transfer(ident,kind,int(game.state.inventory.get(kind,0)),true);storage_menu(ident),row)
  button("Take all",func():game.state.transfer(ident,kind,int(game.state.find_object(ident).contents.get(kind,0)),false);storage_menu(ident),row)
  if list.get_child_count()==2:b.grab_focus()
 button("CLOSE",game.close_overlay)
func death():
 open_panel("THE STREET GOT YOU","Your last manual/autosave checkpoint is preserved. Restart the neighborhood or continue from that checkpoint.")
 button("LOAD LAST SAVE",game.load_game).grab_focus()
 button("NEW NEIGHBORHOOD",game.new_game)
 button("QUIT",game.quit_game)
