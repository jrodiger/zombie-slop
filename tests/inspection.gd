extends Node
var game
var failed:int=0
func shot(name:String,at:Vector3,target:Vector3):
 # Fixed room cameras inspect geometry without the avatar obscuring the lens.
 game.player.visual.visible=false
 game.player.camera.global_position=at;game.player.camera.look_at(target)
 await get_tree().create_timer(.15).timeout
 await RenderingServer.frame_post_draw
 game.get_viewport().get_texture().get_image().save_png(game.report_dir()+"/"+name+".png")
 game.player.visual.visible=true
func walk(target:Vector3) -> bool:
 game.player.set_physics_process(true)
 for i in range(240):
  var offset=target-game.player.position;offset.y=0
  if offset.length()<.18:break
  game.player.yaw=atan2(-offset.x,-offset.z);Input.action_press("forward")
  await get_tree().physics_frame
 Input.action_release("forward");game.player.velocity=Vector3.ZERO;game.player.set_physics_process(false)
 var reached=Vector2(game.player.position.x-target.x,game.player.position.z-target.z).length()<.4
 print("ROOM WALK ",target," reached=",reached," actual=",game.player.position)
 if not reached:failed+=1
 return reached
func run(owner_game):
 game=owner_game;game.new_game();game.player.set_process(false)
 for enemy in get_tree().get_nodes_in_group("zombies"):enemy.set_physics_process(false)
 for house_index in [0,1,6,7]:
  var house=game.world.HOUSES[house_index];var at:Vector3=house.at
  game.player.position=at+Vector3(0,.2,-9);game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation()
  await shot("house-%d-front"%house_index,at+Vector3(-10,3,-13),at+Vector3(0,2,0))
  await shot("house-%d-eaves"%house_index,at+Vector3(9,3.25,-9),at+Vector3(0,3.2,0))
  await shot("house-%d-backyard"%house_index,at+Vector3(9,4,9),at+Vector3(4,.6,6.3))
  await shot("house-%d-backyard-close"%house_index,at+Vector3(5.3,1.7,5.8),at+Vector3(4,.6,6.3))
  await walk(at+Vector3(0,.2,-2));await walk(at+Vector3(-2,.2,-2))
  await shot("house-%d-kitchen"%house_index,at+Vector3(1.2,1.9,-1.5),at+Vector3(-3.9,1.1,-3.5))
  var fridge=game.world.containers.filter(func(entry):return entry.address==house.address and entry.kind=="fridge")[0]
  game.world.search_container(fridge);await get_tree().create_timer(.3).timeout
  await shot("house-%d-fridge-open"%house_index,at+Vector3(-2.1,1.4,-2),at+Vector3(-4.5,1.1,-3.5));game.world.close_containers()
  await walk(at+Vector3(0,.2,-1));await walk(at+Vector3(0,.2,2.5));await walk(at+Vector3(3.2,.2,2.5))
  await shot("house-%d-bedroom"%house_index,at+Vector3(.4,1.8,3),at+Vector3(4.6,.75,3.5))
  var safe=game.world.containers.filter(func(entry):return entry.address==house.address and entry.kind=="safe")[0]
  game.world.search_container(safe);await get_tree().create_timer(.3).timeout
  await shot("house-%d-safe-open"%house_index,at+Vector3(2.9,1.15,2.1),at+Vector3(4.7,.6,3.5));game.world.close_containers()
  await shot("house-%d-bedroom-reverse"%house_index,at+Vector3(4.7,1.7,4.4),at+Vector3(-3,.7,3))
  await walk(at+Vector3(0,.2,2.5));await walk(at+Vector3(0,.2,-2));await walk(at+Vector3(0,.2,-9))
 game.player.position=Vector3(105,game.world.ground_height(105,55)+.2,55)
 await shot("river-bridge",Vector3(101,7,55),Vector3(89,-.2,55))
 await shot("river-east-approach",Vector3(112,5,57),Vector3(100,0,55))
 await shot("forest-slope",Vector3(-104,8,57),Vector3(-116,4,78))
 game.ui.backpack();await shot("inventory",game.player.camera.global_position,game.player.camera.global_position-game.player.camera.global_basis.z)
 print("VISUAL INSPECTION WALK FAILURES ",failed)
 return 1 if failed else 0
