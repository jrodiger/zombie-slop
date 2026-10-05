extends CanvasLayer
const ModelPreview=preload("res://game/model_preview.gd")
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
func touch_mode() -> bool:
 return OS.has_feature("mobile") or "--touch-test" in OS.get_cmdline_user_args()
const INK=Color("101a18")
const CREAM=Color("e4dfcc")
const GOLD=Color("e4ba70")
func configure(owner_game):
 game=owner_game;root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 var theme=Theme.new();theme.default_font_size=18
 var style=StyleBoxFlat.new();style.bg_color=Color("22322c");style.border_color=Color("52644e");style.set_border_width_all(1);style.set_corner_radius_all(3);style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=12;style.content_margin_bottom=12
 theme.set_stylebox("normal","Button",style)
 var hover=style.duplicate();hover.bg_color=Color("40533c");hover.border_color=GOLD;theme.set_stylebox("hover","Button",hover);theme.set_stylebox("focus","Button",hover)
 var pressed=style.duplicate();pressed.bg_color=Color("16241e");pressed.border_color=GOLD;theme.set_stylebox("pressed","Button",pressed)
 var disabled=style.duplicate();disabled.bg_color=Color("1a2520");disabled.border_color=Color("36443a");theme.set_stylebox("disabled","Button",disabled);theme.set_color("font_disabled_color","Button",Color("778778"))
 theme.set_color("font_color","Label",CREAM);theme.set_color("font_color","Button",CREAM);root.theme=theme
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud)
 var top=PanelContainer.new();top.position=Vector2(28,24);top.size=Vector2(330,80);top.add_theme_stylebox_override("panel",panel_style());hud.add_child(top)
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",8);top.add_child(v)

 status=text("",17);status.visible=false;v.add_child(status)
 objective=text("",18);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;v.add_child(objective)
 compass=text("",16,GOLD);compass.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);compass.position=Vector2(-300,32);compass.size=Vector2(270,30);compass.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(compass)
 var bottom=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);bottom.position=Vector2(28,-150);bottom.size=Vector2(340,116);bottom.add_theme_stylebox_override("panel",panel_style());hud.add_child(bottom)
 var bv=VBoxContainer.new();bottom.add_child(bv);ammo=text("",21,GOLD);bv.add_child(ammo)
 health=ProgressBar.new();health.max_value=100;health.show_percentage=false;health.custom_minimum_size=Vector2(310,12);bv.add_child(health)
 stamina=ProgressBar.new();stamina.max_value=100;stamina.show_percentage=false;stamina.custom_minimum_size=Vector2(310,5);bv.add_child(stamina)
 prompt=text("",19,CREAM);prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);prompt.position=Vector2(-350,-95);prompt.size=Vector2(700,40);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(prompt)
 message=text("",20,GOLD);message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);message.position=Vector2(-350,164);message.size=Vector2(700,60);message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(message)
 placement=text("",18);placement.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);placement.position=Vector2(-460,-175);placement.size=Vector2(430,145);placement.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(placement)
 var controls=text("Tab Inventory  ·  B Build  ·  E Interact  ·  V Weapons  ·  H Heal  ·  Esc Pause",15,Color("d3d3bd"));controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);controls.position=Vector2(-360,-30);controls.size=Vector2(720,25);controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(controls)
 performance=text("",14);performance.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);performance.position=Vector2(-350,64);performance.size=Vector2(320,60);performance.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(performance)
 reticle=text("·",32,CREAM);reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER);reticle.position=Vector2(-20,-20);reticle.size=Vector2(40,40);reticle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(reticle)
 damage=ColorRect.new();damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);damage.color=Color(.65,.14,.08,0);damage.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(damage)
 for pair in [[health,Color("c66e54")],[stamina,Color("c3ae70")]]:
  var background=StyleBoxFlat.new();background.bg_color=Color("27382e");background.set_corner_radius_all(3)
  var fill=background.duplicate();fill.bg_color=pair[1]
  pair[0].add_theme_stylebox_override("background",background);pair[0].add_theme_stylebox_override("fill",fill)
 if touch_mode():
  controls.hide();bottom.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
  bottom.position=Vector2(28,124);bottom.size=Vector2(340,116)
  compass.position.y=108;performance.position.y=140
  prompt.position.y=-278;placement.position.y=-660;placement.size.y=100
