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
	var slot_data = slot_datas[index]
	if slot_data \
			and slot_data.item_data == grabbed_slot_data.item_data \
			and slot_data.item_data.stackable \
			# Although stacking to max 100 would be nice, we are implimenting
			# weight system that would make this irrelivant
			and slot_data.quantity + grabbed_slot_data.quantity < slot_data.MAX_STACK_SIZE:
		slot_datas[index].quantity += grabbed_slot_data.quantity
		inventory_updated.emit(self)
		return null
	else:
		slot_datas[index] = grabbed_slot_data
		inventory_updated.emit(self)
		return slot_data

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
	
