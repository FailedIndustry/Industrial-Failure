extends Node
class_name WICtl
## World Interface Control. This is the interaction point for the Player class to interact with
## world state.
##
## Unlike Player class that has no RPCs, WICtl is inherantly networked and handles networking
## functions for the player.

@export var inventory: Inventory = Inventory.new()
@export var INTERACTION_DISTANCE = 2
@onready var server_global: ServerGlobal = get_node("/root/ServerGlobal")
@onready var global: Globals = get_node("/root/Globals")

## Variable to determine if a drop has completed. In [method drop_item], it gets set to -1 for not
## complete. In [method _spawn_item], it is set to the id of the item for complete.
var _drop_completed: int = -1
var player: Player

func _ready():
	var parent = get_parent()
	if parent is Player:
		player = parent
	else:
		Logger.error("WICtl: parent node must be player, but found %s" % parent)

func drop_item(item: ItemWrapper):
	Logger.debug("wictl.drop_item")
	_drop_completed = -1
	_server_drop_item.rpc_id(1, item.id, item.item_type.id, item.quantity)
	
	return 0

## Drops the item passed in. Can be a fraction of what the player actually has.
## In the case of error, -1 is returned
@rpc ("reliable","any_peer","call_local") 
func _server_drop_item(item_id: int, type_id: int, quantity: int) -> int:
	push_error("server")
	Logger.debug("%s" % multiplayer.get_remote_sender_id())
	Logger.debug("%s" % multiplayer.get_peers())
	Logger.debug("%s" % multiplayer.get_unique_id())
	var type = server_global.item_types[type_id]
	Logger.debug("wictl._server_drop_item: Dropping %d %s" % [quantity, type.name])
	var new_item = inventory.remove(type, quantity, item_id)
	new_item.owner = get_node("/root/Main/Game")
	if _server_create_item(new_item) != 0: return -1
	
	return 0

## CAUTION This should never be called directly, only from [method drop]. This
## will create or move ItemWrapper to a new [PhysicalItem] and place it on the ground.
func _server_create_item(item: ItemWrapper) -> int:
	Logger.debug("wictl._server_create_item: Creating %s" % item.item_type.name)
	var mask = 0b111111111101
	var origin = owner.camera.global_position
	var rotation = owner.camera.global_rotation
	var x = cos(rotation.x)*sin(rotation.y)
	var z = cos(rotation.x)*cos(rotation.y)
	var y = sin(rotation.x)
	var end = origin + Vector3(-x,y,-z).normalized() * 5
	
	var space_state = owner.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = mask
	var result = space_state.intersect_ray(query)
	if result:
		end = result["position"]
	
	var item_type = server_global.get_item_type_id(item.item_type)
	_spawn_item.rpc(item.id, item_type, item.quantity, end)
	return 0

@rpc("reliable", "call_local", "authority") 
func _spawn_item(item_id: int, item_type_id: int, quantity: int, position: Vector3):
	if _drop_completed == item_id: return
	_drop_completed = item_id
	
	var item_type = server_global.item_types[item_type_id]
	var item = ItemWrapper.new()
	item.item_type = item_type
	item.quantity = quantity
	var world: Node = player.get_node('/root/Main')
	var physical_item = item.item_type.physical_item.instantiate()
	for child in physical_item.get_children():
		if child is NetworkedItem:
			child.item_data = item
	world.add_child(physical_item)
	physical_item.global_position = position
	Logger.debug("%s is adding %s at %s" % [multiplayer.get_unique_id(), item.item_type.name, position])

func interact():
	var globals: Globals = get_node("/root/Globals")
	var result = globals.interact_raycast(player)
	if result.is_empty():
		Logger.debug("WICtl.interact: No item found in raycast")
		return
	
	var collider: Object = result["collider"]
	Logger.debug("WICtl.interact: raycast hit %s" % collider.name)
	for child in collider.get_children():
		Logger.debug("%s" % child)
		if child is NetworkedItem and child.has_method("interact"):
			Logger.debug("WICtl.interact: child %s is NetworkedItem. Calling interact" % child.name)
			child.interact(player)
			return
	
	Logger.debug("WICtl.interact: No NetworkedItem found.")
