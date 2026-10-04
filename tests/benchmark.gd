extends Node
# Exported graphical stress run. Never reads or writes the player's normal save.
var game
var samples:Array[float]=[]
var sections:Dictionary={}
var counts:Dictionary={}
var draws:Array=[]
var cpu:Dictionary={}
var elapsed:float=0
var stage:int=-1
var last_time:int=0
var duration:float=600.0
var hitches:Array=[]
var shadows:bool=true
var capped:bool=false
const STAGES=["street traversal","populated supply view","interior","shooting encounter","50-piece furnished base","placement preview","forest and river","driving"]
func run(owner_game):
 game=owner_game
 if "--benchmark-short" in OS.get_cmdline_user_args():duration=60.0
 shadows=not "--benchmark-low" in OS.get_cmdline_user_args()
 capped="--benchmark-capped" in OS.get_cmdline_user_args()
 game.new_game();game.state.settings.cap=capped;game.state.settings.shadows=shadows;game.apply_settings();game.show_performance=true
 game.state.inventory.wood=1000;game.state.inventory.scrap=1000
 # Stress base has 50 settled, collision-bearing objects, no active rigid bodies.
 for i in range(50):
  var kind=["plant","radio","chair","storage","barricade"][i%5]
  if kind in game.catalog.FURNITURE:game.state.inventory[kind]=100
  var at=Vector3(-37+(i%10)*2.6,.015,42+(i/10)*2)
  var ident=game.state.place(kind,at,float(i%4)*PI/2,true)
  if ident<0:push_error("Benchmark placement failed: "+kind);continue
  game.spawn_piece(game.state.find_object(ident))
 game.state.player_position=[-24,.2,20]
 await get_tree().create_timer(5).timeout
 for name in STAGES:sections[name]=[];cpu[name]={"physics":[],"process":[],"draws":[]}
 last_time=Time.get_ticks_usec()
 print("BENCHMARK BEGIN: %s seconds, exported=%s, cap=%s, shadows=%s, 50 placed"%[duration,not OS.has_feature("editor"),Engine.max_fps,shadows])
 while elapsed<duration:
  await get_tree().process_frame
  var now=Time.get_ticks_usec();var ms=float(now-last_time)/1000.0;last_time=now;elapsed+=ms/1000.0
  var current=int(minf(elapsed,duration-.001)/(duration/(STAGES.size()*2.0)))%STAGES.size()
  if current!=stage:
   game.cancel_placement();stage=current
   Input.action_release("forward");Input.action_release("fire");Input.action_release("aim")
   Input.action_release("left")
   if game.player.driving!=null:game.player.driving.exit_driver()
   if stage==0:game.player.position=Vector3(0,.2,20);game.player.yaw=0;game.player.pitch=-.18
   if stage==1:game.player.position=Vector3(14,.2,-25);game.player.yaw=-PI/2;game.player.pitch=-.15
   if stage==2:game.player.position=Vector3(-24,.3,29);game.player.yaw=PI;game.player.pitch=-.2
   if stage==3:game.player.position=Vector3(0,.2,-35);game.player.yaw=0;game.player.pitch=-.1;game.world.alert_zombies(game.player.position,60)
   if stage==4:game.player.position=Vector3(-24,.2,37);game.player.yaw=PI;game.player.pitch=-.24
   if stage==5:game.player.position=Vector3(-24,.2,38);game.player.yaw=PI;game.player.pitch=-.35;game.begin_placement("wall")
   if stage==6:game.player.position=Vector3(104,game.world.ground_height(104,55)+.2,55);game.player.yaw=PI/2;game.player.pitch=-.25
   if stage==7:
    var car=get_tree().get_nodes_in_group("vehicles")[3];car.position=Vector3(0,.04,80);car.rotation.y=PI;car.speed=0;car.velocity=Vector3.ZERO;car.reset_physics_interpolation();car.enter(game.player)
   game.player.reset_physics_interpolation()
   print("BENCHMARK STAGE ",STAGES[stage]," at ",int(elapsed),"s")
  if game.state.health<100:game.state.health=100
  # Keep the stress population alive throughout the measurement, including
  # shooting sections; normal gameplay damage and respawning remain unchanged.
  for enemy in get_tree().get_nodes_in_group("zombies"):
   if enemy.alive:enemy.hp=10000
  # Camera motion and bounded real movement exercise traversal; reset each lap.
  if stage==0:
   Input.action_press("forward")
   if game.player.position.z< -65:game.player.position=Vector3(0,.2,20);game.player.reset_physics_interpolation()
  elif stage==3:
   game.state.magazine=12;Input.action_press("aim");Input.action_press("fire")
  elif stage in [1,4]:game.player.yaw+=.08*ms/1000
  elif stage==6:game.player.yaw+=.16*ms/1000
  elif stage==7:
   Input.action_press("forward")
   var car=game.player.driving
   if car.position.z< -80:car.position=Vector3(0,.04,80);car.speed=0;car.velocity=Vector3.ZERO;car.reset_physics_interpolation()
  samples.append(ms);sections[STAGES[stage]].append(ms)
  if ms>25:
   hitches.append({"elapsed_seconds":elapsed,"stage":STAGES[stage],"frame_ms":ms,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000})
  if samples.size()%60==0:
   draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   cpu[STAGES[stage]].physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
   cpu[STAGES[stage]].process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
   cpu[STAGES[stage]].draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
   counts[STAGES[stage]]=get_tree().get_nodes_in_group("zombies").size()
 if game.placement_kind!="":game.cancel_placement()
 Input.action_release("forward");Input.action_release("aim");Input.action_release("fire")
 if game.player.driving!=null:game.player.driving.exit_driver()
 var stats=statistics(samples)
 var report={"engine":Engine.get_version_info().string,"exported":not OS.has_feature("editor"),"renderer":RenderingServer.get_current_rendering_method()+" / "+RenderingServer.get_current_rendering_driver_name(),"duration_seconds":elapsed,"resolution":[game.get_viewport().get_visible_rect().size.x,game.get_viewport().get_visible_rect().size.y],"settings":{"cap":capped,"max_fps":Engine.max_fps,"vsync_mode":DisplayServer.window_get_vsync_mode(),"shadows":shadows},"placed_objects":game.state.objects.size(),"enemy_count_by_section":counts,"overall":stats,"sections":{},"sampled_cpu_ms_and_draws":cpu,"method":"Automated graphical scene; eight equal segments repeated twice. Damage neutralized and ammo replenished only in benchmark. Includes route movement, camera pans, actual fire, live placement preview, forest/river view and real vehicle acceleration. A physical controller and human play session are not implied."}
 for name in sections:report.sections[name]=statistics(sections[name])
 report.hitches_over_25ms=hitches
 var f=FileAccess.open(game.report_dir()+"/performance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 await RenderingServer.frame_post_draw
 game.get_viewport().get_texture().get_image().save_png(game.report_dir()+"/benchmark.png")
 print("BENCHMARK COMPLETE ",JSON.stringify(stats))
func statistics(values:Array) -> Dictionary:
 if values.is_empty():return {}
 var sorted=values.duplicate();sorted.sort();var total=0.0
 for v in values:total+=v
 var slow=sorted.slice(maxi(0,sorted.size()-maxi(1,int(sorted.size()*.01))))
 var slow_total=0.0
 for v in slow:slow_total+=v
 return {"frames":values.size(),"average_fps":values.size()*1000.0/total,"p50_ms":sorted[int(sorted.size()*.5)],"p95_ms":sorted[mini(sorted.size()-1,int(sorted.size()*.95))],"p99_ms":sorted[mini(sorted.size()-1,int(sorted.size()*.99))],"one_percent_low_fps":slow.size()*1000.0/slow_total,"max_ms":sorted.back(),"frames_over_16_67ms":values.filter(func(v):return v>16.667).size(),"frames_over_20ms":values.filter(func(v):return v>20.0).size(),"frames_over_33_33ms":values.filter(func(v):return v>33.333).size()}
