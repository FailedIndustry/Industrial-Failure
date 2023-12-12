extends Resource
class_name ItemType
## A type of item, like an apple. Unlike [ItemWrapper], this does not contain
## any information that should change at runtime

@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
## Texture of the item in the inventory
@export var texture: Texture
## Physical representation of the item
@export var physical_item: Resource = preload("res://entities/item/PhysicalItem.tscn")

## Used in [member PhysicalItem.local_update_state] Has to have function 
## signature of (ItemWrapper) -> int, where 0 is sucess and anything else is 
## failure.
##
## In the case of a failure, then the physical representation of the item
## will not be deleted.
@export var on_interact: Callable = empty_function

func empty_function(_item_data) -> int:
	return 0
