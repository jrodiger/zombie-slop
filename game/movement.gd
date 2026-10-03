extends RefCounted
# Probe the top of a low obstruction, then sweep the full capsule upward and
# forward. Checking the raised path keeps walls and ceilings authoritative.
static func step_up(body:CharacterBody3D,motion:Vector3,height:float=.30) -> bool:
 if not body.is_on_floor() or body.velocity.y>0 or motion.length_squared()<.000001:return false
 var obstacle=KinematicCollision3D.new()
 if not body.test_move(body.global_transform,motion,obstacle):return false
 if obstacle.get_normal().dot(Vector3.UP)>=cos(body.floor_max_angle):return false
 var capsule=body.get_child(0) as CollisionShape3D
 var foot_offset=capsule.position.y-capsule.shape.height*.5
 var ahead=body.global_position+motion+motion.normalized()*(capsule.shape.radius+.04)
 var top=ahead+Vector3.UP*(height+foot_offset)
 var hit=body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top,top+Vector3.DOWN*(height+.02),body.collision_mask,[body.get_rid()]))
 if hit.is_empty() or hit.normal.dot(Vector3.UP)<cos(body.floor_max_angle):return false
 var rise=float(hit.position.y)-foot_offset-body.global_position.y+.002
 if rise<=.005 or rise>height:return false
 var raised=body.global_transform
 if body.test_move(raised,Vector3.UP*rise):return false
 raised.origin.y+=rise
 if body.test_move(raised,motion):return false
 body.global_position=raised.origin+motion
 return true
