extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 99

@export var stackable = true
@export var item_data: ItemData
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

func set_quantity(value: int):
	quantity = value
	if quantity > 1 and not item_data.stackable:
		Logger.error("slot_data.set_quantity: Adding more than 1 to item_data \
					  when not stackable. Adding one to preserve total quantity")
		push_error("slot_data.set_quantity: %s is stacking but not stackable" 
				  % item_data.name)
	elif quantity < 0:
		Logger.fatal("slot_data.set_quantity: quantity is less than 0. \
					  There is most likely a duplication glitch somewhere.")
		push_error("QUANTITY LESS THAN 0 NOT ALLOWED >:(")
		Logger.fatal("Continuing due to lack of ability to rectify this issue.")