func text(value:String,size:int,color:Color=CREAM) -> Label:
 var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l
func panel_style() -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(.045,.075,.06,.94);s.border_color=Color("52644e");s.set_border_width_all(1);s.set_corner_radius_all(8);s.content_margin_left=22;s.content_margin_right=22;s.content_margin_top=18;s.content_margin_bottom=18;return s
func _process(delta):
 if game==null:return
 hud.visible=game.running and not game.overlay
 notice_left=maxf(0,notice_left-delta);message.visible=notice_left>0
 if not game.running:return
 health.value=game.state.health;stamina.value=game.player.sprint_energy
 ammo.text="%s  %02d / %03d\nHEALTH %d"%[game.player.profile().name,game.state.magazine,int(game.state.inventory[game.player.profile().ammo]),game.state.health]
 if game.player.profile().get("melee",false):ammo.text="%s\nHEALTH %d"%[game.player.profile().name,game.state.health]
 if game.player.driving!=null:ammo.text="DRIVING  ·  %d km/h\nHEALTH %d"%[roundi(absf(game.player.driving.speed)*3.6),game.state.health]
 if game.player.reload_left>0:ammo.text="RELOADING…  %.1fs\nHEALTH %d"%[game.player.reload_left,game.state.health]
 status.text="DAY 01   ·   WOOD %d   SCRAP %d   MED %d"%[game.state.inventory.wood,game.state.inventory.scrap,game.state.inventory.medkit]
 objective.text=game.objective_text()
 compass.text="HOME  %dm  ·  %s"%[game.player.global_position.distance_to(game.world.safe_center),game.heading()]
 prompt.text=game.interaction_prompt()
 placement.visible=game.placement_kind!=""
 if placement.visible:
  placement.text="%s  ·  %s\n%s\nWheel / Q / R  rotate  ·  Shift + wheel  fine (free)\n↑ / ↓  height  ·  + / −  distance  ·  T  snap\nLMB / A  place  ·  Esc / B  cancel"%[game.catalog.ITEMS[game.placement_kind].name,"SNAP" if game.snap else "FREE",game.placement_reason]
  if touch_mode():placement.text="%s  ·  %s\n%s\nUse Rotate, Raise/Lower, Nearer/Farther and Snap\nPlace confirms  ·  Cancel or Android Back returns"%[game.catalog.ITEMS[game.placement_kind].name,"SNAP" if game.snap else "FREE",game.placement_reason]
  placement.modulate=Color("c0db89") if game.placement_valid else Color("e99279")
 reticle.text="×" if game.hit_feedback>0 else ("+" if game.player.aiming else "·")
 damage.color.a=game.damage_feedback*.55
 performance.visible=game.show_performance
 if performance.visible:performance.text="%d FPS  ·  %.2f ms process\n%d enemies  ·  %d placed\n%d draws  ·  %d triangles"%[Engine.get_frames_per_second(),Performance.get_monitor(Performance.TIME_PROCESS)*1000,get_tree().get_nodes_in_group("zombies").size(),game.state.objects.size(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)]
func toast(value:String):
 message.text=value;notice_left=3.0
func clear_panel():
 if is_instance_valid(panel):panel.queue_free()
 panel=null
