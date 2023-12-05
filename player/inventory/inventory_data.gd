extends Resource
class_name InventoryData

signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button: int)

@export var slot_datas: Array[SlotData]

func grab_slot_data(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)

	# returning slot_data will 'swap' grabbed item with the one that is
	# being hovered over. This includes null
	return slot_data

func drop_slot_data(from_index: int, to_index: int) -> int:
	var from = slot_datas[from_index]
	var to = slot_datas[to_index]
	var initial_quantity = get_quantity(from, to)
	
	var merge_type = merge_in_inventory(from_index, to_index)
	
	if get_quantity(from, to) != initial_quantity:
		Logger.error("drop_slot_data: mismatch in end quantity after functions")
	
	match merge_type:
		StackableType.FullyMergeable:
			return -1
		StackableType.PartiallyMergeable:
			return from_index
		StackableType.NotMergeable:
			return -1
		StackableType.Switch:
			return -1
	
	Logger.error("drop_slot_data: unreachable")
	return -1

func get_quantity(a: SlotData, b: SlotData) -> int:
	var a_quantity = a.quantity if a else 0
	var b_quantity = b.quantity if b else 0
	return a_quantity + b_quantity
	

func merge_in_inventory(from_index: int, to_index: int) -> StackableType:
	if from_index == to_index:
		Logger.debug("Same index was selected. Returning")
		return StackableType.NotMergeable
	
	var from = slot_datas[from_index]
	var to = slot_datas[to_index]
	var merge_type = is_mergeable(from, to)
	match merge_type:
		StackableType.Switch:
			Logger.debug("Not Mergeable. Switching")
			var temp = from
			slot_datas[from_index] = to
			slot_datas[to_index] = from
		StackableType.FullyMergeable:
			Logger.debug("FullyMerging %s and %s" \
					   % [from.quantity, to.quantity])
			to.quantity += from.quantity
			slot_datas[from_index] = null
			inventory_updated.emit(self)
			Logger.debug("Final: %s" % to.quantity)
		StackableType.PartiallyMergeable:
			Logger.debug("PartialMerge %s and %s" \
					   % [from.quantity, to.quantity])
			var remaining = to.quantity + from.quantity - to.MAX_STACK_SIZE
			to.quantity = to.MAX_STACK_SIZE
			from.quantity = remaining
			
			Logger.debug("Setting 'to' slot to %s" % to.quantity)
			Logger.debug("Setting 'from' slot to %s" % from.quantity)
		StackableType.NotMergeable:
			Logger.debug("Not Mergeable")
			pass
			
	inventory_updated.emit(self)
	return merge_type

enum StackableType {
	NotMergeable,
	Switch,
	PartiallyMergeable,
	FullyMergeable
}

func is_mergeable(from: SlotData, to: SlotData) -> StackableType:	
	if !from or !from.item_data:
		Logger.error("is_mergeable: from item has null values!")
		return StackableType.NotMergeable
	elif to and (!to.item_data or to.quantity > to.MAX_STACK_SIZE):
		Logger.error("is_mergeable: but has invalid data (\
					  item: %s, quanitty: %s, MAX_STACK_SIZE: %s)" \
				   % [to.item_data, to.quantity, to.MAX_STACK_SIZE])
		return StackableType.NotMergeable
	elif !to:
		Logger.info("is_mergeable: 'to' item empty, valid for switch")
		return StackableType.Switch
	
	var same_item = to.item_data == from.item_data
	if to.quantity < to.MAX_STACK_SIZE \
			and same_item \
			and to.stackable:
		var total_quantity = to.quantity + from.quantity
		if total_quantity < to.MAX_STACK_SIZE:
			return StackableType.FullyMergeable
		else:
			return StackableType.PartiallyMergeable
	
	return StackableType.Switch

func drop_single_slot_data(from_index: int, to_index: int) -> int:
	var from = slot_datas[from_index]
	var to = slot_datas[to_index]
	
	var stackable = is_mergeable(from, to) 
	if !to:
		var single_data = from.duplicate()
		single_data.quantity  = 1
		from.quantity 		 -= 1
		slot_datas[to_index] = single_data
	elif to.item_data == from.item_data \
			and to.quantity < to.MAX_STACK_SIZE:
		to.quantity 	+= 1
		from.quantity 	-= 1
		
	
	if from.quantity <= 0:
		slot_datas[from_index] = null
	
	inventory_updated.emit(self)
	return from_index if from.quantity > 0 else -1

func on_slot_clicked(index: int, button: int):
	Logger.debug("Inv slot %d clicked" % index)
	inventory_interact.emit(self, index, button)
	
