extends Resource
class_name Inventory

@export var items: Array[ItemWrapper]
var owner

## Add item to inventory. CAUTION Should never be called directly, only from interaction
## on an item. This is to make sure that there are checks in place for validation.
func add(item: ItemWrapper) -> int:
	Logger.debug("Inventory: Adding %s" % item.item_type.name)
	items.append(item)
	return 0

## Removes the item passed in from inventory. Can be a fraction of what the player actually has.
## In the case of error, -1 is returned.
func remove(type: ItemType, quantity: int, id: int = -1) -> ItemWrapper:
	var index: int = filter_for_type(type)
	
	### Guard functions ###
	if index == -1:
		Logger.error("inventory.remove: Type %s not found in inventory" % type.name)
		return
	var to_change = items[index]
	if id != -1 and id != to_change.id:
		Logger.error("inventory.remove: Id %d does not match input id %d" % [to_change.id, id])
		return
	
	### Remove and Return ###
	if to_change.quantity > quantity:
		to_change.quantity -= quantity
		
		var server_globals: ServerGlobal = owner.get_node("/root/ServerGlobal")
		var new_item: ItemWrapper = server_globals.create_item(to_change.owner, 
															   to_change.item_type,
															   quantity)
		return new_item
	elif to_change.quantity == quantity:
		items.remove_at(index)
		return to_change
	else:
		Logger.error("inventory.remove: Tried to remove more than inv has")
		return

## Returns -1 in case of no match or error
func filter_for_type(type: ItemType):
	var index: int = -1
	for i: int in range(0, items.size()):
		if items[i].item_type.id == type.id:
			# If the index has already been set
			if index != -1: 
				Logger.error("inventory.filter_for_type: two %s in inventory" % type.name)
				return -1
			else:
				return i
	
	return index