func open_panel(title:String,subtitle:String="",wide:bool=false) -> VBoxContainer:
 game.inventory_open=false
 clear_panel();game.overlay=true;hud.visible=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if game.touch!=null:game.touch.release_all()
 var extent=get_viewport().get_visible_rect().size
 var dimensions=Vector2(minf(920 if wide else 600,extent.x-32),minf(760 if wide else 640,extent.y-32))
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);panel.position=-dimensions/2;panel.size=dimensions;panel.add_theme_stylebox_override("panel",panel_style());root.add_child(panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;panel.add_child(scroll)
 panel_content=VBoxContainer.new();panel_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel_content.add_theme_constant_override("separation",10);scroll.add_child(panel_content)
 panel_content.add_child(text(title,31,GOLD))
 if subtitle!="":var label=text(subtitle,16);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;panel_content.add_child(label)
 return panel_content
func button(value:String,callback:Callable,parent:Node=null) -> Button:
 var b=Button.new();b.text=value;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size.y=96 if touch_mode() else 52;b.pressed.connect(func():game.sound("ui",.25);callback.call());(parent if parent!=null else panel_content).add_child(b);return b
func survivor_selector(parent:Node):
 var row=HBoxContainer.new();parent.add_child(row);row.add_child(text("SURVIVOR",16,GOLD))
 var select=OptionButton.new();row.add_child(select);select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;select.size_flags_vertical=Control.SIZE_SHRINK_CENTER;select.custom_minimum_size.y=48
 var keys=game.catalog.CHARACTERS.keys()
 for kind in keys:select.add_item(game.catalog.CHARACTERS[kind])
 var preview=ModelPreview.new();row.add_child(preview);preview.configure(game,game.state.character,true)
 select.select(keys.find(game.state.character));select.item_selected.connect(func(index):game.change_character(keys[index]);select.select(keys.find(game.state.character));preview.show_model(game.state.character))
func item_button(kind:String,label:String,callback:Callable,parent:Node=null) -> Button:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);(parent if parent!=null else panel_content).add_child(row)
 var icon=ModelPreview.new();row.add_child(icon);icon.configure(game,kind)
 var b=button(label,callback,row);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return b
func start_screen():
 open_panel("ZOMBIE SLOP","CEDAR END  /  AN OFFLINE SURVIVAL SANDBOX",true)
 panel_content.add_child(text("Explore · Scavenge · Furnish · Fortify",18,GOLD))
 survivor_selector(panel_content)
 button("NEW NEIGHBORHOOD",game.new_game).grab_focus()
 var continue_button=button("CONTINUE SAVED GAME",game.load_game);continue_button.disabled=not FileAccess.file_exists(game.save_path) and not FileAccess.file_exists(game.save_path+".bak")
 button("SETTINGS",settings)
 button("QUIT",game.quit_game)
 var help=text("WASD / left stick  move   ·   Mouse / right stick  look\nRMB / LT  aim   ·   LMB / RT  fire   ·   R / X  reload\nE / A  collect   ·   B / Y  build & furnish\nShift / L3  sprint   ·   H / D-pad up  heal\nTab / Back  inventory   ·   V / D-pad left  cycle weapons",16);panel_content.add_child(help)
func pause():
 open_panel("TAKE A BREATH","Game paused. Essential progress is saved locally.")
 button("RESUME",game.close_overlay).grab_focus()
 button("SAVE GAME",game.save_game)
 button("INVENTORY" if touch_mode() else "INVENTORY  ·  TAB",backpack)
 button("BUILD / DECORATE",build_menu)
 button("SETTINGS",settings)
 button("RETURN HOME IF STUCK",func():game.recover_player();game.close_overlay())
 button("SAVE AND QUIT",func():if game.save_game():game.quit_game())
func settings():
 open_panel("FIELD SETTINGS","Adjust picture, controls and sound. Changes apply immediately.")
 var cap=CheckButton.new();cap.text="Limit to 60 FPS";cap.button_pressed=bool(game.state.settings.cap);cap.toggled.connect(func(on):game.state.settings.cap=on;game.apply_settings());panel_content.add_child(cap);cap.grab_focus()
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
  b.disabled=not game.state.can_afford(kind)
  if first==null and not b.disabled:first=b
 list.add_child(text("CONSTRUCTION",16,GOLD))
 for kind in game.catalog.BUILD:
  var costs:Array=[]
  for key in game.catalog.ITEMS[kind].cost:costs.append(str(game.catalog.ITEMS[kind].cost[key])+" "+key)
  var b=button(game.catalog.ITEMS[kind].name+"  ·  "+", ".join(costs),func():game.begin_placement(kind),list);b.disabled=not game.state.can_afford(kind)
  if first==null and not b.disabled:first=b
 var back=button("BACK",game.close_overlay)
 (back if first==null else first).grab_focus()
