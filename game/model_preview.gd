extends SubViewportContainer
# Render the same imported mesh used in play; no static icon can drift from it.
var viewport:SubViewport
var stage:Node3D
var camera:Camera3D
var model:Node3D
var game
var survivor:bool=false
func configure(owner_game,kind:String,character:bool=false):
 game=owner_game;survivor=character;mouse_filter=Control.MOUSE_FILTER_IGNORE;stretch=true
 custom_minimum_size=Vector2(180,200) if character else Vector2(76,64)
 viewport=SubViewport.new();viewport.size=Vector2i(360,400) if character else Vector2i(152,128);viewport.own_world_3d=true;viewport.handle_input_locally=false;add_child(viewport)
 stage=Node3D.new();viewport.add_child(stage)
 var env=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("192823");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.75;env.environment=settings;stage.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.2;stage.add_child(light)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;stage.add_child(camera)
 show_model(kind)
func show_model(kind:String):
 if is_instance_valid(model):stage.remove_child(model);model.queue_free()
 if survivor:
  model=game.assets.model("survivor" if kind=="matt" else "survivor-"+kind)
  for entry in game.catalog.WEAPONS:
   var weapon=model.find_child(str(game.catalog.WEAPONS[entry].get("model",entry.capitalize())),true,false)
   if weapon!=null:weapon.visible=false
  stage.add_child(model);game.assets.animate(game.assets.animation(model),"Idle",0)
  model.rotation.y=.35;camera.position=Vector3(0,1,4);camera.look_at(Vector3(0,1,0));camera.size=2.35
 else:
  model=item_model(kind);stage.add_child(model)
  var bounds=game.world.model_bounds(model);var center=bounds.get_center();var extent=maxf(.12,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
  camera.position=center+Vector3(1,.75,1.5).normalized()*extent*3;camera.look_at(center);camera.size=extent*1.35
  if kind in game.catalog.WEAPONS:
   # Imported attachments have different local orientations. Show their broad
   # profile instead of looking down a barrel and reducing the icon to a line.
   var axes=[0,1,2];axes.sort_custom(func(a,b):return bounds.size[a]>bounds.size[b])
   var long_axis=Vector3.ZERO;long_axis[axes[0]]=1;var up=Vector3.ZERO;up[axes[1]]=1;var normal=Vector3.ZERO;normal[axes[2]]=1
   camera.position=center+(normal*3+long_axis*.12+up*.18)*extent;camera.look_at(center,up);camera.size=extent
 # Refresh only on content changes. Preview cost stops once the menu closes.
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if survivor else SubViewport.UPDATE_ONCE
func item_model(kind:String) -> Node3D:
 if game.catalog.ITEMS.has(kind):return game.assets.model(game.catalog.ITEMS[kind].asset)
 if kind in game.catalog.WEAPONS:
  var source=game.assets.model("survivor-shaun")
  var name=str(game.catalog.WEAPONS[kind].get("model",kind.capitalize()))
  var weapon=source.find_child(name,true,false)
  var copy=weapon.duplicate() if weapon!=null else Node3D.new();source.free();copy.transform=Transform3D.IDENTITY;return copy
 var representations={"food":"food-tin","water":"bottle","medkit":"medkit","wood":"woodlog","scrap":"scrap-parts","vehicle_parts":"vehicle-parts","ammo":"ammo-box","rifle_ammo":"ammo-box","shells":"ammo-box"}
 return game.assets.model(representations.get(kind,"backpack"))
