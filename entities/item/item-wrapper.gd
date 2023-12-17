extends Resource
class_name ItemWrapper

@export var quantity: int = 1 : set = set_quantity
@export var item_type: ItemType
@export var id: int

func set_quantity(value: int) -> void:
	if value < 0:
		Logger.error("ItemData.set_quantity: quantity %s < 0" % value)
	quantity = value

## This should be changed to owner_id or something like that
var owner: Object
