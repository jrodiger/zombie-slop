extends RefCounted
var scenes:Dictionary={}
func model(kind:String) -> Node3D:
 var path="res://assets/"+kind+".glb"
 if not scenes.has(kind):
  if not ResourceLoader.exists(path):
   push_error("Missing external asset: "+path+". Run scripts/assemble.py.")
   return Node3D.new()
  scenes[kind]=load(path)
 return scenes[kind].instantiate()
func animation(root:Node) -> AnimationPlayer:
 if root is AnimationPlayer:return root
 for child in root.get_children():
  var found=animation(child)
  if found!=null:return found
 return null
func skeleton(root:Node) -> Skeleton3D:
 if root is Skeleton3D:return root
 for child in root.get_children():
  var found=skeleton(child)
  if found!=null:return found
 return null
func animate(player:AnimationPlayer,clip:String,blend:float=.15,loop:bool=true):
 if player==null:return
 for name in player.get_animation_list():
  if name==clip or name.ends_with("/"+clip) or name.ends_with(clip):
   if player.current_animation!=name:
    player.get_animation(name).loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
    player.play(name,blend)
   return
