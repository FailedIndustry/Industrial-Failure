extends Resource
class_name Inventory

@export var items: Array[ItemWrapper]
var owner: Player

## Drops the item passed in. Can be a fraction of what the player actually has.
## In the case of error, -1 is returned
func drop(item: ItemWrapper) -> int:
	Logger.debug("Inventory: Dropping %d %s" % [item.quantity, item.item_type.name])
	if remove(item) != 0: return -1
	
	_create_item(item)
	return 0

## Add item to inventory. CAUTION Should never be called directly, only from interaction
## on an item. This is to make sure that there are checks in place for validation.
func add(item: ItemWrapper) -> int:
	Logger.debug("Inventory: Adding %s" % item.item_type.name)
	items.append(item)
	return 0

## CAUTION This should never be called directly, only from [method drop]. This
## will create or move ItemWrapper to a new [PhysicalItem] and place it on the ground.
func _create_item(item: ItemWrapper) -> int:
	Logger.debug("Inventory: Creating %s" % item.item_type.name)
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
	
	var world: Node = owner.get_node('/root/Main')
	var physical_item = item.item_type.physical_item.instantiate()
	for child in physical_item.get_children():
		if child is NetworkedItem:
			child.item_data = item
	physical_item.global_position = end
	world.add_child(physical_item)
	Logger.info("%s" % end)
	return 0

## Removes the item passed in from inventory. Can be a fraction of what the player actually has.
## In the case of error, -1 is returned.
func remove(item: ItemWrapper) -> int:
	var index: int = filter_for_type(item.item_type)
	# in the case of [method filter_for_type] errored
	if index == -1: return -1
	var to_change = items[index]
	if to_change.quantity > item.quantity:
		to_change.quantity -= item.quantity
		return 0
	elif to_change.quantity == item.quantity:
		# Make sure that the owner of the item is no longer the owner of the inventory
		if to_change.owner == owner:
			to_change.owner = null
		items.remove_at(index)
		return 0
	else:
		Logger.error("inventory.remove: Tried to remove more than inv has")
		return -1

## Returns -1 in case of no match or error
func filter_for_type(type: ItemType):
	var index: int = -1
	for i: int in range(0, items.size()):
		if items[i].item_type == type:
			# If the index has already been set
			if index != -1: 
				Logger.error("Two items of same type in array")
				return -1
			else:
				index = i
	
	return index

