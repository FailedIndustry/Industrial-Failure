extends Node3D
class_name PhysicalItem
@onready var mesh = $MeshInstance3D
@onready var area = $Area3D
@export var item_data: ItemWrapper

## Interact entry point for each local item. This will be sent to the server
## in another function.
## 
## This function is present on every client (and host) mirror of an item and
## is merely a wrapper around [method server_update_state]. Use this function
## to identify if an item is interactable and then call the interaction through
## this method. See [method player.interact] for an example.
func interact():
	Logger.debug("item.interact: peer_id %d interacted with item" \
				% multiplayer.get_unique_id())
	
	# id of 1 is always the server. The server will verify this call
	# and then send it to all clients.
	server_update_state.rpc_id(1)

## Call the server to update the state of the item. The server will verify
## this request and then send it to all clients.
@rpc("any_peer", 	# Any client can request and update in state
	 "call_local",	# Make sure client updates their local state too
	 "reliable"		# Make sure the server gets the request
) func server_update_state():
	var sender_id = multiplayer.get_remote_sender_id()
	Logger.debug("item.server_update_state: peer_id %d interacted with item" \
				% sender_id)
	
	# Find each node in the area of `area`, and if the player is the same one
	# who called this function, then propogate the call.
	# Note: get_overlapping_bodies conforms to the mask of `area`. Area at time of 
	# this comment has collision mask of 0b10 (position 2, Player).
	for node in area.get_overlapping_bodies():
		Logger.info("item.server_update_state: %s in range" % node)
		# So long as the node is a player, it's name should be the peer_id
		# of that player. See [Main]
		if node.name == str(sender_id):
			Logger.info("item.server_update_state: %d is verified as in range" \
					   % sender_id)
			if verify_raycast(node):
				Logger.info("item.server_update_state: %d raycast verified" \
					   % sender_id)
				local_update_state.rpc(node)
		else:
			Logger.info("item.server_update_state: %s id != %d id" \
					  % [node.name, sender_id])
	
@rpc("authority",	# Only accept rpc calls from the server
	 "call_local",	# Also initiate this call locally (on the server in this case)
	 "reliable"		# Make sure all clients get this call
) func local_update_state(player: Player):
	Logger.info("local_update_state")
	Logger.info("%d" % multiplayer.get_unique_id())
	
	add_item_to_player(player)

func add_item_to_player(player: Player) -> void:
	player.inventory.add(item_data)
	self.queue_free()

func verify_raycast(node):
	const ITEM_MASK = 0b100
	var origin = node.camera.project_ray_origin(Vector2.ZERO)
	var end = origin + node.camera.project_ray_normal(Vector2.ZERO) * 100
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collision_mask = ITEM_MASK
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		Logger.debug("item.verify_raycast: No item found in raycast")
		return false
	
	if result["collider_id"] == get_instance_id():
		Logger.debug("item.verify_raycast: Raycast verified")
		return true
