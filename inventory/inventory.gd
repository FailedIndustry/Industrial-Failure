extends Resource
class_name Inventory

@export var items: Array[ItemWrapper]
var owner: Player

## Add item to inventory. CAUTION Should never be called directly, only from interaction
## on an item. This is to make sure that there are checks in place for validation.
func add(item: ItemWrapper) -> int:
	Logger.debug("Inventory: Adding %s" % item.item_type.name)
	items.append(item)
	return 0

## Removes the item passed in from inventory. Can be a fraction of what the player actually has.
## In the case of error, -1 is returned.
func remove(item: ItemWrapper, id: int = -1) -> int:
	var index: int = filter_for_type(item.item_type)
	
	### Guard functions ###
	if index == -1:
		Logger.error("inventory.remove: Type %s not found in inventory" % item.item_type.name)
		return -1
	var to_change = items[index]
	if id != -1 and id != to_change.id:
		Logger.error("inventory.remove: Id %d does not match input id %d" % [to_change.id, id])
		return -1
	
	### Remove logic ###
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
		if items[i].item_type.id == type.id:
			# If the index has already been set
			if index != -1: 
				Logger.error("inventory.filter_for_type: two %s in inventory" % type.name)
				return -1
			else:
				index = i
	
	return index

