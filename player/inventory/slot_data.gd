extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 99

@export var item_data: ItemData
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

func set_quantity(value: int):
	quantity = value
	if quantity > 1 and not item_data.stackable:
		Logger.Error("slot_data.set_quantity: Adding more than 1 to item_data")
		push_error("slot_data.set_quantity: %s is stacking but not stackable" 
				  % item_data.name)
