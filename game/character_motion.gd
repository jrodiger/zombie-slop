extends RefCounted
# Two disjoint sets of bone tracks keep reload/fire independent of foot cadence.
# Copies are local to the player; previews and other instances keep their sources.
const LOWER_BONES=["Root","Body","UpperLeg.L","LowerLeg.L","Foot.L","PoleTarget.L","UpperLeg.R","LowerLeg.R","Foot.R","PoleTarget.R"]
var legs:AnimationPlayer
var owner_game
func lower_track(animation:Animation,index:int) -> bool:
 var path=animation.track_get_path(index)
 return path.get_subname_count()>0 and str(path.get_subname(0)) in LOWER_BONES
func configure(game,upper:AnimationPlayer):
 owner_game=game
 if upper==null:return
 legs=AnimationPlayer.new();legs.name="LocomotionLayer";upper.get_parent().add_child(legs);legs.root_node=upper.root_node
 legs.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
 var library=AnimationLibrary.new()
 for clip in ["Idle","Walk","Run"]:
  var source=upper.get_animation(clip)
  if source==null:continue
  var filtered=source.duplicate()
  for index in range(filtered.get_track_count()-1,-1,-1):
   if not lower_track(filtered,index):filtered.remove_track(index)
  filtered.loop_mode=Animation.LOOP_LINEAR;library.add_animation(clip,filtered)
 legs.add_animation_library("",library)
 for name in upper.get_animation_library_list():
  var original=upper.get_animation_library(name);var private_library=AnimationLibrary.new()
  for clip in original.get_animation_list():
   var animation=original.get_animation(clip).duplicate()
   if clip!="Death":
    for index in range(animation.get_track_count()-1,-1,-1):
     if lower_track(animation,index):animation.remove_track(index)
   private_library.add_animation(clip,animation)
  upper.remove_animation_library(name);upper.add_animation_library(name,private_library)
 legs.play("Idle");legs.seek(0,true)
func update(speed:float,sprinting:bool):
 if not is_instance_valid(legs):return
 if not owner_game.running or owner_game.overlay:legs.pause();return
 var clip="Idle" if speed<.25 else ("Run" if sprinting else "Walk")
 if legs.current_animation!=clip:
  var phase=legs.current_animation_position/maxf(.001,legs.current_animation_length)
  var moving=legs.current_animation in ["Walk","Run"] and clip in ["Walk","Run"]
  legs.play(clip,.16)
  if moving:legs.seek(phase*legs.current_animation_length)
 elif not legs.is_playing():legs.play()
 legs.speed_scale=1 if clip=="Idle" else clampf(speed/(5.8 if clip=="Run" else 3.4),.65,1.35)
func stop():
 if is_instance_valid(legs):legs.active=false