func loot_menu(entry:Dictionary):
 open_panel(entry.title.to_upper(),entry.address+"  /  Search the contents and take what you need.")
 panel_content.add_child(text("YOUR PACK  ·  Wood %d  Scrap %d  Food %d  Water %d"%[game.state.inventory.wood,game.state.inventory.scrap,game.state.inventory.food,game.state.inventory.water],16))
 var items=game.world.container_items(entry)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(540,350);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;panel_content.add_child(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 var first:Button=null
 for item in items:
  var label=game.catalog.WEAPONS[item.kind].name if item.kind in game.catalog.WEAPONS else item.kind.replace("_"," ").capitalize()
  var b=item_button(item.kind,label+"   ×"+str(item.amount),func():game.take_container_item(entry.id,item.id);loot_menu(entry),list)
  if first==null:first=b
 if items.is_empty():panel_content.add_child(text("Nothing left here. Try another house.",20))
 var close=button("CLOSE",game.close_overlay)
 (close if first==null else first).grab_focus()
func backpack():
 if not game.running:return
 open_panel("INVENTORY","Health %d / 100  ·  Close or Android Back returns to play"%game.state.health if touch_mode() else "Health %d / 100  ·  Tab closes your pack"%game.state.health,true);game.inventory_open=true
 survivor_selector(panel_content)
 var columns=HBoxContainer.new();columns.add_theme_constant_override("separation",24);columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;panel_content.add_child(columns)
 for section in ["EQUIPMENT & SUPPLIES","FURNISHINGS & MATERIALS"]:
  var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(410,230);scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(scroll)
  var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list);list.add_child(text(section,16,GOLD))
  if section=="EQUIPMENT & SUPPLIES":
   for kind in game.state.weapons:
    var entry=game.catalog.WEAPONS[kind];var rounds="" if entry.get("melee",false) else "  ·  %d / %d"%[game.state.weapons[kind],game.state.inventory[entry.ammo]]
    button(entry.name+rounds+("  ✓" if kind==game.state.equipped else "  Equip"),func():game.player.equip(kind);backpack(),list)
   for kind in ["medkit","food","water"]:
    var b=button("%s  ×%d  ·  Use"%[kind.capitalize(),game.state.inventory[kind]],func():game.player.use_supply(kind);backpack(),list);b.disabled=game.state.inventory[kind]<=0 or game.state.health>=100
   for kind in ["ammo","rifle_ammo","shells"]:list.add_child(text("%s   ×%d"%[kind.replace("_"," ").capitalize(),game.state.inventory[kind]],17))
  else:
   for kind in ["wood","scrap","vehicle_parts"]:list.add_child(text("%s   ×%d"%[kind.replace("_"," ").capitalize(),game.state.inventory[kind]],20))
   for kind in game.catalog.FURNITURE:
    var b=button("%s  ×%d   ·   Place"%[game.catalog.ITEMS[kind].name,game.state.inventory[kind]],func():game.begin_placement(kind),list);b.disabled=game.state.inventory[kind]<=0
 var car=game.world.nearest_vehicle(game.player.global_position)
 if car!=null and not car.armored:
  button("FIT VEHICLE ARMOR  ·  2 vehicle parts + 10 scrap",func():car.upgrade();backpack())
 var row=HBoxContainer.new();panel_content.add_child(row);button("BUILD / DECORATE",build_menu,row);button("CLOSE" if touch_mode() else "CLOSE  ·  TAB",game.close_overlay,row).grab_focus()
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
  b.disabled=carried==0
  var take=button("Take all",func():game.state.transfer(ident,kind,int(game.state.find_object(ident).contents.get(kind,0)),false);storage_menu(ident),row);take.disabled=stored==0
  if list.get_child_count()==2:(take if b.disabled else b).grab_focus()
 button("CLOSE",game.close_overlay)
func death():
 open_panel("THE STREET GOT YOU","Your last manual/autosave checkpoint is preserved. Restart the neighborhood or continue from that checkpoint.")
 button("LOAD LAST SAVE",game.load_game).grab_focus()
 survivor_selector(panel_content)
 button("NEW NEIGHBORHOOD",game.new_game)
 button("QUIT",game.quit_game)
