extends Node

var INTERACTION_DISTANCE = 2

func interact_raycast(player: Player) -> Dictionary:
	var mask = 0b111111101
	var origin = player.camera.global_position
	var rotation = player.global_rotation
	var x = cos(rotation.x)*sin(rotation.y)
	var z = cos(rotation.x)*cos(rotation.y)
	var y = sin(rotation.x)
	var end = origin + Vector3(-x,y,-z).normalized() * INTERACTION_DISTANCE
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = mask
	query.collide_with_areas = true
	
	var result = player.get_world_3d().direct_space_state.intersect_ray(query)
	Logger.info("%s" % result)
	return result
	
