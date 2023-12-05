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

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var initial_quantity = get_initial_quantity(grabbed_slot_data, index)
	
	var result = merge_in_inventory(grabbed_slot_data, index)
	
	if verify_end_quantity(result, index, initial_quantity):
		Logger.fatal("drop_slot_data: mismatch in end quantity after functions")
	
	return result

func get_initial_quantity(grabbed_slot_data: SlotData, index: int) -> int:
	var slot_quantity: int
	if !slot_datas[index]:
		slot_quantity = 0
	else:
		slot_quantity = slot_datas[index].quantity
	
	var grabbed_quantity: int
	if !grabbed_slot_data:
		grabbed_quantity = 0
	else:
		grabbed_quantity = grabbed_slot_data.quantity
	
	return grabbed_quantity + slot_quantity

func verify_end_quantity(result: SlotData, index: int, initial_quantity: int) -> bool:
	if !result:
		return initial_quantity != slot_datas[index].quantity
	elif !slot_datas[index]:
		return result.quantity != initial_quantity
	else:
		return initial_quantity != result.quantity + slot_datas[index].quantity

func merge_in_inventory(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	match is_mergeable(grabbed_slot_data, index):
		StackableType.NotStackable:
			Logger.debug("NotStackable. Switching")
			slot_datas[index] = grabbed_slot_data
			inventory_updated.emit(self)
			return slot_data
		StackableType.FullyMergeable:
			Logger.debug("FullyMerging %s and %s" \
					   % [slot_datas[index].quantity, grabbed_slot_data.quantity])
			slot_data.quantity += grabbed_slot_data.quantity
			Logger.debug("Final: %s" % slot_data.quantity)
			inventory_updated.emit(self)
			return null
		StackableType.PartiallyMergeable:
			Logger.debug("PartialMerge %s and %s" \
					   % [slot_datas[index].quantity, grabbed_slot_data.quantity])
			var remaining = grabbed_slot_data.quantity - (slot_data.MAX_STACK_SIZE - slot_data.quantity)
			slot_data.quantity = slot_data.MAX_STACK_SIZE
			Logger.debug("Setting slot to %s" % slot_data.quantity)
			grabbed_slot_data.quantity = remaining
			Logger.debug("Setting grabbed slot to %s" % grabbed_slot_data.quantity)
			return grabbed_slot_data
	
	return null

enum StackableType {
	NotStackable,
	PartiallyMergeable,
	FullyMergeable
}

func is_mergeable(grabbed_slot_data: SlotData, index: int) -> StackableType:	
	if !grabbed_slot_data \
			or !slot_datas[index] \
			or !grabbed_slot_data.item_data \
			or !slot_datas[index].item_data:
		Logger.error("item has null values!")
		return StackableType.NotStackable
	
	var slot_data = slot_datas[index]
	var same_item = slot_data.item_data == grabbed_slot_data.item_data
	var quantity = slot_data.quantity
	var stackable = slot_data.MAX_STACK_SIZE
	if quantity > slot_data.MAX_STACK_SIZE:
		Logger.error("%s %ss is more than max!" % [slot_data.quantity, slot_data.name])
		return StackableType.NotStackable
	
	if slot_data.quantity < slot_data.MAX_STACK_SIZE \
			and same_item \
			and stackable:
		var total_quantity = slot_data.quantity + grabbed_slot_data.quantity
		if total_quantity < slot_data.MAX_STACK_SIZE:
			return StackableType.FullyMergeable
		else:
			return StackableType.PartiallyMergeable
	
	return StackableType.NotStackable

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		pass
		# TODO add functionality to stack
	else:
		var single_data = grabbed_slot_data.duplicate()
		single_data.quantity = 1
		grabbed_slot_data.quantity -= 1
		Logger.fatal('%s' % grabbed_slot_data.quantity)
		slot_datas[index] = single_data
	
	inventory_updated.emit(self)
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null

func on_slot_clicked(index: int, button: int):
	Logger.debug("Inv slot %d clicked" % index)
	inventory_interact.emit(self, index, button)
	
